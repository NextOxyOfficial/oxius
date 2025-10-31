from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.utils import timezone
from .models import Message, ChatRoom, OnlineStatus


@receiver(post_save, sender=Message)
def update_chatroom_on_message(sender, instance, created, **kwargs):
    """
    Update chatroom's last message timestamp and preview when a new message is created
    """
    if created and not instance.is_deleted:
        chatroom = instance.chatroom
        chatroom.last_message_at = instance.created_at
        chatroom.last_message_preview = instance.get_preview()
        chatroom.save(update_fields=['last_message_at', 'last_message_preview', 'updated_at'])


@receiver(pre_save, sender=Message)
def handle_message_deletion(sender, instance, **kwargs):
    """
    Update chatroom preview when message is deleted
    """
    if instance.pk:  # Only for existing messages
        try:
            old_instance = Message.objects.get(pk=instance.pk)
            # If message is being deleted
            if not old_instance.is_deleted and instance.is_deleted:
                # Update chatroom's last message preview
                chatroom = instance.chatroom
                last_message = chatroom.messages.filter(
                    is_deleted=False
                ).exclude(pk=instance.pk).order_by('-created_at').first()
                
                if last_message:
                    chatroom.last_message_preview = last_message.get_preview()
                    chatroom.save(update_fields=['last_message_preview'])
        except Message.DoesNotExist:
            pass


@receiver(post_save, sender='auth.User')
def create_online_status(sender, instance, created, **kwargs):
    """
    Create online status for new users
    """
    if created:
        OnlineStatus.objects.get_or_create(user=instance)
