"""Server-side event instrumentation.

We attach *extra* receivers to models that already emit signals, so we capture
real engagement without editing a single view. Each receiver only calls the
fire-and-forget ``track()`` helper, which never raises.

Client-only events (app_open, screen_view, dwell time) will arrive later via a
small ``POST /api/engagement/track/`` endpoint the app can call; the backend
signals below already give us solid behavioural signal on their own.
"""

from django.db.models.signals import post_save
from django.dispatch import receiver

from base.models import DiamondTransaction
from business_network.models import (
    BusinessNetworkFollowerModel,
    BusinessNetworkPost,
    BusinessNetworkPostComment,
    BusinessNetworkPostLike,
)

from .services import track


@receiver(post_save, sender=BusinessNetworkPostLike)
def _on_post_like(sender, instance, created, **kwargs):
    if created:
        track(
            user=getattr(instance, "user", None),
            event_type="post_like",
            surface="feed",
            object_type="bn_post",
            object_id=getattr(instance, "post_id", ""),
        )


@receiver(post_save, sender=BusinessNetworkPostComment)
def _on_post_comment(sender, instance, created, **kwargs):
    if created:
        track(
            user=getattr(instance, "author", None),
            event_type="post_comment",
            surface="feed",
            object_type="bn_post",
            object_id=getattr(instance, "post_id", ""),
        )


@receiver(post_save, sender=BusinessNetworkPost)
def _on_post_create(sender, instance, created, **kwargs):
    if created:
        track(
            user=getattr(instance, "author", None),
            event_type="post_create",
            surface="feed",
            object_type="bn_post",
            object_id=getattr(instance, "pk", ""),
        )


@receiver(post_save, sender=BusinessNetworkFollowerModel)
def _on_follow(sender, instance, created, **kwargs):
    if created:
        track(
            user=getattr(instance, "follower", None),
            event_type="follow",
            surface="feed",
            object_type="user",
            object_id=getattr(instance, "following_id", ""),
        )


@receiver(post_save, sender=DiamondTransaction)
def _on_diamond_txn(sender, instance, created, **kwargs):
    if created:
        track(
            user=getattr(instance, "user", None),
            event_type="diamond_txn",
            surface="wallet",
            object_type="diamond",
            object_id=getattr(instance, "pk", ""),
            metadata={"amount": getattr(instance, "amount", None)},
        )
