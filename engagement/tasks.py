"""Phase B — Memory.

A periodic job that rolls the raw UserEvent log (plus chat presence) into one
compact UserState row per user: activity windows, streaks, lifecycle stage,
churn risk, value tier, habits and a "pending" snapshot the nudge engine and
assistant will read. Pure backend; safe to run repeatedly.
"""

import logging
from collections import Counter, defaultdict
from datetime import timedelta

from celery import shared_task
from django.conf import settings
from django.contrib.auth import get_user_model
from django.utils import timezone

from .models import NudgeLog, UserEvent, UserState

logger = logging.getLogger(__name__)

User = get_user_model()

# Events that count as a real "core action" (used to mark a user activated).
CORE_ACTIONS = {
    "post_create", "post_like", "post_comment", "follow",
    "order_placed", "listing_post", "ride_request", "recharge",
    "gig_complete", "diamond_txn", "deposit",
}


def _lifecycle(now, joined, last_active, active_days_7d, events_30d):
    """Heuristic lifecycle stage. Order matters."""
    if last_active is None:
        # Never did anything trackable.
        if joined and joined >= now - timedelta(days=1):
            return UserState.STAGE_NEW
        return UserState.STAGE_CHURNED if (joined and joined < now - timedelta(days=30)) else UserState.STAGE_ONBOARDING

    days_since = (now - last_active).days
    if joined and joined >= now - timedelta(days=1) and events_30d < 3:
        return UserState.STAGE_NEW
    if days_since > 30:
        return UserState.STAGE_CHURNED
    if days_since >= 7:
        return UserState.STAGE_DORMANT
    if days_since >= 3:
        return UserState.STAGE_AT_RISK
    if active_days_7d >= 4:
        return UserState.STAGE_HABITUAL
    return UserState.STAGE_ACTIVATED


def _churn_risk(last_active, now, streak):
    if last_active is None:
        return 0.9
    days = (now - last_active).days
    risk = min(days / 30.0, 1.0)            # 0 today .. 1 at 30d idle
    risk *= max(0.4, 1.0 - streak * 0.05)   # a strong streak lowers risk
    return round(min(max(risk, 0.0), 1.0), 3)


def _value_tier(user, surfaces, has_create, has_earn):
    if getattr(user, "is_pro", False):
        return "pro"
    if has_create:
        return "creator"
    if has_earn:
        return "earner"
    return "explorer"


def _streak(day_set, today):
    """Count consecutive active days ending today (or yesterday)."""
    if not day_set:
        return 0
    # Allow the streak to still "count" if they were active yesterday.
    cursor = today if today in day_set else today - timedelta(days=1)
    if cursor not in day_set:
        return 0
    n = 0
    while cursor in day_set:
        n += 1
        cursor -= timedelta(days=1)
    return n


