"""Saved push-notification ("Updates") API.

Backs the AdsyConnect Updates tab: lists the current user's notifications
(plus broadcasts), exposes unread count, and marks them read. Notifications
with a `deep_link` carry a "Visit" button on the client.
"""
from django.db.models import Q
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from ..models import UserNotification
from ..serializers import UserNotificationSerializer


class _NotificationPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100


def _visible_qs(user):
    # The user's own notifications plus any broadcast (user is null).
    return UserNotification.objects.filter(
        Q(user=user) | Q(user__isnull=True)
    ).order_by("-created_at")


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def list_user_notifications(request):
    qs = _visible_qs(request.user)
    paginator = _NotificationPagination()
    page = paginator.paginate_queryset(qs, request)
    serializer = UserNotificationSerializer(page, many=True)
    return paginator.get_paginated_response(serializer.data)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def user_notifications_unread_count(request):
    count = (
        UserNotification.objects.filter(user=request.user, is_read=False).count()
    )
    return Response({"unread": count})


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def mark_user_notification_read(request, notification_id):
    # Only the user's own (non-broadcast) notifications carry per-user read state.
    updated = UserNotification.objects.filter(
        id=notification_id, user=request.user
    ).update(is_read=True)
    if not updated:
        return Response(
            {"detail": "Notification not found."},
            status=status.HTTP_404_NOT_FOUND,
        )
    return Response({"success": True})


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def mark_all_user_notifications_read(request):
    UserNotification.objects.filter(user=request.user, is_read=False).update(
        is_read=True
    )
    return Response({"success": True})
