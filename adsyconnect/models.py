from datetime import timedelta

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
    
    # Per-user "clear messages": each side may clear independently. A user who
    # cleared no longer sees messages up to their timestamp; the other side
    # keeps seeing everything. Once BOTH sides have cleared, messages older
    # than both timestamps serve no one and are hard-deleted.
    cleared_at_user1 = models.DateTimeField(null=True, blank=True)
    cleared_at_user2 = models.DateTimeField(null=True, blank=True)

    # Per-user archive (hidden from the main list, still receives messages) and
    # mute (no push notifications). Each participant controls their own flag.
    archived_by_user1 = models.BooleanField(default=False)
    archived_by_user2 = models.BooleanField(default=False)
    muted_by_user1 = models.BooleanField(default=False)
    muted_by_user2 = models.BooleanField(default=False)

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

    def _is_user1(self, user):
        return self.user1_id == getattr(user, 'id', user)

    def is_archived_for(self, user):
        return self.archived_by_user1 if self._is_user1(user) else self.archived_by_user2

    def is_muted_for(self, user):
        return self.muted_by_user1 if self._is_user1(user) else self.muted_by_user2

    def set_archived(self, user, value):
        if self._is_user1(user):
            self.archived_by_user1 = value
        else:
            self.archived_by_user2 = value
        self.save(update_fields=['archived_by_user1', 'archived_by_user2'])

    def set_muted(self, user, value):
        if self._is_user1(user):
            self.muted_by_user1 = value
        else:
            self.muted_by_user2 = value
        self.save(update_fields=['muted_by_user1', 'muted_by_user2'])

    def has_spam_from_other(self, user):
        """Whether the OTHER participant has sent this user a spam message.
        Drives the 'Maybe spam' bucket in the chat list."""
        other = self.get_other_user(user)
        if other is None:
            return False
        return self.messages.filter(
            sender=other, is_spam=True, is_deleted=False
        ).exists()


