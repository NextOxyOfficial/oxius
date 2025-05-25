from rest_framework import serializers
from .models import SupportTicket, TicketReply
from django.contrib.auth import get_user_model

User = get_user_model()

class UserMinimalSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'image']

class TicketReplySerializer(serializers.ModelSerializer):
    user = UserMinimalSerializer(read_only=True)
    
    class Meta:
        model = TicketReply
        fields = ['id', 'user', 'message', 'is_from_admin', 'created_at']
        read_only_fields = ['id', 'user', 'is_from_admin', 'created_at']

class SupportTicketSerializer(serializers.ModelSerializer):
    user = UserMinimalSerializer(read_only=True)
    replies = TicketReplySerializer(many=True, read_only=True)
    reply_count = serializers.SerializerMethodField()
    last_read_at = serializers.SerializerMethodField()
    is_unread = serializers.SerializerMethodField()  # Use is_unread instead of has_unread for better clarity
    
    class Meta:
        model = SupportTicket
        fields = ['id', 'user', 'title', 'message', 'status', 'created_at', 'updated_at', 
                 'replies', 'reply_count', 'last_read_at', 'is_unread']
        read_only_fields = ['id', 'user', 'created_at', 'updated_at']
    
    def get_reply_count(self, obj):
        return obj.replies.count()
    
    def get_last_read_at(self, obj):
        user = self.context['request'].user
        try:
            read_status = obj.read_statuses.get(user=user)
            return read_status.last_read_at
        except:
            return None
    
    def get_is_unread(self, obj):
        user = self.context['request'].user
        try:
            read_status = obj.read_statuses.get(user=user)
            # Check if there are replies after the last read time
            # This will show as "unread" if there are any replies after the last read time
            return obj.replies.filter(created_at__gt=read_status.last_read_at).exists()
        except:
            # If no read status exists, all messages are unread
            return obj.replies.exists()

class SupportTicketCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = SupportTicket
        fields = ['title', 'message']

class TicketReplyCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = TicketReply
        fields = ['message']
