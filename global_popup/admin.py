from django.contrib import admin
from .models import PopupDesktop, PopupMobile, PopupView

# Register your models here.


@admin.register(PopupDesktop)
class PopupDesktopAdmin(admin.ModelAdmin):
    list_display = ['id', 'is_active', 'show_for_logged_in_users',
                    'show_for_anonymous_users', 'viewing_condition', 'total_views', 'created_at']
    list_filter = ['is_active', 'show_for_logged_in_users',
                   'show_for_anonymous_users', 'viewing_condition', 'created_at']
    search_fields = ['id']
    readonly_fields = ['total_views', 'created_at', 'updated_at']


@admin.register(PopupMobile)
class PopupMobileAdmin(admin.ModelAdmin):
    list_display = ['id', 'is_active', 'show_for_logged_in_users',
                    'show_for_anonymous_users', 'viewing_condition', 'total_views', 'created_at']
    list_filter = ['is_active', 'show_for_logged_in_users',
                   'show_for_anonymous_users', 'viewing_condition', 'created_at']
    search_fields = ['id']
    readonly_fields = ['total_views', 'created_at', 'updated_at']


@admin.register(PopupView)
class PopupViewAdmin(admin.ModelAdmin):
    list_display = ['get_popup_type', 'get_popup_id',
                    'get_user_identifier', 'viewed_at']
    list_filter = ['viewed_at']
    search_fields = ['user__email', 'session_key', 'ip_address']
    readonly_fields = ['viewed_at']

    def get_popup_type(self, obj):
        return "Desktop" if obj.popup_desktop else "Mobile"
    get_popup_type.short_description = 'Popup Type'

    def get_popup_id(self, obj):
        return obj.popup_desktop.id if obj.popup_desktop else obj.popup_mobile.id
    get_popup_id.short_description = 'Popup ID'

    def get_user_identifier(self, obj):
        return obj.user.email if obj.user else f"Session: {obj.session_key}"
    get_user_identifier.short_description = 'User'
