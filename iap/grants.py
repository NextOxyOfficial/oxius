"""Grant in-app entitlements from a verified Google Play purchase."""
import logging
from datetime import timedelta

from django.utils import timezone
from django.utils.dateparse import parse_datetime

logger = logging.getLogger(__name__)


def _subscription_expiry(google_data):
    """Pull the expiry time from a subscriptionsv2 response, if present."""
    if not isinstance(google_data, dict):
        return None
    items = google_data.get("lineItems") or []
    for it in items:
        exp = it.get("expiryTime")
        if exp:
            dt = parse_datetime(exp)
            if dt:
                return dt
    return None


def grant(purchase, product, google_data):
    """Apply the entitlement for a verified purchase. Returns True on success.
    Never raises — a failure is logged and the purchase stays non-granted."""
    user = purchase.user
    try:
        if product.kind == "diamonds":
            user.diamond_balance = (user.diamond_balance or 0) + product.diamonds
            user.save(update_fields=["diamond_balance"])
            try:
                from base.models import DiamondTransaction

                # Log only — the balance is already credited above.
                # completed=True prevents DiamondTransaction.save() from
                # crediting diamond_balance a second time (double-credit).
                DiamondTransaction.objects.create(
                    user=user,
                    to_user=user,
                    transaction_type="purchase",
                    amount=product.diamonds,
                    cost=0,
                    completed=True,
                    approved=True,
                    payment_method="google_play",
                    description=f"Google Play purchase: {product.google_product_id}",
                )
            except Exception:
                logger.exception("[iap] diamond txn log failed (non-fatal)")
            return True

        if product.kind == "pro":
            expiry = _subscription_expiry(google_data) or (
                timezone.now() + timedelta(days=product.duration_days or 30)
            )
            user.is_pro = True
            user.pro_validity = expiry
            user.auto_renew = True
            user.save(update_fields=["is_pro", "pro_validity", "auto_renew"])
            purchase.expiry_at = expiry
            return True

        if product.kind == "gold":
            from business_network.models import GoldSponsor

            gs = None
            if purchase.ref_id:
                gs = GoldSponsor.objects.filter(
                    id=purchase.ref_id, user=user
                ).first()
            if gs is None:
                gs = (
                    GoldSponsor.objects.filter(user=user, status="pending")
                    .order_by("-created_at")
                    .first()
                )
            if gs is None:
                logger.warning("[iap] gold grant: no pending sponsor for %s", user.id)
                return False
            months = getattr(getattr(gs, "package", None), "duration_months", 1) or 1
            expiry = _subscription_expiry(google_data) or (
                timezone.now() + timedelta(days=30 * months)
            )
            gs.status = "active"
            gs.start_date = timezone.now()
            gs.end_date = expiry
            gs.auto_renew = True
            gs.is_featured = True
            gs.save()
            purchase.expiry_at = expiry
            return True
    except Exception:
        logger.exception("[iap] grant failed for %s", product.google_product_id)
    return False


def revoke(purchase, reason="expired"):
    """Reverse a subscription entitlement (RTDN cancel/expire/refund)."""
    user = purchase.user
    try:
        if purchase.kind == "pro":
            user.is_pro = False
            user.pro_validity = None
            user.auto_renew = False
            user.save(update_fields=["is_pro", "pro_validity", "auto_renew"])
        elif purchase.kind == "gold":
            from business_network.models import GoldSponsor

            GoldSponsor.objects.filter(user=user, status="active").update(
                status="expired", auto_renew=False
            )
    except Exception:
        logger.exception("[iap] revoke failed")
