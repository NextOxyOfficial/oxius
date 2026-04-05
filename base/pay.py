from django.shortcuts import render
from rest_framework import status
from rest_framework.response import Response
from rest_framework.decorators import api_view
from shurjopay_plugin import *
from django.conf import settings
from urllib.parse import urlparse

def _is_safe_redirect_url(value):
    try:
        parsed = urlparse(value)
    except Exception:
        return False

    return parsed.scheme in ["http", "https"] and bool(parsed.netloc)


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
 
        if hasattr(payment_details, "__dict__"):
            payment_details_dict = payment_details.__dict__
        else:
            return Response(
                {"error": "Payment details could not be serialized."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        return Response(payment_details_dict, status=status.HTTP_200_OK)
    except Exception as e:
        message = str(e)
        normalized_message = message.lower()

        pending_markers = [
            "not found",
            "no data",
            "invalid sp order id",
            "invalid order",
            "does not exist",
            "unable to verify",
            "merchant order",
        ]

        if any(marker in normalized_message for marker in pending_markers):
            return Response(
                {
                    "sp_order_id": oid,
                    "bank_status": "pending",
                    "shurjopay_message": "Pending",
                    "message": "Payment is not confirmed yet.",
                },
                status=status.HTTP_200_OK,
            )

        return Response(
            {"error": message},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
@api_view(["GET"])
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
        payment_details = payment_engine.make_payment(model)
        
        # Convert the payment details to a dictionary
        if hasattr(payment_details, "__dict__"):
            payment_details_dict = payment_details.__dict__
        else:
            return Response(
                {"error": "Payment details could not be serialized."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
        return Response(payment_details_dict, status=status.HTTP_200_OK)
    
    except Exception as e:
        print(str(e))
        return Response(
            {"error": str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
