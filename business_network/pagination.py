from rest_framework.pagination import PageNumberPagination

class StandardResultsSetPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100

class SmallResultsSetPagination(PageNumberPagination):
    page_size = 5
    page_size_query_param = 'page_size'
    max_page_size = 20

class LargeResultsSetPagination(PageNumberPagination):
    page_size = 25
    page_size_query_param = 'page_size'
    max_page_size = 100

class MediumDevicePagination(PageNumberPagination):
    """Optimized pagination for medium-level devices"""
    page_size = 7
    page_size_query_param = 'page_size'
    max_page_size = 15

class LowDevicePagination(PageNumberPagination):
    """Optimized pagination for low-end devices"""
    page_size = 3
    page_size_query_param = 'page_size'
    max_page_size = 8