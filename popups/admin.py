from django.contrib import admin
from django.utils.html import format_html
from django.utils.safestring import mark_safe
from .models import Popup, PopupView


@admin.register(Popup)
class PopupAdmin(admin.ModelAdmin):
    list_display = [
        'title', 'popup_type', 'is_active', 'image_preview', 
        'start_date', 'end_date', 'view_count', 'created_at'
    ]
    list_filter = [
        'popup_type', 'is_active', 'display_frequency', 
        'show_to_authenticated_users', 'show_to_anonymous_users', 'created_at'
    ]
    search_fields = ['title', 'text_content']
    readonly_fields = ['view_count', 'created_at', 'updated_at', 'image_preview']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('title', 'popup_type', 'image', 'image_preview', 'text_content')
        }),        ('Link Settings', {
            'fields': ('link_url', 'link_text', 'link_navigation'),
            'classes': ('collapse',)
        }),('Display Settings', {
            'fields': (
                'is_active', 'start_date', 'end_date', 'display_frequency', 
                'delay_seconds'
            )
        }),
        ('Close Settings', {
            'fields': (
                'auto_close_enabled', 'auto_close_delay', 'show_close_button', 
                'close_on_overlay_click'
            ),
            'classes': ('collapse',)
        }),        ('Target Audience', {
            'fields': ('show_to_authenticated_users', 'show_to_anonymous_users', 'show_to_pro_users_only'),
            'classes': ('collapse',)
        }),
        ('Styling', {
            'fields': ('width', 'height', 'background_color', 'text_color'),
            'classes': ('collapse',)
        }),
        ('Statistics', {
            'fields': ('view_count', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def image_preview(self, obj):
        if obj.image:
            return format_html(
                '<img src="{}" style="max-width: 200px; max-height: 150px; object-fit: contain;" />',
                obj.image.url
            )
        return "No image"
    image_preview.short_description = "Image Preview"
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related()
    
    class Media:
        css = {
            'all': ('admin/css/popup_admin.css',)
        }
        js = ('admin/js/popup_admin.js',)


@admin.register(PopupView)
class PopupViewAdmin(admin.ModelAdmin):
    list_display = ['popup', 'user', 'session_key', 'ip_address', 'viewed_at']
    list_filter = ['popup', 'viewed_at']
    search_fields = ['popup__title', 'user__username', 'ip_address']
    readonly_fields = ['popup', 'user', 'session_key', 'ip_address', 'viewed_at']
    
    def has_add_permission(self, request):
        return False
    
    def has_change_permission(self, request, obj=None):
        return False
