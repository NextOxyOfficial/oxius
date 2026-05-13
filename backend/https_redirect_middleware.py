import json

from django.conf import settings
from django.shortcuts import redirect


class CloudflareHttpsRedirectMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Use raw HTTP_HOST header instead of get_host() so this middleware
        # never raises DisallowedHost when localhost is not in ALLOWED_HOSTS.
        raw_host = request.META.get("HTTP_HOST", "").split(":")[0]
        if not settings.DEBUG and raw_host in {"adsyclub.com", "www.adsyclub.com"}:
            try:
                visitor = json.loads(request.META.get("HTTP_CF_VISITOR", "{}"))
            except json.JSONDecodeError:
                visitor = {}

            if visitor.get("scheme") == "http":
                return redirect(f"https://{raw_host}{request.get_full_path()}", permanent=True)

        return self.get_response(request)