@shared_task
def aggregate_user_states():
    now = timezone.now()
    today = now.date()
    since_30d = now - timedelta(days=30)
    since_7d = now - timedelta(days=7)

    # --- One pass over recent events, grouped in memory (cheap at our scale) ---
    per_user_days = defaultdict(set)          # user_id -> {date}
    per_user_days_7d = defaultdict(set)
    per_user_count_30d = Counter()
    per_user_count_7d = Counter()
    per_user_last = {}                        # user_id -> datetime
    per_user_surfaces = defaultdict(Counter)
    per_user_hours = defaultdict(Counter)
    per_user_types = defaultdict(set)

    rows = UserEvent.objects.filter(
        created_at__gte=since_30d, user__isnull=False
    ).values_list("user_id", "created_at", "surface", "event_type")
    for uid, created, surface, etype in rows.iterator(chunk_size=2000):
        local = timezone.localtime(created)
        d = local.date()
        per_user_days[uid].add(d)
        per_user_count_30d[uid] += 1
        per_user_types[uid].add(etype)
        if surface:
            per_user_surfaces[uid][surface] += 1
        per_user_hours[uid][local.hour] += 1
        if created >= since_7d:
            per_user_count_7d[uid] += 1
            per_user_days_7d[uid].add(d)
        prev = per_user_last.get(uid)
        if prev is None or created > prev:
            per_user_last[uid] = created

    # Chat presence as a passive "active" signal.
    presence = {}
    try:
        from adsyconnect.models import OnlineStatus
        for uid, seen in OnlineStatus.objects.values_list("user_id", "last_seen"):
            presence[uid] = seen
    except Exception:  # pragma: no cover
        logger.exception("could not load OnlineStatus presence")

    processed = 0
    states = []
    user_qs = User.objects.all().only(
        "id", "date_joined", "last_login", "is_pro", "pro_validity",
        "kyc", "kyc_pending", "balance",
    )
    for user in user_qs.iterator(chunk_size=500):
        uid = user.id
        try:
            ev_last = per_user_last.get(uid)
            seen = presence.get(uid)
            candidates = [c for c in (ev_last, seen, user.last_login) if c]
            last_active = max(candidates) if candidates else None

            days_set = per_user_days.get(uid, set())
            streak = _streak(days_set, today)
            events_30d = per_user_count_30d.get(uid, 0)
            active_days_7d = len(per_user_days_7d.get(uid, set()))

            stage = _lifecycle(now, user.date_joined, last_active, active_days_7d, events_30d)
            types = per_user_types.get(uid, set())
            has_create = "post_create" in types
            has_earn = bool(types & {"diamond_txn", "gig_complete", "deposit"})

            top_surfaces = dict(per_user_surfaces.get(uid, Counter()).most_common(5))
            preferred_hours = [h for h, _ in per_user_hours.get(uid, Counter()).most_common(3)]

            pending = {}
            if not getattr(user, "kyc", False):
                pending["kyc"] = True
            try:
                if user.balance and float(user.balance) > 0:
                    pending["withdrawable_balance"] = float(user.balance)
            except (TypeError, ValueError):
                pass
            if getattr(user, "is_pro", False) and user.pro_validity:
                if user.pro_validity <= now + timedelta(days=3):
                    pending["subscription_expiring"] = user.pro_validity.isoformat()

            state = UserState(
                user_id=uid,
                last_active_at=last_active,
                active_days_7d=active_days_7d,
                active_days_30d=len(days_set),
                events_7d=per_user_count_7d.get(uid, 0),
                events_30d=events_30d,
                active_days_streak=streak,
                longest_streak=streak,  # refined once we persist history
                lifecycle_stage=stage,
                churn_risk=_churn_risk(last_active, now, streak),
                value_tier=_value_tier(user, top_surfaces, has_create, has_earn),
                top_surfaces=top_surfaces,
                preferred_hours=preferred_hours,
                pending=pending,
            )
            states.append(state)
            processed += 1
        except Exception:  # pragma: no cover - never let one user break the run
            logger.exception("aggregate_user_states failed for user %s", uid)

    # Upsert in bulk. longest_streak preserves the historical max.
    update_fields = [
        "last_active_at", "active_days_7d", "active_days_30d", "events_7d",
        "events_30d", "active_days_streak", "lifecycle_stage", "churn_risk",
        "value_tier", "top_surfaces", "preferred_hours", "pending", "updated_at",
    ]
    existing_longest = dict(
        UserState.objects.values_list("user_id", "longest_streak")
    )
    for s in states:
        s.longest_streak = max(s.active_days_streak, existing_longest.get(s.user_id, 0))
    UserState.objects.bulk_create(
        states,
        update_conflicts=True,
        unique_fields=["user"],
        update_fields=update_fields + ["longest_streak"],
        batch_size=500,
    )

    result = {"processed": processed, "timestamp": now.isoformat()}
    logger.info("aggregate_user_states: %s", result)
    return result


# ---------------------------------------------------------------------------
# Phase C — Cortex (Next-Best-Action engine)
# ---------------------------------------------------------------------------

