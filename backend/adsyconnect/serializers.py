from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import ChatRoom, Message, MessageReport, OnlineStatus, TypingStatus, BlockedUser

User = get_user_model()


class UserBasicSerializer(serializers.ModelSerializer):
    """Basic user information for chat"""
    avatar = serializers.SerializerMethodField()
    is_online = serializers.SerializerMethodField()
    profession = serializers.CharField(read_only=True)
    
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'avatar', 'is_online', 'profession']
    
    def get_avatar(self, obj):
        """Get user avatar/profile picture"""
        if hasattr(obj, 'image') and obj.image:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.image.url)
            return obj.image.url if hasattr(obj.image, 'url') else str(obj.image)
        return None
    
    def get_is_online(self, obj):
        """Check if user is online"""
        try:
            return obj.online_status.is_online
        except:
            return False


class MessageSerializer(serializers.ModelSerializer):
    """Serializer for chat messages"""
    sender_info = UserBasicSerializer(source='sender', read_only=True)
    receiver_info = UserBasicSerializer(source='receiver', read_only=True)
    
    class Meta:
        model = Message
        fields = [
            'id', 'chatroom', 'sender', 'receiver', 'message_type',
            'content', 'media_file', 'voice_duration', 'is_read',
            'created_at', 'sender_info', 'receiver_info'
        ]
        read_only_fields = ['sender', 'created_at']


class ChatRoomSerializer(serializers.ModelSerializer):
    """Serializer for chat rooms"""
    other_user = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.IntegerField(read_only=True, default=0)
    
    class Meta:
        model = ChatRoom
        fields = [
            'id', 'user1', 'user2', 'other_user', 'last_message',
            'last_message_at', 'last_message_preview', 'unread_count', 'created_at'
        ]
        read_only_fields = ['created_at', 'last_message_at', 'last_message_preview']
    
    def get_other_user(self, obj):
        """Get the other user in the chat room"""
        request = self.context.get('request')
        if not request:
            return None
        
        other_user = obj.user2 if obj.user1 == request.user else obj.user1
        return UserBasicSerializer(other_user).data
    
    def get_last_message(self, obj):
        """Get the last message in the chat room"""
        last_msg = obj.messages.order_by('-created_at').first()
        if last_msg:
            return {
                'id': last_msg.id,
                'content': last_msg.get_preview(),
                'message_type': last_msg.message_type,
                'created_at': last_msg.created_at,
                'sender_id': last_msg.sender.id,
            }
        return None


class MessageReportSerializer(serializers.ModelSerializer):
    """Serializer for message reports"""
    reporter_info = UserBasicSerializer(source='reporter', read_only=True)
    reported_user_info = UserBasicSerializer(source='reported_user', read_only=True)
    
    class Meta:
        model = MessageReport
        fields = [
            'id', 'reporter', 'reported_user', 'message', 'report_type',
            'description', 'created_at', 'reporter_info', 'reported_user_info'
        ]
        read_only_fields = ['reporter', 'created_at']


class OnlineStatusSerializer(serializers.ModelSerializer):
    """Serializer for online status"""
    user_info = UserBasicSerializer(source='user', read_only=True)
    
    class Meta:
        model = OnlineStatus
        fields = ['id', 'user', 'is_online', 'last_seen', 'user_info']
        read_only_fields = ['last_seen']


class TypingStatusSerializer(serializers.ModelSerializer):
    """Serializer for typing status"""
    user_info = UserBasicSerializer(source='user', read_only=True)
    
    class Meta:
        model = TypingStatus
        fields = ['id', 'chatroom', 'user', 'is_typing', 'updated_at', 'user_info']
        read_only_fields = ['updated_at']


class BlockedUserSerializer(serializers.ModelSerializer):
    """Serializer for blocked users"""
    blocker_info = UserBasicSerializer(source='blocker', read_only=True)
    blocked_info = UserBasicSerializer(source='blocked', read_only=True)
    
    class Meta:
        model = BlockedUser
        fields = ['id', 'blocker', 'blocked', 'created_at', 'blocker_info', 'blocked_info']
        read_only_fields = ['created_at']
