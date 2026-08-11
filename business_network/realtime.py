# -*- coding: utf-8 -*-
"""Business Network over the websocket.

The Business Network had no realtime path at all — not one channel-layer call
in the whole app. Notifications went out as FCM push, which is right for a
phone in a pocket and useless for the person looking at the screen: the bell's
count only moved on a reload, and a comment on the post you were reading
appeared when you pulled to refresh.

Two audiences, so two kinds of broadcast:

* the person a thing happened TO — their own `user_<id>` group, the same one
  AdsyConnect's chat already uses, so no new socket and no new plumbing on the
  client;
* everyone looking at a particular post — a `post_<id>` group they join while
  that post is on screen and leave when it is not.

Every function here is best-effort. A feed that cannot reach Redis must still
serve the request; a missing live update is a cosmetic loss, a 500 is not.
"""
import logging

logger = logging.getLogger(__name__)


def _layer():
    """The channel layer, or None when there isn't one configured."""
    try:
        from channels.layers import get_channel_layer
        return get_channel_layer()
    except Exception:
        return None


def _send(group_name, payload):
    layer = _layer()
    if layer is None:
        return False
    try:
        from asgiref.sync import async_to_sync
        async_to_sync(layer.group_send)(group_name, payload)
        return True
    except Exception:
        # Signals run inside the request that caused them. Whatever went wrong
        # with Redis, the like still happened.
        logger.warning('realtime send to %s failed', group_name, exc_info=True)
        return False


def post_group(post_id):
    """Channel group for everyone with this post on screen."""
    return 'post_%s' % str(post_id).replace('-', '')


def user_group(user_id):
    return 'user_%s' % user_id


def notification_payload(notification, *, unread_count=None):
    """What the bell needs to render a new row without fetching anything."""
    actor = notification.actor
    avatar = ''
    try:
        if getattr(actor, 'image', None):
            avatar = actor.image.url
    except Exception:
        avatar = ''

    name = ''
    try:
        name = (actor.get_full_name() or '').strip()
    except Exception:
        name = ''
    if not name:
        name = getattr(actor, 'first_name', '') or getattr(actor, 'email', '')

    payload = {
        'type': 'bn_notification',
        'notification': {
            'id': str(notification.id),
            # Same vocabulary as the FCM `type` the app already routes on
            # (follow / like_post / comment / ...), so tapping a live row and
            # tapping a pushed one land in the same place.
            'notification_type': notification.type,
            'actor_id': str(actor.id),
            'actor_name': name,
            'actor_avatar': avatar,
            'target_id': notification.target_id or '',
            'parent_id': notification.parent_id or '',
            'content': notification.content or '',
            'read': bool(notification.read),
            'created_at': notification.created_at.isoformat()
            if notification.created_at else None,
        },
    }
    if unread_count is not None:
        payload['unread_count'] = unread_count
    return payload


def broadcast_notification(notification):
    """Push a notification to its recipient's socket."""
    from .models import BusinessNetworkNotification

    try:
        unread_count = BusinessNetworkNotification.objects.filter(
            recipient_id=notification.recipient_id, read=False
        ).count()
    except Exception:
        unread_count = None

    return _send(
        user_group(notification.recipient_id),
        {
            'type': 'bn_notification_event',
            'payload': notification_payload(
                notification, unread_count=unread_count),
        },
    )


def broadcast_post_activity(post_id, activity):
    """Tell everyone reading this post that something changed on it.

    [activity] is a dict describing what happened — a comment arriving, a like
    count moving. Deliberately small: the client already has the post, so this
    is a nudge with the delta, not a re-send of the whole thing.
    """
    return _send(
        post_group(post_id),
        {
            'type': 'bn_post_activity_event',
            'payload': dict(activity, type='bn_post_activity',
                            post_id=str(post_id)),
        },
    )
