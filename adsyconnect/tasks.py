import logging

from celery import shared_task
from django.utils import timezone

from .models import CallSession

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=1, default_retry_delay=10)
def send_group_push_notification(
    self, group_id, sender_id, sender_name, message_preview
):
    """Push a group message to every member except the sender, skipping
    members who muted the group. Runs off the request thread — a group can
    have many members and each FCM send is a network round-trip.

    Payload type is 'group_message' (NOT 'message') so the app routes the tap
    to the AdsyConnect list instead of trying to open a 1:1 room by group id.
    """
    from base.fcm_service import send_fcm_notification
    from base.models import FCMToken
    from .models import ChatGroup

    try:
        group = ChatGroup.objects.filter(id=group_id).first()
        if group is None:
            return {'skipped': 'missing_group'}

        recipient_ids = list(
            group.memberships.filter(muted=False)
            .exclude(user_id=sender_id)
            .values_list('user_id', flat=True)
        )
        if not recipient_ids:
            return {'skipped': 'no_recipients'}

        tokens = FCMToken.objects.filter(
            user_id__in=recipient_ids, is_active=True
        ).values_list('token', flat=True)

        body = f'{sender_name}: {message_preview}'
        if len(body) > 110:
            body = body[:110] + '…'
        sent = 0
        for token in tokens:
            if str(token or '').startswith('voip:'):
                continue
            ok = send_fcm_notification(
                fcm_token=token,
                title=group.name,
                body=body,
                data={
                    'type': 'group_message',
                    'group_id': str(group.id),
                    'group_name': group.name,
                    'sender_id': str(sender_id),
                    'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                },
            )
            if ok:
                sent += 1
        return {'sent': sent}
    except Exception as exc:
        logger.warning('send_group_push_notification failed: %s', exc)
        try:
            raise self.retry(exc=exc)
        except self.MaxRetriesExceededError:
            return {'error': str(exc)}


@shared_task(bind=True, max_retries=2, default_retry_delay=10)
def send_chat_push_notification(
    self, receiver_id, sender_id, sender_name, message_preview, chatroom_id
):
    """Send the "new message" push to the receiver, off the request thread.

    Each FCM send is a blocking network round-trip; doing this inline in
    POST /messages/ made sending slow and intermittently blew past the
    client's HTTP timeout (even though the message was already saved). Running
    it here keeps message send fast and makes delivery retryable.

    Re-checks the receiver's active chat at delivery time so we don't ping
    someone who is already looking at the conversation.
    """
    from django.contrib.auth import get_user_model
    from base.fcm_service import send_message_notification
    from .models import ChatRoom, ActiveChatSession

    User = get_user_model()
    try:
        receiver = User.objects.filter(id=receiver_id).first()
        sender = User.objects.filter(id=sender_id).first()
        if not receiver or not sender:
            return {'skipped': 'missing_user'}

        chatroom = ChatRoom.objects.filter(id=chatroom_id).first()
        if chatroom and ActiveChatSession.is_user_in_chat(receiver, chatroom):
            return {'skipped': 'receiver_in_chat'}
        # Defence in depth: never push for a conversation the receiver muted,
        # even if the enqueue-time check was somehow bypassed.
        if chatroom and chatroom.is_muted_for(receiver):
            return {'skipped': 'muted'}

        send_message_notification(
            recipient_user=receiver,
            sender_user=sender,
            sender_name=sender_name,
            message_text=message_preview,
            chat_id=str(chatroom_id),
        )
        return {'sent': True}
    except Exception as exc:
        logger.warning('send_chat_push_notification failed: %s', exc)
        try:
            raise self.retry(exc=exc)
        except self.MaxRetriesExceededError:
            return {'error': str(exc)}


@shared_task
def cleanup_stale_call_sessions():
    """Move stale call sessions out of active states.

    Media connection happens on the client through Agora, but this watchdog
    prevents old ringing/joining sessions from keeping both clients in a
    confusing active-call state after network, push, or app lifecycle failures.
    """

    now = timezone.now()
    ringing_cutoff = now - timezone.timedelta(seconds=90)
    accepted_cutoff = now - timezone.timedelta(hours=8)

    missed_count = 0
    ended_count = 0

    for call in CallSession.objects.filter(
        status=CallSession.STATUS_RINGING,
        last_status_at__lt=ringing_cutoff,
    ):
        call.update_status(CallSession.STATUS_MISSED, at=now)
        missed_count += 1

    for call in CallSession.objects.filter(
        status=CallSession.STATUS_ACCEPTED,
        last_status_at__lt=accepted_cutoff,
    ):
        call.update_status(CallSession.STATUS_ENDED, at=now)
        ended_count += 1

    return {
        'missed': missed_count,
        'ended': ended_count,
    }
