import json
import logging
import secrets
from decimal import Decimal, InvalidOperation
from urllib.parse import parse_qsl, urlencode, urlparse, urlunparse

from django.conf import settings
from django.core.cache import cache
from django.shortcuts import render
import requests
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from shurjopay_plugin import *

from .models import Balance


logger = logging.getLogger(__name__)


_PAYMENT_STATE_MAX_AGE = 60 * 60 * 6
_PAYMENT_REF_CACHE_PREFIX = "payment_ref:"

def _is_safe_redirect_url(value):
    try:
        parsed = urlparse(value)
    except Exception:
        return False

    return parsed.scheme in ["http", "https"] and bool(parsed.netloc)


def _append_query_params(url, extra_params):
    if not url:
        return url

    parsed = urlparse(url)
    query = dict(parse_qsl(parsed.query, keep_blank_values=True))
    for key, value in extra_params.items():
        if value is None:
            continue
        query[key] = str(value)

    return urlunparse(
        parsed._replace(query=urlencode(query, doseq=True)),
    )


def _payment_ref_cache_key(payment_ref):
    return f"{_PAYMENT_REF_CACHE_PREFIX}{payment_ref}"


def _create_payment_ref(*, user_id, order_id, amount):
    payment_ref = secrets.token_urlsafe(9)
    cache.set(
        _payment_ref_cache_key(payment_ref),
        {
            "user_id": str(user_id),
            "order_id": str(order_id),
            "amount": str(amount),
        },
        timeout=_PAYMENT_STATE_MAX_AGE,
    )
    return payment_ref


def _load_payment_ref(payment_ref):
    return cache.get(_payment_ref_cache_key(payment_ref))


def _serialize_payment_details(payment_details):
    if hasattr(payment_details, "__dict__"):
        return payment_details.__dict__
    return None


_PENDING_PAYMENT_MARKERS = [
    "not found",
    "no data",
    "invalid sp order id",
    "invalid order",
    "does not exist",
    "unable to verify",
    "merchant order",
    "initiated",
    "pending",
]


def _is_pending_payment_error(message):
    normalized_message = str(message or "").lower()
    return any(marker in normalized_message for marker in _PENDING_PAYMENT_MARKERS)


def _pending_payment_response(order_id=None, *, include_success=False):
    payload = {
        "status": "pending",
        "bank_status": "pending",
        "shurjopay_message": "Pending",
        "message": "Payment is not confirmed yet.",
    }
    if order_id:
        payload["sp_order_id"] = order_id
    if include_success:
        payload["success"] = False
    return Response(payload, status=status.HTTP_200_OK)


def _find_checkout_url(payload):
    if isinstance(payload, dict):
        candidate_keys = [
            "checkout_url",
            "payment_url",
            "redirect_url",
            "bank_page_url",
            "gateway_url",
            "url",
            "checkoutUrl",
            "redirectUrl",
            "redirect",
            "link",
        ]

        for key in candidate_keys:
            value = payload.get(key)
            if isinstance(value, str) and value.strip().startswith(("http://", "https://")):
                return value.strip()

        for value in payload.values():
            found = _find_checkout_url(value)
            if found:
                return found

    if isinstance(payload, list):
        for item in payload:
            found = _find_checkout_url(item)
            if found:
                return found

    if isinstance(payload, str) and payload.strip().startswith(("http://", "https://")):
        return payload.strip()

    return None


def _normalize_payment_creation_response(payload):
    if not isinstance(payload, dict):
        return None

    normalized = dict(payload)
    checkout_url = _find_checkout_url(normalized)
    if checkout_url:
        normalized.setdefault("checkout_url", checkout_url)

    return normalized if normalized.get("checkout_url") else None


def _make_payment_with_fallback(payment_engine, payment_request):
    try:
        payment_details = payment_engine.make_payment(payment_request)
        serialized = _serialize_payment_details(payment_details)
        if serialized is not None:
            normalized = _normalize_payment_creation_response(serialized)
            if normalized is not None:
                return normalized
    except KeyError as exc:
        if str(exc).strip("'") != "checkout_url":
            raise

    if payment_engine.AUTH_TOKEN is None or payment_engine.is_token_valid() is False:
        payment_engine.AUTH_TOKEN = payment_engine.authenticate()

    url = requests.compat.urljoin(payment_engine.SP_ENDPOINT, "secret-pay")
    headers = {
        "content-type": "application/json",
        "Authorization": f"{payment_engine.AUTH_TOKEN.token_type} {payment_engine.AUTH_TOKEN.token}",
    }
    payloads = payment_engine._map_payment_request(payment_request)
    response = requests.post(url, headers=headers, data=json.dumps(payloads))
    response_json = response.json()
    normalized = _normalize_payment_creation_response(response_json)

    if normalized is None:
        raise ValueError(response_json.get("message") or response_json.get("sp_message") or "Payment gateway did not return a checkout URL")

    return normalized


