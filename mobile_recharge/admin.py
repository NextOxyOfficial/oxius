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
        """Override save_model to trigger notifications when status changes to completed"""
        # Store the original status if this is an update
        original_status = None
        if change and obj.pk:
            try:
                original_obj = Recharge.objects.get(pk=obj.pk)
                original_status = original_obj.status
            except Recharge.DoesNotExist:
                original_status = None
        
        # Save the object first
        super().save_model(request, obj, form, change)
        
        # Check if status changed from pending to completed
        if (original_status == 'pending' and obj.status == 'completed' and obj.user):
            try:
                from base.views import create_mobile_recharge_notification
                
                # Create notification for the user
                notification = create_mobile_recharge_notification(
                    user=obj.user,
                    amount=obj.amount,
                    phone_number=obj.phone_number
                )
                
                print(f"✓ Notification created for recharge {obj.id}: {notification}")
                
                # Add success message to admin
                messages.success(
                    request, 
                    f"Recharge approved! Notification sent to {obj.user.email or obj.user.name}"
                )
                
            except Exception as e:
                print(f"Error creating notification for recharge {obj.id}: {e}")
                messages.error(
                    request, 
                    f"Recharge approved but failed to send notification: {e}"
                )
    def approve_recharges(self, request, queryset):
        """Admin action to approve selected recharge requests"""
        approved_count = 0
        
        for recharge in queryset:
            if recharge.status == 'pending':
                print(f"Approving recharge {recharge.id} for user {recharge.user}")
                
                # Manually trigger notification creation since signal might not be reliable
                try:
                    from base.views import create_mobile_recharge_notification
                    
                    # Update status to completed
                    recharge.status = 'completed'
                    recharge.save()
                    
                    # Create notification
                    notification = create_mobile_recharge_notification(
                        user=recharge.user,
                        amount=recharge.amount,
                        phone_number=recharge.phone_number
                    )
                    print(f"Created notification: {notification}")
                    approved_count += 1
                    
                except Exception as e:
                    print(f"Error approving recharge {recharge.id}: {e}")
                    messages.error(request, f"Error approving recharge {recharge.id}: {e}")
        
        if approved_count > 0:
            messages.success(request, f"Successfully approved {approved_count} recharge(s). Notifications have been sent to users.")
        else:
            messages.warning(request, "No pending recharges were found to approve.")
    
    approve_recharges.short_description = "✓ Approve selected recharge requests"

admin.site.register(Recharge, RechargeAdmin)
