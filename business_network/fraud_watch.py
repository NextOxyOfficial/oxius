"""Security watchdog — multi-layer abuse detection for the ads/monetization
economy. Every anomaly is logged to FraudAlert AND urgently emailed to the
admin. Detection layers (on top of the always-on ones: billing dedupe,
per-user daily event ceiling, live burst limiter, KYC gates, monetization
trust score):

  hourly `security_sweep` (celery):
    • reward_pump   — a viewer racking up absurd daily ad views
    • ctr_anomaly   — bot-like click-through rates
    • self_view     — an advertiser farming their own ads
    • balance_anomaly — creator ad-earnings ledger exceeding what their
                        content's tracked views could legitimately produce
    • spam          — one user flooding comments

Nothing here auto-freezes accounts — a human (admin) decides; the system's
job is to catch it fast and shout.
"""
import logging
import os

from django.core.mail import send_mail
from django.utils import timezone

logger = logging.getLogger(__name__)

ADMIN_ALERT_EMAIL = os.getenv("ADMIN_ALERT_EMAIL", "alimulislam50@gmail.com")


def raise_alert(user, kind, details):
    """Log a FraudAlert and urgently email the admin. Never raises."""
    from .models import FraudAlert

    try:
        # One email per user+kind per day — the log keeps every occurrence.
        from django.core.cache import cache

        alert = FraudAlert.objects.create(
            user=user, kind=kind, details=details[:2000]
        )
        mail_key = (
            f"fraudmail:{kind}:{getattr(user, 'id', 'anon')}:"
            f"{timezone.localdate().isoformat()}"
        )
        if cache.get(mail_key):
            return alert
        cache.set(mail_key, 1, 60 * 60 * 26)

        who = (
            f"{user.get_full_name() or user.username} <{user.email}> "
            f"(id {user.id})" if user is not None else "anonymous"
        )
        try:
            send_mail(
                subject=f"🚨 AdsyClub SECURITY ALERT — {kind}",
                message=(
                    "Unusual activity detected.\n\n"
                    f"Type: {kind}\nUser: {who}\n"
                    f"Time: {timezone.now():%Y-%m-%d %H:%M} \n\n"
                    f"Details:\n{details}\n\n"
                    "Review: https://adsyclub.com/admin/business_network/"
                    "fraudalert/"
                ),
                from_email=None,  # DEFAULT_FROM_EMAIL
                recipient_list=[ADMIN_ALERT_EMAIL],
                fail_silently=True,
            )
            alert.emailed = True
            alert.save(update_fields=["emailed"])
        except Exception:
            logger.exception("fraud alert email failed")
        return alert
    except Exception:
        logger.exception("raise_alert failed")
        return None


def run_security_sweep():
    """Hourly anomaly scan over the last 24h of activity. Returns stats."""
    from datetime import timedelta

    from django.db.models import Count, Q

    from .models import (
        AdEvent,
        AdViewerDaily,
        BusinessNetworkPostComment,
        CreatorAdEarning,
    )

    since = timezone.now() - timedelta(hours=24)
    today = timezone.localdate()
    flagged = 0

    # 1) Viewer reward pumping: implausible daily tracked ad views.
    for row in AdViewerDaily.objects.filter(
        date=today, views__gt=300
    ).select_related("user"):
        raise_alert(
            row.user, "reward_pump",
            f"{row.views} tracked ad views today (>300 is not organic "
            "scrolling).",
        )
        flagged += 1

    # 2) Bot-like CTR: many events AND >40% clicks.
    stats = (
        AdEvent.objects.filter(created_at__gte=since, user__isnull=False)
        .values("user")
        .annotate(
            total=Count("id"),
            clicks=Count(
                "id", filter=Q(event_type__in=["click", "cta_click"])
            ),
        )
        .filter(total__gte=50)
    )
    for s in stats:
        if s["clicks"] / s["total"] > 0.4:
            from base.models import User

            u = User.objects.filter(id=s["user"]).first()
            raise_alert(
                u, "ctr_anomaly",
                f"{s['clicks']} clicks out of {s['total']} ad events in 24h "
                f"(CTR {s['clicks'] / s['total']:.0%}).",
            )
            flagged += 1

    # 3) Advertiser farming their own ads (viewer == ad owner).
    self_rows = (
        AdEvent.objects.filter(
            created_at__gte=since, source="panel",
            ad__isnull=False, user__isnull=False,
        )
        .filter(user=models_F_ad_user())
        .values("user")
        .annotate(total=Count("id"))
        .filter(total__gte=30)
    )
    for s in self_rows:
        from base.models import User

        u = User.objects.filter(id=s["user"]).first()
        raise_alert(
            u, "self_view",
            f"{s['total']} events on their OWN ads in 24h — possible "
            "reward/earnings farming.",
        )
        flagged += 1

    # 4) Balance anomaly: today's credited creator ad earnings that exceed
    # what tracked creator impressions could produce at the max rate.
    from decimal import Decimal

    from .models import AdsSystemConfig

    cfg = AdsSystemConfig.get()
    max_rate = Decimal("0.60") * Decimal(cfg.creator_share_percent) / 100
    for row in CreatorAdEarning.objects.filter(date=today).select_related(
        "creator"
    ):
        cap = (
            Decimal(row.panel_views + row.admob_views) * max_rate
            + Decimal("1.00")
        )
        if row.amount > cap:
            raise_alert(
                row.creator, "balance_anomaly",
                f"Ledger amount ৳{row.amount} exceeds plausible max ৳{cap} "
                f"for {row.panel_views}+{row.admob_views} views.",
            )
            flagged += 1

    # 5) Comment spam: >120 comments in 24h.
    spam = (
        BusinessNetworkPostComment.objects.filter(created_at__gte=since)
        .values("author")
        .annotate(total=Count("id"))
        .filter(total__gt=120)
    )
    for s in spam:
        from base.models import User

        u = User.objects.filter(id=s["author"]).first()
        raise_alert(
            u, "spam", f"{s['total']} comments posted in 24h."
        )
        flagged += 1

    return {"flagged": flagged}


def models_F_ad_user():
    from django.db.models import F

    return F("ad__user")
