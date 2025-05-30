from django.contrib import admin
from django.utils.html import format_html
from django.contrib import messages
from tinymce.widgets import TinyMCE
from .models import SupportTicket, TicketReply, TicketReadStatus, BulkTicket

@admin.register(SupportTicket)
class SupportTicketAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'user', 'status', 'reply_count', 'is_unread_for_user', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('title', 'message', 'user__email', 'user__username')
    readonly_fields = ('created_at', 'updated_at', 'id', 'message_preview')
    list_editable = ('status',)
    
    fieldsets = (
        ('Ticket Information', {
            'fields': ('user', 'title', 'message', 'status')
        }),
        ('Message Preview', {
            'fields': ('message_preview',),
            'classes': ('collapse',)
        }),
        ('Metadata', {
            'fields': ('id', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def message_preview(self, obj):
        """Display the rendered HTML message"""
        if obj.message:
            return format_html(
                '<div style="max-height: 300px; overflow-y: auto; border: 1px solid #ddd; padding: 10px; background: #f9f9f9;">{}</div>',
                obj.message
            )
        return "No message"
    
    message_preview.short_description = "Message Preview (Rendered)"
    
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
    
    def get_form(self, request, obj=None, **kwargs):
        form = super().get_form(request, obj, **kwargs)
        # Apply TinyMCE widget to the message field safely
        if 'message' in form.base_fields:
            form.base_fields['message'].widget = TinyMCE(attrs={'cols': 80, 'rows': 20})
        return form

@admin.register(TicketReply)
class TicketReplyAdmin(admin.ModelAdmin):
    list_display = ('id', 'ticket', 'user', 'is_from_admin', 'short_message', 'created_at')
    list_filter = ('is_from_admin', 'created_at', 'ticket__status')
    search_fields = ('message', 'user__email', 'user__username', 'ticket__title')
    readonly_fields = ('created_at', 'updated_at', 'id', 'message_preview')
    
    fieldsets = (
        ('Reply Information', {
            'fields': ('ticket', 'user', 'message', 'is_from_admin')
        }),
        ('Message Preview', {
            'fields': ('message_preview',),
            'classes': ('collapse',)
        }),
        ('Metadata', {
            'fields': ('id', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def message_preview(self, obj):
        """Display the rendered HTML message"""
        if obj.message:
            return format_html(
                '<div style="max-height: 300px; overflow-y: auto; border: 1px solid #ddd; padding: 10px; background: #f9f9f9;">{}</div>',
                obj.message
            )
        return "No message"
    
    message_preview.short_description = "Message Preview (Rendered)"
    
    def short_message(self, obj):
        return obj.message[:50] + '...' if len(obj.message) > 50 else obj.message
    
    short_message.short_description = 'Message'
    
    def get_form(self, request, obj=None, **kwargs):
        form = super().get_form(request, obj, **kwargs)
        # Apply TinyMCE widget to the message field safely
        if 'message' in form.base_fields:
            form.base_fields['message'].widget = TinyMCE(attrs={'cols': 80, 'rows': 15})
        return form

@admin.register(TicketReadStatus)
class TicketReadStatusAdmin(admin.ModelAdmin):
    list_display = ('ticket', 'user', 'last_read_at')
    list_filter = ('last_read_at', 'user')
    search_fields = ('ticket__title', 'user__email', 'user__username')
    readonly_fields = ('last_read_at',)

@admin.register(BulkTicket)
class BulkTicketAdmin(admin.ModelAdmin):
    list_display = ('title', 'target_type', 'created_by', 'is_processed', 'tickets_created_count', 'created_at')
    list_filter = ('target_type', 'is_processed', 'created_at')
    search_fields = ('title', 'message', 'created_by__email', 'created_by__username')
    readonly_fields = ('is_processed', 'processed_at', 'tickets_created_count', 'created_at', 'message_preview')
    filter_horizontal = ('target_users',)
    
    fieldsets = (
        ('Bulk Ticket Information', {
            'fields': ('title', 'message', 'target_type', 'target_users')
        }),
        ('Message Preview', {
            'fields': ('message_preview',),
            'classes': ('collapse',)
        }),
        ('Processing Status', {
            'fields': ('is_processed', 'processed_at', 'tickets_created_count'),
            'classes': ('collapse',)
        }),
        ('Metadata', {
            'fields': ('created_by', 'created_at'),
            'classes': ('collapse',)
        }),
    )
    
    def message_preview(self, obj):
        """Display the rendered HTML message"""
        if obj.message:
            return format_html(
                '<div style="max-height: 300px; overflow-y: auto; border: 1px solid #ddd; padding: 10px; background: #f9f9f9;">{}</div>',
                obj.message
            )
        return "No message"
    
    message_preview.short_description = "Message Preview (Rendered)"
    
    def get_form(self, request, obj=None, **kwargs):
        form = super().get_form(request, obj, **kwargs)
        # Apply TinyMCE widget to the message field safely
        if 'message' in form.base_fields:
            form.base_fields['message'].widget = TinyMCE(attrs={'cols': 80, 'rows': 30})
        return form
    
    def save_model(self, request, obj, form, change):
        """Override save to set created_by and process bulk tickets"""
        if not change:  # Only set created_by on creation
            obj.created_by = request.user
        
        super().save_model(request, obj, form, change)
        
        # Process the bulk ticket if it hasn't been processed yet
        if not obj.is_processed:
            try:
                created_count = obj.create_individual_tickets()
                messages.success(
                    request, 
                    f'Successfully created {created_count} individual tickets from bulk ticket "{obj.title}"'
                )
            except Exception as e:
                messages.error(
                    request, 
                    f'Error processing bulk ticket: {str(e)}'
                )
    
    def get_queryset(self, request):
        """Show all bulk tickets but highlight user's own"""
        return super().get_queryset(request)
    
    def has_change_permission(self, request, obj=None):
        """Allow changes only if ticket hasn't been processed"""
        if obj and obj.is_processed:
            return False
        return super().has_change_permission(request, obj)
    
    def has_delete_permission(self, request, obj=None):
        """Allow deletion only if ticket hasn't been processed"""
        if obj and obj.is_processed:
            return False
        return super().has_delete_permission(request, obj)
