from celery import shared_task
from django.utils import timezone

from .models import CallSession


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
