from django.contrib import admin

from .forms import ZonalOfficeAdminForm
from .models import ZonalOffice, ZoneFeatureCommission


class ZoneFeatureCommissionInline(admin.TabularInline):
    """Fixed list: every feature is always a row — pick % or flat ৳ + value.

    Rows are auto-created per office (see ZonalOfficeAdmin._ensure_rows), so
    there is no Add/Delete; value 0 simply means no commission.
    """
    model = ZoneFeatureCommission
    fields = ("feature_label", "commission_type", "value")
    readonly_fields = ("feature_label",)
    extra = 0
    can_delete = False

    def has_add_permission(self, request, obj=None):
        return False

    @admin.display(description="Feature")
    def feature_label(self, obj):
        return obj.get_feature_display() if obj and obj.pk else ""


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

    # ---- keep one commission row per feature, always ----
    def _ensure_rows(self, office):
        if not office or not office.pk:
            return
        existing = set(office.commissions.values_list("feature", flat=True))
        missing = [
            ZoneFeatureCommission(office=office, feature=f)
            for f, _ in ZoneFeatureCommission.FEATURES
            if f not in existing
        ]
        if missing:
            ZoneFeatureCommission.objects.bulk_create(missing)

    def save_related(self, request, form, formsets, change):
        super().save_related(request, form, formsets, change)
        # New office: create the full feature list right away.
        self._ensure_rows(form.instance)

    def change_view(self, request, object_id, form_url="", extra_context=None):
        try:
            self._ensure_rows(self.get_object(request, object_id))
        except Exception:
            pass
        return super().change_view(request, object_id, form_url, extra_context)


from .models import AreaManager, AreaManagerCommission, ZonalNote, ZonalNotice


@admin.register(ZonalNotice)
class ZonalNoticeAdmin(admin.ModelAdmin):
    """Post notices here — officers see them on the /zoneadmin dashboard."""
    list_display = ("title", "target", "is_active", "created_at")
    list_filter = ("is_active",)
    search_fields = ("title", "body")

    @admin.display(description="Target")
    def target(self, obj):
        return obj.office.city if obj.office_id else "All zones"


@admin.register(ZonalNote)
class ZonalNoteAdmin(admin.ModelAdmin):
    """Officers' Primary Notes (created from /zoneadmin) — viewable here."""
    list_display = ("title", "office", "updated_at")
    list_filter = ("office",)
    search_fields = ("title", "body")


class AreaManagerCommissionInline(admin.TabularInline):
    model = AreaManagerCommission
    extra = 0


@admin.register(AreaManager)
class AreaManagerAdmin(admin.ModelAdmin):
    """Area managers are created by zonal officers from /zoneadmin; this is
    the owner's read/manage window into all of them."""
    list_display = ("name", "area", "office", "phone", "is_active", "created_at")
    list_filter = ("office", "is_active")
    search_fields = ("name", "area", "phone")
    inlines = [AreaManagerCommissionInline]
