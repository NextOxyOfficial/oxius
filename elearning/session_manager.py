# Session management utilities for e-learning access control
import hashlib
import json
from datetime import timedelta
from django.utils import timezone
from django.contrib.auth import get_user_model
from django.db.models import Q, Count
from django.core.cache import cache
from .models import ELearningSession, SessionActivityLog, DeviceSession, SuspiciousActivity

User = get_user_model()


class ELearningSessionManager:
    """Manages e-learning sessions and access control"""
    
    @staticmethod
    def generate_device_fingerprint(request):
        """Generate a device fingerprint from request data"""
        components = [
            request.META.get('HTTP_USER_AGENT', ''),
            request.META.get('HTTP_ACCEPT_LANGUAGE', ''),
            request.META.get('HTTP_ACCEPT_ENCODING', ''),
            request.META.get('HTTP_ACCEPT', ''),
            # Add more browser fingerprinting data as needed
        ]
        
        fingerprint_data = '|'.join(components)
        return hashlib.md5(fingerprint_data.encode()).hexdigest()
    
    @staticmethod
    def get_client_ip(request):
        """Get the client's IP address"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip
    
    @staticmethod
    def check_subscription_status(user):
        """Check user's subscription status and validity"""
        if not user or user.is_anonymous:
            return False, None
        
        # Check if user has active pro subscription
        if hasattr(user, 'is_pro') and user.is_pro:
            # Check if pro validity hasn't expired
            if user.pro_validity and user.pro_validity > timezone.now():
                return True, user.pro_validity
        
        # Check new subscription system
        try:
            from subscription.models import Subscription
            active_subscription = Subscription.objects.filter(
                user=user,
                status='active',
                end_date__gt=timezone.now(),
                plan__price__gt=0  # Only paid plans count as pro
            ).first()
            
            if active_subscription:
                return True, active_subscription.end_date
        except ImportError:
            pass
        
        return False, None
    
    @classmethod
    def can_start_session(cls, user, request):
        """Check if user can start a new e-learning session"""
        if not user or user.is_anonymous:
            return False, "Authentication required"
        
        device_fingerprint = cls.generate_device_fingerprint(request)
        ip_address = cls.get_client_ip(request)
        
        # Check for existing active sessions
        active_sessions = ELearningSession.objects.filter(
            user=user,
            status='active'
        )
        
        # Check for concurrent sessions from different devices/IPs
        different_devices = active_sessions.exclude(
            device_fingerprint=device_fingerprint
        ).exists()
        
        different_ips = active_sessions.exclude(
            ip_address=ip_address
        ).exists()
        
        if different_devices or different_ips:
            # Log suspicious activity
            cls._log_suspicious_activity(
                user, 
                'concurrent_sessions',
                f"Attempted concurrent access from different device/IP",
                {
                    'current_device': device_fingerprint,
                    'current_ip': ip_address,
                    'active_sessions': list(active_sessions.values_list('device_fingerprint', 'ip_address'))
                }
            )
            return False, "Another session is already active from a different device or location"
        
        # Check device session limits
        device_session, created = DeviceSession.objects.get_or_create(
            device_fingerprint=device_fingerprint,
            defaults={
                'user': user,
                'device_name': request.META.get('HTTP_USER_AGENT', '')[:100],
                'browser_info': request.META.get('HTTP_USER_AGENT', ''),
            }
        )
        
        if not device_session.can_start_new_session():
            return False, "Maximum concurrent sessions reached for this device"
        
        return True, "Session can be started"
    
    @classmethod
    def start_session(cls, user, request, page_url):
        """Start a new e-learning session"""
        can_start, message = cls.can_start_session(user, request)
        if not can_start:
            return None, message
        
        device_fingerprint = cls.generate_device_fingerprint(request)
        ip_address = cls.get_client_ip(request)
        is_pro, subscription_end = cls.check_subscription_status(user)
        
        # End any existing active sessions for this user/device combination
        ELearningSession.objects.filter(
            user=user,
            device_fingerprint=device_fingerprint,
            status='active'
        ).update(status='terminated', ended_at=timezone.now())
        
        # Create new session
        session = ELearningSession.objects.create(
            user=user,
            session_key=request.session.session_key or '',
            device_fingerprint=device_fingerprint,
            ip_address=ip_address,
            user_agent=request.META.get('HTTP_USER_AGENT', ''),
            page_url=page_url,
            is_pro_user=is_pro,
            subscription_valid_until=subscription_end
        )
        
        # Update device session count
        device_session = DeviceSession.objects.get(device_fingerprint=device_fingerprint)
        device_session.increment_sessions()
        
        # Log session start
        SessionActivityLog.objects.create(
            session=session,
            action='session_start',
            ip_address=ip_address,
            details={
                'page_url': page_url,
                'is_pro': is_pro,
                'user_agent': request.META.get('HTTP_USER_AGENT', '')
            }
        )
        
        return session, "Session started successfully"
    
    @staticmethod
    def update_session_activity(session_id, activity_data):
        """Update session with new activity"""
        try:
            session = ELearningSession.objects.get(id=session_id, status='active')
            
            # Update session fields if provided
            if 'subject_id' in activity_data:
                session.subject_id = activity_data['subject_id']
            if 'current_video_id' in activity_data:
                session.current_video_id = activity_data['current_video_id']
            
            session.last_activity = timezone.now()
            session.save()
            
            # Log activity
            SessionActivityLog.objects.create(
                session=session,
                action=activity_data.get('action', 'page_access'),
                ip_address=activity_data.get('ip_address', session.ip_address),
                details=activity_data
            )
            
            return session
        except ELearningSession.DoesNotExist:
            return None
    
    @staticmethod
    def add_viewing_time(session_id, seconds_watched):
        """Add viewing time to session and check limits"""
        try:
            session = ELearningSession.objects.get(id=session_id, status='active')
            
            # Add viewing time and check limits
            can_continue = session.add_viewing_time(seconds_watched)
            
            if not can_continue and not session.is_pro_user:
                # Log time limit reached
                SessionActivityLog.objects.create(
                    session=session,
                    action='time_limit_reached',
                    ip_address=session.ip_address,
                    details={
                        'total_time': session.session_viewing_time,
                        'limit': 60
                    }
                )
                return session, False, "Time limit reached for non-pro users"
            
            return session, True, "Time updated successfully"
        except ELearningSession.DoesNotExist:
            return None, False, "Session not found"
    
    @staticmethod
    def end_session(session_id, reason='user_initiated'):
        """End an active session"""
        try:
            session = ELearningSession.objects.get(id=session_id)
            session.expire_session(reason)
            
            # Update device session count
            try:
                device_session = DeviceSession.objects.get(
                    device_fingerprint=session.device_fingerprint
                )
                device_session.decrement_sessions()
            except DeviceSession.DoesNotExist:
                pass
            
            # Log session end
            SessionActivityLog.objects.create(
                session=session,
                action='session_end',
                ip_address=session.ip_address,
                details={'reason': reason}
            )
            
            return True
        except ELearningSession.DoesNotExist:
            return False
    
    @classmethod
    def cleanup_expired_sessions(cls):
        """Clean up expired and inactive sessions"""
        timeout_threshold = timezone.now() - timedelta(minutes=30)
        
        # Find inactive sessions
        inactive_sessions = ELearningSession.objects.filter(
            status='active',
            last_activity__lt=timeout_threshold
        )
        
        # Update device session counts for inactive sessions
        for session in inactive_sessions:
            try:
                device_session = DeviceSession.objects.get(
                    device_fingerprint=session.device_fingerprint
                )
                device_session.decrement_sessions()
            except DeviceSession.DoesNotExist:
                pass
        
        # Mark sessions as inactive
        inactive_sessions.update(
            status='inactive',
            ended_at=timezone.now()
        )
        
        return inactive_sessions.count()
    
    @classmethod
    def detect_suspicious_activity(cls, user):
        """Detect and log suspicious activity patterns"""
        if not user or user.is_anonymous:
            return
        
        # Check for multiple devices in short time
        recent_sessions = ELearningSession.objects.filter(
            user=user,
            started_at__gte=timezone.now() - timedelta(hours=1)
        )
        
        unique_devices = recent_sessions.values_list(
            'device_fingerprint', flat=True
        ).distinct().count()
        
        if unique_devices > 3:
            cls._log_suspicious_activity(
                user,
                'multiple_devices',
                f"Used {unique_devices} different devices in 1 hour",
                {
                    'device_count': unique_devices,
                    'session_count': recent_sessions.count(),
                    'devices': list(recent_sessions.values_list('device_fingerprint', flat=True))
                }
            )
        
        # Check for rapid account switching
        recent_activities = SessionActivityLog.objects.filter(
            session__user=user,
            timestamp__gte=timezone.now() - timedelta(minutes=30),
            action='session_start'
        )
        
        if recent_activities.count() > 5:
            cls._log_suspicious_activity(
                user,
                'rapid_switching',
                f"Started {recent_activities.count()} sessions in 30 minutes",
                {
                    'session_starts': recent_activities.count(),
                    'timeframe': '30 minutes'
                }
            )
    
    @staticmethod
    def _log_suspicious_activity(user, activity_type, description, evidence):
        """Log suspicious activity"""
        SuspiciousActivity.objects.create(
            user=user,
            activity_type=activity_type,
            description=description,
            evidence=evidence,
            severity=5 if 'concurrent' in activity_type else 3
        )
    
    @staticmethod
    def get_session_status(session_id):
        """Get current session status and remaining time"""
        try:
            session = ELearningSession.objects.get(id=session_id)
            
            if not session.is_active():
                return {
                    'is_active': False,
                    'status': session.status,
                    'message': 'Session has expired or ended'
                }
            
            remaining_time = session.get_remaining_time()
            
            return {
                'is_active': True,
                'status': session.status,
                'is_pro': session.is_pro_user,
                'remaining_time': remaining_time,
                'total_viewing_time': session.session_viewing_time,
                'last_activity': session.last_activity
            }
        except ELearningSession.DoesNotExist:
            return {
                'is_active': False,
                'status': 'not_found',
                'message': 'Session not found'
            }
