import logging
from datetime import timedelta

from celery import shared_task
from django.utils import timezone

logger = logging.getLogger(__name__)

SITE = "https://adsyclub.com"
RENEW_DEEPLINK = f"{SITE}/business-network"         # Gold Sponsor management hub (sidebar)
DEPOSIT_DEEPLINK = f"{SITE}/deposit-withdraw"      # top-up wallet


def _notify_sponsor(sponsor, stage, *, push_title, push_body, email_subject,
                    email_heading, email_body_html, deep_link,
                    button_text="এখনই রিনিউ করুন"):
    """Deliver one lifecycle step (push + email) exactly once per sponsor+stage.

    Returns True if this was a fresh send, False if the step was already sent
    (so callers can keep their stats accurate)."""
    from .models import GoldSponsorReminderLog

    if GoldSponsorReminderLog.objects.filter(sponsor=sponsor, stage=stage).exists():
        return False

    user = sponsor.user

    # Push notification (also creates an in-app "Updates" entry).
    try:
        from base.push_notifications import send_push_notification
        send_push_notification(
            title=push_title,
            body=push_body,
            deep_link=deep_link,
            notification_type="gold_sponsor",
            users=[user],
        )
    except Exception:
        logger.exception("gold sponsor push failed for sponsor %s", sponsor.id)

    # Email (best-effort; no-op until SMTP credentials are configured).
    try:
        from base.email_service import send_gold_sponsor_email
        send_gold_sponsor_email(
            user,
            subject=email_subject,
            heading=email_heading,
            message_html=email_body_html,
            button_text=button_text,
            button_url=deep_link,
        )
    except Exception:
        logger.exception("gold sponsor email failed for sponsor %s", sponsor.id)

    try:
        GoldSponsorReminderLog.objects.get_or_create(
            sponsor=sponsor, stage=stage, defaults={'channel': 'push+email'})
    except Exception:
        pass
    return True


def _notify_renewed(sponsor, result):
    biz = sponsor.business_name
    end = result.get('end_date')
    price = int(result.get('price') or 0)
    _notify_sponsor(
        sponsor, 'autorenew_success',
        push_title="Gold Sponsor রিনিউ হয়েছে ✅",
        push_body=f"“{biz}” স্পনসরশিপ {end:%d-%m-%Y} পর্যন্ত বাড়ানো হয়েছে।",
        email_subject="আপনার Gold Sponsorship রিনিউ হয়েছে",
        email_heading="আপনার Gold Sponsorship অটো-রিনিউ হয়েছে ✅",
        email_body_html=(
            f"আপনার Adsy Pay ব্যালেন্স থেকে ৳{price} কেটে “{biz}”-এর মেয়াদ "
            f"<strong>{end:%d-%m-%Y}</strong> পর্যন্ত বাড়ানো হয়েছে। ফিচার্ড থাকার জন্য ধন্যবাদ!"
        ),
        deep_link=RENEW_DEEPLINK,
        button_text="স্পনসরশিপ দেখুন",
    )


