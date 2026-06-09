import logging
from datetime import timedelta

from celery import shared_task
from django.db import transaction
from django.utils import timezone

from .utils import expire_due_subscriptions

logger = logging.getLogger(__name__)


def _notify(user, title, body, deep_link, nudge_key, cooldown_days=0):
    """Send a Bangla push + Updates entry. With cooldown_days>0, skip if the same
    nudge_key was sent to the user within that window (avoids daily spam)."""
    try:
        from base.push_notifications import send_push_notification
        from engagement.models import NudgeLog
        if cooldown_days:
            since = timezone.now() - timedelta(days=cooldown_days)
            if NudgeLog.objects.filter(
                user=user, nudge_key=nudge_key, sent_at__gte=since
            ).exists():
                return False
        send_push_notification(
            title=title, body=body, deep_link=deep_link,
            notification_type="subscription", users=[user],
        )
        try:
            NudgeLog.objects.create(
                user=user, nudge_key=nudge_key, channel="push",
                title=title, deep_link=deep_link,
            )
        except Exception:
            pass
        return True
    except Exception:
        logger.exception("auto-renew notify failed for %s", getattr(user, "id", "?"))
        return False


@shared_task
def process_auto_renewals():
    """Smart auto-renew: for subscriptions with auto_renew on that are about to
    expire, charge the Adsy Pay balance and extend Pro. If the balance is too
    low, follow up with a Bangla reminder to top up (the "brain" follow-up)."""
    from base.models import Balance
    from .models import Subscription, SubscriptionLog

    now = timezone.now()
    soon = now + timedelta(days=2)
    SITE = "https://adsyclub.com"

    subs = Subscription.objects.filter(
        auto_renew=True,
        status="active",
        plan__price__gt=0,
        end_date__isnull=False,
        end_date__lte=soon,
    ).select_related("user", "plan")

    # Charge the live Pro price (admin-managed source of truth), not the legacy
    # SubscriptionPlan.price — customers actually pay the ProPricing amount.
    try:
        from base.models import ProPricing
        live_price = ProPricing.current().effective_monthly_price
    except Exception:
        live_price = None

    renewed = 0
    nudged = 0
    for sub in subs:
        user = sub.user
        plan = sub.plan
        price = live_price if live_price is not None else plan.price
        try:
            balance = user.balance or 0
            if balance >= price:
                with transaction.atomic():
                    base = sub.end_date if (sub.end_date and sub.end_date > now) else now
                    sub.end_date = base + timedelta(days=plan.duration_days)
                    sub.status = "active"
                    sub.save(update_fields=["end_date", "status", "updated_at"])

                    user.balance = balance - price
                    user.is_pro = True
                    user.pro_validity = sub.end_date
                    user.save(update_fields=["balance", "is_pro", "pro_validity"])

                    Balance.objects.create(
                        user=user, transaction_type="subscription",
                        amount=price, payable_amount=price,
                        completed=True, approved=True,
                    )
                    SubscriptionLog.objects.create(
                        subscription=sub, action="renewed",
                        details=f"Auto-renewed from Adsy Pay balance (BDT {price})",
                    )
                renewed += 1
                _notify(
                    user,
                    "Pro সাবস্ক্রিপশন রিনিউ হয়েছে ✅",
                    f"Adsy Pay ব্যালান্স থেকে ৳{int(price)} কেটে আপনার Pro মেয়াদ "
                    f"{sub.end_date:%d-%m-%Y} পর্যন্ত বাড়ানো হয়েছে।",
                    f"{SITE}/upgrade-to-pro",
                    "autorenew_success",
                )
            else:
                # Balance too low — follow up (once every 2 days) to top up.
                if _notify(
                    user,
                    "Pro রিনিউ করতে ব্যালান্স দরকার ⏳",
                    f"আপনার Pro সাবস্ক্রিপশন শীঘ্রই শেষ হচ্ছে। অটো-রিনিউয়ের জন্য "
                    f"Adsy Pay-তে ৳{int(price)} দরকার, এখন আছে ৳{int(balance)}। "
                    f"রিচার্জ করলে মেয়াদ অটোমেটিক বেড়ে যাবে।",
                    f"{SITE}/deposit-withdraw",
                    "autorenew_balance_low",
                    cooldown_days=2,
                ):
                    nudged += 1
        except Exception:
            logger.exception("auto-renew failed for subscription %s", sub.id)

    result = {"renewed": renewed, "nudged": nudged, "timestamp": now.isoformat()}
    logger.info("process_auto_renewals: %s", result)
    return result


@shared_task
def deactivate_expired_subscriptions():
    """
    Deactivate Pro subscriptions that have expired.
    This task handles both the new subscription system and legacy user fields.
    This task is scheduled to run daily via Celery Beat.
    """
    result = expire_due_subscriptions(now=timezone.now(), trigger='celery')
    result_message = (
        'Successfully deactivated '
        f"{result['total_processed']} expired Pro subscriptions "
        f"(New system: {result['subscriptions_expired']}, "
        f"Legacy: {result['legacy_users_deactivated']})"
    )
    print(f"📊 {result_message}")
    return result_message