def _finalize_verified_deposit(*, user, payment_details):
    merchant_invoice_no = payment_details.get("merchant_invoice_no")
    if not merchant_invoice_no:
        raise ValueError("Missing merchant invoice number")

    existing_transaction = Balance.objects.filter(
        user=user,
        merchant_invoice_no=merchant_invoice_no,
        transaction_type="deposit",
    ).first()

    if existing_transaction:
        if existing_transaction.completed or existing_transaction.bank_status == "completed":
            return {
                "already_processed": True,
                "transaction_id": str(existing_transaction.id),
            }

        return {
            "already_processed": True,
            "transaction_id": str(existing_transaction.id),
        }

    try:
        payable_amount = Decimal(str(payment_details.get("payable_amount") or payment_details.get("amount") or 0)).quantize(Decimal("0.01"))
    except (InvalidOperation, TypeError, ValueError):
        raise ValueError("Invalid payable amount")

    try:
        amount = Decimal(str(payment_details.get("amount") or payable_amount)).quantize(Decimal("0.01"))
    except (InvalidOperation, TypeError, ValueError):
        amount = payable_amount

    try:
        received_amount = Decimal(str(payment_details.get("received_amount") or payable_amount)).quantize(Decimal("0.01"))
    except (InvalidOperation, TypeError, ValueError):
        received_amount = payable_amount

    transaction = Balance.objects.create(
        user=user,
        transaction_type="deposit",
        payment_method=payment_details.get("payment_method") or "shurjopay",
        amount=amount,
        payable_amount=payable_amount,
        received_amount=received_amount,
        merchant_invoice_no=merchant_invoice_no,
        shurjopay_order_id=payment_details.get("shurjopay_order_id") or payment_details.get("sp_order_id") or "",
        payment_confirmed_at=payment_details.get("payment_confirmed_at"),
        bank_status="completed",
    )

    return {
        "already_processed": False,
        "transaction_id": str(transaction.id),
    }


def _build_engine(return_url=None, cancel_url=None):
    resolved_return = return_url if return_url and _is_safe_redirect_url(return_url) else settings.SP_RETURN
    resolved_cancel = cancel_url if cancel_url and _is_safe_redirect_url(cancel_url) else settings.SP_CANCEL

    return ShurjopayPlugin(
        ShurjoPayConfigModel(
            SP_USERNAME=settings.SP_USERNAME,
            SP_PASSWORD=settings.SP_PASSWORD,
            SP_ENDPOINT=settings.SP_ENDPOINT,
            SP_RETURN=resolved_return,
            SP_CANCEL=resolved_cancel,
            SP_PREFIX=settings.SP_PREFIX,
            SP_LOGDIR='./shurjopay_live.log'
        )
    )


