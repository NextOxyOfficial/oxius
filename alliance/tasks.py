"""Send Alliance outreach emails — directly, using the SMTP settings configured
in Django admin (base.EmailSettings). No Celery worker / server-side queue is
required: sends run in a background daemon thread inside the Django process, so
this works the same locally and in production.

Sends are deliberately *staggered* (a slow, randomized trickle) rather than a
burst — this protects sender reputation. The founder hits "Send" on /alliance;
each draft goes out a bit later than the last."""

import logging
import random
import threading
import time
from datetime import timedelta

from django.db import close_old_connections
from django.utils import timezone

logger = logging.getLogger(__name__)

# Default spacing between sends (seconds). ~2.5 min + up to 1 min jitter => a
# slow, human-like trickle. Tune via dispatch_outreach() args.
DEFAULT_SPACING = 150
DEFAULT_JITTER = 60


def send_draft_now(draft_id):
    """Send a single outreach draft right now via the Django-admin SMTP settings.
    Handles the status transitions (sending -> sent/failed). Returns a result dict."""
    from .models import OutreachDraft
    from .emails import send_outreach

    draft = OutreachDraft.objects.filter(id=draft_id).first()
    if not draft:
        return {"skipped": "missing"}
    if draft.status in ("sent", "skipped", "sending"):
        return {"skipped": draft.status}

    draft.status = "sending"
    draft.save(update_fields=["status", "updated_at"])
    try:
        send_outreach(draft)
        draft.status = "sent"
        draft.sent_at = timezone.now()
        draft.error = ""
        draft.save(update_fields=["status", "sent_at", "error", "updated_at"])
        logger.info("Alliance: sent draft %s -> %s", draft_id, draft.to_email)
        return {"sent": str(draft.id)}
    except Exception as exc:
        logger.exception("Alliance send failed for draft %s", draft_id)
        draft.status = "failed"
        draft.error = str(exc)[:500]
        draft.save(update_fields=["status", "error", "updated_at"])
        return {"failed": str(exc)[:200]}


def _run_staggered(plan):
    """Background worker: send each draft after its gap. `plan` is a list of
    (draft_id, gap_seconds_before_this_send)."""
    for draft_id, gap in plan:
        if gap > 0:
            time.sleep(gap)
        close_old_connections()  # drop any connection that went stale while sleeping
        try:
            send_draft_now(draft_id)
        except Exception:  # never let one failure kill the whole run
            logger.exception("Alliance staggered send crashed on %s", draft_id)
    close_old_connections()


def dispatch_outreach(draft_ids, *, spacing=DEFAULT_SPACING, jitter=DEFAULT_JITTER):
    """Schedule the given drafts to send, staggered. Returns how many were queued.

    Only drafts in a sendable state (draft/approved/failed/scheduled) are queued;
    already sent/sending/skipped ones are left alone. Sending happens in a daemon
    thread so the HTTP request returns immediately."""
    from .models import OutreachDraft

    now = timezone.now()
    delay = 0
    prev_delay = 0
    plan = []  # (draft_id, gap_before_this_send)
    sendable = {"draft", "approved", "failed", "scheduled"}
    for did in draft_ids:
        draft = OutreachDraft.objects.filter(id=did).first()
        if not draft or draft.status not in sendable:
            continue
        draft.status = "scheduled"
        draft.scheduled_for = now + timedelta(seconds=delay)
        draft.error = ""
        draft.save(update_fields=["status", "scheduled_for", "error", "updated_at"])
        plan.append((str(draft.id), delay - prev_delay))
        prev_delay = delay
        delay += spacing + random.randint(0, jitter)

    if plan:
        threading.Thread(target=_run_staggered, args=(plan,), daemon=True).start()
    logger.info("Alliance dispatch: queued %s drafts (staggered)", len(plan))
    return len(plan)
