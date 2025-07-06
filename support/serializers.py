from rest_framework import serializers
from .models import SupportTicket, TicketReply, PublicContact
from django.contrib.auth import get_user_model

User = get_user_model()


class UserMinimalSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "username", "email", "image"]


class TicketReplySerializer(serializers.ModelSerializer):
    user = UserMinimalSerializer(read_only=True)

    class Meta:
        model = TicketReply
        fields = ["id", "user", "message", "is_from_admin", "created_at"]
        read_only_fields = ["id", "user", "is_from_admin", "created_at"]


class SupportTicketSerializer(serializers.ModelSerializer):
    user = UserMinimalSerializer(read_only=True)
    replies = TicketReplySerializer(many=True, read_only=True)
    reply_count = serializers.SerializerMethodField()
    last_read_at = serializers.SerializerMethodField()
    is_unread = (
        serializers.SerializerMethodField()
    )  # Use is_unread instead of has_unread for better clarity

    class Meta:
        model = SupportTicket
        fields = [
            "id",
            "user",
            "title",
            "message",
            "status",
            "created_at",
            "updated_at",
            "replies",
            "reply_count",
            "last_read_at",
            "is_unread",
        ]
        read_only_fields = ["id", "user", "created_at", "updated_at"]

    def get_reply_count(self, obj):
        return obj.replies.count()

    def get_last_read_at(self, obj):
        user = self.context["request"].user
        try:
            read_status = obj.read_statuses.get(user=user)
            return read_status.last_read_at
        except Exception:
            return None

    def get_is_unread(self, obj):
        user = self.context["request"].user
        try:
            read_status = obj.read_statuses.get(user=user)

            # Get the most recent activity time (either ticket creation or latest reply)
            latest_reply = obj.replies.order_by("-created_at").first()
            if latest_reply:
                latest_activity_time = latest_reply.created_at
            else:
                latest_activity_time = obj.created_at

            # The ticket is unread if the latest activity happened after the last read time
            return latest_activity_time > read_status.last_read_at

        except Exception:
            # If no read status exists, the ticket is unread
            return True


class SupportTicketCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = SupportTicket
        fields = ["title", "message"]


class TicketReplyCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = TicketReply
        fields = ["message"]


class PublicContactSerializer(serializers.ModelSerializer):
    class Meta:
        model = PublicContact
        fields = ["name", "email", "phone", "message"]

    def create(self, validated_data):
        return PublicContact.objects.create(**validated_data)


class PublicContactListSerializer(serializers.ModelSerializer):
    """Serializer for admin to view all public contacts"""

    responded_by = serializers.StringRelatedField(read_only=True)

    class Meta:
        model = PublicContact
        fields = [
            "id",
            "name",
            "email",
            "phone",
            "message",
            "status",
            "admin_notes",
            "responded_by",
            "responded_at",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]
