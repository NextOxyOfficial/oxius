from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    ChatRoom, Message, MessageReport, 
    BlockedUser, TypingStatus, OnlineStatus
)

User = get_user_model()


class UserBasicSerializer(serializers.ModelSerializer):
    """Basic user info for chat"""
    avatar = serializers.SerializerMethodField()
    is_online = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'avatar', 
                  'is_online', 'profession', 'is_verified']
    
    def get_avatar(self, obj):
        if hasattr(obj, 'profile') and obj.profile.profile_picture:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.profile.profile_picture.url)
        return None
    
    def get_is_online(self, obj):
        try:
            return obj.online_status.is_online
        except:
            return False


class MessageSerializer(serializers.ModelSerializer):
    """Message serializer"""
    sender = UserBasicSerializer(read_only=True)
    receiver = UserBasicSerializer(read_only=True)
    media_url = serializers.SerializerMethodField()
    thumbnail_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Message
        fields = [
            'id', 'chatroom', 'sender', 'receiver', 'message_type', 
            'content', 'media_url', 'thumbnail_url', 'file_name', 
            'file_size', 'voice_duration', 'is_read', 'read_at', 
            'is_deleted', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'sender', 'receiver', 'created_at', 
                           'updated_at', 'read_at']
    
    def get_media_url(self, obj):
        if obj.media_file:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.media_file.url)
        return None
    
    def get_thumbnail_url(self, obj):
        if obj.media_thumbnail:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.media_thumbnail.url)
        return None


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
        
        # Validate based on message type
        if message_type == 'text' and not content:
            raise serializers.ValidationError("Text messages must have content")
        
        if message_type in ['image', 'video', 'document', 'voice'] and not media_file:
            raise serializers.ValidationError(f"{message_type} messages must have a media file")
        
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
    
    class Meta:
        model = ChatRoom
        fields = [
            'id', 'other_user', 'last_message_at', 'last_message_preview',
            'unread_count', 'last_message', 'is_blocked', 'blocked_by',
            'created_at', 'updated_at'
        ]
    
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
        last_msg = obj.messages.filter(is_deleted=False).order_by('-created_at').first()
        if last_msg:
            return {
                'id': str(last_msg.id),
                'content': last_msg.get_preview(),
                'message_type': last_msg.message_type,
                'created_at': last_msg.created_at,
                'is_me': last_msg.sender == self.context.get('request').user
            }
        return None


class MessageReportSerializer(serializers.ModelSerializer):
    """Message report serializer"""
    reporter = UserBasicSerializer(read_only=True)
    reported_user = UserBasicSerializer(read_only=True)
    
    class Meta:
        model = MessageReport
        fields = [
            'id', 'reporter', 'reported_user', 'message', 'reason',
            'description', 'status', 'created_at'
        ]
        read_only_fields = ['id', 'reporter', 'status', 'created_at']
    
    def create(self, validated_data):
        validated_data['reporter'] = self.context['request'].user
        return super().create(validated_data)


class BlockedUserSerializer(serializers.ModelSerializer):
    """Blocked user serializer"""
    blocker = UserBasicSerializer(read_only=True)
    blocked = UserBasicSerializer(read_only=True)
    
    class Meta:
        model = BlockedUser
        fields = ['id', 'blocker', 'blocked', 'reason', 'created_at']
        read_only_fields = ['id', 'blocker', 'created_at']
    
    def create(self, validated_data):
        validated_data['blocker'] = self.context['request'].user
        return super().create(validated_data)


class OnlineStatusSerializer(serializers.ModelSerializer):
    """Online status serializer"""
    user = UserBasicSerializer(read_only=True)
    
    class Meta:
        model = OnlineStatus
        fields = ['user', 'is_online', 'last_seen']
        read_only_fields = ['user', 'last_seen']


class TypingStatusSerializer(serializers.ModelSerializer):
    """Typing status serializer"""
    user = UserBasicSerializer(read_only=True)
    
    class Meta:
        model = TypingStatus
        fields = ['id', 'chatroom', 'user', 'is_typing', 'updated_at']
        read_only_fields = ['id', 'user', 'updated_at']
