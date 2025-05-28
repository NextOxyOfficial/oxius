# Custom middleware to monitor session behavior
import logging
from django.utils import timezone

logger = logging.getLogger(__name__)

class SessionMonitoringMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Log session info before processing request
        if hasattr(request, 'session') and request.session.session_key:
            logger.info(f"Session {request.session.session_key} - Age: {request.session.get_expiry_age()} seconds")
        
        response = self.get_response(request)
        
        # Log session info after processing request
        if hasattr(request, 'session') and request.session.session_key:
            logger.info(f"Session {request.session.session_key} - Updated, expires: {request.session.get_expiry_date()}")
        
        return response
