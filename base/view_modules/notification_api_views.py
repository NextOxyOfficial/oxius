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

from ..models import NotificationRead, UserNotification
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


def _read_broadcast_ids(user, notification_ids=None):
    """IDs of broadcast notifications this user has already read."""
    qs = NotificationRead.objects.filter(
        user=user, notification__user__isnull=True
    )
    if notification_ids is not None:
        qs = qs.filter(notification_id__in=notification_ids)
    return set(qs.values_list("notification_id", flat=True))


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def list_user_notifications(request):
    qs = _visible_qs(request.user)
    paginator = _NotificationPagination()
    page = paginator.paginate_queryset(qs, request)
    broadcast_ids = [n.id for n in page if n.user_id is None]
    read_ids = _read_broadcast_ids(request.user, broadcast_ids) if broadcast_ids else set()
    serializer = UserNotificationSerializer(
        page,
        many=True,
        context={"request": request, "read_broadcast_ids": read_ids},
    )
    return paginator.get_paginated_response(serializer.data)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def user_notifications_unread_count(request):
    own_unread = UserNotification.objects.filter(
        user=request.user, is_read=False
    ).count()
    # Broadcasts the user hasn't read yet.
    read_ids = _read_broadcast_ids(request.user)
    broadcast_unread = (
        UserNotification.objects.filter(user__isnull=True)
        .exclude(id__in=read_ids)
        .count()
    )
    return Response({"unread": own_unread + broadcast_unread})


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def mark_user_notification_read(request, notification_id):
    notif = (
        UserNotification.objects.filter(id=notification_id)
        .filter(Q(user=request.user) | Q(user__isnull=True))
        .first()
    )
    if notif is None:
        return Response(
            {"detail": "Notification not found."},
            status=status.HTTP_404_NOT_FOUND,
        )
    if notif.user_id is None:
        # Broadcast — record a per-user read receipt (idempotent).
        NotificationRead.objects.get_or_create(notification=notif, user=request.user)
    elif not notif.is_read:
        notif.is_read = True
        notif.save(update_fields=["is_read"])
    return Response({"success": True})


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def mark_all_user_notifications_read(request):
    UserNotification.objects.filter(user=request.user, is_read=False).update(
        is_read=True
    )
    # Record read receipts for every broadcast the user hasn't read yet.
    already = _read_broadcast_ids(request.user)
    unread_broadcasts = (
        UserNotification.objects.filter(user__isnull=True)
        .exclude(id__in=already)
        .values_list("id", flat=True)
    )
    NotificationRead.objects.bulk_create(
        [
            NotificationRead(notification_id=nid, user=request.user)
            for nid in unread_broadcasts
        ],
        ignore_conflicts=True,
    )
    return Response({"success": True})
