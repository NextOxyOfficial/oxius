import logging
from datetime import timedelta

from celery import shared_task
from django.utils import timezone

logger = logging.getLogger(__name__)

SITE = "https://adsyclub.com"
RENEW_DEEPLINK = f"{SITE}/adsy-business-network"   # Gold Sponsor management hub
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
