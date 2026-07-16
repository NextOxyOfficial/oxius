"""In-App Purchase API: product catalog, purchase verification, RTDN webhook."""
import base64
import hashlib
import json
import logging
from datetime import timedelta

from django.conf import settings
from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from . import grants, verify
from .models import IapProduct, IapPurchase

logger = logging.getLogger(__name__)

# How often one purchase may hop between AdsyClub accounts. Google ties a
# subscription to the buyer's Google account, so moving it is legitimate — but
# without a cooldown one subscription could be passed around indefinitely.
TRANSFER_COOLDOWN = timedelta(days=30)


def obfuscated_account_id(user):
    """Stable, non-reversible id for a user, sent to Play as
    obfuscatedAccountId. Google echoes it back on verification, which is how we
    tell which AdsyClub account started a purchase. Must never be the raw user
    id or email — Google's docs require it not contain personal data."""
    raw = f"{settings.SECRET_KEY}:{user.id}".encode("utf-8")
    return hashlib.sha256(raw).hexdigest()[:32]


def _mask_email(email):
    """a***@gmail.com — enough for the user to recognise their own account
    without disclosing someone else's address."""
    email = (email or "").strip()
    if "@" not in email:
        return ""
    local, _, domain = email.partition("@")
    head = local[:1] if local else ""
    return f"{head}***@{domain}"


@api_view(["GET"])
@permission_classes([AllowAny])
def iap_products(request):
    """Product catalog for the app — the Play product ids to query. Filter by
    ?kind=diamonds|pro|gold."""
    qs = IapProduct.objects.filter(is_active=True)
    kind = (request.query_params.get("kind") or "").strip()
    if kind:
        qs = qs.filter(kind=kind)
    data = [
        {
            "kind": p.kind,
            "title": p.title,
            "google_product_id": p.google_product_id,
            "base_plan_id": p.base_plan_id,
            "is_subscription": p.is_subscription,
            "diamonds": p.diamonds,
            "duration_days": p.duration_days,
            "price_label": p.price_label,
        }
        for p in qs
    ]
    # The obfuscatedAccountId the app must attach to purchases. Derived from the
    # SECRET_KEY, so only the server can produce it — the client just echoes it
    # back to Play, which returns it to us on verification.
    account_id = (
        obfuscated_account_id(request.user)
        if request.user.is_authenticated
        else ""
    )
    return Response({"products": data, "account_id": account_id})


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def iap_verify(request):
    """Verify a Google Play purchase server-side and grant the entitlement.

    Body: {product_id, purchase_token, ref_id?}. Idempotent — a token is
    honored once.
    """
    product_id = (request.data.get("product_id") or "").strip()
    token = (request.data.get("purchase_token") or "").strip()
    ref_id = (request.data.get("ref_id") or "").strip()
    if not product_id or not token:
        return Response(
            {"success": False, "error": "product_id and purchase_token required"},
            status=400,
        )

    product = IapProduct.objects.filter(
        google_product_id=product_id, is_active=True
    ).first()
    if product is None:
        return Response(
            {"success": False, "error": "unknown product"}, status=400
        )

    # Idempotency: a previously-granted token just re-confirms success — but
    # only for the account that owns it.
    existing = IapPurchase.objects.filter(purchase_token=token).first()
    if existing and existing.user_id != request.user.id:
        # The buyer's Google account already spent this token on a different
        # AdsyClub account. Never silently re-link it — that would let any user
        # claim someone else's purchase by replaying the token. Transferring is
        # an explicit, rate-limited action (see iap_transfer).
        return Response(
            {
                "success": False,
                "error": "token_owned_by_other_account",
                "owner_hint": _mask_email(getattr(existing.user, "email", "")),
            },
            status=409,
        )
    if existing and existing.status == "granted":
        return Response({"success": True, "status": "already_granted"})

    purchase = existing or IapPurchase(
        user=request.user,
        kind=product.kind,
        google_product_id=product_id,
        purchase_token=token,
        is_subscription=product.is_subscription,
    )
    purchase.ref_id = ref_id or purchase.ref_id
    purchase.obfuscated_account_id = obfuscated_account_id(request.user)

    # Server-side verification with Google.
    if product.is_subscription:
        google_data = verify.verify_subscription(token)
    else:
        google_data = verify.verify_product(
            product_id=product_id, purchase_token=token
        )

    if not google_data:
        purchase.status = "failed"
        purchase.error = "verification_unavailable_or_invalid"
        purchase.save()
        return Response(
            {"success": False, "error": "verification failed"}, status=402
        )

    # Sanity: one-off products must be in 'purchased' state.
    if not product.is_subscription:
        if google_data.get("purchaseState", 0) != 0:
            purchase.status = "failed"
            purchase.raw = google_data
            purchase.error = "not_purchased"
            purchase.save()
            return Response(
                {"success": False, "error": "purchase not completed"}, status=402
            )

    granted = grants.grant(
        purchase, product, google_data, amount=request.data.get("amount")
    )
    purchase.raw = google_data
    purchase.status = "granted" if granted else "failed"
    purchase.save()

    if granted:
        # Acknowledge so Google doesn't auto-refund after 3 days.
        try:
            if product.is_subscription:
                verify.acknowledge_subscription(token)
            else:
                verify.acknowledge_product(product_id, token)
        except Exception:
            logger.exception("[iap] acknowledge failed (non-fatal)")
        # Email the buyer + admins (async; never blocks the response).
        try:
            from base.email_service import send_iap_purchase_email

            send_iap_purchase_email(purchase, product, event="purchase")
        except Exception:
            logger.exception("[iap] purchase email dispatch failed")

    return Response({"success": granted, "status": purchase.status})


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def iap_resolve_token(request):
    """Who owns this Google Play purchase?

    The app calls this with a token from queryPurchases() before offering to
    subscribe, so it can explain "already subscribed" instead of letting Google
    reject the purchase with a bare ITEM_ALREADY_OWNED.

    Body: {purchase_token}. Returns status:
      unclaimed    - no AdsyClub account holds it; it can be claimed via verify
      yours        - already linked to the caller; just restore the entitlement
      other_account- linked elsewhere; offer login-there or transfer-here
    """
    token = (request.data.get("purchase_token") or "").strip()
    if not token:
        return Response(
            {"success": False, "error": "purchase_token required"}, status=400
        )

    purchase = IapPurchase.objects.filter(purchase_token=token).first()
    if purchase is None:
        return Response({"success": True, "status": "unclaimed"})

    if purchase.user_id == request.user.id:
        return Response(
            {
                "success": True,
                "status": "yours",
                "product_id": purchase.google_product_id,
                "expiry_at": purchase.expiry_at,
            }
        )

    can_transfer, reason = _transfer_availability(purchase)
    return Response(
        {
            "success": True,
            "status": "other_account",
            "product_id": purchase.google_product_id,
            "owner_hint": _mask_email(getattr(purchase.user, "email", "")),
            "can_transfer": can_transfer,
            "reason": reason,
        }
    )


