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
    
    class Meta:
        model = SupportTicket
        fields = ['id', 'user', 'title', 'message', 'status', 'created_at', 'updated_at', 'replies', 'reply_count']
        read_only_fields = ['id', 'user', 'created_at', 'updated_at']
    
    def get_reply_count(self, obj):
        return obj.replies.count()

class SupportTicketCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = SupportTicket
        fields = ['title', 'message']

class TicketReplyCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = TicketReply
        fields = ['message']
