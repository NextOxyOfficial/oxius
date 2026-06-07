from django.contrib import admin

from .models import NudgeLog, UserEvent, UserState


@admin.register(UserEvent)
class UserEventAdmin(admin.ModelAdmin):
    list_display = ("created_at", "event_type", "surface", "user", "object_type", "object_id")
    list_filter = ("event_type", "surface", "created_at")
    search_fields = ("user__email", "event_type", "object_id")
    date_hierarchy = "created_at"
    readonly_fields = (
        "user", "event_type", "surface", "object_type", "object_id",
        "metadata", "session_id", "created_at",
    )

    def has_add_permission(self, request):
        return False  # events are written by track(), never by hand


@admin.register(UserState)
class UserStateAdmin(admin.ModelAdmin):
    list_display = (
        "user", "lifecycle_stage", "value_tier", "last_active_at",
        "active_days_streak", "events_7d", "churn_risk", "updated_at",
    )
    list_filter = ("lifecycle_stage", "value_tier")
    search_fields = ("user__email",)
    readonly_fields = ("updated_at",)


@admin.register(NudgeLog)
class NudgeLogAdmin(admin.ModelAdmin):
    list_display = ("sent_at", "nudge_key", "channel", "user", "opened_at", "converted_at")
    list_filter = ("nudge_key", "channel", "sent_at")
    search_fields = ("user__email", "nudge_key")
    date_hierarchy = "sent_at"
    readonly_fields = ("sent_at",)

    def has_add_permission(self, request):
        return False
