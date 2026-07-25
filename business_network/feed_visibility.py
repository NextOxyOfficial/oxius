"""Single source of truth for "which posts may this viewer see".

The main feed builds this inline (views.py), but the optimized/lightweight
and prioritized feeds were querying BusinessNetworkPost.objects with no
visibility or ban filter at all — and two of them are reachable anonymously.
There happen to be no private/followers posts in the database today, so it was
latent rather than actively leaking, but the first private post a user writes
would have been served to the public. Everything now goes through here.
"""
from django.db.models import Q


def visible_posts_q(user):
    """Q() limiting posts to what `user` (may be anonymous) is allowed to see."""
    authed = user is not None and getattr(user, "is_authenticated", False)
    if not authed:
        return Q(visibility="public")

    followed_ids = []
    try:
        from .models import BusinessNetworkFollowerModel as BusinessNetworkFollower

        followed_ids = list(
            BusinessNetworkFollower.objects
            .filter(follower=user)
            .values_list("following_id", flat=True)
        )
    except Exception:
        followed_ids = []

    return (
        Q(visibility="public")
        | Q(author=user)
        | Q(visibility="followers", author_id__in=followed_ids)
    )
