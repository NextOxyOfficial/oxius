from rest_framework import serializers

from .models import OutreachDraft, AllianceDonation


class OutreachDraftSerializer(serializers.ModelSerializer):
    class Meta:
        model = OutreachDraft
        fields = [
            "id", "language", "category", "company", "to_name", "to_email", "subject",
            "body_html", "notes", "status", "scheduled_for", "sent_at",
            "error", "created_at", "updated_at",
        ]
        # status/sent_at/etc. change only through the send/skip actions, never
        # via a plain edit — so the founder can freely edit subject/body/email.
        read_only_fields = [
            "id", "status", "scheduled_for", "sent_at", "error",
            "created_at", "updated_at",
        ]


class AllianceDonationSerializer(serializers.ModelSerializer):
    class Meta:
        model = AllianceDonation
        fields = [
            "id", "order_id", "amount", "donor_name", "donor_email",
            "donor_phone", "message", "status", "created_at", "completed_at",
        ]
        read_only_fields = fields