class ChatGroup(models.Model):
    """A named group conversation with any number of members.

    Kept separate from the 1-on-1 ChatRoom/Message pair so the heavily-used
    direct-chat paths stay untouched. The creator starts as admin; admins can
    add/remove members and rename the group; anyone can leave.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=80)
    image = models.ImageField(
        upload_to='adsyconnect/groups/', null=True, blank=True
    )
    creator = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='adsy_groups_created'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_message_at = models.DateTimeField(default=timezone.now)
    last_message_preview = models.TextField(blank=True, null=True)

    class Meta:
        db_table = 'adsyconnect_chat_groups'
        ordering = ['-last_message_at']

    def __str__(self):
        return f'Group: {self.name}'

    def is_member(self, user):
        return self.memberships.filter(user=user).exists()

    def is_admin(self, user):
        return self.memberships.filter(user=user, role='admin').exists()


class ChatGroupMembership(models.Model):
    ROLE_CHOICES = [('admin', 'Admin'), ('member', 'Member')]

    group = models.ForeignKey(
        ChatGroup, on_delete=models.CASCADE, related_name='memberships'
    )
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='adsy_group_memberships'
    )
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='member')
    joined_at = models.DateTimeField(auto_now_add=True)
    # Everything before this stays hidden for the member (like 1:1 clear).
    cleared_at = models.DateTimeField(null=True, blank=True)
    muted = models.BooleanField(default=False)
    # Typing heartbeat: set on every keystroke batch; a member counts as
    # "typing" while this is a few seconds fresh (clients poll it).
    typing_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'adsyconnect_chat_group_memberships'
        unique_together = ['group', 'user']

    def __str__(self):
        return f'{self.user.username} in {self.group.name} ({self.role})'


class GroupMessage(models.Model):
    MESSAGE_TYPES = [
        ('text', 'Text'),
        ('voice', 'Voice'),
        ('image', 'Image'),
        ('video', 'Video'),
        ('document', 'Document'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    group = models.ForeignKey(
        ChatGroup, on_delete=models.CASCADE, related_name='messages'
    )
    sender = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='adsy_group_messages'
    )
    message_type = models.CharField(
        max_length=20, choices=MESSAGE_TYPES, default='text'
    )
    content = models.TextField(blank=True, null=True)
    media_file = models.FileField(
        upload_to='adsyconnect/group_media/%Y/%m/%d/', blank=True, null=True
    )
    file_name = models.CharField(max_length=255, blank=True, null=True)
    voice_duration = models.IntegerField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    is_deleted = models.BooleanField(default=False)

    class Meta:
        db_table = 'adsyconnect_group_messages'
        ordering = ['created_at']
        indexes = [
            # Name must match migration 0009 exactly, or makemigrations keeps
            # detecting a phantom rename.
            models.Index(
                fields=['group', 'created_at'],
                name='adsy_grpmsg_grp_created_idx',
            ),
        ]

    def get_preview(self):
        if self.is_deleted:
            return 'Message deleted'
        if self.message_type == 'voice':
            return '🎤 Voice message'
        if self.message_type == 'image':
            return '📷 Photo'
        if self.message_type == 'video':
            return '🎥 Video'
        if self.message_type == 'document':
            return f'📄 {self.file_name or "Document"}'
        text = self.content or ''
        # A shared post's structured payload must never leak into previews.
        if text.startswith('ADSYPOST'):
            return '📎 পোস্ট'
        return text[:50] + '...' if len(text) > 50 else text


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
    is_edited = models.BooleanField(default=False)
    edited_at = models.DateTimeField(null=True, blank=True)

    # Auto spam classification (keyword-based, set once at send time). Powers
    # the "Maybe spam" chat-list bucket. spam_category is vulgar/gambling/
    # marketing/link when flagged, else empty.
    is_spam = models.BooleanField(default=False)
    spam_category = models.CharField(max_length=20, blank=True, default='')

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
    
    @staticmethod
    def _clean_reply_text(content):
        """Strip the reply header from a reply message before previewing.

        Reply messages embed their context inside the body as
        ``<↩️> (uuid) Sender: quoted preview\\n\\nActual message``. A naive
        ``content[:50]`` preview would leak the raw ``(uuid) Sender:`` header
        into the chat list (it never reaches the actual text). This returns
        only the real reply body so the list shows what the user actually
        typed. Non-reply content is returned untouched.
        """
        if not content:
            return content
        text = content.lstrip()
        # '↩️' is the correct emoji; 'â†©ï¸' is the historical mojibake variant
        # (UTF-8 bytes mis-decoded as Latin-1) that older/app messages stored.
        reply_prefixes = ('↩️', 'â†©ï¸', '↩')
        matched = next((p for p in reply_prefixes if text.startswith(p)), None)
        if not matched:
            return content
        # Preferred path: the real message sits after the blank-line separator.
        if '\n\n' in text:
            body = text.split('\n\n', 1)[1].strip()
            if body:
                return body
        # No separator survived — drop the "(uuid) Sender:" header instead.
        rest = text[len(matched):].strip()
        if rest.startswith('('):
            close = rest.find(')')
            if close != -1:
                rest = rest[close + 1:].strip()
        if ':' in rest:
            rest = rest.split(':', 1)[1].strip()
        return rest or 'Reply'

    def get_preview(self):
        """Get message preview for chat list"""
        if self.is_deleted:
            return "Message deleted"

        if self.message_type == 'text':
            text = self._clean_reply_text(self.content or '')
            return text[:50] + '...' if len(text) > 50 else text
        elif self.message_type == 'image':
            return "📷 Photo"
        elif self.message_type == 'video':
            return "🎥 Video"
        elif self.message_type == 'voice':
            return "🎤 Voice message"
        elif self.message_type == 'document':
            return f"📄 {self.file_name or 'Document'}"
        return "Message"
    
    def get_display_content(self):
        """Get display content for deleted messages"""
        if self.is_deleted:
            return "Message removed"
        return self.content
    
    def get_time_display(self):
        """Get smart time display - hide if within same minute"""
        from django.utils import timezone
        from datetime import timedelta
        
        now = timezone.now()
        diff = now - self.created_at
        
        # If less than 1 minute, don't show time
        if diff < timedelta(minutes=1):
            return None
        
        # If less than 1 hour, show minutes
        if diff < timedelta(hours=1):
            minutes = int(diff.total_seconds() / 60)
            return f"{minutes}m ago"
        
        # If less than 24 hours, show hours
        if diff < timedelta(hours=24):
            hours = int(diff.total_seconds() / 3600)
            return f"{hours}h ago"
        
        # If less than 7 days, show days
        if diff < timedelta(days=7):
            days = diff.days
            return f"{days}d ago"
        
        # Otherwise show date
        return self.created_at.strftime("%b %d")


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

    STALE_AFTER = timedelta(seconds=90)
    
    def __str__(self):
        return f"{self.user.username} - {'Online' if self.is_online else 'Offline'}"

    def is_effectively_online(self):
        if not self.is_online or not self.last_seen:
            return False
        return self.last_seen >= timezone.now() - self.STALE_AFTER

    def set_presence(self, is_online, *, seen_at=None):
        self.is_online = is_online
        self.last_seen = seen_at or timezone.now()
        self.save(update_fields=['is_online', 'last_seen'])
    
    def update_last_seen(self):
        """Update last seen timestamp"""
        self.set_presence(self.is_online, seen_at=timezone.now())


class ActiveChatSession(models.Model):
    """
    Tracks which chat a user is currently viewing.
    Used to prevent push notifications when user is already in the chat.
    """
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='active_chat_session',
        primary_key=True
    )
    chatroom = models.ForeignKey(
        ChatRoom,
        on_delete=models.CASCADE,
        related_name='active_sessions',
        null=True,
        blank=True
    )
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'adsyconnect_active_chat_session'
    
    def __str__(self):
        if self.chatroom:
            return f"{self.user.username} active in chat {self.chatroom.id}"
        return f"{self.user.username} not in any chat"
    
    @classmethod
    def set_active_chat(cls, user, chatroom):
        """Set user's active chat"""
        session, _ = cls.objects.update_or_create(
            user=user,
            defaults={'chatroom': chatroom}
        )
        return session
    
    @classmethod
    def clear_active_chat(cls, user):
        """Clear user's active chat"""
        cls.objects.filter(user=user).update(chatroom=None)
    
    @classmethod
    def is_user_in_chat(cls, user, chatroom):
        """Whether the user is actively viewing this chat.

        We keep a freshness window so a session left stuck by a closed tab,
        backgrounded app or crash (where the client never sent "clear") can't
        suppress push notifications forever. Clients refresh the session while
        the chat stays open (heartbeat); after the window it's treated as left.
        """
        try:
            session = cls.objects.get(user=user)
            if not session.chatroom or session.chatroom_id != chatroom.id:
                return False
            return session.updated_at >= timezone.now() - timedelta(minutes=20)
        except cls.DoesNotExist:
            return False


