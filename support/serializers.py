import html
import re

from rest_framework import serializers
from django.utils.html import strip_tags
from .models import SupportTicket, TicketReply, PublicContact
from django.contrib.auth import get_user_model

User = get_user_model()


def _plain_text(value):
    """Render rich/HTML ticket text as clean plain text.

    Some tickets were written through rich-text inputs and stored with markup
    ("<p>...</p>"), which then leaked literally into the app and web UIs.
    Strip tags + unescape entities on the way out (covers old rows too) and
    on the way in for new submissions.
    """
    if not value:
        return value
    text = strip_tags(str(value))
    text = html.unescape(text)
    return re.sub(r"\n{3,}", "\n\n", text).strip()


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

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data["message"] = _plain_text(data.get("message"))
        return data


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

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data["title"] = _plain_text(data.get("title"))
        data["message"] = _plain_text(data.get("message"))
        return data

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

    def validate_title(self, value):
        return _plain_text(value)

    def validate_message(self, value):
        return _plain_text(value)


class TicketReplyCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = TicketReply
        fields = ["message"]

    def validate_message(self, value):
        return _plain_text(value)


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
