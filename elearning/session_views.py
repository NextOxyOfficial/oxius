# API views for e-learning session management
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from django.utils import timezone
from django.http import JsonResponse
import json
import uuid

from .session_manager import ELearningSessionManager
from .models import ELearningSession, SessionActivityLog
from subscription.utils import is_pro_subscriber


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def start_elearning_session(request):
    """Start a new e-learning session"""
    try:
        page_url = request.data.get('page_url', request.META.get('HTTP_REFERER', ''))
        
        if not page_url:
            return Response({
                'error': 'Page URL is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if user can start a session
        session, message = ELearningSessionManager.start_session(
            request.user, 
            request, 
            page_url
        )
        
        if not session:
            return Response({
                'error': message,
                'can_access': False
            }, status=status.HTTP_403_FORBIDDEN)
        
        # Get session status
        session_status = ELearningSessionManager.get_session_status(session.id)
        
        return Response({
            'success': True,
            'session_id': str(session.id),
            'message': message,
            'session_status': session_status,
            'can_access': True
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({
            'error': f'Failed to start session: {str(e)}',
            'can_access': False
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def check_elearning_access(request):
    """Check if user can access e-learning content"""
    try:
        can_start, message = ELearningSessionManager.can_start_session(
            request.user, 
            request
        )
        
        # Get user's subscription status
        is_pro, subscription_end = ELearningSessionManager.check_subscription_status(request.user)
        
        # Get active session if exists
        active_session = ELearningSession.objects.filter(
            user=request.user,
            status='active'
        ).first()
        
        session_info = None
        if active_session and active_session.is_active():
            session_info = ELearningSessionManager.get_session_status(active_session.id)
        
        return Response({
            'can_access': can_start,
            'message': message,
            'is_pro': is_pro,
            'subscription_end': subscription_end,
            'active_session': session_info,
            'user_id': request.user.id
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': f'Failed to check access: {str(e)}',
            'can_access': False
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_session_activity(request):
    """Update session activity"""
    try:
        session_id = request.data.get('session_id')
        if not session_id:
            return Response({
                'error': 'Session ID is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        activity_data = {
            'action': request.data.get('action', 'page_access'),
            'subject_id': request.data.get('subject_id'),
            'current_video_id': request.data.get('current_video_id'),
            'ip_address': ELearningSessionManager.get_client_ip(request),
            'details': request.data.get('details', {})
        }
        
        session = ELearningSessionManager.update_session_activity(
            session_id, 
            activity_data
        )
        
        if not session:
            return Response({
                'error': 'Session not found or expired'
            }, status=status.HTTP_404_NOT_FOUND)
        
        session_status = ELearningSessionManager.get_session_status(session.id)
        
        return Response({
            'success': True,
            'session_status': session_status
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': f'Failed to update activity: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def track_viewing_time(request):
    """Track video viewing time and check limits"""
    try:
        session_id = request.data.get('session_id')
        seconds_watched = request.data.get('seconds_watched', 0)
        
        if not session_id or seconds_watched <= 0:
            return Response({
                'error': 'Valid session ID and seconds_watched are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        session, can_continue, message = ELearningSessionManager.add_viewing_time(
            session_id, 
            seconds_watched
        )
        
        if not session:
            return Response({
                'error': message
            }, status=status.HTTP_404_NOT_FOUND)
        
        session_status = ELearningSessionManager.get_session_status(session.id)
        
        response_data = {
            'success': True,
            'can_continue': can_continue,
            'message': message,
            'session_status': session_status
        }
        
        # If time limit reached, include upgrade message
        if not can_continue and not session.is_pro_user:
            response_data['upgrade_message'] = "You've reached the 1-minute viewing limit for free users. Upgrade to Pro for unlimited access!"
            response_data['should_redirect'] = True
            response_data['redirect_url'] = '/upgrade-to-pro'
        
        return Response(response_data, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': f'Failed to track viewing time: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def end_elearning_session(request):
    """End the current e-learning session"""
    try:
        session_id = request.data.get('session_id')
        reason = request.data.get('reason', 'user_initiated')
        
        if not session_id:
            return Response({
                'error': 'Session ID is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        success = ELearningSessionManager.end_session(session_id, reason)
        
        if success:
            return Response({
                'success': True,
                'message': 'Session ended successfully'
            }, status=status.HTTP_200_OK)
        else:
            return Response({
                'error': 'Session not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
    except Exception as e:
        return Response({
            'error': f'Failed to end session: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_session_status(request):
    """Get current session status"""
    try:
        session_id = request.GET.get('session_id')
        
        if not session_id:
            # Try to find active session for user
            active_session = ELearningSession.objects.filter(
                user=request.user,
                status='active'
            ).first()
            
            if not active_session:
                return Response({
                    'has_session': False,
                    'message': 'No active session found'
                }, status=status.HTTP_200_OK)
            
            session_id = active_session.id
        
        session_status = ELearningSessionManager.get_session_status(session_id)
        
        return Response({
            'has_session': True,
            'session_id': str(session_id),
            'session_status': session_status
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': f'Failed to get session status: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def heartbeat(request):
    """Session heartbeat to keep session alive"""
    try:
        session_id = request.GET.get('session_id')
        
        if not session_id:
            return Response({
                'error': 'Session ID is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Update session activity
        activity_data = {
            'action': 'heartbeat',
            'ip_address': ELearningSessionManager.get_client_ip(request),
            'details': {'timestamp': timezone.now().isoformat()}
        }
        
        session = ELearningSessionManager.update_session_activity(
            session_id, 
            activity_data
        )
        
        if not session:
            return Response({
                'error': 'Session not found or expired',
                'session_expired': True
            }, status=status.HTTP_404_NOT_FOUND)
        
        session_status = ELearningSessionManager.get_session_status(session.id)
        
        return Response({
            'success': True,
            'session_status': session_status
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': f'Heartbeat failed: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# Admin endpoints for monitoring
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_sessions(request):
    """Get user's session history (for admins or user themselves)"""
    try:
        user_id = request.GET.get('user_id')
        
        # Only allow users to see their own sessions unless they're admin
        if user_id and str(request.user.id) != user_id and not request.user.is_staff:
            return Response({
                'error': 'Permission denied'
            }, status=status.HTTP_403_FORBIDDEN)
        
        target_user = request.user
        if user_id and request.user.is_staff:
            from django.contrib.auth import get_user_model
            User = get_user_model()
            try:
                target_user = User.objects.get(id=user_id)
            except User.DoesNotExist:
                return Response({
                    'error': 'User not found'
                }, status=status.HTTP_404_NOT_FOUND)
        
        sessions = ELearningSession.objects.filter(
            user=target_user
        ).order_by('-started_at')[:20]
        
        session_data = []
        for session in sessions:
            session_data.append({
                'id': str(session.id),
                'status': session.status,
                'started_at': session.started_at,
                'ended_at': session.ended_at,
                'last_activity': session.last_activity,
                'total_viewing_time': session.total_viewing_time,
                'session_viewing_time': session.session_viewing_time,
                'is_pro_user': session.is_pro_user,
                'ip_address': session.ip_address,
                'page_url': session.page_url,
                'subject_id': session.subject_id,
                'current_video_id': session.current_video_id
            })
        
        return Response({
            'success': True,
            'sessions': session_data,
            'user_id': target_user.id,
            'username': target_user.username
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': f'Failed to get sessions: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# Cleanup task endpoint (for admin or scheduled tasks)
@api_view(['POST'])
def cleanup_expired_sessions(request):
    """Clean up expired sessions (admin only)"""
    try:
        # Only allow admin access or internal calls
        if not (request.user.is_authenticated and request.user.is_staff):
            # Check if this is an internal call (for scheduled tasks)
            api_key = request.META.get('HTTP_X_API_KEY')
            if api_key != 'internal_cleanup_key':  # Replace with proper API key
                return Response({
                    'error': 'Permission denied'
                }, status=status.HTTP_403_FORBIDDEN)
        
        cleaned_count = ELearningSessionManager.cleanup_expired_sessions()
        
        return Response({
            'success': True,
            'cleaned_sessions': cleaned_count,
            'message': f'Cleaned up {cleaned_count} expired sessions'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'error': f'Cleanup failed: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
