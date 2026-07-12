"""In-App Purchase API: product catalog, purchase verification, RTDN webhook."""
import base64
import json
import logging

from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from . import grants, verify
from .models import IapProduct, IapPurchase

logger = logging.getLogger(__name__)


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
    return Response({"products": data})


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

    # Idempotency: a previously-granted token just re-confirms success.
    existing = IapPurchase.objects.filter(purchase_token=token).first()
    if existing and existing.status == "granted":
        return Response({"success": True, "status": "already_granted"})

    purchase = existing or IapPurchase(
        user=request.user,
        kind=product.kind,
        google_product_id=product_id,
        purchase_token=token,
        is_subscription=product.is_subscription,
    )
    purchase.user = request.user
    purchase.ref_id = ref_id or purchase.ref_id

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

    granted = grants.grant(purchase, product, google_data)
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
