import logging

logger = logging.getLogger(__name__)


def track(
    user=None,
    event_type="",
    *,
    surface="",
    object_type="",
    object_id="",
    session_id="",
    metadata=None,
):
    """Record a behavioural event. Fire-and-forget: this MUST never raise, so a
    failure here can never break the user-facing request that triggered it.

    Args:
        user: a User instance (or None for anonymous/device events).
        event_type: short snake_case verb, e.g. "post_like", "product_view".
        surface: which super-app area, e.g. "feed", "eshop", "rideshare".
        object_type / object_id: optional target of the action.
        metadata: optional JSON-serializable dict of extra context.
    """
    try:
        if not event_type:
            return None
        # Local import keeps this module import-safe during app loading.
        from .models import UserEvent

        resolved_user = user if getattr(user, "is_authenticated", False) else None
        return UserEvent.objects.create(
            user=resolved_user,
            event_type=event_type[:64],
            surface=(surface or "")[:32],
            object_type=(object_type or "")[:64],
            object_id=str(object_id or "")[:64],
            session_id=(session_id or "")[:64],
            metadata=metadata or {},
        )
    except Exception:  # pragma: no cover - defensive, never propagate
        logger.exception("engagement.track failed for event_type=%s", event_type)
        return None