class CallSession(models.Model):
    """Tracks the lifecycle of a 1-on-1 AdsyConnect Agora call."""

    CALL_TYPES = [
        ('audio', 'Audio'),
        ('video', 'Video'),
    ]

    STATUS_RINGING = 'ringing'
    STATUS_ACCEPTED = 'accepted'
    STATUS_REJECTED = 'rejected'
    STATUS_BUSY = 'busy'
    STATUS_CANCELLED = 'cancelled'
    STATUS_ENDED = 'ended'
    STATUS_MISSED = 'missed'
    STATUS_FAILED = 'failed'

    CALL_STATUSES = [
        (STATUS_RINGING, 'Ringing'),
        (STATUS_ACCEPTED, 'Accepted'),
        (STATUS_REJECTED, 'Rejected'),
        (STATUS_BUSY, 'Busy'),
        (STATUS_CANCELLED, 'Cancelled'),
        (STATUS_ENDED, 'Ended'),
        (STATUS_MISSED, 'Missed'),
        (STATUS_FAILED, 'Failed'),
    ]

    TERMINAL_STATUSES = {
        STATUS_REJECTED,
        STATUS_BUSY,
        STATUS_CANCELLED,
        STATUS_ENDED,
        STATUS_MISSED,
        STATUS_FAILED,
    }

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    channel_name = models.CharField(max_length=80, unique=True)
    caller = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='adsyconnect_outgoing_calls',
    )
    callee = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='adsyconnect_incoming_calls',
    )
    call_type = models.CharField(max_length=10, choices=CALL_TYPES, default='audio')
    status = models.CharField(max_length=20, choices=CALL_STATUSES, default=STATUS_RINGING)
    started_at = models.DateTimeField(auto_now_add=True)
    accepted_at = models.DateTimeField(null=True, blank=True)
    ended_at = models.DateTimeField(null=True, blank=True)
    last_status_at = models.DateTimeField(default=timezone.now)
    duration_seconds = models.PositiveIntegerField(null=True, blank=True)

    class Meta:
        db_table = 'adsyconnect_call_sessions'
        ordering = ['-started_at']
        indexes = [
            models.Index(fields=['caller', '-started_at']),
            models.Index(fields=['callee', '-started_at']),
            models.Index(fields=['status', '-started_at']),
        ]

    def __str__(self):
        return (
            f'{self.caller.username} -> {self.callee.username} '
            f'[{self.call_type}:{self.status}]'
        )

    def update_status(self, status_value, *, at=None):
        timestamp = at or timezone.now()
        update_fields = ['status', 'last_status_at']

        self.status = status_value
        self.last_status_at = timestamp

        if status_value == self.STATUS_ACCEPTED and self.accepted_at is None:
            self.accepted_at = timestamp
            update_fields.append('accepted_at')

        if status_value in self.TERMINAL_STATUSES:
            self.ended_at = timestamp
            if 'ended_at' not in update_fields:
                update_fields.append('ended_at')

        if self.accepted_at and self.ended_at:
            self.duration_seconds = max(
                0,
                int((self.ended_at - self.accepted_at).total_seconds()),
            )
            if 'duration_seconds' not in update_fields:
                update_fields.append('duration_seconds')

        self.save(update_fields=update_fields)