def _transfer_availability(purchase):
    """A purchase may move at most once per TRANSFER_COOLDOWN."""
    if not purchase.is_subscription:
        # Diamonds are consumables — already credited and spendable, so there is
        # nothing to move. Only recurring entitlements can be relocated.
        return False, "not_transferable"
    if purchase.status != "granted":
        return False, "not_active"
    if purchase.transferred_at:
        elapsed = timezone.now() - purchase.transferred_at
        if elapsed < TRANSFER_COOLDOWN:
            days = (TRANSFER_COOLDOWN - elapsed).days + 1
            return False, f"cooldown_{days}d"
    return True, ""


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def iap_transfer(request):
    """Move a purchase's entitlement to the calling AdsyClub account.

    Google ties the subscription to the buyer's Google account, so a user who
    signs into AdsyClub with a different email cannot buy it again — Play says
    ITEM_ALREADY_OWNED. Since the entitlement is ours to place, we let them move
    it: the previous account loses it, this one gains it, and the Google-side
    subscription is untouched. One payment still yields exactly one active
    entitlement.

    Body: {purchase_token}.
    """
    token = (request.data.get("purchase_token") or "").strip()
    if not token:
        return Response(
            {"success": False, "error": "purchase_token required"}, status=400
        )

    purchase = IapPurchase.objects.filter(purchase_token=token).first()
    if purchase is None:
        return Response(
            {"success": False, "error": "unknown purchase"}, status=404
        )
    if purchase.user_id == request.user.id:
        return Response({"success": True, "status": "already_yours"})

    product = IapProduct.objects.filter(
        google_product_id=purchase.google_product_id
    ).first()
    if product is None:
        return Response(
            {"success": False, "error": "unknown product"}, status=400
        )

    can_transfer, reason = _transfer_availability(purchase)
    if not can_transfer:
        return Response(
            {"success": False, "error": "transfer_unavailable", "reason": reason},
            status=409,
        )

    # Re-check with Google: never move a lapsed or refunded entitlement.
    google_data = verify.verify_subscription(token) if purchase.is_subscription \
        else verify.verify_product(
            product_id=purchase.google_product_id, purchase_token=token
        )
    if not google_data:
        return Response(
            {"success": False, "error": "verification failed"}, status=402
        )

    # Strip the entitlement from the old account first, so a mid-way failure
    # can never leave the same purchase active on two accounts.
    previous_user = purchase.user
    grants.revoke(purchase, reason="transferred")

    purchase.user = request.user
    purchase.obfuscated_account_id = obfuscated_account_id(request.user)
    purchase.transferred_at = timezone.now()
    purchase.transfer_count += 1
    purchase.raw = google_data

    granted = grants.grant(purchase, product, google_data)
    purchase.status = "granted" if granted else "failed"
    purchase.save()

    logger.info(
        "[iap] transfer %s: user %s -> %s (%s)",
        purchase.google_product_id, previous_user.id, request.user.id,
        "ok" if granted else "FAILED",
    )
    return Response({"success": granted, "status": purchase.status})


