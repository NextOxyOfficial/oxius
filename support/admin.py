from django.contrib import admin
from django.utils.html import format_html
from .models import SupportTicket, TicketReply, TicketReadStatus

@admin.register(SupportTicket)
class SupportTicketAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'user', 'status', 'reply_count', 'is_unread_for_user', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('title', 'message', 'user__email', 'user__username')
    readonly_fields = ('created_at', 'updated_at', 'id')
    list_editable = ('status',)
    
    fieldsets = (
        ('Ticket Information', {
            'fields': ('user', 'title', 'message', 'status')
        }),
        ('Metadata', {
            'fields': ('id', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def reply_count(self, obj):
        return obj.replies.count()
    reply_count.short_description = 'Replies'
    
    def is_unread_for_user(self, obj):
        """Show if the ticket is unread for the user"""
        try:
            read_status = obj.read_statuses.get(user=obj.user)
            # Check if there's activity after last read
            latest_reply = obj.replies.order_by('-created_at').first()
            if latest_reply:
                latest_activity_time = latest_reply.created_at
            else:
                latest_activity_time = obj.created_at
                
            is_unread = latest_activity_time > read_status.last_read_at
            if is_unread:
                return format_html('<span style="color: red; font-weight: bold;">●</span> Unread')
            else:
                return format_html('<span style="color: green;">✓</span> Read')
        except:
            return format_html('<span style="color: red; font-weight: bold;">●</span> Unread')
    
    is_unread_for_user.short_description = 'Read Status'
    
    def save_model(self, request, obj, form, change):
        """Override save to ensure proper handling of admin-created tickets"""
        super().save_model(request, obj, form, change)
        
        # The signal will handle creating the TicketReadStatus
        # But we can add any additional admin-specific logic here if needed

@admin.register(TicketReply)
class TicketReplyAdmin(admin.ModelAdmin):
    list_display = ('id', 'ticket', 'user', 'is_from_admin', 'short_message', 'created_at')
    list_filter = ('is_from_admin', 'created_at', 'ticket__status')
    search_fields = ('message', 'user__email', 'user__username', 'ticket__title')
    readonly_fields = ('created_at', 'updated_at', 'id')
    
    def short_message(self, obj):
        return obj.message[:50] + '...' if len(obj.message) > 50 else obj.message
    
    short_message.short_description = 'Message'

@admin.register(TicketReadStatus)
class TicketReadStatusAdmin(admin.ModelAdmin):
    list_display = ('ticket', 'user', 'last_read_at')
    list_filter = ('last_read_at', 'user')
    search_fields = ('ticket__title', 'user__email', 'user__username')
    readonly_fields = ('last_read_at',)
