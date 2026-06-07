"""Helper to send a push notification AND persist it as a UserNotification.

Use this anywhere you want to notify users about something they can later find
in the app's "Updates" tab. Pass a `deep_link` (an in-app path such as
"/business-network/posts/123" or "/eshop") to make the notification tappable —
the app navigates there on tap, and shows a "Visit" button on the saved update.
"""
from django.db.models import Q

from .models import FCMToken, User, UserNotification


def _stringify(data):
    """FCM data payloads must be string -> string."""
    return {str(k): "" if v is None else str(v) for k, v in (data or {}).items()}


def send_push_notification(
    *,
    title,
    body="",
    deep_link="",
    image="",
    notification_type="general",
    data=None,
    users=None,
    broadcast=False,
):
    """Persist + push a notification.

    - users: iterable of User to target. Each gets their own saved + delivered
      notification.
    - broadcast=True: store a single broadcast row (user=None) visible to
      everyone in the Updates tab, and fan the push out to all active devices.

    Returns the list of created UserNotification objects.
    """
    from .fcm_service import send_fcm_notification_multicast

    base_data = dict(data or {})
    if deep_link:
        base_data["deep_link"] = deep_link
    base_data["notification_type"] = notification_type

    created = []

    def _deliver(notification, token_qs):
        payload = dict(base_data)
        payload["notification_id"] = str(notification.id)
        tokens = list(token_qs.values_list("token", flat=True))
        if tokens:
            try:
                send_fcm_notification_multicast(
                    tokens, title, body, _stringify(payload)
                )
            except Exception as e:  # never let a push failure break the caller
                print(f"[push] FCM send failed: {e}")

    if broadcast:
        notification = UserNotification.objects.create(
            user=None,
            title=title,
            body=body,
            deep_link=deep_link,
            image=image,
            notification_type=notification_type,
            data=base_data,
        )
        created.append(notification)
        _deliver(notification, FCMToken.objects.filter(is_active=True))
        return created

    for user in users or []:
        notification = UserNotification.objects.create(
            user=user,
            title=title,
            body=body,
            deep_link=deep_link,
            image=image,
            notification_type=notification_type,
            data=base_data,
        )
        created.append(notification)
        _deliver(notification, FCMToken.objects.filter(user=user, is_active=True))

    return created
