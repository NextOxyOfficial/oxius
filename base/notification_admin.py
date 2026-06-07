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
        """Single place to compose + send a push notification.

        Routes through send_push_notification() so every send is ALSO saved as a
        UserNotification (shown in the app's Updates tab) and can carry a
        `deep_link` that the app opens on tap / via a "Visit" button.
        """
        if request.method == 'POST':
            title = (request.POST.get('title') or '').strip()
            body = (request.POST.get('body') or '').strip()
            deep_link = (request.POST.get('deep_link') or '').strip()
            data_type = request.POST.get('data_type', 'general')
            recipient_type = request.POST.get('recipient_type')

            if not title or not body:
                messages.error(request, '❌ Title and message are required')
                return HttpResponseRedirect('../')

            from .push_notifications import send_push_notification

            extra = {'click_action': 'FLUTTER_NOTIFICATION_CLICK'}
            print(
                f'\n📤 Sending notification "{title}" '
                f'(recipient={recipient_type}, deep_link={deep_link or "-"})'
            )

            try:
                if recipient_type == 'all':
                    created = send_push_notification(
                        title=title, body=body, deep_link=deep_link,
                        notification_type=data_type, broadcast=True, data=extra,
                    )
                    messages.success(
                        request,
                        '✅ Broadcast sent to all devices and saved to Updates.',
                    )

                elif recipient_type == 'specific':
                    user_email = request.POST.get('user_email')
                    try:
                        user = User.objects.get(email=user_email)
                    except User.DoesNotExist:
                        messages.error(request, f'❌ User not found: {user_email}')
                        return HttpResponseRedirect('../')
                    send_push_notification(
                        title=title, body=body, deep_link=deep_link,
                        notification_type=data_type, users=[user], data=extra,
                    )
                    messages.success(
                        request, f'✅ Sent to {user.email} and saved to Updates.'
                    )

                elif recipient_type == 'active':
                    from datetime import timedelta

                    from django.utils import timezone

                    seven_days_ago = timezone.now() - timedelta(days=7)
                    active_users = list(
                        User.objects.filter(last_login__gte=seven_days_ago)
                    )
                    created = send_push_notification(
                        title=title, body=body, deep_link=deep_link,
                        notification_type=data_type, users=active_users,
                        data=extra,
                    )
                    messages.success(
                        request,
                        f'✅ Sent to {len(created)} active users and saved.',
                    )
                else:
                    messages.error(request, '❌ Unknown recipient type')

                return HttpResponseRedirect('../')

            except Exception as e:
                import traceback
                traceback.print_exc()
                messages.error(request, f'❌ Error: {e}')
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
