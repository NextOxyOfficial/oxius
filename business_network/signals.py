from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.db.models import F
from django.db.models.functions import Greatest
from django.utils import timezone
from .models import (
    BusinessNetworkFollowerModel,
    BusinessNetworkPostLike,
    BusinessNetworkPostComment,
    BusinessNetworkMindforceComment,
    BusinessNetworkMediaLike,
    BusinessNetworkMediaComment,
    BusinessNetworkNotification,
    BusinessNetworkPost,
    UserSavedPosts,
)
from base.fcm_service import send_fcm_notification_async
from base.models import FCMToken


# ---------------------------------------------------------------------------
# Denormalized feed counters
# ---------------------------------------------------------------------------
# Keep BusinessNetworkPost.{like_count, comment_count, save_count, last_activity_at}
# in sync with their source rows. We use atomic F() .update() so concurrent
# likes/comments can't lose increments, and .update() (not .save()) so we don't
# re-trigger the post's slug/id logic. Greatest(..., 0) floors decrements at 0.

def _bump_post_counter(post_id, field, delta, touch_activity):
    if not post_id:
        return
    updates = {}
    if delta > 0:
        updates[field] = F(field) + delta
    else:
        updates[field] = Greatest(F(field) + delta, 0)
    if touch_activity:
        updates["last_activity_at"] = timezone.now()
    BusinessNetworkPost.objects.filter(pk=post_id).update(**updates)


@receiver(post_save, sender=BusinessNetworkPostLike)
def increment_post_like_count(sender, instance, created, **kwargs):
    if created:
        _bump_post_counter(instance.post_id, "like_count", 1, touch_activity=True)


@receiver(post_delete, sender=BusinessNetworkPostLike)
def decrement_post_like_count(sender, instance, **kwargs):
    _bump_post_counter(instance.post_id, "like_count", -1, touch_activity=False)


@receiver(post_save, sender=BusinessNetworkPostComment)
def increment_post_comment_count(sender, instance, created, **kwargs):
    if created:
        _bump_post_counter(instance.post_id, "comment_count", 1, touch_activity=True)


@receiver(post_delete, sender=BusinessNetworkPostComment)
def decrement_post_comment_count(sender, instance, **kwargs):
    _bump_post_counter(instance.post_id, "comment_count", -1, touch_activity=False)


@receiver(post_save, sender=UserSavedPosts)
def increment_post_save_count(sender, instance, created, **kwargs):
    if created:
        _bump_post_counter(instance.post_id, "save_count", 1, touch_activity=True)


@receiver(post_delete, sender=UserSavedPosts)
def decrement_post_save_count(sender, instance, **kwargs):
    _bump_post_counter(instance.post_id, "save_count", -1, touch_activity=False)

@receiver(post_save, sender=BusinessNetworkFollowerModel)
def create_follow_notification(sender, instance, created, **kwargs):
    """Create notification when a user follows another user"""
    if created:
        BusinessNetworkNotification.objects.create(
            recipient=instance.following,
            actor=instance.follower,
            type='follow',
            read=False
        )
        
        # Send FCM push notification
        tokens = FCMToken.objects.filter(user=instance.following, is_active=True)
        for token in tokens:
            send_fcm_notification_async(
                fcm_token=token.token,
                title='New Follower',
                body=f'{instance.follower.get_full_name() or instance.follower.email} started following you',
                data={
                    'type': 'follow',
                    'user_id': str(instance.follower.id),
                    'click_action': 'FLUTTER_NOTIFICATION_CLICK'
                }
            )


