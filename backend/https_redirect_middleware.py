import json

from django.conf import settings
from django.shortcuts import redirect


class CloudflareHttpsRedirectMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if not settings.DEBUG and request.get_host() in {"adsyclub.com", "www.adsyclub.com"}:
            try:
                visitor = json.loads(request.META.get("HTTP_CF_VISITOR", "{}"))
            except json.JSONDecodeError:
                visitor = {}

            if visitor.get("scheme") == "http":
                return redirect(f"https://{request.get_host()}{request.get_full_path()}", permanent=True)

        return self.get_response(request)
