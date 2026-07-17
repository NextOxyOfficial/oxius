from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.db.models import Q
from .models import (
    ChatRoom, Message, MessageReport,
    BlockedUser, TypingStatus, OnlineStatus,
    ChatGroup, ChatGroupMembership, GroupMessage,
)

User = get_user_model()


class UserBasicSerializer(serializers.ModelSerializer):
    """Basic user info for chat"""
    avatar = serializers.SerializerMethodField()
    is_online = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'avatar', 
                  'is_online', 'profession', 'is_pro', 'kyc']
    
    def get_avatar(self, obj):
        if hasattr(obj, 'image') and obj.image:
            request = self.context.get('request')
            if request:
                url = request.build_absolute_uri(obj.image.url)
                # Ensure HTTPS in production
                if url.startswith('http://') and not request.get_host().startswith('127.0.0.1') and not request.get_host().startswith('localhost'):
                    url = url.replace('http://', 'https://', 1)
                return url
            return obj.image.url
        return None
    
    def get_is_online(self, obj):
        try:
            return obj.online_status.is_effectively_online()
        except Exception:
            return False


class MessageSerializer(serializers.ModelSerializer):
    """Message serializer"""
    sender = UserBasicSerializer(read_only=True)
    receiver = UserBasicSerializer(read_only=True)
    media_url = serializers.SerializerMethodField()
    thumbnail_url = serializers.SerializerMethodField()
    display_content = serializers.SerializerMethodField()
    time_display = serializers.SerializerMethodField()
    
    class Meta:
        model = Message
        fields = [
            'id', 'chatroom', 'sender', 'receiver', 'message_type', 
            'content', 'display_content', 'media_url', 'thumbnail_url', 
            'file_name', 'file_size', 'voice_duration', 'is_read', 'read_at', 
            'is_deleted', 'is_edited', 'edited_at', 'created_at', 'updated_at', 'time_display'
        ]
        read_only_fields = ['id', 'sender', 'receiver', 'created_at', 
                           'updated_at', 'read_at', 'is_edited', 'edited_at']
    
    def get_media_url(self, obj):
        if obj.media_file:
            request = self.context.get('request')
            if request:
                url = request.build_absolute_uri(obj.media_file.url)
                # Ensure HTTPS in production
                if url.startswith('http://') and not request.get_host().startswith('127.0.0.1') and not request.get_host().startswith('localhost'):
                    url = url.replace('http://', 'https://', 1)
                return url
        return None
    
    def get_thumbnail_url(self, obj):
        if obj.media_thumbnail:
            request = self.context.get('request')
            if request:
                url = request.build_absolute_uri(obj.media_thumbnail.url)
                # Ensure HTTPS in production
                if url.startswith('http://') and not request.get_host().startswith('127.0.0.1') and not request.get_host().startswith('localhost'):
                    url = url.replace('http://', 'https://', 1)
                return url
        return None
    
    def get_display_content(self, obj):
        """Return 'Message removed' for deleted messages"""
        return obj.get_display_content()
    
    def get_time_display(self, obj):
        """Return smart time display or None if within same minute"""
        return obj.get_time_display()


class MessageCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating messages"""
    
    class Meta:
        model = Message
        fields = [
            'chatroom', 'receiver', 'message_type', 'content', 
            'media_file', 'file_name', 'voice_duration'
        ]
    
    def validate(self, data):
        message_type = data.get('message_type')
        content = data.get('content')
        media_file = data.get('media_file')
        request = self.context.get('request')
        sender = getattr(request, 'user', None)
        receiver = data.get('receiver')
        chatroom = data.get('chatroom')
        
        # Validate based on message type
        if message_type == 'text' and not content:
            raise serializers.ValidationError("Text messages must have content")
        
        if message_type in ['image', 'video', 'document', 'voice'] and not media_file:
            raise serializers.ValidationError(f"{message_type} messages must have a media file")

        if sender and receiver and chatroom:
            is_chat_blocked = bool(chatroom.is_blocked)
            is_user_blocked = BlockedUser.objects.filter(
                Q(blocker=sender, blocked=receiver) |
                Q(blocker=receiver, blocked=sender)
            ).exists()
            if is_chat_blocked or is_user_blocked:
                raise serializers.ValidationError(
                    "Messaging is disabled because one of the users has blocked this conversation."
                )
        
        return data
    
    def create(self, validated_data):
        # Set sender from request user
        validated_data['sender'] = self.context['request'].user
        return super().create(validated_data)


class ChatRoomSerializer(serializers.ModelSerializer):
    """ChatRoom serializer with user details"""
    other_user = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    blocked_by_me = serializers.SerializerMethodField()
    is_archived = serializers.SerializerMethodField()
    is_muted = serializers.SerializerMethodField()
    # Chat-list tab classification.
    i_follow_them = serializers.SerializerMethodField()
    they_follow_me = serializers.SerializerMethodField()
    is_mutual = serializers.SerializerMethodField()
    is_spam = serializers.SerializerMethodField()

    class Meta:
        model = ChatRoom
        fields = [
            'id', 'other_user', 'last_message_at', 'last_message_preview',
            'unread_count', 'last_message', 'is_blocked', 'blocked_by',
            'blocked_by_me', 'is_archived', 'is_muted',
            'i_follow_them', 'they_follow_me', 'is_mutual', 'is_spam',
            'created_at', 'updated_at'
        ]

    def get_is_archived(self, obj):
        user = getattr(self.context.get('request'), 'user', None)
        return obj.is_archived_for(user) if user else False

    def get_is_muted(self, obj):
        user = getattr(self.context.get('request'), 'user', None)
        return obj.is_muted_for(user) if user else False

    def _follow_sets(self):
        """(i_follow ids, they_follow ids) for the current user, computed once
        per request and shared across every room in the list (avoids N+1)."""
        request = self.context.get('request')
        user = getattr(request, 'user', None)
        if not user or not getattr(user, 'is_authenticated', False):
            return set(), set()
        cache = getattr(request, '_adsy_follow_sets', None)
        if cache is not None:
            return cache
        from business_network.models import BusinessNetworkFollowerModel as F_

        i_follow = set(
            F_.objects.filter(follower=user).values_list('following_id', flat=True)
        )
        follow_me = set(
            F_.objects.filter(following=user).values_list('follower_id', flat=True)
        )
        cache = (i_follow, follow_me)
        request._adsy_follow_sets = cache
        return cache

    def _other_id(self, obj):
        user = getattr(self.context.get('request'), 'user', None)
        if not user:
            return None
        return obj.user2_id if obj.user1_id == user.id else obj.user1_id

    def get_i_follow_them(self, obj):
        other = self._other_id(obj)
        return other in self._follow_sets()[0] if other else False

    def get_they_follow_me(self, obj):
        other = self._other_id(obj)
        return other in self._follow_sets()[1] if other else False

    def get_is_mutual(self, obj):
        return self.get_i_follow_them(obj) and self.get_they_follow_me(obj)

    def get_is_spam(self, obj):
        user = getattr(self.context.get('request'), 'user', None)
        return obj.has_spam_from_other(user) if user else False

    def get_blocked_by_me(self, obj):
        """True if the current user is the one who blocked this conversation.

        The frontend uses this to decide whether to show the 'Unblock' action:
        only the user who placed the block can lift it. Computed from the
        canonical BlockedUser table so it stays correct regardless of which
        surface (chat or business-network profile) created the block.
        """
        request = self.context.get('request')
        user = getattr(request, 'user', None)
        if user and user.is_authenticated:
            other_user = obj.get_other_user(user)
            if other_user:
                return BlockedUser.objects.filter(
                    blocker=user, blocked=other_user
                ).exists()
        return False
    
    def get_other_user(self, obj):
        request = self.context.get('request')
        if request and request.user:
            other_user = obj.get_other_user(request.user)
            return UserBasicSerializer(other_user, context=self.context).data
        return None
    
    def get_unread_count(self, obj):
        request = self.context.get('request')
        if request and request.user:
            return obj.get_unread_count(request.user)
        return 0
    
    def get_last_message(self, obj):
        # Include deleted messages so frontend can show "Message removed"
        last_msg = obj.messages.order_by('-created_at').first()

        # Respect a per-user clear: the participant who cleared must not see a
        # pre-clear message resurface as the chat-list preview.
        request = self.context.get('request')
        user = getattr(request, 'user', None)
        if last_msg is not None and user is not None:
            cleared_at = (
                obj.cleared_at_user1 if user == obj.user1
                else obj.cleared_at_user2 if user == obj.user2
                else None
            )
            if cleared_at is not None and last_msg.created_at <= cleared_at:
                return None

        if last_msg:
            return {
                'id': str(last_msg.id),
                'content': last_msg.get_preview(),
                'message_type': last_msg.message_type,
                'created_at': last_msg.created_at,
                'is_me': last_msg.sender == self.context.get('request').user,
                'is_deleted': last_msg.is_deleted  # Include deleted status
            }
        return None


class MessageReportSerializer(serializers.ModelSerializer):
    """Message report serializer"""
    reporter = UserBasicSerializer(read_only=True)
    reported_user = serializers.PrimaryKeyRelatedField(queryset=User.objects.all())
    reported_user_info = UserBasicSerializer(source='reported_user', read_only=True)
    
    class Meta:
        model = MessageReport
        fields = [
            'id', 'reporter', 'reported_user', 'message', 'reason',
            'reported_user_info', 'description', 'status', 'created_at'
        ]
        read_only_fields = ['id', 'reporter', 'status', 'created_at']
    
    def create(self, validated_data):
        validated_data['reporter'] = self.context['request'].user
        return super().create(validated_data)


class BlockedUserSerializer(serializers.ModelSerializer):
    """Blocked user serializer"""
    blocker = UserBasicSerializer(read_only=True)
    blocked = serializers.PrimaryKeyRelatedField(queryset=User.objects.all())
    blocked_info = UserBasicSerializer(source='blocked', read_only=True)
    
    class Meta:
        model = BlockedUser
        fields = ['id', 'blocker', 'blocked', 'blocked_info', 'reason', 'created_at']
        read_only_fields = ['id', 'blocker', 'created_at']
    
    def create(self, validated_data):
        validated_data['blocker'] = self.context['request'].user
        return super().create(validated_data)


class OnlineStatusSerializer(serializers.ModelSerializer):
    """Online status serializer"""
    user = UserBasicSerializer(read_only=True)
    user_id = serializers.CharField(read_only=True)
    is_online = serializers.SerializerMethodField()
    
    class Meta:
        model = OnlineStatus
        fields = ['user', 'user_id', 'is_online', 'last_seen']
        read_only_fields = ['user', 'last_seen']

    def get_is_online(self, obj):
        return obj.is_effectively_online()


class TypingStatusSerializer(serializers.ModelSerializer):
    """Typing status serializer"""
    user = UserBasicSerializer(read_only=True)
    
    class Meta:
        model = TypingStatus
        fields = ['id', 'chatroom', 'user', 'is_typing', 'updated_at']
        read_only_fields = ['id', 'user', 'updated_at']


class GroupMemberSerializer(serializers.ModelSerializer):
    """A group member with their role."""
    user = UserBasicSerializer(read_only=True)

    class Meta:
        model = ChatGroupMembership
        fields = ['user', 'role', 'joined_at']


class GroupMessageSerializer(serializers.ModelSerializer):
    sender = UserBasicSerializer(read_only=True)
    media_url = serializers.SerializerMethodField()

    class Meta:
        model = GroupMessage
        fields = [
            'id', 'group', 'sender', 'message_type', 'content', 'media_url',
            'voice_duration', 'created_at', 'is_deleted',
        ]
        read_only_fields = ['id', 'sender', 'created_at', 'is_deleted']

    def get_media_url(self, obj):
        if not obj.media_file:
            return None
        request = self.context.get('request')
        url = obj.media_file.url
        if request:
            url = request.build_absolute_uri(url)
            if url.startswith('http://') and 'localhost' not in url and '127.0.0.1' not in url:
                url = url.replace('http://', 'https://', 1)
        return url


class ChatGroupSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()
    member_count = serializers.SerializerMethodField()
    my_role = serializers.SerializerMethodField()
    members = GroupMemberSerializer(source='memberships', many=True, read_only=True)

    class Meta:
        model = ChatGroup
        fields = [
            'id', 'name', 'image_url', 'creator', 'member_count', 'my_role',
            'members', 'last_message_at', 'last_message_preview', 'created_at',
        ]
        read_only_fields = fields

    def get_image_url(self, obj):
        if not obj.image:
            return None
        request = self.context.get('request')
        url = obj.image.url
        if request:
            url = request.build_absolute_uri(url)
            if url.startswith('http://') and 'localhost' not in url and '127.0.0.1' not in url:
                url = url.replace('http://', 'https://', 1)
        return url

    def get_member_count(self, obj):
        return obj.memberships.count()

    def get_my_role(self, obj):
        user = getattr(self.context.get('request'), 'user', None)
        if not user or not getattr(user, 'is_authenticated', False):
            return None
        m = obj.memberships.filter(user=user).first()
        return m.role if m else None
