from django.conf import settings
from django.db import models


class UserEvent(models.Model):
    """Append-only behavioural event log — the raw "senses" of the assistant
    brain. Writes go through ``engagement.services.track()`` which never raises,
    so logging an event can never break the request that produced it.

    Keep this table lean and let a periodic job (Phase B) roll it up into
    ``UserState``. Old rows can be pruned/aggregated after ~90 days.
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.CASCADE,
        related_name="engagement_events",
    )
    event_type = models.CharField(max_length=64)
    # Which part of the super-app: feed, eshop, rideshare, chat, gigs, ...
    surface = models.CharField(max_length=32, blank=True, default="")
    # Optional target of the action (e.g. object_type="product", object_id="123").
    object_type = models.CharField(max_length=64, blank=True, default="")
    object_id = models.CharField(max_length=64, blank=True, default="")
    metadata = models.JSONField(default=dict, blank=True)
    session_id = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=["user", "-created_at"], name="eng_event_user_recent_idx"),
            models.Index(fields=["event_type", "-created_at"], name="eng_event_type_recent_idx"),
        ]

    def __str__(self):
        who = self.user_id or "anon"
        return f"{self.event_type} by {who} @ {self.created_at:%Y-%m-%d %H:%M}"


class UserState(models.Model):
    """Per-user rolled-up profile the brain reads cheaply. One row per user,
    refreshed by ``engagement.tasks.aggregate_user_states`` (Phase B)."""

    STAGE_NEW = "new"
    STAGE_ONBOARDING = "onboarding"
    STAGE_ACTIVATED = "activated"
    STAGE_HABITUAL = "habitual"
    STAGE_AT_RISK = "at_risk"
    STAGE_DORMANT = "dormant"
    STAGE_RESURRECTED = "resurrected"
    STAGE_CHURNED = "churned"
    LIFECYCLE_CHOICES = [
        (STAGE_NEW, "New"),
        (STAGE_ONBOARDING, "Onboarding"),
        (STAGE_ACTIVATED, "Activated"),
        (STAGE_HABITUAL, "Habitual"),
        (STAGE_AT_RISK, "At risk"),
        (STAGE_DORMANT, "Dormant"),
        (STAGE_RESURRECTED, "Resurrected"),
        (STAGE_CHURNED, "Churned"),
    ]

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="engagement_state",
        primary_key=True,
    )

    # Activity
    last_active_at = models.DateTimeField(null=True, blank=True)
    active_days_7d = models.PositiveIntegerField(default=0)
    active_days_30d = models.PositiveIntegerField(default=0)
    events_7d = models.PositiveIntegerField(default=0)
    events_30d = models.PositiveIntegerField(default=0)
    active_days_streak = models.PositiveIntegerField(default=0)
    longest_streak = models.PositiveIntegerField(default=0)

    # Lifecycle / value
    lifecycle_stage = models.CharField(
        max_length=20, choices=LIFECYCLE_CHOICES, default=STAGE_NEW
    )
    churn_risk = models.FloatField(default=0.0)  # 0..1 heuristic
    value_tier = models.CharField(max_length=20, default="explorer")

    # Interests / habits (derived)
    top_interests = models.JSONField(default=list, blank=True)
    top_surfaces = models.JSONField(default=dict, blank=True)
    preferred_hours = models.JSONField(default=list, blank=True)

    # Denormalized snapshot used to build nudges/assistant briefings (Phase C/E):
    # cart left, expiring subscription, pending KYC, withdrawable balance, etc.
    pending = models.JSONField(default=dict, blank=True)

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=["lifecycle_stage"], name="eng_state_stage_idx"),
            models.Index(fields=["-last_active_at"], name="eng_state_active_idx"),
        ]

    def __str__(self):
        return f"{self.user_id} [{self.lifecycle_stage}]"
