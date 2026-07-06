import uuid

from django.contrib.auth import authenticate
from django.core.cache import cache
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken

from ..models import User


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def generate_web_login_token(request):
    """Generate a short-lived single-use token for app-to-web login handoff."""
    token_key = f"app_web_token_{uuid.uuid4().hex}"
    user_id = request.user.id
    cache.set(token_key, user_id, timeout=120)
    return Response({"token": token_key})


@api_view(["POST"])
@permission_classes([AllowAny])
def exchange_web_login_token(request):
    """Exchange a single-use app-to-web token for JWT tokens."""
    token_key = request.data.get("token")
    if not token_key or not token_key.startswith("app_web_token_"):
        return Response({"error": "Invalid token"}, status=400)

    user_id = cache.get(token_key)
    if user_id is None:
        return Response({"error": "Token expired or invalid"}, status=401)

    cache.delete(token_key)

    try:
        user = User.objects.get(id=user_id)
        refresh = RefreshToken.for_user(user)
        return Response(
            {
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            }
        )
    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=404)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def login_as_view(request):
    # Staff-only impersonation: the caller must already be an authenticated
    # staff user AND re-confirm their own credentials. Never expose this to
    # unauthenticated clients — it would act as a password oracle.
    if not request.user.is_staff:
        return Response({"error": "Staff access required"}, status=403)

    username = request.data.get("username")
    password = request.data.get("password")
    login_as = request.data.get("login_as")

    user = authenticate(username=username, password=password)

    if user is not None and user.is_staff and user == request.user:
        try:
            login_as_user = User.objects.get(username=login_as)
            refresh = RefreshToken.for_user(login_as_user)
            return Response(
                {
                    "refresh": str(refresh),
                    "access": str(refresh.access_token),
                }
            )
        except User.DoesNotExist:
            return Response({"error": "Target user not found"}, status=404)

    return Response({"error": "Invalid admin credentials"}, status=400)
