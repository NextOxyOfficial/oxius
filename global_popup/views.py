from django.shortcuts import render
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.utils import timezone
from django.db.models import F
from datetime import timedelta
from .models import PopupDesktop, PopupMobile, PopupView
from .serializers import PopupDesktopSerializer, PopupMobileSerializer, PopupViewSerializer

# Create your views here.


class PopupDesktopView(APIView):
    def get(self, request):
        user = request.user if request.user.is_authenticated else None
        session_key = request.session.session_key

        # Ensure session exists for anonymous users
        if not user and not session_key:
            request.session.create()
            # Get active popups based on user authentication status
            session_key = request.session.session_key
        if user:
            # For logged-in users: get popups that are active AND allow logged-in users
            popups = PopupDesktop.objects.filter(
                is_active=True,
                show_for_logged_in_users=True
            )
        else:
            # For anonymous users: get popups that are active AND allow anonymous users
            popups = PopupDesktop.objects.filter(
                is_active=True,
                show_for_anonymous_users=True
            )

        # Additional safety check: if no user type is allowed, return empty
        if not popups.exists():
            return Response([])

        # Filter popups based on viewing conditions
        available_popups = []
        for popup in popups:
            should_show = self.should_show_popup(popup, user, session_key)
            if should_show:
                available_popups.append(popup)

        serializer = PopupDesktopSerializer(available_popups, many=True)
        return Response(serializer.data)

    def should_show_popup(self, popup, user, session_key):
        """Check if popup should be shown based on viewing condition"""

        if popup.viewing_condition == 'always':
            return True

        # Check existing views
        if user:
            existing_view = PopupView.objects.filter(
                popup_desktop=popup,
                user=user
            ).first()
        else:
            existing_view = PopupView.objects.filter(
                popup_desktop=popup,
                session_key=session_key
            ).first()

        if not existing_view:
            return True

        if popup.viewing_condition == 'once':
            return False

        now = timezone.now()
        if popup.viewing_condition == 'daily':
            return existing_view.viewed_at.date() < now.date()
        elif popup.viewing_condition == 'weekly':
            return existing_view.viewed_at < now - timedelta(weeks=1)
        elif popup.viewing_condition == 'monthly':
            return existing_view.viewed_at < now - timedelta(days=30)

        return False


class PopupMobileView(APIView):
    def get(self, request):
        user = request.user if request.user.is_authenticated else None
        session_key = request.session.session_key

        # Ensure session exists for anonymous users
        if not user and not session_key:
            request.session.create()
            # Get active popups based on user authentication status
            session_key = request.session.session_key
        if user:
            # For logged-in users: get popups that are active AND allow logged-in users
            popups = PopupMobile.objects.filter(
                is_active=True,
                show_for_logged_in_users=True
            )
        else:
            # For anonymous users: get popups that are active AND allow anonymous users
            popups = PopupMobile.objects.filter(
                is_active=True,
                show_for_anonymous_users=True
            )

        # Additional safety check: if no user type is allowed, return empty
        if not popups.exists():
            return Response([])

        # Filter popups based on viewing conditions
        available_popups = []
        for popup in popups:
            should_show = self.should_show_popup(popup, user, session_key)
            if should_show:
                available_popups.append(popup)

        serializer = PopupMobileSerializer(available_popups, many=True)
        return Response(serializer.data)

    def should_show_popup(self, popup, user, session_key):
        """Check if popup should be shown based on viewing condition"""

        if popup.viewing_condition == 'always':
            return True

        # Check existing views
        if user:
            existing_view = PopupView.objects.filter(
                popup_mobile=popup,
                user=user
            ).first()
        else:
            existing_view = PopupView.objects.filter(
                popup_mobile=popup,
                session_key=session_key
            ).first()

        if not existing_view:
            return True

        if popup.viewing_condition == 'once':
            return False

        now = timezone.now()
        if popup.viewing_condition == 'daily':
            return existing_view.viewed_at.date() < now.date()
        elif popup.viewing_condition == 'weekly':
            return existing_view.viewed_at < now - timedelta(weeks=1)
        elif popup.viewing_condition == 'monthly':
            return existing_view.viewed_at < now - timedelta(days=30)

        return False


class PopupViewTrackingView(APIView):
    """Track popup views"""

    def post(self, request):
        popup_type = request.data.get('popup_type')  # 'desktop' or 'mobile'
        popup_id = request.data.get('popup_id')

        if not popup_type or not popup_id:
            return Response(
                {'error': 'popup_type and popup_id are required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = request.user if request.user.is_authenticated else None
        session_key = request.session.session_key
        ip_address = self.get_client_ip(request)
        user_agent = request.META.get('HTTP_USER_AGENT', '')

        try:
            if popup_type == 'desktop':
                popup = PopupDesktop.objects.get(id=popup_id)
                # Increment total views
                PopupDesktop.objects.filter(id=popup_id).update(
                    total_views=F('total_views') + 1)

                # Create or update view record
                view_data = {
                    'popup_desktop': popup,
                    'ip_address': ip_address,
                    'user_agent': user_agent,
                }
                if user:
                    view_data['user'] = user
                    PopupView.objects.update_or_create(
                        popup_desktop=popup,
                        user=user,
                        defaults=view_data
                    )
                else:
                    view_data['session_key'] = session_key
                    PopupView.objects.update_or_create(
                        popup_desktop=popup,
                        session_key=session_key,
                        defaults=view_data
                    )

            elif popup_type == 'mobile':
                popup = PopupMobile.objects.get(id=popup_id)
                # Increment total views
                PopupMobile.objects.filter(id=popup_id).update(
                    total_views=F('total_views') + 1)

                # Create or update view record
                view_data = {
                    'popup_mobile': popup,
                    'ip_address': ip_address,
                    'user_agent': user_agent,
                }
                if user:
                    view_data['user'] = user
                    PopupView.objects.update_or_create(
                        popup_mobile=popup,
                        user=user,
                        defaults=view_data
                    )
                else:
                    view_data['session_key'] = session_key
                    PopupView.objects.update_or_create(
                        popup_mobile=popup,
                        session_key=session_key,
                        defaults=view_data
                    )
            else:
                return Response(
                    {'error': 'Invalid popup_type. Use "desktop" or "mobile"'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            return Response({'success': True}, status=status.HTTP_200_OK)

        except (PopupDesktop.DoesNotExist, PopupMobile.DoesNotExist):
            return Response(
                {'error': 'Popup not found'},
                status=status.HTTP_404_NOT_FOUND
            )

    def get_client_ip(self, request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip
