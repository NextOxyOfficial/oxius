import re
from django.utils.deprecation import MiddlewareMixin


class DeviceOptimizationMiddleware(MiddlewareMixin):
    """
    Middleware to detect device capability and optimize responses accordingly
    """
    
    # User agent patterns for different device types
    LOW_END_PATTERNS = [
        r'(?i).*android.*2\.[0-3].*',  # Old Android versions
        r'(?i).*android.*4\.[0-1].*',  # Older Android versions
        r'(?i).*nokia.*',               # Nokia devices
        r'(?i).*blackberry.*',          # BlackBerry devices
        r'(?i).*windows.*phone.*7.*',   # Old Windows Phone
        r'(?i).*opera.*mini.*',         # Opera Mini browser
    ]
    
    MEDIUM_END_PATTERNS = [
        r'(?i).*android.*4\.[2-4].*',   # Mid-range Android
        r'(?i).*android.*5\..*',        # Android 5.x
        r'(?i).*android.*6\..*',        # Android 6.x
        r'(?i).*iphone.*os.*[6-9].*',   # Older iPhone versions
        r'(?i).*ipad.*os.*[6-9].*',     # Older iPad versions
    ]
    
    def process_request(self, request):
        user_agent = request.META.get('HTTP_USER_AGENT', '')
        
        # Check for device level override in query params
        device_level = request.GET.get('device_level')
        if device_level in ['low', 'medium', 'high']:
            request.device_level = device_level
            return
        
        # Detect device level from user agent
        for pattern in self.LOW_END_PATTERNS:
            if re.match(pattern, user_agent):
                request.device_level = 'low'
                return
        
        for pattern in self.MEDIUM_END_PATTERNS:
            if re.match(pattern, user_agent):
                request.device_level = 'medium'
                return
        
        # Default to high-end for modern devices
        request.device_level = 'high'
    
    def process_response(self, request, response):
        # Add device level header for debugging
        if hasattr(request, 'device_level'):
            response['X-Device-Level'] = request.device_level
        
        return response
