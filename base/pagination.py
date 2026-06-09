from rest_framework.pagination import PageNumberPagination, LimitOffsetPagination
from rest_framework.response import Response


class MicroGigPagination(PageNumberPagination):
    """Backward-compatible pagination for the micro-gigs feed, which is consumed
    three different ways:

    - Flutter app sends ``?page=&page_size=`` -> standard paginated response
      ``{count, next, previous, results}`` (so the app finally paginates instead
      of pulling every gig at once).
    - Homepage (index.vue) sends ``?limit=&offset=`` and expects a *plain array*
      window -> we honour limit/offset and return just that array.
    - The full micro-gigs page (micro-gigs.vue) sends no params and has no
      load-more UI -> return everything, exactly like before (no regression).
    """

    page_size = 12
    page_size_query_param = "page_size"
    max_page_size = 100

    def paginate_queryset(self, queryset, request, view=None):
        params = request.query_params
        if "limit" in params or "offset" in params:
            self._mode = "limit"
            self._lo = LimitOffsetPagination()
            self._lo.default_limit = self.page_size
            self._lo.max_limit = self.max_page_size
            return self._lo.paginate_queryset(queryset, request, view)
        if "page" in params or "page_size" in params:
            self._mode = "page"
            return super().paginate_queryset(queryset, request, view)
        # No pagination params -> let the view return the full list as before.
        self._mode = "all"
        return None

    def get_paginated_response(self, data):
        if getattr(self, "_mode", "page") == "limit":
            return Response(data)  # plain array window for the homepage
        return super().get_paginated_response(data)


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

class ProductPagination(PageNumberPagination):
    page_size = 12
    page_size_query_param = 'page_size'
    max_page_size = 50