@receiver(post_save, sender=BusinessNetworkPostLike)
def create_post_like_notification(sender, instance, created, **kwargs):
    """Create notification when a user likes a post"""
    if created and instance.post.author != instance.user:
        # Use title if available, otherwise use content or default message
        content = instance.post.title[:100] if instance.post.title else (
            instance.post.content[:100] if instance.post.content else "Liked your post"
        )
        
        BusinessNetworkNotification.objects.create(
            recipient=instance.post.author,
            actor=instance.user,
            type='like_post',
            target_id=instance.post.id,
            read=False,
            content=content
        )
        
        # Send FCM push notification
        tokens = FCMToken.objects.filter(user=instance.post.author, is_active=True)
        for token in tokens:
            send_fcm_notification_async(
                fcm_token=token.token,
                title='Post Liked',
                body=f'{instance.user.get_full_name() or instance.user.email} liked your post',
                data={
                    'type': 'like_post',
                    'post_id': str(instance.post.id),
                    'user_id': str(instance.user.id),
                    'click_action': 'FLUTTER_NOTIFICATION_CLICK'
                }
            )


@receiver(post_save, sender=BusinessNetworkPostComment)
def create_post_comment_notification(sender, instance, created, **kwargs):
    """Create notification when a user comments on a post"""
    if created and instance.post.author != instance.author:
        BusinessNetworkNotification.objects.create(
            recipient=instance.post.author,
            actor=instance.author,
            type='comment',
            target_id=instance.post.id,
            parent_id=instance.post.id,
            read=False,
            content=instance.content[:100]
        )
        
        # Send FCM push notification
        tokens = FCMToken.objects.filter(user=instance.post.author, is_active=True)
        comment_preview = instance.content[:50] + '...' if len(instance.content) > 50 else instance.content
        for token in tokens:
            send_fcm_notification_async(
                fcm_token=token.token,
                title='New Comment',
                body=f'{instance.author.get_full_name() or instance.author.email}: {comment_preview}',
                data={
                    'type': 'comment',
                    'post_id': str(instance.post.id),
                    'comment_id': str(instance.id),
                    'user_id': str(instance.author.id),
                    'click_action': 'FLUTTER_NOTIFICATION_CLICK'
                }
            )


@receiver(post_save, sender=BusinessNetworkMediaLike)
def create_media_like_notification(sender, instance, created, **kwargs):
    """Create notification when a user likes a media"""
    # Find the post that contains this media
    posts = instance.media.business_network_posts.all()
    
    # If this media is part of posts, notify each post author
    for post in posts:
        if created and post.author != instance.user:
            BusinessNetworkNotification.objects.create(
                recipient=post.author,
                actor=instance.user,
                type='like_post',
                target_id=post.id,
                read=False,
                content="Liked media in your post"
            )


@receiver(post_save, sender=BusinessNetworkMediaComment)
def create_media_comment_notification(sender, instance, created, **kwargs):
    """Create notification when a user comments on media"""
    # Find posts containing this media
    posts = instance.media.business_network_posts.all()
    
    # If this media is part of posts, notify each post author
    for post in posts:
        if created and post.author != instance.author:
            BusinessNetworkNotification.objects.create(
                recipient=post.author,
                actor=instance.author,
                type='comment',
                target_id=post.id,
                read=False,
                content=instance.content[:100]
            )


@receiver(post_save, sender=BusinessNetworkMindforceComment)
def create_mindforce_comment_notification(sender, instance, created, **kwargs):
    """Create notification when a user comments on a mindforce problem"""
    # Notify the problem creator about the new comment
    if created and instance.mindforce_problem.user != instance.author:
        BusinessNetworkNotification.objects.create(
            recipient=instance.mindforce_problem.user,
            actor=instance.author,
            type='comment',
            target_id=instance.mindforce_problem.id,
            read=False,
            content=instance.content[:100]
        )
    
    # If comment is marked as a solution, create a solution notification
    if instance.is_solved and instance.mindforce_problem.user != instance.author:
        BusinessNetworkNotification.objects.create(
            recipient=instance.author,
            actor=instance.mindforce_problem.user,
            type='solution',
            target_id=instance.mindforce_problem.id,
            read=False,
            content=f"Marked your advice as a solution to '{instance.mindforce_problem.title}'"
        )