from django.contrib import admin
from django.shortcuts import render
from django.urls import path
from django.http import HttpResponseRedirect
from django.contrib import messages
from django.utils.html import format_html
from .models import FCMToken
from .fcm_service import send_fcm_notification, send_fcm_notification_multicast
from django.contrib.auth import get_user_model

User = get_user_model()


class NotificationAdminPanel(admin.ModelAdmin):
    """
    Custom admin panel for sending push notifications
    """
    change_list_template = 'admin/notification_panel.html'
    
    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path('send-notification/', self.admin_site.admin_view(self.send_notification_view), name='send-notification'),
        ]
        return custom_urls + urls
    
    def send_notification_view(self, request):
        """View for sending notifications"""
        if request.method == 'POST':
            notification_type = request.POST.get('notification_type')
            title = request.POST.get('title')
            body = request.POST.get('body')
            data_type = request.POST.get('data_type', 'general')
            
            # Get recipients
            recipient_type = request.POST.get('recipient_type')
            
            try:
                if recipient_type == 'all':
                    # Send to all users
                    tokens = FCMToken.objects.filter(is_active=True).values_list('token', flat=True)
                    token_list = list(tokens)
                    
                    if token_list:
                        response = send_fcm_notification_multicast(
                            fcm_tokens=token_list,
                            title=title,
                            body=body,
                            data={'type': data_type, 'click_action': 'FLUTTER_NOTIFICATION_CLICK'}
                        )
                        if response:
                            messages.success(request, f'✅ Notification sent to {response.success_count} users')
                            if response.failure_count > 0:
                                messages.warning(request, f'⚠️ Failed to send to {response.failure_count} users')
                        else:
                            messages.error(request, '❌ Failed to send notifications')
                    else:
                        messages.warning(request, '⚠️ No active tokens found')
                
                elif recipient_type == 'specific':
                    # Send to specific user
                    user_email = request.POST.get('user_email')
                    try:
                        user = User.objects.get(email=user_email)
                        tokens = FCMToken.objects.filter(user=user, is_active=True).values_list('token', flat=True)
                        
                        success_count = 0
                        for token in tokens:
                            if send_fcm_notification(
                                fcm_token=token,
                                title=title,
                                body=body,
                                data={'type': data_type, 'click_action': 'FLUTTER_NOTIFICATION_CLICK'}
                            ):
                                success_count += 1
                        
                        if success_count > 0:
                            messages.success(request, f'✅ Notification sent to {user.email}')
                        else:
                            messages.error(request, f'❌ Failed to send notification to {user.email}')
                    except User.DoesNotExist:
                        messages.error(request, f'❌ User not found: {user_email}')
                
                elif recipient_type == 'active':
                    # Send to recently active users (logged in last 7 days)
                    from django.utils import timezone
                    from datetime import timedelta
                    
                    seven_days_ago = timezone.now() - timedelta(days=7)
                    active_users = User.objects.filter(last_login__gte=seven_days_ago)
                    tokens = FCMToken.objects.filter(
                        user__in=active_users,
                        is_active=True
                    ).values_list('token', flat=True)
                    token_list = list(tokens)
                    
                    if token_list:
                        response = send_fcm_notification_multicast(
                            fcm_tokens=token_list,
                            title=title,
                            body=body,
                            data={'type': data_type, 'click_action': 'FLUTTER_NOTIFICATION_CLICK'}
                        )
                        if response:
                            messages.success(request, f'✅ Notification sent to {response.success_count} active users')
                        else:
                            messages.error(request, '❌ Failed to send notifications')
                    else:
                        messages.warning(request, '⚠️ No active users found')
                
                return HttpResponseRedirect('../')
                
            except Exception as e:
                messages.error(request, f'❌ Error: {str(e)}')
                return HttpResponseRedirect('../')
        
        # GET request - show form
        context = {
            'title': 'Send Push Notification',
            'total_tokens': FCMToken.objects.filter(is_active=True).count(),
            'total_users': User.objects.filter(fcm_tokens__is_active=True).distinct().count(),
        }
        return render(request, 'admin/send_notification_form.html', context)
    
    def changelist_view(self, request, extra_context=None):
        """Override changelist to show notification panel"""
        extra_context = extra_context or {}
        
        # Statistics
        total_tokens = FCMToken.objects.filter(is_active=True).count()
        total_users = User.objects.filter(fcm_tokens__is_active=True).distinct().count()
        android_tokens = FCMToken.objects.filter(is_active=True, device_type='android').count()
        ios_tokens = FCMToken.objects.filter(is_active=True, device_type='ios').count()
        
        # Recent tokens
        recent_tokens = FCMToken.objects.filter(is_active=True).select_related('user').order_by('-updated_at')[:10]
        
        extra_context.update({
            'total_tokens': total_tokens,
            'total_users': total_users,
            'android_tokens': android_tokens,
            'ios_tokens': ios_tokens,
            'recent_tokens': recent_tokens,
        })
        
        return super().changelist_view(request, extra_context=extra_context)


# Register a dummy model for the notification panel
class NotificationPanel:
    """Dummy model for notification admin panel"""
    class Meta:
        verbose_name = 'Push Notification'
        verbose_name_plural = 'Push Notifications'
        app_label = 'base'


# Don't register the actual model, just use it for the admin panel
admin.site.register(FCMToken, NotificationAdminPanel)
