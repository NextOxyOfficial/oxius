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


@api_view(["GET"])
def getLogo(request):
    logo = get_object_or_404(Logo)
    serializer = logoSerializer(logo)
    return Response(serializer.data)


@api_view(["GET"])
def get_eshop_logo(request):
    e_shop_logo = get_object_or_404(EshopLogo)
    serializer = EshopLogoSerializer(e_shop_logo)
    return Response(serializer.data)


@api_view(["GET"])
def getAuthenticationBanner(request):
    banner = get_object_or_404(AuthenticationBanner)
    serializer = AuthenticationBannerSerializer(banner)
    return Response(serializer.data)


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

    serializer = AdminNoticeSerializer(queryset, many=True)
    return Response(serializer.data)
