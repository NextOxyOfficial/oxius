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
    """Daily 06:00 (Dhaka) good-morning broadcast — a warm start to the day
    plus a gentle pull into the feed and services. The greeting rotates by
    weekday so regulars never get the same message two days in a row."""
    from base.push_notifications import send_push_notification

    # (title, body) per weekday — Monday=0 ... Sunday=6. Each pairs a warm
    # wish with ONE concrete thing to check inside AdsyClub.
    greetings = [
        (
            "শুভ সকাল! নতুন সপ্তাহ শুরু 🌤️",
            "আজকের দিনটা দারুণ কাটুক। ফিডে ঢুঁ মেরে দেখুন আপনার নেটওয়ার্কে "
            "নতুন কী হলো — আর মাইক্রো গিগসে আজকের ইনকামের সুযোগগুলোও রেডি।",
        ),
        (
            "শুভ সকাল! চা হাতে এক নজর ☕",
            "দিনটা ভালো যাক। এক কাপ চায়ের সাথে ফিডটা দেখে নিন — রাতে আপনার "
            "পোস্টে কারা লাইক-কমেন্ট করল, জানতে ২ মিনিটও লাগবে না।",
        ),
        (
            "শুভ সকাল! আজ কিছু বিক্রি করবেন? 🌅",
            "ঘরে অব্যবহৃত জিনিস পড়ে আছে? পুরাতন কেনাবেচায় ছবি তুলে পোস্ট "
            "করুন — আপনার এলাকার ক্রেতারাই আগে দেখবে। শুভ দিন!",
        ),
        (
            "শুভ সকাল! দিনটা আপনার হোক 🌞",
            "আজ নতুন কাউকে ফলো করুন, একটা পোস্ট দিন — নেটওয়ার্ক যত বড়, "
            "সুযোগ তত বেশি। ফিডে আপনার জন্য নতুন সাজেশন অপেক্ষা করছে।",
        ),
        (
            "শুভ সকাল! সপ্তাহ প্রায় শেষ 🌻",
            "আজকের দিনটা ঝরঝরে কাটুক। eShop-এ নতুন প্রোডাক্ট উঠেছে — "
            "পছন্দ হলে ক্যাশ অন ডেলিভারিতে ঘরে চলে আসবে।",
        ),
        (
            "শুভ সকাল! ছুটির আমেজে ☀️",
            "সাপ্তাহিক ছুটি ভালো কাটুক। ফুরসতে ফিডটা ঘুরে দেখুন, আর "
            "মোবাইল রিচার্জ লাগলে অ্যাপ থেকেই সেরে নিন — ১ মিনিটের কাজ।",
        ),
        (
            "শুভ সকাল! নতুন সপ্তাহের প্রস্তুতি 🌄",
            "আগামীকাল থেকে নতুন সপ্তাহ — আজই প্রোফাইলটা গুছিয়ে নিন আর "
            "আমার সেবায় আপনার সার্ভিসটা পোস্ট করে রাখুন। শুভ দিন!",
        ),
    ]

    # Beat fires at 00:00 UTC == 06:00 Dhaka; weekday comes from Dhaka's date.
    dhaka_now = timezone.now() + timedelta(hours=6)
    title, body = greetings[dhaka_now.weekday() % 7]

    send_push_notification(
        title=title,
        body=body,
        deep_link="https://adsyclub.com/business-network",
        notification_type="good_morning",
        broadcast=True,
    )
    logger.info("good morning push sent: %s", title)
    return title
