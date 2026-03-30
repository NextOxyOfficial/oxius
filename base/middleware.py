from django.http import HttpResponseNotAllowed


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
