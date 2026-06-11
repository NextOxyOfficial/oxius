from django.contrib import admin

from .forms import ZonalOfficeAdminForm
from .models import ZonalOffice, ZoneFeatureCommission


class ZoneFeatureCommissionInline(admin.TabularInline):
    """Set per-feature commission % for the zone right on the office page."""
    model = ZoneFeatureCommission
    extra = 0
    max_num = len(ZoneFeatureCommission.FEATURES)


@admin.register(ZonalOffice)
class ZonalOfficeAdmin(admin.ModelAdmin):
    form = ZonalOfficeAdminForm
    fields = ("user", "name", "division", "city", "is_active")
    list_display = ("name", "city", "officer_email", "is_active", "created_at")
    list_filter = ("is_active", "city")
    search_fields = ("name", "city", "user__email", "user__name")
    # Search-as-you-type by email/name — no raw UUID entry needed.
    autocomplete_fields = ("user",)
    inlines = [ZoneFeatureCommissionInline]

    @admin.display(description="Officer")
    def officer_email(self, obj):
        return getattr(obj.user, "email", "")
