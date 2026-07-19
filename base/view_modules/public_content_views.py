from django.core.cache import cache
from django.db import models
from django.shortcuts import get_object_or_404
from rest_framework.decorators import api_view
from rest_framework.response import Response

from ..models import AdminNotice, AuthenticationBanner, EshopLogo, Logo
from ..serializers import (
    AdminNoticeSerializer,
    AuthenticationBannerSerializer,
    EshopLogoSerializer,
    logoSerializer,
)

# These three endpoints serve global, rarely-changing content that is requested
# on nearly every page/app load, so we cache the serialized payload in Redis.
# Short TTL means an admin edit shows up within a few minutes without any manual
# cache busting.
_PUBLIC_CACHE_TTL = 300  # seconds


@api_view(["GET"])
def getLogo(request):
    data = cache.get("public:logo")
    if data is None:
        logo = get_object_or_404(Logo)
        data = logoSerializer(logo).data
        cache.set("public:logo", data, _PUBLIC_CACHE_TTL)
    return Response(data)


@api_view(["GET"])
def get_eshop_logo(request):
    data = cache.get("public:eshop_logo")
    if data is None:
        e_shop_logo = get_object_or_404(EshopLogo)
        data = EshopLogoSerializer(e_shop_logo).data
        cache.set("public:eshop_logo", data, _PUBLIC_CACHE_TTL)
    return Response(data)


@api_view(["GET"])
def getAuthenticationBanner(request):
    data = cache.get("public:auth_banner")
    if data is None:
        banner = get_object_or_404(AuthenticationBanner)
        data = AuthenticationBannerSerializer(banner).data
        cache.set("public:auth_banner", data, _PUBLIC_CACHE_TTL)
    return Response(data)


@api_view(["GET"])
def getAdminNotice(request):
    notification_type = request.GET.get("type", None)
    user_id = request.user.id if request.user.is_authenticated else None

    queryset = AdminNotice.objects.all()

    if user_id:
        queryset = queryset.filter(models.Q(user=None) | models.Q(user_id=user_id))
    else:
        queryset = queryset.filter(user=None)

    if notification_type and notification_type != "all":
        queryset = queryset.filter(notification_type=notification_type)

    queryset = queryset.order_by("-created_at")

    # Opt-in pagination: the app's inbox passes ?page=N and expects
    # {results, next, count}. Without the param the legacy plain-array
    # response is kept for older clients. (Previously `page` was ignored and
    # the ENTIRE notice history shipped in one response.)
    page_param = request.GET.get("page")
    if page_param:
        from django.core.paginator import EmptyPage, Paginator

        paginator = Paginator(queryset, 20)
        try:
            page_obj = paginator.page(int(page_param))
        except (EmptyPage, ValueError):
            return Response({"results": [], "next": None, "count": paginator.count})
        serializer = AdminNoticeSerializer(page_obj.object_list, many=True)
        # NOTE: `next` must be a string (the app casts it to String?).
        next_page = (
            f"?page={page_obj.next_page_number()}" if page_obj.has_next() else None
        )
        return Response(
            {
                "results": serializer.data,
                "next": next_page,
                "count": paginator.count,
            }
        )

    serializer = AdminNoticeSerializer(queryset, many=True)
    return Response(serializer.data)
