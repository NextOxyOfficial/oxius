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
from base.name_utils import friendly_first_name

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

    # Pre-aggregate live service-post counts by area ONCE (one grouped query),
    # so the per-user loop below is just dict lookups instead of N queries.
    try:
        from .services import build_area_service_index, resolve_user_area
        area_index = build_area_service_index()
    except Exception:  # pragma: no cover
        logger.exception("could not build area service index")
        area_index = {"upazila": {}, "city": {}, "state": {}}
        resolve_user_area = None

    processed = 0
    states = []
    user_qs = User.objects.all().only(
        "id", "date_joined", "last_login", "is_pro", "pro_validity",
        "kyc", "kyc_pending", "balance",
        "name", "image", "phone", "gender", "date_of_birth",
        "upazila", "city", "state",
        "last_search_upazila", "last_search_city", "last_search_state",
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
            # Profile completeness — flag when key fields are missing so the brain
            # can nudge the user to finish (better reach, trust and matches).
            if not (
                (getattr(user, "name", "") or "").strip()
                and getattr(user, "image", None)
                and (getattr(user, "phone", "") or "").strip()
                and getattr(user, "gender", None)
                and getattr(user, "date_of_birth", None)
            ):
                pending["profile_incomplete"] = True
            try:
                if user.balance and float(user.balance) > 0:
                    pending["withdrawable_balance"] = float(user.balance)
            except (TypeError, ValueError):
                pass
            if getattr(user, "is_pro", False) and user.pro_validity:
                if user.pro_validity <= now + timedelta(days=3):
                    pending["subscription_expiring"] = user.pro_validity.isoformat()

            # Local targeting: how many live services exist in the user's area
            # (profile address, else last-searched location). Powers the
            # "N electricians, M plumbers near you" nudge + email; when we have
            # no location at all, flag it so we can ask them to add an address.
            if resolve_user_area is not None:
                area_label, area_level, area_key = resolve_user_area(user)
                if area_key:
                    cats = area_index.get(area_level, {}).get(area_key, [])
                    if cats:
                        pending["area_label"] = area_label
                        pending["area_services"] = [
                            {"cat": c, "n": n} for c, n in cats[:3]
                        ]
                else:
                    pending["no_location"] = True

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
    # Send during the audience's daytime, not the server's (UTC). Default to
    # Asia/Dhaka since the app's primary market is Bangladesh.
    try:
        from zoneinfo import ZoneInfo
        tz = ZoneInfo(getattr(settings, "ENGAGEMENT_TIMEZONE", "Asia/Dhaka"))
        local_hour = now.astimezone(tz).hour
    except Exception:  # pragma: no cover
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
    # PUSH CATALOG nudges only: feature promos and engagement emails keep their
    # own daily/cooldown accounting, so counting them here silently delayed
    # high-value nudges (money waiting / KYC / local services) by up to a day
    # whenever a promo or an email happened to go out first.
    since = now - timedelta(days=14)
    last_any = {}                         # user_id -> latest sent_at
    last_by_key = defaultdict(dict)       # user_id -> {nudge_key: sent_at}
    for uid, key, sent in (
        NudgeLog.objects.filter(sent_at__gte=since, channel="push")
        .exclude(nudge_key__startswith="promo_")
        .values_list("user_id", "nudge_key", "sent_at")
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


@shared_task
def run_feature_promos():
    """Feature-awareness campaign.

    Spreads ~2 promo notifications per user per day across 9am–9pm Bangladesh
    time, at random hours so they don't all fire at once, and never repeats a
    line it sent the same user within the last week. Goes to every active user
    with a device. Toggle with ENGAGEMENT_FEATURE_PROMOS_ENABLED.
    """
    import random
    from django.db.models import Count
    from .feature_promos import pick_promo

    if not getattr(settings, "ENGAGEMENT_FEATURE_PROMOS_ENABLED", True):
        return {"skipped": "disabled"}

    per_day = int(getattr(settings, "ENGAGEMENT_FEATURE_PROMOS_PER_DAY", 2))
    now = timezone.now()  # UTC
    bdt = now + timedelta(hours=6)  # Bangladesh Standard Time = UTC+6
    hour = bdt.hour
    if not (9 <= hour < 21):  # only 9am–9pm BDT
        return {"skipped": "outside-window", "bdt_hour": hour}

    # Spread the remaining sends over the hours left in today's window, so each
    # user's messages land at random, different times instead of all together.
    runs_remaining = max(1, 21 - hour)

    bdt_midnight = bdt.replace(hour=0, minute=0, second=0, microsecond=0)
    day_start_utc = bdt_midnight - timedelta(hours=6)
    week_ago = now - timedelta(days=7)

    sent_today = dict(
        NudgeLog.objects.filter(
            nudge_key__startswith="promo_", sent_at__gte=day_start_utc
        )
        .values("user")
        .annotate(c=Count("id"))
        .values_list("user", "c")
    )

    users = User.objects.filter(is_active=True, fcm_tokens__is_active=True).distinct()

    from base.push_notifications import send_push_notification

    sent = 0
    for user in users.iterator(chunk_size=500):
        need = per_day - sent_today.get(user.id, 0)
        if need <= 0:
            continue
        # Probability spread: send `need` over the remaining `runs_remaining`.
        if random.random() >= (need / runs_remaining):
            continue
        recent = set(
            NudgeLog.objects.filter(
                user=user, nudge_key__startswith="promo_", sent_at__gte=week_ago
            ).values_list("nudge_key", flat=True)
        )
        key, title, body, deep_link = pick_promo(exclude_keys=recent)
        # Personal touch: registered users are greeted by first name.
        _first = friendly_first_name(
            getattr(user, "name", "") or getattr(user, "first_name", ""),
            fallback="",
        )
        if _first:
            body = f"{_first}, {body}"
        try:
            send_push_notification(
                title=title,
                body=body,
                deep_link=deep_link,
                notification_type="feature",
                users=[user],
            )
            NudgeLog.objects.create(
                user=user,
                nudge_key=key,
                channel="push",
                title=title,
                deep_link=deep_link,
            )
            sent += 1
        except Exception:
            logger.exception("feature promo send failed for user %s", user.id)

    logger.info("run_feature_promos: sent=%s bdt_hour=%s", sent, hour)
    return {"sent": sent, "bdt_hour": hour, "runs_remaining": runs_remaining}


@shared_task
def run_email_engine(dry_run=False):
    """Email counterpart of the push brain. For each eligible user, email either
    the single best activity-based nudge (verify KYC, complete profile, renew Pro,
    withdraw balance, win-back, ...) or — when none applies — a varied, helpful
    feature email with live eShop content. Uses an independent email cooldown
    (channel='email') so it never collides with push frequency, and never repeats
    a line it already emailed the same user. OFF by default — flip
    ENGAGEMENT_EMAIL_ENABLED on after validating with dry_run=True.
    """
    from .nudges import CATALOG
    from .feature_promos import pick_promo
    from base.email_service import send_engagement_email

    if not getattr(settings, "ENGAGEMENT_EMAIL_ENABLED", False) and not dry_run:
        return {"skipped": "disabled"}

    now = timezone.now()
    try:
        from zoneinfo import ZoneInfo
        tz = ZoneInfo(getattr(settings, "ENGAGEMENT_TIMEZONE", "Asia/Dhaka"))
        local_hour = now.astimezone(tz).hour
    except Exception:  # pragma: no cover
        local_hour = timezone.localtime(now).hour
    start_h, end_h = getattr(settings, "ENGAGEMENT_EMAIL_HOURS", (10, 20))
    if not dry_run and not (start_h <= local_hour < end_h):
        return {"skipped": f"quiet_hours (local hour {local_hour})"}

    per_run_cap = getattr(settings, "ENGAGEMENT_EMAIL_PER_RUN_CAP", 200)
    cooldown_days = getattr(settings, "ENGAGEMENT_EMAIL_COOLDOWN_DAYS", 3)
    lifecycle_enabled = getattr(settings, "ENGAGEMENT_LIFECYCLE_NUDGES_ENABLED", False)
    catalog = [
        n for n in sorted(CATALOG, key=lambda n: n.priority, reverse=True)
        if n.reliable or lifecycle_enabled
    ]

    # Recent EMAIL history only — independent of push cooldowns.
    since = now - timedelta(days=30)
    last_any = {}
    last_by_key = defaultdict(dict)
    for uid, key, sent_at in NudgeLog.objects.filter(
        channel="email", sent_at__gte=since
    ).values_list("user_id", "nudge_key", "sent_at"):
        if uid not in last_any or sent_at > last_any[uid]:
            last_any[uid] = sent_at
        prev = last_by_key[uid].get(key)
        if prev is None or sent_at > prev:
            last_by_key[uid][key] = sent_at

    states = (
        UserState.objects.select_related("user").exclude(lifecycle_stage="churned")
    )

    sent = 0
    plan = []
    for state in states.iterator(chunk_size=500):
        if sent >= per_run_cap:
            break
        user = state.user
        if getattr(user, "is_suspended", False) or not getattr(user, "is_active", True):
            continue
        if not getattr(user, "email", None):
            continue  # no address → can't email
        # One engagement email per user within the cooldown window.
        la = last_any.get(user.id)
        if la and la >= now - timedelta(days=cooldown_days):
            continue

        chosen = None
        for nudge in catalog:
            try:
                if not nudge.eligible(state, user):
                    continue
                prev = last_by_key.get(user.id, {}).get(nudge.key)
                if prev and prev >= now - timedelta(
                    days=max(nudge.cooldown_days, cooldown_days)
                ):
                    continue
                chosen = nudge
                break
            except Exception:  # pragma: no cover
                logger.exception("email nudge eligibility failed: %s", nudge.key)

        if chosen:
            try:
                title, body = chosen.build(state, user)
            except Exception:  # pragma: no cover
                logger.exception("email nudge build failed: %s", chosen.key)
                continue
            key, deep_link, content_feature = chosen.key, chosen.deep_link, None
        else:
            # No activity nudge applies → a fresh, helpful feature email. Exclude
            # promo lines already emailed so two emails never look alike.
            recent_promos = {
                k for k in last_by_key.get(user.id, {}) if k.startswith("promo_")
            }
            key, title, body, deep_link = pick_promo(exclude_keys=recent_promos)
            # "promo_<feature>_<i>" → feature-appropriate dynamic content
            # (eShop products, rideshare service areas, ...).
            content_feature = key.split("_")[1] if key.count("_") >= 2 else None

        if dry_run:
            plan.append({"user": user.id, "key": key, "title": title})
            sent += 1
            continue

        try:
            send_engagement_email(
                user,
                subject=title,
                heading=title,
                body_html=body,
                button_text="এখনই দেখুন",
                button_url=deep_link,
                content_feature=content_feature,
            )
            NudgeLog.objects.create(
                user=user,
                nudge_key=key,
                channel="email",
                title=title,
                deep_link=deep_link,
            )
            sent += 1
        except Exception:  # pragma: no cover - never let one send kill the run
            logger.exception("email engine send failed: %s -> %s", key, user.id)

    result = {"sent": sent, "dry_run": dry_run, "timestamp": now.isoformat()}
    if dry_run:
        result["plan"] = plan[:50]
        result["by_key"] = dict(Counter(p["key"] for p in plan))
    logger.info("run_email_engine: sent=%s dry_run=%s", sent, dry_run)
    return result


@shared_task
def run_guest_nudges(dry_run=False):
    """Registration-conversion pushes to GUEST devices (FCMToken.user is None).

    Sends one message per due device per run, cycling through the message list
    forever (one per day) — it does NOT stop after the series; promo_count just
    keeps counting and we wrap with modulo so the messages keep rotating until
    the device registers (which removes it from the guest pool).
    """
    from django.db.models import Q
    from base.models import FCMToken
    from base.fcm_service import send_fcm_notification_multicast
    from .guest_promos import GUEST_PROMOS

    if not getattr(settings, "GUEST_NUDGES_ENABLED", False) and not dry_run:
        return {"skipped": "disabled"}

    now = timezone.now()
    cooldown_days = getattr(settings, "GUEST_NUDGE_COOLDOWN_DAYS", 1)
    per_run_cap = getattr(settings, "GUEST_NUDGE_PER_RUN_CAP", 500)
    cutoff = now - timedelta(days=cooldown_days)

    qs = (
        FCMToken.objects.filter(user__isnull=True, is_active=True)
        .filter(Q(last_promo_at__isnull=True) | Q(last_promo_at__lt=cutoff))
        .order_by("last_promo_at")
    )

    sent = 0
    by_index = Counter()
    for tok in qs.iterator(chunk_size=500):
        if sent >= per_run_cap:
            break
        # Wrap forever so the series loops: #0,#1,...,#5,#0,#1,...
        idx = tok.promo_count % len(GUEST_PROMOS)
        title, body, deep_link = GUEST_PROMOS[idx]
        by_index[idx] += 1
        if dry_run:
            sent += 1
            continue
        try:
            send_fcm_notification_multicast(
                [tok.token], title, body,
                {
                    "type": "guest_promo",
                    "deep_link": deep_link,
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                },
            )
            FCMToken.objects.filter(pk=tok.pk).update(
                last_promo_at=now, promo_count=tok.promo_count + 1
            )
            sent += 1
        except Exception:
            logger.exception("guest nudge send failed for token %s", tok.pk)

    result = {"sent": sent, "dry_run": dry_run, "by_index": dict(by_index)}
    logger.info("run_guest_nudges: %s", result)
    return result


@shared_task
def send_good_morning_push():
    """Daily 06:00 (Dhaka) good-morning push — personalized by NAME for every
    registered user ("শুভ সকাল, রাহিম!") and a generic greeting for guest
    devices.

    28 distinct messages: 4 weekly sets x 7 days, picked by (ISO-week % 4,
    weekday) — the same message returns only once a month, so it never feels
    repeated. Bangladesh-aware: Sunday starts the work week, Friday-Saturday
    are the weekend."""
    import time as _time

    from base.fcm_service import send_fcm_notification_multicast
    from base.models import FCMToken
    from base.push_notifications import send_push_notification

    # Index: [week_set][weekday]  (weekday(): Mon=0 ... Sun=6)
    greetings = [
        # ── সপ্তাহ-সেট ১ ──────────────────────────────────────────────
        [
            ("শুভ সকাল! আজ সোমবার 🌤️",
             "কাজের গতি আজ পুরোদমে — টু-ডু লিস্টের সবচেয়ে কঠিন কাজটা সকালেই সেরে ফেলুন, বিকেলটা হালকা লাগবে। ফাঁকে ফিডে চোখ বুলিয়ে নিন 😊"),
            ("শুভ সকাল! মঙ্গলবার মানেই ছন্দ 🍵",
             "আজকের প্ল্যান কী? যেটাই হোক, চায়ের কাপটা শেষ করে শুরু করুন — আর মাইক্রো গিগসে ২ মিনিটে আজকের ইনকামের সুযোগগুলো দেখে নিন।"),
            ("শুভ সকাল! বুধবার — সপ্তাহের মাঝপথ 🌞",
             "অর্ধেক পথ পেরিয়ে এসেছেন, 😄 আজ কাউকে ধন্যবাদ বলুন যার কথা অনেকদিন ভাবা হয়নি — মন ভালো হয়ে যাবে।"),
            ("শুভ সকাল! বৃহস্পতিবার চলে এলো 🌈",
             "কাল ছুটি! আজ কাজগুলো গুছিয়ে শেষ করুন, যাতে কাল মাথা একদম ফাঁকা থাকে। eShop-এ নতুন কী উঠল এক নজর দেখে রাখুন — ছুটিতে কাজে দেবে।"),
            ("শুভ সকাল! আজ শুক্রবার — ছুটির দিন 🕌",
             "জুম্মা মোবারক! আজ পরিবারের সাথে ভালো সময় কাটুক, দুপুরে ভালো-মন্দ খাওয়া হোক 😊 অবসরে ফিডে ঢুঁ মারলে দেখবেন নেটওয়ার্কে কত কী হলো।"),
            ("শুভ সকাল! শনিবারের আয়েশ ☀️",
             "ছুটির দ্বিতীয় দিন — আজ ঘরটা একটু গুছিয়ে ফেলবেন নাকি? গোছানো ঘরে মনও গোছানো থাকে 😄 কাজ শেষে পুরাতন কেনাবেচায় অপ্রয়োজনীয় জিনিসগুলো তুলে দিন।"),
            ("শুভ সকাল! রবিবার — নতুন সপ্তাহ শুরু 🌅",
             "নতুন সপ্তাহ, নতুন লক্ষ্য! আজ যা শুরু করবেন তাতেই সপ্তাহটার ছাপ পড়বে — সময় নষ্ট নয় 💪 ফিডে আপনার জন্য নতুন সাজেশন রেডি।"),
        ],
        # ── সপ্তাহ-সেট ২ ──────────────────────────────────────────────
        [
            ("শুভ সকাল! সোমবারের শক্তি নিয়ে নামুন 💪",
             "যে কাজটা ফেলে রেখেছেন, আজই সেটার দিন — শুরু করলেই অর্ধেক শেষ 😊 কাজের ফাঁকে মোবাইল রিচার্জ লাগলে অ্যাপেই ১ মিনিটে হয়ে যাবে।"),
            ("শুভ সকাল! মঙ্গলবার শুভ হোক 🍀",
             "আজ প্রিয়জনকে একটা ফোন দিন — ব্যস্ততার অজুহাতে কতদিন কথা হয়নি বলুন তো? 😄 আর নেটওয়ার্ক বাড়াতে ফিডে নতুন মানুষদের ফলো করে নিন।"),
            ("শুভ সকাল! বুধবারের রোদটা সুন্দর 🌻",
             "শরীরটাই আসল পুঁজি — আজ ১০ মিনিট হাঁটাহাঁটি হয়ে যাক? তারপর আমার সেবায় দেখুন আপনার এলাকায় নতুন কী কী সার্ভিস এলো।"),
            ("শুভ সকাল! বৃহস্পতিবার — ফিনিশিং টাচ 🎯",
             "সপ্তাহের শেষ কর্মদিবস প্রায়! আজ ঝুলে থাকা কাজগুলো শেষ করুন, ছুটিটা প্রাপ্য করে নিন 😊 আপনার পোস্টে কে কী বলল, ফিডে দেখে নিন।"),
            ("শুভ সকাল! শুক্রবারের প্রশান্তি 🤲",
             "জুম্মা মোবারক! আজ তাড়াহুড়ো নেই — পরিবারের সবাই একসাথে খাবেন, গল্প হবে। বিকেলের অবসরে eShop-এর নতুন প্রোডাক্টগুলো দেখে রাখুন।"),
            ("শুভ সকাল! শনিবার — নিজের দিন 🌼",
             "আজকের দিনটা নিজেকে দিন — যে বইটা পড়া হয়নি, যে কাজটা শখের, সেটাই হোক 😄 ফুরসতে আমার সেবায় নিজের সার্ভিসটাও পোস্ট করে রাখুন।"),
            ("শুভ সকাল! রবিবার — ফ্রেশ শুরু 🌄",
             "সপ্তাহের প্রথম দিনেই এগিয়ে থাকুন — আজ সকালের ১ ঘণ্টা মন দিয়ে কাজ করলে পুরো সপ্তাহ সহজ হয়ে যায় 💪 ফিডে আজকের আপডেটগুলো দেখুন।"),
        ],
        # ── সপ্তাহ-সেট ৩ ──────────────────────────────────────────────
        [
            ("শুভ সকাল! সোমবার, হাসিমুখে শুরু 😊",
             "মুখ গোমড়া করে সোমবার পার হয় না — একটা হাসি দিন, আয়নাও হাসবে 😄 কাজের ফাঁকে মাইক্রো গিগসে ছোট টাস্ক করে বাড়তি ইনকামটাও হয়ে যাক।"),
            ("শুভ সকাল! মঙ্গলবারের ছোট্ট চ্যালেঞ্জ 🎯",
             "আজ একটা জিনিস নতুন শিখুন — ছোট হলেও চলবে। দিনশেষে নিজেকেই ধন্যবাদ দেবেন 😊 eLearning-এ ঢুঁ মারলে শুরু করার জায়গা পেয়ে যাবেন।"),
            ("শুভ সকাল! বুধবার — একটু দম নিন 🍃",
             "ব্যস্ততার মাঝেও ৫ মিনিট নিজের জন্য — জানালার পাশে চা, বাইরে তাকানো, ব্যস 😌 তারপর ফিডে দেখুন নেটওয়ার্কে নতুন কী হলো।"),
            ("শুভ সকাল! বৃহস্পতিবার — আর একদিন! 🌈",
             "ছুটির গন্ধ পাচ্ছেন? 😄 আজ ডেস্কটা/ঘরটা গুছিয়ে রাখুন — শনিবার ফিরে এসে গোছানো জায়গা দেখলে মনটাই ভালো হয়ে যাবে।"),
            ("শুভ সকাল! জুম্মা মোবারক 🕌",
             "শুক্রবারের বরকতময় সকাল! আজ বাবা-মা বা মুরুব্বিদের খোঁজ নিন — একটা ফোনেই ওঁদের দিনটা ভালো হয়ে যায় 😊 অবসরে ফিডটাও ঘুরে দেখবেন।"),
            ("শুভ সকাল! শনিবারের মজা 🌞",
             "আজ বাসার সবাই মিলে ভালো কিছু রান্না হোক? খিচুড়ি-ইলিশ নাকি বিরিয়ানি — কমেন্টে জানাতে ইচ্ছা করছে তো? 😄 পোস্ট করে ফেলুন ফিডে!"),
            ("শুভ সকাল! রবিবার — গোল সেট করুন 📝",
             "এই সপ্তাহে ৩টা লক্ষ্য লিখে ফেলুন — লেখা লক্ষ্য পূরণ হয় বেশি, এটা প্রমাণিত 💪 আর প্রোফাইলটা আপডেট থাকলে সুযোগও খুঁজে নেয় আপনাকে।"),
        ],
        # ── সপ্তাহ-সেট ৪ ──────────────────────────────────────────────
        [
            ("শুভ সকাল! সোমবার — সময়ের দাম দিন ⏰",
             "আজ ফোন স্ক্রলে সময় নষ্ট কম, কাজে মন বেশি — রাতে নিজেকে নিয়ে গর্ব হবে 😊 দরকারি জিনিস কিনতে হলে eShop-এ দাম দেখে নিন আগে।"),
            ("শুভ সকাল! মঙ্গলবারের রোদ্দুর 🌤️",
             "যা আছে তার জন্য শুকরিয়া, যা চাই তার জন্য চেষ্টা — এই তো জীবন 😊 আজ আপনার দক্ষতার একটা পোস্ট দিন, নেটওয়ার্ক জানুক আপনি কী পারেন।"),
            ("শুভ সকাল! বুধবার — অর্ধেক জয় হয়ে গেছে 🏆",
             "সপ্তাহের মাঝখানে দাঁড়িয়ে আপনি — পেছনে যা হয়নি তা ভুলে সামনের দুটো দিন দুর্দান্ত করুন 💪 ফিডে নতুন গিগ আর সুযোগগুলো দেখে নিন।"),
            ("শুভ সকাল! বৃহস্পতিবার — উইকেন্ড প্ল্যান কী? 🌤️",
             "কাল ছুটি — কোথাও ঘুরতে যাবেন, নাকি বাসায় আরাম? প্ল্যানটা আজই করে ফেলুন 😄 আর কাজের লিস্ট আজই শেষ করুন, ছুটিতে অফিসের চিন্তা নিষেধ!"),
            ("শুভ সকাল! শুক্রবার — পরিবারের দিন 🕌",
             "জুম্মা মোবারক! নামাজ, ভালো খাওয়া, পরিবারের আড্ডা — আজকের রুটিন এটাই হোক 😊 সন্ধ্যায় ফুরসতে ফিডে সপ্তাহের সেরা পোস্টগুলো দেখে নিন।"),
            ("শুভ সকাল! শনিবার — রিচার্জ হয়ে নিন 🔋",
             "মোবাইলের মতো মানুষেরও রিচার্জ লাগে — আজ ভালো ঘুম, ভালো খাওয়া, প্রিয় মানুষদের সঙ্গ 😄 (আর মোবাইলের রিচার্জটা অ্যাপ থেকেই হয়ে যাবে!)"),
            ("শুভ সকাল! রবিবার — এ সপ্তাহটা আপনার 🌅",
             "গত সপ্তাহে যা পারেননি, এ সপ্তাহে সেটাই করবেন — বিশ্বাস রাখুন নিজের উপর 💪 শুরুটা হোক ফিড থেকে: দেখুন আপনার জগতে নতুন কী।"),
        ],
    ]

    # Beat fires at 00:00 UTC == 06:00 Dhaka. Weekday + ISO-week both come
    # from Dhaka's date so the day-name in the message is always right.
    dhaka_now = timezone.now() + timedelta(hours=6)
    week_set = dhaka_now.isocalendar()[1] % 4
    title, body = greetings[week_set][dhaka_now.weekday() % 7]
    deep_link = "https://adsyclub.com/business-network"

    User = get_user_model()
    user_ids = list(
        FCMToken.objects.filter(is_active=True, user__isnull=False)
        .values_list("user_id", flat=True)
        .distinct()
    )
    users = User.objects.filter(id__in=user_ids, is_active=True)

    sent = 0
    for user in users.iterator(chunk_size=500):
        first = friendly_first_name(
            getattr(user, "name", "") or getattr(user, "first_name", ""),
            fallback="",
        )
        # "শুভ সকাল! ..." -> "শুভ সকাল, রাহিম! ..." for registered users.
        personal_title = (
            title.replace("শুভ সকাল!", f"শুভ সকাল, {first}!", 1)
            if first
            else title
        )
        try:
            send_push_notification(
                title=personal_title,
                body=body,
                deep_link=deep_link,
                notification_type="good_morning",
                users=[user],
            )
            sent += 1
        except Exception:
            logger.exception("good morning push failed for user %s", user.id)
        _time.sleep(0.03)  # FCM-friendly pacing over thousands of users

    # Guest devices (no account yet) still get the generic greeting.
    guest_tokens = list(
        FCMToken.objects.filter(is_active=True, user__isnull=True)
        .values_list("token", flat=True)
    )
    for i in range(0, len(guest_tokens), 450):
        chunk = guest_tokens[i : i + 450]
        try:
            send_fcm_notification_multicast(
                chunk,
                title,
                body,
                {
                    "deep_link": deep_link,
                    "notification_type": "good_morning",
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                },
            )
        except Exception:
            logger.exception("good morning guest chunk failed")

    logger.info(
        "good morning push: %s registered, %s guest tokens", sent, len(guest_tokens)
    )
    return {"registered": sent, "guests": len(guest_tokens)}
