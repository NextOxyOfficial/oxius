from django.contrib import admin
from django.contrib import messages
from django.utils.html import format_html

# Register your models here.

from .models import *

admin.site.register(Operator)
admin.site.register(Package)

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