@shared_task
def process_gold_sponsor_lifecycle():
    """Lifecycle engine for Gold Sponsors (scheduled via Celery Beat):

      1. Auto-renew (charge wallet + extend) within ~2 days of expiry, or right
         at expiry, for sponsors with auto_renew on.
      2. Multi-step pre-expiry reminders (7d -> 3d -> 1d) for manual sponsors.
      3. Mark lapsed sponsors expired + send an expiry notice.
      4. A single win-back ~3 days after expiry.

    Each step is sent once per sponsor (GoldSponsorReminderLog); renewing resets
    the log so the next period gets a fresh sequence.
    """
    from .models import GoldSponsor

    now = timezone.now()
    stats = {"renewed": 0, "reminded": 0, "expired": 0,
             "autorenew_low": 0, "winback": 0}

    active = (GoldSponsor.objects
              .filter(status='active', end_date__isnull=False)
              .select_related('user', 'package'))

    for s in active:
        try:
            biz = s.business_name
            days_left = (s.end_date - now).days

            # --- Already lapsed --------------------------------------------
            if s.end_date <= now:
                if s.auto_renew:
                    res = s.extend(charge=True, reason='auto')
                    if res.get('ok'):
                        stats["renewed"] += 1
                        _notify_renewed(s, res)
                        continue
                    # wanted to auto-renew but couldn't charge -> fall through
                s.status = 'expired'
                s.save(update_fields=['status', 'updated_at'])
                stats["expired"] += 1
                _notify_sponsor(
                    s, 'expired_notice',
                    push_title="Gold Sponsor মেয়াদ শেষ ⏳",
                    push_body=f"“{biz}” স্পনসরশিপের মেয়াদ শেষ হয়েছে। রিনিউ করলে আবার ফিচার্ড হবে।",
                    email_subject="আপনার Gold Sponsorship-এর মেয়াদ শেষ হয়েছে",
                    email_heading="আপনার Gold Sponsorship-এর মেয়াদ শেষ হয়েছে",
                    email_body_html=f"“{biz}” এখন আর ফিচার্ড নেই। আবার গ্রাহকদের সামনে আসতে এখনই রিনিউ করুন।",
                    deep_link=RENEW_DEEPLINK,
                )
                continue

            # --- Proactive auto-renew within 2 days ------------------------
            if s.auto_renew and days_left <= 2:
                res = s.extend(charge=True, reason='auto')
                if res.get('ok'):
                    stats["renewed"] += 1
                    _notify_renewed(s, res)
                else:
                    price = int(res.get('price') or 0)
                    bal = int(res.get('balance') or 0)
                    if _notify_sponsor(
                        s, 'autorenew_low',
                        push_title="রিনিউ করতে ব্যালেন্স দরকার ⏳",
                        push_body=f"“{biz}” অটো-রিনিউয়ের জন্য ৳{price} দরকার, আছে ৳{bal}। রিচার্জ করলে অটো বেড়ে যাবে।",
                        email_subject="Gold Sponsorship অটো-রিনিউ করতে ব্যালেন্স যোগ করুন",
                        email_heading="এখনো অটো-রিনিউ করা যায়নি",
                        email_body_html=(
                            f"“{biz}”-এর অটো-রিনিউয়ের জন্য Adsy Pay-তে ৳{price} দরকার, "
                            f"কিন্তু আপনার আছে ৳{bal}। ব্যালেন্স যোগ করলে মেয়াদ শেষ হওয়ার "
                            f"আগেই এটি অটোমেটিক রিনিউ হয়ে যাবে।"
                        ),
                        deep_link=DEPOSIT_DEEPLINK,
                        button_text="ব্যালেন্স যোগ করুন",
                    ):
                        stats["autorenew_low"] += 1
                continue

            # --- Manual sponsors: staged pre-expiry reminders --------------
            if not s.auto_renew:
                if days_left <= 1:
                    stage, when = 'expiry_1d', "আগামীকাল"
                elif days_left <= 3:
                    stage, when = 'expiry_3d', f"{days_left} দিনে"
                elif days_left <= 7:
                    stage, when = 'expiry_7d', f"{days_left} দিনে"
                else:
                    continue
                if _notify_sponsor(
                    s, stage,
                    push_title="Gold Sponsor শেষ হতে চলেছে ⏰",
                    push_body=f"“{biz}” স্পনসরশিপ {when} শেষ হবে। এখনই রিনিউ করে ফিচার্ড থাকুন।",
                    email_subject="আপনার Gold Sponsorship শীঘ্রই শেষ হচ্ছে",
                    email_heading=f"“{biz}” আর {max(days_left, 0)} দিনে শেষ হবে",
                    email_body_html=f"কোনো বিরতি ছাড়াই “{biz}” ফিচার্ড রাখতে এখনই রিনিউ করুন।",
                    deep_link=RENEW_DEEPLINK,
                ):
                    stats["reminded"] += 1
        except Exception:
            logger.exception("gold sponsor lifecycle failed for sponsor %s",
                             getattr(s, 'id', '?'))

    # --- Win-back ~3 days after expiry (once) --------------------------------
    winback = (GoldSponsor.objects
               .filter(status='expired',
                       end_date__lt=now - timedelta(days=3),
                       end_date__gte=now - timedelta(days=6))
               .select_related('user', 'package'))
    for s in winback:
        try:
            if _notify_sponsor(
                s, 'winback',
                push_title="ফিরে আসুন — Gold Sponsor 🌟",
                push_body=f"“{s.business_name}” আবার ফিচার করতে চান? এক ক্লিকেই রিনিউ করুন।",
                email_subject="আপনার ব্যবসাকে আবার স্পটলাইটে আনুন",
                email_heading="আপনার Gold Sponsorship রিনিউ করুন",
                email_body_html=f"“{s.business_name}” এখন আর ফিচার্ড নেই। এক ক্লিকেই রিনিউ করে আবার গ্রাহকদের কাছে পৌঁছান।",
                deep_link=RENEW_DEEPLINK,
            ):
                stats["winback"] += 1
        except Exception:
            logger.exception("gold sponsor win-back failed for sponsor %s",
                             getattr(s, 'id', '?'))

    logger.info("process_gold_sponsor_lifecycle: %s", stats)
    return stats


