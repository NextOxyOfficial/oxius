"""Count/flag annotations for feed querysets.

The feed used to `prefetch_related("post_likes__user")` and then answer
like_count with `len(cache)` and is_liked with a scan over that cache. That
means every like row on every post in the page — plus a User row per like — was
pulled into memory to produce one integer and one boolean. A post with 20k likes
dragged 20k rows and 20k users into a request that only needed "20000" and
"True", and it got worse as posts aged and accumulated likes.

These annotations answer the same two questions in the database. Counts are
correlated subqueries rather than `Count()` over a join on purpose: several
joined Counts in one queryset multiply each other's rows (the classic Django
fan-out), which is both wrong without `distinct=True` and slow with it. A
subquery per relation stays an index lookup on the relation's post_id.

The serializer prefers these when present and still falls back to the prefetch
cache and then to COUNT, so callers that don't annotate keep working unchanged.
"""

from django.db.models import (
    BooleanField,
    Count,
    Exists,
    IntegerField,
    OuterRef,
    Subquery,
    Value,
)
from django.db.models.functions import Coalesce


def _count_subquery(model, fk_name="post"):
    """COUNT(*) of [model] rows pointing at the outer post, as a scalar."""
    return Coalesce(
        Subquery(
            model.objects.filter(**{fk_name: OuterRef("pk")})
            .order_by()
            .values(fk_name)
            .annotate(c=Count("id"))
            .values("c")[:1],
            output_field=IntegerField(),
        ),
        Value(0),
        output_field=IntegerField(),
    )


def feed_count_annotations(user=None):
    """Annotations every feed queryset should carry.

    Returns like/comment/follower counts and, for a signed-in viewer, whether
    they liked each post — none of which require loading the rows themselves.
    """
    from .models import (
        BusinessNetworkPostComment,
        BusinessNetworkPostFollow,
        BusinessNetworkPostLike,
    )

    from .models import BusinessNetworkPost

    annotations = {
        "like_count_db": _count_subquery(BusinessNetworkPostLike),
        "comment_count_db": _count_subquery(BusinessNetworkPostComment),
        "follower_count_db": _count_subquery(BusinessNetworkPostFollow),
        # Reshares point at the original through shared_from, so the same
        # subquery shape works — and without it get_share_count fell through to
        # obj.reshares.count(), one COUNT per post on every feed page.
        "reshare_count_db": _count_subquery(
            BusinessNetworkPost, fk_name="shared_from"),
    }

    if user is not None and getattr(user, "is_authenticated", False):
        annotations["is_liked_db"] = Exists(
            BusinessNetworkPostLike.objects.filter(
                post=OuterRef("pk"), user=user
            )
        )
    else:
        annotations["is_liked_db"] = Value(False, output_field=BooleanField())

    return annotations
