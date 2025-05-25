from django.contrib import admin
from .models import SupportTicket, TicketReply

@admin.register(SupportTicket)
class SupportTicketAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'user', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('title', 'message', 'user__email', 'user__username')
    readonly_fields = ('created_at', 'updated_at')

@admin.register(TicketReply)
class TicketReplyAdmin(admin.ModelAdmin):
    list_display = ('id', 'ticket', 'user', 'is_from_admin', 'created_at')
    list_filter = ('is_from_admin', 'created_at')
    search_fields = ('message', 'user__email', 'user__username', 'ticket__title')
    readonly_fields = ('created_at', 'updated_at')