engine = _build_engine()
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def verifyPayment(request):
    # Extracting query parameters
    required_params = [
        'sp_order_id', 
    ]
    
    # Check if all required parameters are provided
    missing_params = [param for param in required_params if param not in request.query_params]
    if missing_params:
        return Response(
            {"error": f"Missing mandatory parameters: {', '.join(missing_params)}"},
            status=status.HTTP_400_BAD_REQUEST
        )
    oid = request.query_params.get('sp_order_id')
    try:
        payment_details = engine.verify_payment(oid)
        payment_details_dict = _serialize_payment_details(payment_details)

        if payment_details_dict is None:
            return Response(
                {"error": "Payment details could not be serialized."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        return Response(payment_details_dict, status=status.HTTP_200_OK)
    except Exception as e:
        message = str(e)
        if _is_pending_payment_error(message):
            logger.info("Shurjopay verification still pending for order %s", oid)
            return _pending_payment_response(oid)

        logger.exception("Unexpected Shurjopay verification error for order %s", oid)
        return Response(
            {"error": "Payment verification failed."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def makePayment(request):
    # Extracting query parameters
    required_params = [
        'amount', 'order_id', 'currency', 'customer_name',
        'customer_address', 'customer_phone', 'customer_city', 'customer_post_code'
    ]

    # Check if all required parameters are provided
    missing_params = [param for param in required_params if param not in request.query_params]
    if missing_params:
        return Response(
            {"error": f"Missing mandatory parameters: {', '.join(missing_params)}"},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Sanity-check the amount server-side (this is a wallet top-up — the user
    # deposits their own money, and the wallet is later credited from the
    # gateway-confirmed received_amount, not this value — but still reject junk
    # and absurd values to stop gateway abuse).
    try:
        amt = Decimal(str(request.query_params.get('amount'))).quantize(Decimal("0.01"))
    except (InvalidOperation, TypeError, ValueError):
        return Response({"error": "Invalid amount"}, status=status.HTTP_400_BAD_REQUEST)
    if amt <= 0 or amt > Decimal("500000"):
        return Response(
            {"error": "Amount must be between 1 and 500000"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        return_url = request.query_params.get('return_url')
        cancel_url = request.query_params.get('cancel_url')

        # Extract parameters from the request
        amount = request.query_params.get('amount')
        order_id = request.query_params.get('order_id')
        currency = request.query_params.get('currency')
        customer_name = request.query_params.get('customer_name')
        customer_address = request.query_params.get('customer_address')
        customer_phone = request.query_params.get('customer_phone')
        customer_city = request.query_params.get('customer_city')
        customer_post_code = request.query_params.get('customer_post_code')

        if getattr(request, 'user', None) is not None and request.user.is_authenticated:
            payment_ref = _create_payment_ref(
                user_id=request.user.id,
                order_id=order_id,
                amount=amount,
            )
            return_url = _append_query_params(
                return_url or settings.SP_RETURN,
                {
                    'payment_ref': payment_ref,
                },
            )
            cancel_url = _append_query_params(
                cancel_url or settings.SP_CANCEL,
                {
                    'payment_ref': payment_ref,
                },
            )

        # Creating the payment request model
        model = PaymentRequestModel(
            amount=amount,
            order_id=order_id,
            currency=currency,
            customer_name=customer_name,
            customer_address=customer_address,
            customer_phone=customer_phone,
            customer_city=customer_city,
            customer_post_code=customer_post_code,
        )
        
        # Making the payment
        payment_engine = _build_engine(return_url=return_url, cancel_url=cancel_url)
        payment_details_dict = _make_payment_with_fallback(payment_engine, model)
        
        return Response(payment_details_dict, status=status.HTTP_200_OK)
    
    except Exception as e:
        print(str(e))
        return Response(
            {"error": str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(["POST"])
def finalizePaymentWithState(request):
    payment_ref = (
        request.data.get("payment_ref")
        or request.query_params.get("payment_ref")
        or request.data.get("payment_state")
        or request.query_params.get("payment_state")
    )
    order_id = request.data.get("sp_order_id") or request.query_params.get("sp_order_id")

    if not payment_ref or not order_id:
        return Response(
            {"error": "payment_ref and sp_order_id are required"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    state = _load_payment_ref(payment_ref)
    if not state:
        return Response(
            {"error": "Invalid or expired payment session"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    user_id = state.get("user_id")
    if not user_id:
        return Response(
            {"error": "Payment session is missing user information"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    user_model = Balance._meta.get_field("user").remote_field.model
    try:
        user = user_model.objects.get(pk=user_id)
    except user_model.DoesNotExist:
        return Response(
            {"error": "User not found for this payment session"},
            status=status.HTTP_404_NOT_FOUND,
        )

    try:
        payment_details = engine.verify_payment(order_id)
        payment_details_dict = _serialize_payment_details(payment_details)
        if payment_details_dict is None:
            raise ValueError("Payment details could not be serialized.")
    except Exception as exc:
        message = str(exc)
        if _is_pending_payment_error(message):
            logger.info("Shurjopay finalization still pending for order %s", order_id)
            return _pending_payment_response(order_id, include_success=True)

        logger.exception("Unexpected Shurjopay finalization error for order %s", order_id)
        return Response({"error": "Payment verification failed."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    bank_status = str(payment_details_dict.get("bank_status") or "").lower()
    sp_message = str(payment_details_dict.get("shurjopay_message") or "").lower()
    is_success = sp_message == "success" or bank_status in {"success", "completed"}
    is_failed = any(marker in f"{sp_message} {bank_status}" for marker in ["fail", "cancel", "declin", "expire", "invalid"])
    merchant_invoice_no = str(payment_details_dict.get("merchant_invoice_no") or "")

    if str(state.get("order_id") or "") != merchant_invoice_no:
        return Response(
            {"error": "Payment session does not match this order"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if not is_success:
        return Response(
            {
                "success": False,
                "status": "failed" if is_failed else "pending",
                "message": payment_details_dict.get("shurjopay_message") or "Payment is not confirmed yet.",
                "payment_details": payment_details_dict,
            },
            status=status.HTTP_200_OK,
        )

    try:
        finalize_result = _finalize_verified_deposit(
            user=user,
            payment_details=payment_details_dict,
        )
    except ValueError as exc:
        return Response({"error": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as exc:
        return Response({"error": str(exc)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return Response(
        {
            "success": True,
            "status": "success",
            "message": "Payment successful! Your balance has been updated.",
            "already_processed": finalize_result["already_processed"],
            "transaction_id": finalize_result["transaction_id"],
            "payment_details": payment_details_dict,
        },
        status=status.HTTP_200_OK,
    )
