from django.contrib import admin
from .models import SupportTicket, TicketReply, TicketReadStatus

@admin.register(SupportTicket)
class SupportTicketAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'user', 'status', 'reply_count', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('title', 'message', 'user__email', 'user__username')
    readonly_fields = ('created_at', 'updated_at', 'id')
    list_editable = ('status',)
    
    def reply_count(self, obj):
        return obj.replies.count()
    
    reply_count.short_description = 'Replies'

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
