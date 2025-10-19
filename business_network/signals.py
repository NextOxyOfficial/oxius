from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from .models import (
    BusinessNetworkFollowerModel, 
    BusinessNetworkPostLike, 
    BusinessNetworkPostComment,
    BusinessNetworkMindforceComment,
    BusinessNetworkMediaLike,
    BusinessNetworkMediaComment,
    BusinessNetworkNotification
)

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