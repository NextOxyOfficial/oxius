from django.contrib import admin
from django.utils.html import format_html
from .models import Gig, GigReview, GigFavorite, GigOrder, OrderMessage


@admin.register(Gig)
class GigAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'category', 'price', 'status', 'views_count', 'orders_count', 'created_at')
    list_filter = ('category', 'status', 'is_featured', 'created_at')
    search_fields = ('title', 'description', 'user__first_name', 'user__last_name', 'user__email')
    readonly_fields = ('id', 'views_count', 'orders_count', 'created_at', 'updated_at')
    ordering = ('-created_at',)


@admin.register(GigReview)
class GigReviewAdmin(admin.ModelAdmin):
    list_display = ('gig', 'user', 'rating', 'created_at')
    list_filter = ('rating', 'created_at')
    search_fields = ('gig__title', 'user__first_name', 'user__last_name', 'comment')
    readonly_fields = ('id', 'created_at')
    ordering = ('-created_at',)


@admin.register(GigFavorite)
class GigFavoriteAdmin(admin.ModelAdmin):
    list_display = ('gig', 'user', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('gig__title', 'user__first_name', 'user__last_name')
    readonly_fields = ('id', 'created_at')
    ordering = ('-created_at',)


class OrderMessageInline(admin.TabularInline):
    model = OrderMessage
    extra = 0
    readonly_fields = ('id', 'sender', 'content', 'message_type', 'media_preview', 'is_read', 'created_at')
    fields = ('sender', 'content', 'message_type', 'media_preview', 'is_read', 'created_at')
    ordering = ('created_at',)
    
    def media_preview(self, obj):
        if obj.media:
            return format_html('<img src="{}" style="max-height: 50px; max-width: 100px;" />', obj.media.url)
        return '-'
    media_preview.short_description = 'Media'
    
    def has_add_permission(self, request, obj=None):
        return False
    
    def has_delete_permission(self, request, obj=None):
        return True


@admin.register(GigOrder)
class GigOrderAdmin(admin.ModelAdmin):
    list_display = ('order_id_short', 'gig', 'buyer', 'seller', 'price', 'status', 'message_count', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('gig__title', 'buyer__first_name', 'seller__first_name')
    readonly_fields = ('id', 'created_at', 'updated_at')
    ordering = ('-created_at',)
    inlines = [OrderMessageInline]
    
    def order_id_short(self, obj):
        return str(obj.id)[:8]
    order_id_short.short_description = 'Order ID'
    
    def message_count(self, obj):
        count = obj.messages.count()
        if count > 0:
            return format_html('<span style="color: green; font-weight: bold;">{}</span>', count)
        return count
    message_count.short_description = 'Messages'


@admin.register(OrderMessage)
class OrderMessageAdmin(admin.ModelAdmin):
    list_display = ('order_id_short', 'sender', 'content_preview', 'message_type', 'media_preview', 'is_read', 'created_at')
    list_filter = ('message_type', 'is_read', 'created_at')
    search_fields = ('order__id', 'sender__first_name', 'sender__last_name', 'content')
    readonly_fields = ('id', 'created_at')
    ordering = ('-created_at',)
    raw_id_fields = ('order', 'sender')
    
    def order_id_short(self, obj):
        return str(obj.order.id)[:8]
    order_id_short.short_description = 'Order'
    
    def content_preview(self, obj):
        if obj.content:
            return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
        return '-'
    content_preview.short_description = 'Content'
    
    def media_preview(self, obj):
        if obj.media:
            return format_html('<img src="{}" style="max-height: 40px; max-width: 80px;" />', obj.media.url)
        return '-'
    media_preview.short_description = 'Media'