@shared_task
def compute_monetization_earnings_task(period=None):
    """Daily (Celery Beat): refresh approved creators' points + pool shares
    for the current month. Schedule a second run a few days into each month
    with the previous period to finalize it after the holdback window."""
    from .monetization import compute_period_earnings

    summary = compute_period_earnings(period)
    logger.info("compute_monetization_earnings_task: %s", summary)
    return summary


@shared_task
def send_weekly_bn_digests():
    """Weekly community digest to recently-active users — the social-network
    style follow-up that pulls people back into Business Network."""
    import time as _time
    from datetime import timedelta
    from django.utils import timezone
    from django.contrib.auth import get_user_model
    from base.email_service import send_bn_digest_email

    User = get_user_model()
    cutoff = timezone.now() - timedelta(days=45)
    users = (
        User.objects.filter(is_active=True, last_login__gte=cutoff)
        .exclude(email="")
        .exclude(email=None)
    )
    sent = 0
    for user in users.iterator():
        try:
            send_bn_digest_email(user)
            sent += 1
        except Exception:
            continue
        _time.sleep(0.4)  # SMTP-friendly pacing
    return sent


@shared_task
def ads_daily_settlement(target_date=None):
    """Nightly ads settlement (runs for YESTERDAY unless target_date given):

    1. Viewer diamond rewards — every `views_per_diamond` tracked ad views
       (panel + AdMob combined) earns 1 diamond, capped per day. Credited to
       diamond_balance with a DiamondTransaction "bonus" record + push.
    2. Creator ad earnings — impressions attributed to a creator's content
       are valued (panel: cpv * share%; AdMob: admob_view_value * share%),
       written to the CreatorAdEarning ledger and credited to balance.
    3. Interest decay — everyone's ad-interest weights shrink so targeting
       follows RECENT behaviour only (a few days, per config).
    """
    from datetime import timedelta
    from decimal import Decimal

    from django.db.models import Count, Q

    from base.models import DiamondTransaction, User
    from .models import (
        AdEvent,
        AdsSystemConfig,
        AdViewerDaily,
        CreatorAdEarning,
        UserAdProfile,
    )

    cfg = AdsSystemConfig.get()
    day = target_date or (timezone.localdate() - timedelta(days=1))

    # ── 1. Viewer diamond rewards ────────────────────────────────────────
    rewarded_users = 0
    if cfg.viewer_reward_enabled and cfg.views_per_diamond:
        rows = AdViewerDaily.objects.filter(date=day, rewarded=False)
        for row in rows:
            diamonds = min(
                row.views // cfg.views_per_diamond, cfg.max_daily_diamonds
            )
            row.rewarded = True
            row.diamonds_awarded = diamonds
            row.save(update_fields=["rewarded", "diamonds_awarded"])
            if diamonds <= 0:
                continue
            user = row.user
            user.diamond_balance += diamonds
            user.save(update_fields=["diamond_balance"])
            DiamondTransaction.objects.create(
                user=user,
                transaction_type="bonus",
                amount=diamonds,
                completed=True,
                approved=True,
                description=f"Daily ad-view reward for {day} ({row.views} views)",
            )
            rewarded_users += 1
            try:
                from base.push_notifications import send_push_notification

                send_push_notification(
                    title="আজকের রিওয়ার্ড 🎁",
                    body=(
                        f"গতকাল বিজ্ঞাপন দেখার জন্য আপনি {diamonds} ডায়মন্ড "
                        "রিওয়ার্ড পেয়েছেন!"
                    ),
                    deep_link="https://adsyclub.com/business-network",
                    notification_type="ad_reward",
                    users=[user],
                )
            except Exception:
                logger.exception("ad reward push failed for user %s", user.id)

    # ── 2. Creator earnings ──────────────────────────────────────────────
    share = Decimal(cfg.creator_share_percent) / Decimal(100)
    cpv = Decimal(str(cfg.cpv_rate))
    admob_value = Decimal(str(cfg.admob_view_value))

    stats = (
        AdEvent.objects.filter(
            created_at__date=day,
            event_type="impression",
            creator__isnull=False,
        )
        .values("creator")
        .annotate(
            panel_views=Count("id", filter=Q(source="panel")),
            admob_views=Count("id", filter=Q(source="admob")),
        )
    )
    credited_creators = 0
    for s in stats:
        amount = (
            Decimal(s["panel_views"]) * cpv + Decimal(s["admob_views"]) * admob_value
        ) * share
        amount = amount.quantize(Decimal("0.01"))
        row, created = CreatorAdEarning.objects.get_or_create(
            creator_id=s["creator"],
            date=day,
            defaults={
                "panel_views": s["panel_views"],
                "admob_views": s["admob_views"],
                "amount": amount,
            },
        )
        if row.credited:
            continue
        if amount > 0:
            creator = User.objects.filter(id=s["creator"]).first()
            if creator:
                creator.balance += amount
                creator.save(update_fields=["balance"])
        row.credited = True
        row.save(update_fields=["credited"])
        credited_creators += 1

    # ── 3. Interest decay ────────────────────────────────────────────────
    decay_days = max(1, cfg.interest_decay_days)
    factor = 0.5 ** (1.0 / decay_days)  # half-life = interest_decay_days
    for profile in UserAdProfile.objects.exclude(category_weights={}):
        weights = {
            k: round(float(v) * factor, 2)
            for k, v in (profile.category_weights or {}).items()
            if float(v) * factor >= 0.2
        }
        profile.category_weights = weights
        profile.save(update_fields=["category_weights", "updated_at"])

    logger.info(
        "ads_daily_settlement %s: %s viewers rewarded, %s creators credited",
        day, rewarded_users, credited_creators,
    )
    return {
        "date": str(day),
        "viewers_rewarded": rewarded_users,
        "creators_credited": credited_creators,
    }


@shared_task
def build_interest_profiles():
    """Nightly Interest Brain rebuild: classify every recently-active user
    into interest segments from their last 30 days of activity (views, video
    watches, likes, comments, saves, hides, reports, ad clicks). Powers
    interest-matched ad serving — see interest_brain.py."""
    from base.models import User
    from .interest_brain import active_user_ids, build_profile

    ids = active_user_ids()
    built = errors = 0
    for user in User.objects.filter(id__in=ids).iterator(chunk_size=100):
        try:
            build_profile(user)
            built += 1
        except Exception:
            errors += 1
            logger.exception("interest brain failed for user %s", user.id)

    logger.info("build_interest_profiles: %s built, %s errors", built, errors)
    return {"built": built, "errors": errors}
