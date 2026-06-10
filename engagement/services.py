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


def _norm_area(value):
    """Lowercase + trimmed key for case-insensitive area matching."""
    return (value or "").strip().lower()


def build_area_service_index():
    """One grouped query → nested counts of live 'Amar Sheba' service posts by
    area and category. Returned dict is consumed by aggregate_user_states so we
    don't run a query per user.

    Shape:
        {
          "upazila": { "<norm upazila>": [("Electrician", 4), ("Plumber", 10)] },
          "city":    { "<norm city>":    [...] },
          "state":   { "<norm state>":   [...] },
        }
    Each category list is sorted by count desc.
    """
    from collections import defaultdict
    from django.db.models import Count
    from base.models import ClassifiedCategoryPost

    levels = {
        "upazila": defaultdict(lambda: defaultdict(int)),
        "city": defaultdict(lambda: defaultdict(int)),
        "state": defaultdict(lambda: defaultdict(int)),
    }
    rows = (
        ClassifiedCategoryPost.objects.filter(
            service_status="approved", active_service=True
        )
        .values("state", "city", "upazila", "category__title")
        .annotate(n=Count("id"))
    )
    for row in rows.iterator(chunk_size=1000):
        cat = (row.get("category__title") or "").strip()
        if not cat:
            continue
        n = row["n"]
        for level in ("upazila", "city", "state"):
            key = _norm_area(row.get(level))
            if key:
                levels[level][key][cat] += n

    result = {"upazila": {}, "city": {}, "state": {}}
    for level, areas in levels.items():
        for key, cats in areas.items():
            result[level][key] = sorted(
                cats.items(), key=lambda kv: kv[1], reverse=True
            )
    return result


def resolve_user_area(user):
    """Best (label, level, key) for a user: profile address first, then the
    last location they searched services with. Most granular wins."""
    candidates = [
        ("upazila", getattr(user, "upazila", "")),
        ("city", getattr(user, "city", "")),
        ("state", getattr(user, "state", "")),
        ("upazila", getattr(user, "last_search_upazila", "")),
        ("city", getattr(user, "last_search_city", "")),
        ("state", getattr(user, "last_search_state", "")),
    ]
    for level, value in candidates:
        label = (value or "").strip()
        if label:
            return label, level, _norm_area(label)
    return None, None, None