@api_view(["POST"])
@permission_classes([AllowAny])
def iap_rtdn(request):
    """Real-time Developer Notifications (Pub/Sub push) for subscription
    lifecycle — auto-renew, cancel, expire, refund. Keeps entitlements in sync
    without the app. Google posts {message: {data: base64(json)}}."""
    try:
        msg = (request.data or {}).get("message") or {}
        raw = msg.get("data")
        if not raw:
            logger.info("[iap] RTDN received (no data / handshake)")
            return Response({"ok": True})
        payload = json.loads(base64.b64decode(raw).decode("utf-8"))
        if payload.get("testNotification"):
            logger.info("[iap] RTDN TEST notification received OK: %s", payload)
            return Response({"ok": True})
        sub = payload.get("subscriptionNotification")
        if not sub:
            logger.info("[iap] RTDN received (non-subscription): %s", list(payload.keys()))
            return Response({"ok": True})
        logger.info(
            "[iap] RTDN subscriptionNotification type=%s token=%s",
            sub.get("notificationType"), (sub.get("purchaseToken") or "")[:16],
        )
        token = sub.get("purchaseToken", "")
        ntype = sub.get("notificationType")
        purchase = IapPurchase.objects.filter(purchase_token=token).first()
        if not purchase:
            return Response({"ok": True})

        google_data = verify.verify_subscription(token)
        # Notification types: 2 RENEWED, 3 CANCELED, 4 PURCHASED, 12 REVOKED,
        # 13 EXPIRED. Re-derive entitlement from the authoritative state.
        product = IapProduct.objects.filter(
            google_product_id=purchase.google_product_id
        ).first()
        if ntype in (2, 4, 1, 7):  # renewed / purchased / recovered / restarted
            if product and google_data:
                grants.grant(purchase, product, google_data)
                purchase.status = "granted"
                if product and ntype == 2:  # only email real renewals
                    try:
                        from base.email_service import send_iap_purchase_email

                        send_iap_purchase_email(
                            purchase, product, event="renewal"
                        )
                    except Exception:
                        logger.exception("[iap] renewal email failed")
        elif ntype in (13, 12):  # expired / revoked
            # SECURITY: never revoke on the notification alone — this webhook is
            # unauthenticated, so a forged type=13 with a known token could
            # otherwise strip a paying user's entitlement. Only revoke when
            # Google's authoritative state confirms the subscription is no longer
            # active. If verification is unavailable, leave the entitlement.
            state = str((google_data or {}).get("subscriptionState") or "").upper()
            still_active = state in {
                "SUBSCRIPTION_STATE_ACTIVE",
                "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
                "SUBSCRIPTION_STATE_ON_HOLD",
            }
            if not google_data or still_active:
                logger.warning(
                    "[iap] RTDN revoke ignored (unverified/still-active) "
                    "type=%s token=%s state=%s",
                    ntype, (token or "")[:16], state or "unknown",
                )
                return Response({"ok": True})
            grants.revoke(purchase, reason="expired")
            purchase.status = "expired"
            if product:
                try:
                    from base.email_service import send_iap_purchase_email

                    send_iap_purchase_email(purchase, product, event="expired")
                except Exception:
                    logger.exception("[iap] expiry email failed")
        purchase.raw = google_data or purchase.raw
        purchase.updated_at = timezone.now()
        purchase.save()
    except Exception:
        logger.exception("[iap] RTDN handling failed")
    # Always 200 so Pub/Sub doesn't redeliver forever.
    return Response({"ok": True})
