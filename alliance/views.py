import logging
import uuid as uuidlib

from django.contrib.auth import authenticate
from django.core.exceptions import ValidationError
from django.utils import timezone
from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAdminUser
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken

from .models import AllianceDonation, OutreachDraft
from .serializers import AllianceDonationSerializer, OutreachDraftSerializer
from .tasks import dispatch_outreach

logger = logging.getLogger(__name__)

SITE = "https://adsyclub.com"


@api_view(["POST"])
@permission_classes([AllowAny])
def alliance_login(request):
    """Login for the /alliance console using DJANGO ADMIN credentials.

    Only staff/superuser accounts get a token — a normal app user ID will NOT
    work here. Returns a JWT the console uses for the admin-only draft API."""
    identifier = (request.data.get("username") or request.data.get("email") or "").strip()
    password = request.data.get("password") or ""
    if not identifier or not password:
        return Response({"error": "Enter your admin email and password."}, status=400)

    # The custom User model logs in by email (USERNAME_FIELD differs), so resolve
    # the account by email or username and verify the password directly — this is
    # robust regardless of the configured auth backend.
    from django.contrib.auth import get_user_model
    User = get_user_model()
    user = (User.objects.filter(email__iexact=identifier).first()
            or User.objects.filter(username__iexact=identifier).first())
    if user is None or not user.check_password(password):
        return Response({"error": "Invalid admin credentials."}, status=401)
    if not user.is_active:
        return Response({"error": "This account is not active."}, status=403)
    if not (user.is_staff or user.is_superuser):
        return Response(
            {"error": "Access denied. This area is for AdsyClub admins only."},
            status=403,
        )

    refresh = RefreshToken.for_user(user)
    return Response({
        "access": str(refresh.access_token),
        "refresh": str(refresh),
        "name": getattr(user, "name", None) or getattr(user, "email", "Admin"),
        "is_superuser": user.is_superuser,
    })


class OutreachDraftViewSet(viewsets.ModelViewSet):
    """Founder-only console for reviewing/editing/sending outreach drafts.
    (Drafts are prepared by the assistant and inserted; the founder reviews,
    edits subject/body/email here, then sends.)"""

    queryset = OutreachDraft.objects.all()
    serializer_class = OutreachDraftSerializer
    permission_classes = [IsAdminUser]

    def get_queryset(self):
        qs = OutreachDraft.objects.all()
        category = self.request.query_params.get("category")
        status_f = self.request.query_params.get("status")
        if category:
            qs = qs.filter(category=category)
        if status_f:
            qs = qs.filter(status=status_f)
        return qs

    @action(detail=False, methods=["get"])
    def stats(self, request):
        from django.db.models import Count
        rows = OutreachDraft.objects.values("status").annotate(n=Count("id"))
        by_status = {r["status"]: r["n"] for r in rows}
        return Response({
            "total": OutreachDraft.objects.count(),
            "by_status": by_status,
        })

    @action(detail=False, methods=["post"])
    def preview(self, request):
        """Render the FULL outreach email (branded template + signature + Donate)
        for the given subject/body — exactly what the recipient will receive.
        Reflects unsaved edits since the console posts the live field values."""
        from .emails import render_outreach_email

        class _Draft:
            pass

        d = _Draft()
        d.subject = (request.data.get("subject") or "").strip()
        d.body_html = request.data.get("body_html") or ""
        d.to_email = (request.data.get("to_email") or "").strip()
        subject, html, _text = render_outreach_email(d)
        return Response({"html": html, "subject": subject})

    @action(detail=False, methods=["post"])
    def send_test(self, request):
        """Send a TEST of this email to the founder's own inbox before the real
        send. Body: {test_email, subject, body_html}. Uses the Django-admin SMTP."""
        from .emails import send_test_email

        test_email = (request.data.get("test_email") or "").strip()
        if not test_email or "@" not in test_email:
            return Response({"error": "Enter a valid test email address."}, status=400)
        try:
            send_test_email(
                request.data.get("subject") or "",
                request.data.get("body_html") or "",
                test_email,
                draft_id=request.data.get("o") or None,
            )
        except Exception as exc:
            logger.exception("Alliance test send failed -> %s", test_email)
            return Response({"error": f"Test send failed: {exc}"}, status=502)
        return Response({"sent": True, "to": test_email})

    @action(detail=False, methods=["post"])
    def bulk_create(self, request):
        """Insert a batch of prepared drafts. Body: {"drafts": [ {...}, ... ]}."""
        items = request.data.get("drafts") or []
        created = []
        for item in items:
            ser = OutreachDraftSerializer(data=item)
            if ser.is_valid():
                created.append(OutreachDraft(**ser.validated_data))
        OutreachDraft.objects.bulk_create(created)
        return Response({"created": len(created)}, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=["post"])
    def send(self, request):
        """Schedule sending. Body: {"ids": [...]} (or omit to send all sendable)."""
        ids = request.data.get("ids")
        if ids:
            qs = OutreachDraft.objects.filter(id__in=ids)
        else:
            qs = OutreachDraft.objects.filter(status__in=["draft", "approved", "failed"])
        draft_ids = [str(d.id) for d in qs]
        queued = dispatch_outreach(draft_ids)
        return Response({"scheduled": queued})

    @action(detail=True, methods=["post"])
    def skip(self, request, pk=None):
        draft = self.get_object()
        draft.status = "skipped"
        draft.save(update_fields=["status", "updated_at"])
        return Response({"status": "skipped"})


def _lookup_draft(oid):
    """Safely fetch an OutreachDraft by its UUID (returns None on bad/missing id)."""
    if not oid:
        return None
    try:
        return OutreachDraft.objects.filter(id=oid).first()
    except (ValueError, ValidationError):
        return None


