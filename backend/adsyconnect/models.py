from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
import uuid

User = get_user_model()


class ChatRoom(models.Model):
    """
    Represents a chat room between two users
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user1 = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='chatrooms_as_user1'
    )
    user2 = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='chatrooms_as_user2'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Track last message for sorting
    last_message_at = models.DateTimeField(default=timezone.now)
    last_message_preview = models.TextField(blank=True, null=True)
    
    # Block status
    is_blocked = models.BooleanField(default=False)
    blocked_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='blocked_chatrooms'
    )
    blocked_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'adsyconnect_chatrooms'
        ordering = ['-last_message_at']
        unique_together = ['user1', 'user2']
        indexes = [
            models.Index(fields=['user1', 'user2']),
            models.Index(fields=['-last_message_at']),
        ]
    
    def __str__(self):
        return f"Chat: {self.user1.username} <-> {self.user2.username}"
    
    def get_other_user(self, current_user):
        """Get the other user in the chat"""
        return self.user2 if self.user1 == current_user else self.user1
    
    def get_unread_count(self, user):
        """Get unread message count for a specific user"""
        return self.messages.filter(
            is_read=False
        ).exclude(sender=user).count()


class Message(models.Model):
    """
    Represents a message in a chat room
    """
    MESSAGE_TYPES = [
        ('text', 'Text'),
        ('image', 'Image'),
        ('video', 'Video'),
        ('document', 'Document'),
        ('voice', 'Voice'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    chatroom = models.ForeignKey(
        ChatRoom,
        on_delete=models.CASCADE,
        related_name='messages'
    )
    sender = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='sent_messages'
    )
    receiver = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='received_messages'
    )
    
    # Message content
    message_type = models.CharField(max_length=20, choices=MESSAGE_TYPES, default='text')
    content = models.TextField(blank=True, null=True)  # For text messages
    
    # Media fields
    media_file = models.FileField(upload_to='adsyconnect/media/%Y/%m/%d/', blank=True, null=True)
    media_thumbnail = models.ImageField(upload_to='adsyconnect/thumbnails/%Y/%m/%d/', blank=True, null=True)
    file_name = models.CharField(max_length=255, blank=True, null=True)
    file_size = models.BigIntegerField(blank=True, null=True)  # in bytes
    
    # Voice message specific
    voice_duration = models.IntegerField(blank=True, null=True)  # in seconds
    
    # Status
    is_read = models.BooleanField(default=False)
    read_at = models.DateTimeField(null=True, blank=True)
    is_deleted = models.BooleanField(default=False)
    deleted_at = models.DateTimeField(null=True, blank=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'adsyconnect_messages'
        ordering = ['created_at']
        indexes = [
            models.Index(fields=['chatroom', 'created_at']),
            models.Index(fields=['sender', 'created_at']),
            models.Index(fields=['is_read']),
        ]
    
    def __str__(self):
        return f"{self.sender.username} -> {self.receiver.username}: {self.message_type}"
    
    def mark_as_read(self):
        """Mark message as read"""
        if not self.is_read:
            self.is_read = True
            self.read_at = timezone.now()
            self.save(update_fields=['is_read', 'read_at'])
    
    def soft_delete(self):
        """Soft delete message"""
        self.is_deleted = True
        self.deleted_at = timezone.now()
        self.save(update_fields=['is_deleted', 'deleted_at'])
    
    def get_preview(self):
        """Get message preview for chat list"""
        if self.is_deleted:
            return "Message deleted"
        
        if self.message_type == 'text':
            return self.content[:50] + '...' if len(self.content) > 50 else self.content
        elif self.message_type == 'image':
            return "📷 Photo"
        elif self.message_type == 'video':
            return "🎥 Video"
        elif self.message_type == 'voice':
            return "🎤 Voice message"
        elif self.message_type == 'document':
            return f"📄 {self.file_name or 'Document'}"
        return "Message"


class MessageReport(models.Model):
    """
    Represents a report on a message or user
    """
    REPORT_REASONS = [
        ('spam', 'Spam'),
        ('harassment', 'Harassment'),
        ('inappropriate', 'Inappropriate Content'),
        ('scam', 'Scam or Fraud'),
        ('hate_speech', 'Hate Speech'),
        ('violence', 'Violence or Threats'),
        ('other', 'Other'),
    ]
    
    REPORT_STATUS = [
        ('pending', 'Pending'),
        ('reviewed', 'Reviewed'),
        ('resolved', 'Resolved'),
        ('dismissed', 'Dismissed'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    reporter = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='message_reports_made'
    )
    reported_user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='message_reports_received'
    )
    message = models.ForeignKey(
        Message,
        on_delete=models.CASCADE,
        related_name='reports',
        null=True,
        blank=True
    )
    
    reason = models.CharField(max_length=20, choices=REPORT_REASONS)
    description = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=REPORT_STATUS, default='pending')
    
    # Admin review
    reviewed_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviewed_reports'
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)
    admin_notes = models.TextField(blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'adsyconnect_message_reports'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['reporter', 'created_at']),
            models.Index(fields=['reported_user', 'created_at']),
            models.Index(fields=['status']),
        ]
    
    def __str__(self):
        return f"Report by {self.reporter.username} against {self.reported_user.username}"


class BlockedUser(models.Model):
    """
    Represents a blocked user relationship
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    blocker = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='blocked_users'
    )
    blocked = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='blocked_by_users'
    )
    reason = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'adsyconnect_blocked_users'
        unique_together = ['blocker', 'blocked']
        indexes = [
            models.Index(fields=['blocker', 'blocked']),
        ]
    
    def __str__(self):
        return f"{self.blocker.username} blocked {self.blocked.username}"


class TypingStatus(models.Model):
    """
    Represents real-time typing status (for WebSocket)
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    chatroom = models.ForeignKey(
        ChatRoom,
        on_delete=models.CASCADE,
        related_name='typing_statuses'
    )
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='typing_statuses'
    )
    is_typing = models.BooleanField(default=False)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'adsyconnect_typing_status'
        unique_together = ['chatroom', 'user']
    
    def __str__(self):
        return f"{self.user.username} typing in {self.chatroom.id}"


class OnlineStatus(models.Model):
    """
    Represents user online status
    """
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='online_status',
        primary_key=True
    )
    is_online = models.BooleanField(default=False)
    last_seen = models.DateTimeField(default=timezone.now)
    
    class Meta:
        db_table = 'adsyconnect_online_status'
    
    def __str__(self):
        return f"{self.user.username} - {'Online' if self.is_online else 'Offline'}"
    
    def update_last_seen(self):
        """Update last seen timestamp"""
        self.last_seen = timezone.now()
        self.save(update_fields=['last_seen'])
