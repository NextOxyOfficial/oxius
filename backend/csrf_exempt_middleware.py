import re
from django.conf import settings
from django.utils.deprecation import MiddlewareMixin


class CSRFExemptMiddleware(MiddlewareMixin):
    """
    Middleware to exempt API endpoints from CSRF checks
    """
    def process_request(self, request):
        # Exempt all API endpoints from CSRF checks
        if request.path_info.startswith('/api/'):
            setattr(request, '_dont_enforce_csrf_checks', True)
        return None
