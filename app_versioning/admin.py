from django.contrib import admin

from .models import AppVersionConfig


@admin.register(AppVersionConfig)
class AppVersionConfigAdmin(admin.ModelAdmin):
    list_display = (
        "platform",
        "latest_version",
        "latest_build",
        "minimum_supported_version",
        "minimum_supported_build",
        "force_update",
        "is_active",
        "updated_at",
    )
    list_filter = ("platform", "force_update", "is_active")
    search_fields = ("latest_version", "minimum_supported_version", "title")
    list_editable = ("force_update", "is_active")
    readonly_fields = ("created_at", "updated_at")
    fieldsets = (
        (
            "Version Gate",
            {
                "fields": (
                    "platform",
                    "latest_version",
                    "latest_build",
                    "minimum_supported_version",
                    "minimum_supported_build",
                    "force_update",
                    "is_active",
                )
            },
        ),
        ("Popup", {"fields": ("title", "message", "store_url", "snooze_hours")}),
        ("Timestamps", {"fields": ("created_at", "updated_at"), "classes": ("collapse",)}),
    )
