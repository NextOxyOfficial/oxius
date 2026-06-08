import logging

from celery import shared_task
from django.utils import timezone

from .models import CallSession

logger = logging.getLogger(__name__)


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
