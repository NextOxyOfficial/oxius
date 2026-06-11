from django.contrib import admin

from .models import AdPlacement, AdSettings


@admin.register(AdSettings)
class AdSettingsAdmin(admin.ModelAdmin):
    """Master switch, SDK key and brand safety. Keep rating = G to block
    gambling & nudity ads. (Also set Block Lists in the MAX dashboard.)"""
    list_display = ("enabled", "test_mode", "max_ad_content_rating")

    def has_add_permission(self, request):
        # Single global row.
        return not AdSettings.objects.exists()

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(AdPlacement)
class AdPlacementAdmin(admin.ModelAdmin):
    """Each ad slot. Toggle enabled, set ad-unit ids and (for feeds) frequency
    — changes take effect on the app's next config fetch, no app update."""
    list_display = ("label", "key", "ad_format", "enabled", "frequency", "network")
    list_filter = ("enabled", "ad_format", "network")
    list_editable = ("enabled", "frequency")
    search_fields = ("key", "label")
