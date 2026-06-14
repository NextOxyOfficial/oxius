from django.http import HttpResponseNotAllowed, JsonResponse


class AccountSuspendedMiddleware:
    """Block every service API for a suspended user.

    Suspended accounts can still hit the auth endpoints below (so the app can
    log in, detect the suspension, show the lock screen and log out) — but any
    other /api/ call returns 403 {code: account_suspended}. The app watches for
    that code and locks itself.
    """

    # Paths a suspended user is still allowed to call.
    WHITELIST = (
        "/api/auth/login/",
        "/api/auth/social/",
        "/api/auth/register/",
        "/api/auth/logout/",
        "/api/auth/validate-token/",
        "/api/token/refresh/",
        "/api/auth/token/",
    )

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        path = request.path or ""
        if path.startswith("/api/") and not path.startswith(self.WHITELIST):
            user_id = self._user_id_from_jwt(request)
            if user_id is not None:
                from .models import User

                suspended = (
                    User.objects.filter(pk=user_id, is_suspended=True)
                    .only("id", "suspension_reason")
                    .first()
                )
                if suspended is not None:
                    return JsonResponse(
                        {
                            "code": "account_suspended",
                            "detail": "Your account has been suspended.",
                            "reason": suspended.suspension_reason or "",
                        },
                        status=403,
                    )
        return self.get_response(request)

    @staticmethod
    def _user_id_from_jwt(request):
        auth = request.META.get("HTTP_AUTHORIZATION", "")
        if not auth.startswith("Bearer "):
            return None
        try:
            from rest_framework_simplejwt.tokens import AccessToken

            token = AccessToken(auth.split(" ", 1)[1].strip())
            return token.get("user_id")
        except Exception:
            return None


class PrivateCacheMiddleware:
    """Never let an intermediary (CDN/proxy/browser) cache a per-user response.

    Authenticated responses carry tokens and private data — e.g.
    ``/auth/validate-token/`` returns fresh access/refresh tokens AND the user
    object. If a "cache everything" edge rule (Cloudflare/nginx) stored one
    user's response and replayed it to another, that user would be silently
    logged in as someone else (the account-switch / data-leak bug). Forcing
    ``no-store`` + ``Vary`` on any request that carries auth credentials closes
    that cross-account leak, while leaving truly anonymous public GETs cacheable.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        auth = request.META.get("HTTP_AUTHORIZATION", "")
        authed = (
            auth.startswith("Bearer ")
            or auth.startswith("Token ")
            or bool(request.COOKIES.get("sessionid"))
            or bool(request.COOKIES.get("adsyclub-jwt"))
        )
        if authed:
            response["Cache-Control"] = "no-store, no-cache, private, max-age=0"
            response["Pragma"] = "no-cache"
            vary = response.get("Vary")
            response["Vary"] = (
                f"{vary}, Cookie, Authorization" if vary else "Cookie, Authorization"
            )
        return response


class BlockConnectMethodMiddleware:
    """
    Block HTTP CONNECT method requests that are not supported by Django dev server.
    This prevents 404 warnings for proxy requests like ipinfo.io:443.
    """
    
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Block CONNECT method (used for HTTP proxying)
        if request.method == 'CONNECT':
            return HttpResponseNotAllowed(['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS'])
        
        response = self.get_response(request)
        return response
