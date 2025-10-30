from django.contrib import admin
from django.contrib import messages
from django.utils.html import format_html

# Register your models here.

from .models import *

class OperatorAdmin(admin.ModelAdmin):
    list_display = ('name', 'icon_display', 'bg_color_display', 'active', 'created_at')
    list_filter = ('active', 'created_at')
    search_fields = ('name',)
    
    def icon_display(self, obj):
        """Display operator icon in admin"""
        if obj.icon:
            return format_html('<img src="{}" style="width: 32px; height: 32px; border-radius: 4px; border: 1px solid #ddd;" />', obj.icon.url)
        return format_html('<div style="width: 32px; height: 32px; border-radius: 4px; border: 1px solid #ddd; background-color: {}; display: flex; align-items: center; justify-content: center; color: white; font-weight: bold;">{}</div>', 
                         obj.bg_color or '#ccc', obj.name[:2].upper())
    icon_display.short_description = 'Icon'
    
    def bg_color_display(self, obj):
        """Display background color as colored square"""
        return format_html('<div style="width: 20px; height: 20px; border-radius: 4px; background-color: {}; border: 1px solid #ddd;"></div>', obj.bg_color or '#ccc')
    bg_color_display.short_description = 'Color'

admin.site.register(Operator, OperatorAdmin)

class PackageAdmin(admin.ModelAdmin):
    list_display = ('operator_display', 'type', 'price', 'data', 'validity', 'calls', 'popular', 'active')
    list_filter = ('operator', 'type', 'popular', 'active', 'created_at')
    search_fields = ('operator__name', 'type', 'price', 'data')
    list_editable = ('popular', 'active')
    
    def operator_display(self, obj):
        """Display operator name with icon"""
        if obj.operator.icon:
            return format_html('<div style="display: flex; align-items: center;"><img src="{}" style="width: 20px; height: 20px; border-radius: 3px; margin-right: 8px;" /><strong>{}</strong></div>', 
                             obj.operator.icon.url, obj.operator.name)
        return format_html('<div style="display: flex; align-items: center;"><div style="width: 20px; height: 20px; border-radius: 3px; background-color: {}; margin-right: 8px; display: flex; align-items: center; justify-content: center; color: white; font-size: 10px; font-weight: bold;">{}</div><strong>{}</strong></div>', 
                         obj.operator.bg_color or '#ccc', obj.operator.name[:2].upper(), obj.operator.name)
    operator_display.short_description = 'Operator'

admin.site.register(Package, PackageAdmin)

class RechargeAdmin(admin.ModelAdmin):
    list_display = ('user','phone_number','status_display','operator', 'package', 'amount', 'created_at')
    list_filter=('status','operator', 'package', 'amount', 'created_at')
    search_fields = ('user__email', 'user__name', 'phone_number')
    actions = ['approve_recharges']
    
    def status_display(self, obj):
        """Display status with color coding"""
        if obj.status == 'completed':
            return format_html('<span style="color: green; font-weight: bold;">✓ Completed</span>')
        elif obj.status == 'pending':
            return format_html('<span style="color: orange; font-weight: bold;">⏳ Pending</span>')
        return obj.status
    status_display.short_description = 'Status'
    
    def save_model(self, request, obj, form, change):
        """Override save_model - let signals handle notifications"""
        # Store the original status if this is an update
        original_status = None
        if change and obj.pk:
            try:
                original_obj = Recharge.objects.get(pk=obj.pk)
                original_status = original_obj.status
            except Recharge.DoesNotExist:
                original_status = None
        
        # Save the object - signals will handle notification creation
        super().save_model(request, obj, form, change)
        
        # Just provide feedback to admin about what happened
        if (original_status == 'pending' and obj.status == 'completed' and obj.user):
            messages.success(
                request, 
                f"Recharge approved! Notification will be sent to {obj.user.email or obj.user.name}"
            )
    
    def approve_recharges(self, request, queryset):
        """Admin action to approve selected recharge requests"""
        approved_count = 0
        
        for recharge in queryset:
            if recharge.status == 'pending':
                print(f"Approving recharge {recharge.id} for user {recharge.user}")
                
                # Simply update status - signals will handle notification creation
                recharge.status = 'completed'
                recharge.save()
                approved_count += 1
        
        if approved_count > 0:
            messages.success(request, f"Successfully approved {approved_count} recharge(s). Notifications will be sent to users.")
        else:
            messages.warning(request, "No pending recharges were found to approve.")
    
    approve_recharges.short_description = "✓ Approve selected recharge requests"

admin.site.register(Recharge, RechargeAdmin)
