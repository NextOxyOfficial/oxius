from django.contrib import admin
from django.utils.html import format_html
from .models import (
    ChatRoom, Message, MessageReport, 
    BlockedUser, TypingStatus, OnlineStatus
)


@admin.register(ChatRoom)
class ChatRoomAdmin(admin.ModelAdmin):
    list_display = ['id', 'user1_link', 'user2_link', 'last_message_preview_short', 
                    'last_message_at', 'is_blocked', 'created_at']
    list_filter = ['is_blocked', 'created_at', 'last_message_at']
    search_fields = ['user1__username', 'user1__email', 'user2__username', 'user2__email']
    readonly_fields = ['id', 'created_at', 'updated_at']
    date_hierarchy = 'created_at'
    
    def user1_link(self, obj):
        return format_html(
            '<a href="/admin/auth/user/{}/change/">{}</a>',
            obj.user1.id, obj.user1.username
        )
    user1_link.short_description = 'User 1'
    
    def user2_link(self, obj):
        return format_html(
            '<a href="/admin/auth/user/{}/change/">{}</a>',
            obj.user2.id, obj.user2.username
        )
    user2_link.short_description = 'User 2'
    
    def last_message_preview_short(self, obj):
        if obj.last_message_preview:
            return obj.last_message_preview[:50] + '...' if len(obj.last_message_preview) > 50 else obj.last_message_preview
        return '-'
    last_message_preview_short.short_description = 'Last Message'


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ['id', 'sender_link', 'receiver_link', 'message_type', 
                    'content_preview', 'is_read', 'is_deleted', 'created_at']
    list_filter = ['message_type', 'is_read', 'is_deleted', 'created_at']
    search_fields = ['sender__username', 'receiver__username', 'content']
    readonly_fields = ['id', 'created_at', 'updated_at', 'read_at', 'deleted_at']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Message Info', {
            'fields': ('id', 'chatroom', 'sender', 'receiver', 'message_type')
        }),
        ('Content', {
            'fields': ('content', 'media_file', 'media_thumbnail', 'file_name', 
                      'file_size', 'voice_duration')
        }),
        ('Status', {
            'fields': ('is_read', 'read_at', 'is_deleted', 'deleted_at')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )
    
    def sender_link(self, obj):
        return format_html(
            '<a href="/admin/auth/user/{}/change/">{}</a>',
            obj.sender.id, obj.sender.username
        )
    sender_link.short_description = 'Sender'
    
    def receiver_link(self, obj):
        return format_html(
            '<a href="/admin/auth/user/{}/change/">{}</a>',
            obj.receiver.id, obj.receiver.username
        )
    receiver_link.short_description = 'Receiver'
    
    def content_preview(self, obj):
        if obj.is_deleted:
            return format_html('<span style="color: red;">Deleted</span>')
        if obj.message_type == 'text' and obj.content:
            return obj.content[:50] + '...' if len(obj.content) > 50 else obj.content
        return f"{obj.message_type.upper()}"
    content_preview.short_description = 'Content'


@admin.register(MessageReport)
class MessageReportAdmin(admin.ModelAdmin):
    list_display = ['id', 'reporter_link', 'reported_user_link', 'reason', 
                    'status', 'created_at']
    list_filter = ['reason', 'status', 'created_at']
    search_fields = ['reporter__username', 'reported_user__username', 'description']
    readonly_fields = ['id', 'created_at', 'updated_at']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Report Info', {
            'fields': ('id', 'reporter', 'reported_user', 'message', 'reason', 'description')
        }),
        ('Status', {
            'fields': ('status', 'reviewed_by', 'reviewed_at', 'admin_notes')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )
    
    def reporter_link(self, obj):
        return format_html(
            '<a href="/admin/auth/user/{}/change/">{}</a>',
            obj.reporter.id, obj.reporter.username
        )
    reporter_link.short_description = 'Reporter'
    
    def reported_user_link(self, obj):
        return format_html(
            '<a href="/admin/auth/user/{}/change/">{}</a>',
            obj.reported_user.id, obj.reported_user.username
        )
    reported_user_link.short_description = 'Reported User'


@admin.register(BlockedUser)
class BlockedUserAdmin(admin.ModelAdmin):
    list_display = ['id', 'blocker_link', 'blocked_link', 'created_at']
    list_filter = ['created_at']
    search_fields = ['blocker__username', 'blocked__username']
    readonly_fields = ['id', 'created_at']
    date_hierarchy = 'created_at'
    
    def blocker_link(self, obj):
        return format_html(
            '<a href="/admin/auth/user/{}/change/">{}</a>',
            obj.blocker.id, obj.blocker.username
        )
    blocker_link.short_description = 'Blocker'
    
    def blocked_link(self, obj):
        return format_html(
            '<a href="/admin/auth/user/{}/change/">{}</a>',
            obj.blocked.id, obj.blocked.username
        )
    blocked_link.short_description = 'Blocked User'


@admin.register(TypingStatus)
class TypingStatusAdmin(admin.ModelAdmin):
    list_display = ['id', 'user_link', 'chatroom', 'is_typing', 'updated_at']
    list_filter = ['is_typing', 'updated_at']
    search_fields = ['user__username']
    readonly_fields = ['id', 'updated_at']
    
    def user_link(self, obj):
        return format_html(
            '<a href="/admin/auth/user/{}/change/">{}</a>',
            obj.user.id, obj.user.username
        )
    user_link.short_description = 'User'


@admin.register(OnlineStatus)
class OnlineStatusAdmin(admin.ModelAdmin):
    list_display = ['user_link', 'is_online', 'last_seen']
    list_filter = ['is_online', 'last_seen']
    search_fields = ['user__username', 'user__email']
    readonly_fields = ['last_seen']
    
    def user_link(self, obj):
        status_color = 'green' if obj.is_online else 'gray'
        return format_html(
            '<a href="/admin/auth/user/{}/change/"><span style="color: {};">● {}</span></a>',
            obj.user.id, status_color, obj.user.username
        )
    user_link.short_description = 'User'
