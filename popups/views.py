from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone
from django.db.models import Q
from .models import Popup, PopupView
import json


def get_active_popups(request):
    """Get active popups for the current user/session"""
    user = request.user if request.user.is_authenticated else None
    session_key = request.session.session_key
    
    # Get popups that should be shown
    now = timezone.now()
    popups = Popup.objects.filter(
        is_active=True,
        start_date__lte=now
    ).filter(
        Q(end_date__isnull=True) | Q(end_date__gte=now)
    )    # Filter based on user authentication status and pro status
    if user:
        popups = popups.filter(show_to_authenticated_users=True)
        # Filter pro-only popups
        if not user.is_pro:
            popups = popups.filter(show_to_pro_users_only=False)
    else:
        popups = popups.filter(show_to_anonymous_users=True)
        # Anonymous users can't see pro-only popups
        popups = popups.filter(show_to_pro_users_only=False)
    
    # Filter based on display frequency
    popup_list = []
    for popup in popups:
        should_show = True
        
        if popup.display_frequency == 'once':
            # Check if already shown in this session
            if PopupView.objects.filter(
                popup=popup,
                session_key=session_key
            ).exists():
                should_show = False
        elif popup.display_frequency == 'daily':
            # Check if shown today
            today = timezone.now().date()
            if PopupView.objects.filter(
                popup=popup,
                viewed_at__date=today
            ).filter(
                Q(user=user) | Q(session_key=session_key)
            ).exists():
                should_show = False
        if should_show:
            popup_data = {
                'id': popup.id,
                'title': popup.title,
                'popup_type': popup.popup_type,
                'image_url': popup.image.url if popup.image else None,                'text_content': popup.text_content,
                'link_url': popup.link_url,
                'link_text': popup.link_text,
                'link_navigation': popup.link_navigation,
                'delay_seconds': popup.delay_seconds,
                'width': popup.width,
                'height': popup.height,                'background_color': popup.background_color,
                'text_color': popup.text_color,
                # Target audience
                'show_to_pro_users_only': popup.show_to_pro_users_only,
                # Close settings
                'auto_close_enabled': popup.auto_close_enabled,
                'auto_close_delay': popup.auto_close_delay,
                'show_close_button': popup.show_close_button,
                'close_on_overlay_click': popup.close_on_overlay_click,
            }
            popup_list.append(popup_data)
    
    return JsonResponse({'popups': popup_list})


@csrf_exempt
def record_popup_view(request):
    """Record that a popup was viewed"""
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            popup_id = data.get('popup_id')
            
            popup = Popup.objects.get(id=popup_id)
            user = request.user if request.user.is_authenticated else None
            session_key = request.session.session_key
            
            # Get client IP
            x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
            if x_forwarded_for:
                ip_address = x_forwarded_for.split(',')[0]
            else:
                ip_address = request.META.get('REMOTE_ADDR')
            
            # Create or get popup view record
            popup_view, created = PopupView.objects.get_or_create(
                popup=popup,
                user=user,
                session_key=session_key,
                defaults={'ip_address': ip_address}
            )
            
            if created:
                popup.increment_view_count()
            
            return JsonResponse({'status': 'success'})
            
        except Exception as e:
            return JsonResponse({'status': 'error', 'message': str(e)})
    
    return JsonResponse({'status': 'error', 'message': 'Invalid request method'})


@csrf_exempt
def record_popup_close(request):
    """Record that a popup was closed and the reason"""
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            popup_id = data.get('popup_id')
            close_reason = data.get('close_reason', 'unknown')
            
            popup = Popup.objects.get(id=popup_id)
            
            # Log the close event (you can extend this to store in database if needed)
            print(f"Popup {popup.title} (ID: {popup_id}) closed due to: {close_reason}")
            
            return JsonResponse({'status': 'success', 'message': 'Close event recorded'})
            
        except Popup.DoesNotExist:
            return JsonResponse({'status': 'error', 'message': 'Popup not found'})
        except Exception as e:
            return JsonResponse({'status': 'error', 'message': str(e)})
    
    return JsonResponse({'status': 'error', 'message': 'Invalid request method'})