DONATE_SALT = "adsy-donate-v1"  # must match base.email_service.DONATE_SALT


def _decode_donate_token(token):
    """Decode the signed ?u= token used by transactional emails -> (name, language)."""
    if not token:
        return None
    try:
        from django.core import signing
        data = signing.loads(token, salt=DONATE_SALT, max_age=60 * 60 * 24 * 60)
        return (data.get("n", ""), data.get("l", "bn"))
    except Exception:
        return None


@api_view(["GET"])
@permission_classes([AllowAny])
def donate_context(request):
    """Public: given a personalized donate link, return the recipient's display
    name + language so the /donate page can greet them. Two link styles:
      ?o=<draft id>  — Alliance outreach (name/language from the draft)
      ?u=<token>     — transactional emails (name/language from a signed token)
    Exposes only the display name + language."""
    decoded = _decode_donate_token(request.query_params.get("u"))
    if decoded:
        return Response({"name": decoded[0], "language": decoded[1]})
    draft = _lookup_draft(request.query_params.get("o"))
    if not draft:
        return Response({"name": "", "language": "en"})
    return Response({
        "name": draft.to_name or draft.company or "",
        "language": draft.language or "en",
    })


@api_view(["POST"])
@permission_classes([AllowAny])
def donate_initiate(request):
    """Start a SurjoPay donation. Returns a checkout_url to redirect to.
    Donations are recorded separately and NEVER credit a wallet balance."""
    from base.pay import _build_engine, _make_payment_with_fallback
    from shurjopay_plugin import PaymentRequestModel

    amount_raw = request.data.get("amount")
    try:
        amount = float(amount_raw)
        if amount <= 0 or amount > 1_000_000:
            raise ValueError
    except (TypeError, ValueError):
        return Response({"error": "Please enter a valid amount."}, status=400)

    # Personalized/localised context from the donate link (?o=<draft id> or ?u=<token>).
    language = (request.data.get("language") or "en").lower()
    recipient_name = ""
    decoded = _decode_donate_token(request.data.get("u"))
    if decoded:
        recipient_name, language = decoded[0], decoded[1]
    else:
        draft = _lookup_draft(request.data.get("o"))
        if draft:
            recipient_name = draft.to_name or draft.company or ""
            language = draft.language or language
    if language not in ("en", "bn"):
        language = "en"

    order_id = "DONATE_" + uuidlib.uuid4().hex[:16]
    donation = AllianceDonation.objects.create(
        order_id=order_id,
        amount=round(amount, 2),
        language=language,
        recipient_name=recipient_name[:200],
        donor_name=(request.data.get("name") or "").strip()[:200],
        donor_email=(request.data.get("email") or "").strip()[:254],
        donor_phone=(request.data.get("phone") or "").strip()[:40],
        message=(request.data.get("message") or "").strip()[:500],
    )

    return_url = f"{SITE}/donate/success?ref={order_id}"
    cancel_url = f"{SITE}/donate?cancelled=1"
    try:
        engine = _build_engine(return_url=return_url, cancel_url=cancel_url)
        model = PaymentRequestModel(
            amount=str(donation.amount),
            order_id=order_id,
            currency="BDT",
            customer_name=donation.donor_name or "AdsyClub Supporter",
            customer_address="Bangladesh",
            customer_phone=donation.donor_phone or "01700000000",
            customer_city="Dhaka",
            customer_post_code="1200",
        )
        details = _make_payment_with_fallback(engine, model) or {}
    except Exception as exc:
        logger.exception("Donation init failed for %s", order_id)
        donation.status = "failed"
        donation.save(update_fields=["status"])
        return Response({"error": f"Could not start payment: {exc}"}, status=502)

    sp_oid = details.get("sp_order_id") or details.get("shurjopay_order_id")
    if sp_oid:
        donation.sp_order_id = str(sp_oid)
        donation.save(update_fields=["sp_order_id"])

    checkout_url = details.get("checkout_url")
    if not checkout_url:
        donation.status = "failed"
        donation.save(update_fields=["status"])
        return Response({"error": "Payment gateway did not return a checkout URL."}, status=502)

    return Response({"checkout_url": checkout_url, "ref": order_id})


@api_view(["GET"])
@permission_classes([AllowAny])
def donate_verify(request):
    """Verify a donation after SurjoPay redirect. Query: ref=<order_id> (+ optional order_id)."""
    from base.pay import _build_engine, _serialize_payment_details

    ref = request.query_params.get("ref")
    donation = AllianceDonation.objects.filter(order_id=ref).first()
    if not donation:
        return Response({"error": "Donation not found."}, status=404)

    def _payload(status_value):
        return {
            "status": status_value,
            "amount": str(donation.amount),
            "language": donation.language or "en",
            "name": donation.recipient_name or donation.donor_name or "",
        }

    if donation.status == "completed":
        return Response(_payload("completed"))

    sp_oid = request.query_params.get("order_id") or donation.sp_order_id
    if not sp_oid:
        return Response(_payload(donation.status))

    try:
        engine = _build_engine()
        details = _serialize_payment_details(engine.verify_payment(sp_oid)) or {}
    except Exception as exc:
        logger.warning("Donation verify error for %s: %s", ref, exc)
        return Response(_payload(donation.status))

    bank = str(details.get("bank_status") or "").lower()
    msg = str(details.get("sp_message") or details.get("message") or "").lower()
    code = str(details.get("sp_code") or details.get("code") or "")
    is_success = bank == "success" or code == "1000" or "success" in msg

    if is_success:
        donation.status = "completed"
        donation.completed_at = timezone.now()
        donation.save(update_fields=["status", "completed_at"])
        return Response(_payload("completed"))

    return Response(_payload("pending"))