@shared_task
def run_nudge_engine(dry_run=False):
    """Pick the single best nudge for each eligible user and deliver it via push
    + the Updates tab. Guard-railed: feature flag, daytime-only window, one nudge
    per user per day, per-nudge cooldown, and a per-run cap to avoid bursts.

    Pass dry_run=True to compute what *would* be sent without sending/logging —
    used to validate targeting on real data before going live.
    """
    from .nudges import CATALOG

    if not getattr(settings, "ENGAGEMENT_NUDGES_ENABLED", False) and not dry_run:
        return {"skipped": "disabled"}

    now = timezone.now()
    local_hour = timezone.localtime(now).hour
    start_h, end_h = getattr(settings, "ENGAGEMENT_NUDGE_HOURS", (9, 21))
    if not dry_run and not (start_h <= local_hour < end_h):
        return {"skipped": f"quiet_hours (local hour {local_hour})"}

    per_run_cap = getattr(settings, "ENGAGEMENT_NUDGE_PER_RUN_CAP", 500)
    # Lifecycle-based nudges (win-back, at-risk) only fire once the heuristic is
    # backed by enough event history; until then we send only hard-data nudges.
    lifecycle_enabled = getattr(settings, "ENGAGEMENT_LIFECYCLE_NUDGES_ENABLED", False)
    catalog = [
        n for n in sorted(CATALOG, key=lambda n: n.priority, reverse=True)
        if n.reliable or lifecycle_enabled
    ]

    # Preload recent nudge history for caps/cooldowns (one query).
    since = now - timedelta(days=14)
    last_any = {}                         # user_id -> latest sent_at
    last_by_key = defaultdict(dict)       # user_id -> {nudge_key: sent_at}
    for uid, key, sent in NudgeLog.objects.filter(sent_at__gte=since).values_list(
        "user_id", "nudge_key", "sent_at"
    ):
        if uid not in last_any or sent > last_any[uid]:
            last_any[uid] = sent
        prev = last_by_key[uid].get(key)
        if prev is None or sent > prev:
            last_by_key[uid][key] = sent

    # Candidate states: only stages/conditions any nudge cares about.
    states = (
        UserState.objects.select_related("user")
        .exclude(lifecycle_stage="churned")  # don't chase the long-gone here
    )

    sent = 0
    plan = []  # for dry-run reporting
    for state in states.iterator(chunk_size=500):
        if sent >= per_run_cap:
            break
        user = state.user
        if getattr(user, "is_suspended", False) or not getattr(user, "is_active", True):
            continue
        # One nudge per user per day.
        la = last_any.get(user.id)
        if la and la >= now - timedelta(days=1):
            continue

        chosen = None
        for nudge in catalog:
            try:
                if not nudge.eligible(state, user):
                    continue
                prev = last_by_key.get(user.id, {}).get(nudge.key)
                if prev and prev >= now - timedelta(days=nudge.cooldown_days):
                    continue
                chosen = nudge
                break
            except Exception:  # pragma: no cover
                logger.exception("nudge eligibility failed: %s", nudge.key)

        if not chosen:
            continue

        try:
            title, body = chosen.build(state, user)
        except Exception:  # pragma: no cover
            logger.exception("nudge build failed: %s", chosen.key)
            continue

        if dry_run:
            plan.append({"user": user.id, "nudge": chosen.key, "title": title})
            sent += 1
            continue

        try:
            from base.push_notifications import send_push_notification
            send_push_notification(
                title=title,
                body=body,
                deep_link=chosen.deep_link,
                notification_type="assistant",
                users=[user],
            )
            NudgeLog.objects.create(
                user=user,
                nudge_key=chosen.key,
                channel="push",
                title=title,
                deep_link=chosen.deep_link,
            )
            sent += 1
        except Exception:  # pragma: no cover - never let one send kill the run
            logger.exception("nudge send failed: %s -> %s", chosen.key, user.id)

    result = {"sent": sent, "dry_run": dry_run, "timestamp": now.isoformat()}
    if dry_run:
        result["plan"] = plan[:50]
        # breakdown by nudge key
        result["by_nudge"] = dict(Counter(p["nudge"] for p in plan))
    logger.info("run_nudge_engine: sent=%s dry_run=%s", sent, dry_run)
    return result
