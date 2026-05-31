import logging
import re
import time
import uuid

from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.conf import settings
from django.db.models import Q, Max
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.contrib.auth import get_user_model
from .models import (
    ChatRoom, Message, MessageReport, 
    BlockedUser, TypingStatus, OnlineStatus, ActiveChatSession, CallSession
)
from .serializers import (
    ChatRoomSerializer, MessageSerializer, MessageCreateSerializer,
    MessageReportSerializer, BlockedUserSerializer, 
    OnlineStatusSerializer, TypingStatusSerializer
)

User = get_user_model()
logger = logging.getLogger(__name__)

_CALL_TYPE_SET = {'audio', 'video'}
_CHANNEL_NAME_RE = re.compile(r'^[A-Za-z0-9_]{1,64}$')
_CALL_STATUS_ALIASES = {
    'declined': CallSession.STATUS_REJECTED,
    'no_answer': CallSession.STATUS_MISSED,
}


def _is_valid_channel_name(channel_name):
    return bool(channel_name and _CHANNEL_NAME_RE.match(str(channel_name)))


def _active_call_for_user(user):
    cutoff = timezone.now() - timezone.timedelta(seconds=90)
    return CallSession.objects.filter(
        Q(caller=user) | Q(callee=user),
        status__in=[CallSession.STATUS_RINGING, CallSession.STATUS_ACCEPTED],
        last_status_at__gte=cutoff,
    ).order_by('-last_status_at').first()


def _build_user_avatar_url(request, user):
    image_field = None
    if hasattr(user, 'image') and user.image:
        image_field = user.image
    elif hasattr(user, 'profile_image') and user.profile_image:
        image_field = user.profile_image

    if not image_field:
        return ''

    try:
        return request.build_absolute_uri(image_field.url)
    except Exception:
        return image_field.url


def _clean_call_display_name(value):
    value = str(value or '').strip()
    if not value or value.lower() == 'unknown':
        return ''
    if '@' in value:
        local_part = value.split('@', 1)[0].strip()
        if local_part:
            return local_part
    return value


def _build_call_display_name(request, user):
    full_name = _clean_call_display_name(user.get_full_name())
    if full_name:
        return full_name

    first_last = _clean_call_display_name(
        ' '.join(
            part.strip()
            for part in [
                getattr(user, 'first_name', '') or '',
                getattr(user, 'last_name', '') or '',
            ]
            if part and part.strip()
        )
    )
    if first_last:
        return first_last

    provided_name = _clean_call_display_name(request.data.get('caller_name'))
    if provided_name:
        return provided_name

    username = _clean_call_display_name(getattr(user, 'username', ''))
    if username:
        return username

    return 'AdsyClub user'


def _get_call_session_for_user(*, user, channel_name, call_id=None):
    queryset = CallSession.objects.filter(channel_name=channel_name).filter(
        Q(caller=user) | Q(callee=user)
    )
    if call_id:
        queryset = queryset.filter(id=call_id)
    return queryset.order_by('-started_at').first()


def _to_int(value, default=0):
    try:
        return int(str(value).strip())
    except (TypeError, ValueError):
        return default


def _build_agora_rtc_token(*, channel_name, uid, role='publisher'):
    app_id = str(getattr(settings, 'AGORA_APP_ID', '') or '').strip()
    app_certificate = str(
        getattr(settings, 'AGORA_APP_CERTIFICATE', '') or ''
    ).strip()
    expire_seconds = max(
        60,
        _to_int(getattr(settings, 'AGORA_TOKEN_EXPIRE_SECONDS', 3600), 3600),
    )

    if not app_id:
        raise ValueError('AGORA_APP_ID is not configured')

    if not app_certificate:
        return {
            'app_id': app_id,
            'token': '',
            'token_required': False,
            'expires_at': None,
        }

    try:
        from agora_token_builder.RtcTokenBuilder import (
            Role_Publisher,
            Role_Subscriber,
            RtcTokenBuilder,
        )
    except ImportError as exc:
        raise RuntimeError(
            'agora-token-builder package is required when '
            'AGORA_APP_CERTIFICATE is configured'
        ) from exc

    role_value = (
        Role_Publisher
        if str(role).lower() == 'publisher'
        else Role_Subscriber
    )
    expires_at = int(time.time()) + expire_seconds
    token = RtcTokenBuilder.buildTokenWithUid(
        app_id,
        app_certificate,
        str(channel_name),
        int(uid),
        role_value,
        expires_at,
    )

    return {
        'app_id': app_id,
        'token': token,
        'token_required': True,
        'expires_at': expires_at,
    }


def _send_call_data_message(*, target_user, payload):
    from base.models import FCMToken

    success_count = 0
    total_tokens = 0
    last_send_error = None
    voip_result = _send_voip_call_pushes(target_user=target_user, payload=payload)

    try:
        import os
        import datetime
        from django.conf import settings
        import firebase_admin
        from firebase_admin import credentials, messaging

        if not firebase_admin._apps:
            cred_path = os.path.join(settings.BASE_DIR, 'firebase-adminsdk.json')
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)

        fcm_tokens = FCMToken.objects.filter(user=target_user, is_active=True)
        total_tokens = fcm_tokens.count()

        for fcm_token in fcm_tokens:
            try:
                if str(fcm_token.token or '').startswith('voip:'):
                    continue

                # Bug fix: enforce ALL payload values are strings.
                str_payload = {k: str(v) if v is not None else '' for k, v in payload.items()}

                channel_name_val = str_payload.get('channel_name', '')
                collapse_key = f"call_{channel_name_val}" if channel_name_val else None

                # iOS vs Android split:
                # Android: data-only message → Dart background isolate fires → shows local
                #   notification + CallKit. Adding notification= would skip the isolate.
                # iOS: data-only / silent push is throttled by Apple to a few per hour and
                #   is NEVER delivered to a killed app. We must send notification+data so
                #   APNs delivers it as an alert. The Flutter foreground handler still reads
                #   message.data and navigates to the call screen when the app is live.
                is_ios = fcm_token.device_type == 'ios'

                caller_name = _clean_call_display_name(
                    str_payload.get('caller_name')
                ) or 'AdsyClub user'
                call_type = str_payload.get('call_type', 'audio')
                call_type_label = 'Video Call' if call_type == 'video' else 'Voice Call'

                if is_ios:
                    message = messaging.Message(
                        data=str_payload,
                        notification=messaging.Notification(
                            title=f'{caller_name} is calling',
                            body=call_type_label,
                        ),
                        android=messaging.AndroidConfig(
                            priority='high',
                            ttl=datetime.timedelta(seconds=60),
                            collapse_key=collapse_key,
                        ),
                        # iOS: apns-push-type=alert delivers as a visible notification.
                        # content_available=True is kept so the app can handle the call
                        # if it's already running in background.
                        # mutable_content=True allows a notification service extension
                        # to intercept and trigger CallKit in future (VoIP upgrade path).
                        apns=messaging.APNSConfig(
                            headers={
                                'apns-push-type': 'alert',
                                'apns-priority': '10',
                                'apns-collapse-id': collapse_key or '',
                            },
                            payload=messaging.APNSPayload(
                                aps=messaging.Aps(
                                    sound='default',
                                    content_available=True,
                                    mutable_content=True,
                                    category='INCOMING_CALL',
                                ),
                            ),
                        ),
                        token=fcm_token.token,
                    )
                else:
                    message = messaging.Message(
                        data=str_payload,
                        android=messaging.AndroidConfig(
                            priority='high',
                            ttl=datetime.timedelta(seconds=60),
                            collapse_key=collapse_key,
                        ),
                        apns=messaging.APNSConfig(
                            headers={
                                'apns-push-type': 'background',
                                'apns-priority': '5',
                            },
                            payload=messaging.APNSPayload(
                                aps=messaging.Aps(content_available=True),
                            ),
                        ),
                        token=fcm_token.token,
                    )

                messaging.send(message)
                success_count += 1
            except Exception as exc:
                last_send_error = str(exc)
                logger.warning(
                    'Failed to send AdsyConnect call FCM to token %s...: %s',
                    fcm_token.token[:20],
                    exc,
                )
    except Exception as exc:
        last_send_error = str(exc)
        logger.warning('AdsyConnect call FCM fallback failed: %s', exc)

    return {
        'sent_to': success_count,
        'total_tokens': total_tokens,
        'fcm_error': last_send_error,
        **voip_result,
    }


def _broadcast_to_user(user_id, event):
    channel_layer = get_channel_layer()
    if channel_layer is None:
        return
    try:
        async_to_sync(channel_layer.group_send)(f'user_{user_id}', event)
    except Exception as exc:
        logger.warning(
            'AdsyConnect broadcast failed for user %s and event %s: %s',
            user_id,
            event.get('type'),
            exc,
        )


def _call_event_metadata():
    return {
        'event_id': str(uuid.uuid4()),
        'timestamp': str(int(time.time() * 1000)),
    }


def _build_callkit_voip_payload(payload):
    call_type = str(payload.get('call_type') or 'audio')
    caller_name = _clean_call_display_name(payload.get('caller_name')) or 'AdsyClub user'
    callkit_id = str(uuid.uuid4())
    return {
        'id': callkit_id,
        'nameCaller': caller_name,
        'appName': 'AdsyClub',
        'avatar': str(payload.get('caller_avatar') or ''),
        'handle': 'Video Call' if call_type == 'video' else 'Voice Call',
        'type': 1 if call_type == 'video' else 0,
        'duration': 60000,
        'extra': {k: str(v) if v is not None else '' for k, v in payload.items()},
    }


def _send_voip_call_pushes(*, target_user, payload):
    if payload.get('type') != 'incoming_call':
        return {'voip_sent_to': 0, 'voip_total_tokens': 0, 'voip_error': None}

    from base.models import FCMToken
    from .apns_voip import send_voip_push

    tokens = FCMToken.objects.filter(
        user=target_user,
        is_active=True,
        device_type='ios',
    ).exclude(voip_token='')
    total_tokens = tokens.count()
    success_count = 0
    last_error = None
    callkit_payload = _build_callkit_voip_payload(payload)
    collapse_id = payload.get('channel_name') or payload.get('call_id')

    for token in tokens:
        try:
            result = send_voip_push(
                token.voip_token,
                callkit_payload,
                collapse_id=collapse_id,
                environment=token.voip_environment,
            )
            if result.get('sent'):
                success_count += 1
            elif result.get('error'):
                last_error = result.get('error')
        except Exception as exc:
            last_error = str(exc)
            logger.warning('Failed to send AdsyConnect VoIP push: %s', exc)

    return {
        'voip_sent_to': success_count,
        'voip_total_tokens': total_tokens,
        'voip_error': last_error,
    }


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def firebase_custom_token(request):
    try:
        import os
        from django.conf import settings
        import firebase_admin
        from firebase_admin import credentials, auth

        if not firebase_admin._apps:
            cred_path = os.path.join(settings.BASE_DIR, 'firebase-adminsdk.json')
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)

        uid = str(request.user.id)
        token_bytes = auth.create_custom_token(uid)
        token = token_bytes.decode('utf-8') if hasattr(token_bytes, 'decode') else str(token_bytes)
        return Response({'token': token, 'uid': uid})
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def agora_rtc_token(request):
    """Return a scoped Agora RTC token for an active call channel.

    The mobile app may run against Agora projects with token security disabled
    during development. In that case this endpoint returns an empty token with
    token_required=false so existing no-token channels continue to work.
    """
    try:
        channel_name = request.data.get('channel_name')
        uid = _to_int(request.data.get('uid'))
        call_id = request.data.get('call_id')
        role = request.data.get('role') or 'publisher'

        if not channel_name or not uid:
            return Response(
                {'error': 'channel_name and uid are required'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if not _is_valid_channel_name(channel_name):
            return Response(
                {'error': 'Invalid channel_name'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        call_session = _get_call_session_for_user(
            user=request.user,
            channel_name=str(channel_name),
            call_id=call_id,
        )
        if call_session is None:
            return Response(
                {'error': 'Call session not found'},
                status=status.HTTP_404_NOT_FOUND,
            )
        if call_session.status in CallSession.TERMINAL_STATUSES:
            return Response(
                {'error': 'Call session has ended'},
                status=status.HTTP_409_CONFLICT,
            )

        token_data = _build_agora_rtc_token(
            channel_name=channel_name,
            uid=uid,
            role=role,
        )
        return Response({
            'success': True,
            'call_id': str(call_session.id),
            'channel_name': str(call_session.channel_name),
            'uid': uid,
            **token_data,
        })
    except Exception as e:
        logger.exception('Agora token generation failed')
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_call_notification(request):
    """Create a call session and deliver the ringing signal."""
    try:
        callee_id = request.data.get('callee_id')
        channel_name = request.data.get('channel_name')
        call_type = str(request.data.get('call_type', 'audio')).lower()
        if call_type not in _CALL_TYPE_SET:
            call_type = 'audio'

        if not callee_id or not channel_name:
            return Response({'error': 'callee_id and channel_name are required'}, status=status.HTTP_400_BAD_REQUEST)
        if not _is_valid_channel_name(channel_name):
            return Response({'error': 'Invalid channel_name'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            callee = User.objects.get(id=callee_id)
        except User.DoesNotExist:
            return Response({'error': 'Callee not found'}, status=status.HTTP_404_NOT_FOUND)

        caller = request.user
        if caller == callee:
            return Response({'error': 'Cannot call yourself'}, status=status.HTTP_400_BAD_REQUEST)

        caller_active_call = _active_call_for_user(caller)
        if caller_active_call:
            return Response(
                {
                    'error': 'You already have an active call',
                    'active_call_id': str(caller_active_call.id),
                },
                status=status.HTTP_409_CONFLICT,
            )

        callee_active_call = _active_call_for_user(callee)
        if callee_active_call:
            busy_payload = {
                'type': 'call_status',
                'call_id': str(callee_active_call.id),
                'channel_name': str(channel_name),
                'call_type': call_type,
                'status': CallSession.STATUS_BUSY,
                'sender_id': str(callee.id),
                'receiver_id': str(caller.id),
                **_call_event_metadata(),
            }
            _broadcast_to_user(
                caller.id,
                {
                    'type': 'call_status_event',
                    'payload': busy_payload,
                },
            )
            return Response(
                {
                    'error': 'Recipient is busy',
                    'status': CallSession.STATUS_BUSY,
                    'active_call_id': str(callee_active_call.id),
                },
                status=status.HTTP_409_CONFLICT,
            )

        provided_call_id = request.data.get('call_id')
        session_kwargs = {
            'channel_name': str(channel_name),
            'caller': caller,
            'callee': callee,
            'call_type': call_type,
            'status': CallSession.STATUS_RINGING,
        }
        if provided_call_id:
            session_kwargs['id'] = provided_call_id
        call_session = CallSession.objects.create(**session_kwargs)

        caller_name = _build_call_display_name(request, caller)
        caller_avatar = _build_user_avatar_url(request, caller)

        payload = {
            'type': 'incoming_call',
            'call_id': str(call_session.id),
            'channel_name': str(call_session.channel_name),
            'caller_id': str(caller.id),
            'caller_name': caller_name,
            'call_type': call_session.call_type,
            'caller_avatar': caller_avatar or '',
            **_call_event_metadata(),
        }

        _broadcast_to_user(
            callee.id,
            {
                'type': 'incoming_call_event',
                'payload': payload,
            },
        )
        delivery_result = _send_call_data_message(target_user=callee, payload=payload)

        return Response({
            'success': True,
            'call_id': str(call_session.id),
            'status': call_session.status,
            'sent_to_ws': True,
            **delivery_result,
        })
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_call_status(request):
    """Update an existing call session and deliver the status signal."""
    try:
        receiver_id = request.data.get('receiver_id')
        channel_name = request.data.get('channel_name')
        call_type = str(request.data.get('call_type', 'audio')).lower()
        if call_type not in _CALL_TYPE_SET:
            call_type = 'audio'
        status_value = str(request.data.get('status')).lower()
        status_value = _CALL_STATUS_ALIASES.get(status_value, status_value)
        call_id = request.data.get('call_id')

        if not receiver_id or not channel_name or not status_value:
            return Response(
                {'error': 'receiver_id, channel_name and status are required'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if not _is_valid_channel_name(channel_name):
            return Response({'error': 'Invalid channel_name'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            receiver = User.objects.get(id=receiver_id)
        except User.DoesNotExist:
            return Response({'error': 'Receiver not found'}, status=status.HTTP_404_NOT_FOUND)

        sender = request.user
        call_session = _get_call_session_for_user(
            user=sender,
            channel_name=str(channel_name),
            call_id=call_id,
        )

        if call_session:
            call_session.update_status(str(status_value))
            call_type = call_session.call_type

        payload = {
            'type': 'call_status',
            'event_id': str(uuid.uuid4()),
            'channel_name': str(channel_name),
            'call_type': str(call_type),
            'status': str(status_value),
            'sender_id': str(sender.id),
            'receiver_id': str(receiver.id),
            'timestamp': str(int(time.time() * 1000)),
        }
        if call_session:
            payload['call_id'] = str(call_session.id)
        elif call_id:
            payload['call_id'] = str(call_id)

        _broadcast_to_user(
            receiver.id,
            {
                'type': 'call_status_event',
                'payload': payload,
            },
        )
        delivery_result = _send_call_data_message(target_user=receiver, payload=payload)

        return Response({
            'success': True,
            'call_id': str(call_session.id) if call_session else None,
            'status': str(status_value),
            'sent_to_ws': True,
            **delivery_result,
        })
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def _sync_blocked_chatrooms(blocker, blocked, *, is_blocked):
    chatrooms = ChatRoom.objects.filter(
        Q(user1=blocker, user2=blocked) | Q(user1=blocked, user2=blocker)
    )
    if is_blocked:
        chatrooms.update(
            is_blocked=True,
            blocked_by=blocker,
            blocked_at=timezone.now(),
        )
        return

    chatrooms.filter(blocked_by=blocker).update(
        is_blocked=False,
        blocked_by=None,
        blocked_at=None,
    )


class ChatRoomViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing chat rooms
    """
    serializer_class = ChatRoomSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['user1__username', 'user2__username']
    ordering_fields = ['last_message_at', 'created_at']
    ordering = ['-last_message_at']
    pagination_class = None  # Disable pagination to return direct list
    
    def get_queryset(self):
        """Get chat rooms for current user"""
        user = self.request.user
        return ChatRoom.objects.filter(
            Q(user1=user) | Q(user2=user)
        ).select_related('user1', 'user2', 'blocked_by')
    
    @action(detail=False, methods=['post'])
    def get_or_create(self, request):
        """Get or create a chat room with another user"""
        other_user_id = request.data.get('user_id')
        
        if not other_user_id:
            return Response(
                {'error': 'user_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validate UUID format
        import uuid as uuid_lib
        try:
            uuid_lib.UUID(str(other_user_id))
        except (ValueError, TypeError, AttributeError):
            return Response(
                {'error': 'Invalid user_id format (must be valid UUID)'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if user is trying to chat with themselves
        if str(other_user_id) == str(request.user.id):
            return Response(
                {'error': 'Cannot create chat with yourself'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if other user exists
        try:
            other_user = User.objects.get(id=other_user_id)
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        block = BlockedUser.objects.filter(
            Q(blocker=request.user, blocked=other_user) |
            Q(blocker=other_user, blocked=request.user)
        ).first()
        
        # Get or create chat room (ensure no duplicates)
        chatroom = ChatRoom.objects.filter(
            Q(user1=request.user, user2=other_user) |
            Q(user1=other_user, user2=request.user)
        ).first()
        
        if not chatroom:
            chatroom = ChatRoom.objects.create(
                user1=request.user,
                user2=other_user
            )

        if block:
            chatroom.is_blocked = True
            chatroom.blocked_by = block.blocker
            chatroom.blocked_at = block.created_at
            chatroom.save(
                update_fields=[
                    'is_blocked',
                    'blocked_by',
                    'blocked_at',
                    'updated_at',
                ]
            )
        
        serializer = self.get_serializer(chatroom)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def mark_as_read(self, request, pk=None):
        """Mark all messages in chat room as read"""
        chatroom = self.get_object()
        read_at = timezone.now()
        unread_messages = list(
            Message.objects.filter(
                chatroom=chatroom,
                is_read=False,
            )
            .exclude(sender=request.user)
            .values_list('id', 'sender_id')
        )
        
        # Mark all unread messages from other user as read
        Message.objects.filter(
            chatroom=chatroom,
            is_read=False
        ).exclude(sender=request.user).update(
            is_read=True,
            read_at=read_at
        )

        for message_id, sender_id in unread_messages:
            _broadcast_to_user(
                sender_id,
                {
                    'type': 'message_read_update',
                    'message_id': str(message_id),
                    'chatroom_id': str(chatroom.id),
                    'read_at': read_at.isoformat(),
                },
            )
        
        return Response({'status': 'messages marked as read'})
    
    @action(detail=True, methods=['post'])
    def block(self, request, pk=None):
        """Block a chat room"""
        chatroom = self.get_object()
        other_user = chatroom.get_other_user(request.user)
        
        # Create blocked user entry
        BlockedUser.objects.get_or_create(
            blocker=request.user,
            blocked=other_user
        )
        
        # Update chatroom
        chatroom.is_blocked = True
        chatroom.blocked_by = request.user
        chatroom.blocked_at = timezone.now()
        chatroom.save()
        _sync_blocked_chatrooms(request.user, other_user, is_blocked=True)
        
        return Response({'status': 'user blocked'})
    
    @action(detail=True, methods=['post'])
    def unblock(self, request, pk=None):
        """Unblock a chat room"""
        chatroom = self.get_object()
        other_user = chatroom.get_other_user(request.user)
        
        # Remove blocked user entry
        BlockedUser.objects.filter(
            blocker=request.user,
            blocked=other_user
        ).delete()
        
        # Update chatroom
        chatroom.is_blocked = False
        chatroom.blocked_by = None
        chatroom.blocked_at = None
        chatroom.save()
        _sync_blocked_chatrooms(request.user, other_user, is_blocked=False)
        
        return Response({'status': 'user unblocked'})


class MessageViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing messages
    """
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['created_at']
    ordering = ['created_at']
    pagination_class = None  # Disable pagination for messages to return direct list
    
    def get_serializer_class(self):
        if self.action == 'create':
            return MessageCreateSerializer
        return MessageSerializer
    
    def get_queryset(self):
        """Get messages for current user (includes deleted messages)"""
        user = self.request.user
        chatroom_id = self.request.query_params.get('chatroom')
        
        # Return all messages including deleted ones
        # Frontend will show "Message removed" for deleted messages
        queryset = Message.objects.filter(
            Q(sender=user) | Q(receiver=user)
        ).select_related('sender', 'receiver', 'chatroom')
        
        if chatroom_id:
            queryset = queryset.filter(chatroom_id=chatroom_id)
        
        return queryset
    
    def create(self, request, *args, **kwargs):
        """Create a new message and return full serialization"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        message = serializer.save(sender=request.user)
        
        # Update chatroom's last message
        chatroom = message.chatroom
        chatroom.last_message_at = message.created_at
        chatroom.last_message_preview = message.get_preview()
        chatroom.save()
        
        # Send push notification to receiver (only if they're not in this chat)
        try:
            is_receiver_in_chat = ActiveChatSession.is_user_in_chat(message.receiver, chatroom)
            
            if is_receiver_in_chat:
                print(f'📍 Skipping push notification - receiver is in this chat')
            else:
                from base.fcm_service import send_message_notification
                
                sender_name = request.user.get_full_name() or request.user.username or request.user.email
                print(f'📤 Attempting to send chat notification to {message.receiver.email}')
                send_message_notification(
                    recipient_user=message.receiver,
                    sender_user=request.user,
                    sender_name=sender_name,
                    message_text=message.get_preview(),
                    chat_id=str(chatroom.id)
                )
                print(f'✅ Chat notification sent to {message.receiver.email}')
        except Exception as e:
            print(f'❌ Error sending chat notification: {e}')
            import traceback
            traceback.print_exc()
        
        # Return full message serialization with all fields
        output_serializer = MessageSerializer(message, context={'request': request})
        _broadcast_to_user(
            message.receiver_id,
            {
                'type': 'new_message',
                'message': output_serializer.data,
            },
        )
        return Response(output_serializer.data, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """Mark a message as read"""
        message = self.get_object()
        
        if message.receiver == request.user:
            message.mark_as_read()
            _broadcast_to_user(
                message.sender_id,
                {
                    'type': 'message_read_update',
                    'message_id': str(message.id),
                    'chatroom_id': str(message.chatroom_id),
                    'read_at': message.read_at.isoformat() if message.read_at else None,
                },
            )
            return Response({'status': 'message marked as read'})
        
        return Response(
            {'error': 'You can only mark messages sent to you as read'},
            status=status.HTTP_403_FORBIDDEN
        )
    
    def destroy(self, request, *args, **kwargs):
        """Soft delete a message (marks as deleted, doesn't actually delete)"""
        message = self.get_object()
        
        # Only sender can delete their own messages
        if message.sender != request.user:
            return Response(
                {'error': 'You can only delete your own messages'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Soft delete the message
        message.soft_delete()
        
        # Return the updated message data so frontend can update UI immediately
        serializer = self.get_serializer(message)
        return Response(serializer.data, status=status.HTTP_200_OK)
    
    @action(detail=True, methods=['patch'])
    def edit(self, request, pk=None):
        """Edit a text message"""
        message = self.get_object()
        
        # Only sender can edit their own messages
        if message.sender != request.user:
            return Response(
                {'error': 'You can only edit your own messages'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Only text messages can be edited
        if message.message_type != 'text':
            return Response(
                {'error': 'Only text messages can be edited'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Cannot edit deleted messages
        if message.is_deleted:
            return Response(
                {'error': 'Cannot edit deleted messages'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        new_content = request.data.get('content', '').strip()
        if not new_content:
            return Response(
                {'error': 'Content is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Update the message
        message.content = new_content
        message.is_edited = True
        message.edited_at = timezone.now()
        message.save(update_fields=['content', 'is_edited', 'edited_at', 'updated_at'])
        
        serializer = self.get_serializer(message)
        return Response(serializer.data, status=status.HTTP_200_OK)


class MessageReportViewSet(viewsets.ModelViewSet):
    """
    ViewSet for reporting messages/users
    """
    serializer_class = MessageReportSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Get reports made by current user"""
        return MessageReport.objects.filter(
            reporter=self.request.user
        ).select_related('reporter', 'reported_user', 'message')
    
    def perform_create(self, serializer):
        """Create a new report"""
        serializer.save(reporter=self.request.user)


class BlockedUserViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing blocked users
    """
    serializer_class = BlockedUserSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'post', 'delete']
    
    def get_queryset(self):
        """Get users blocked by current user"""
        return BlockedUser.objects.filter(
            blocker=self.request.user
        ).select_related('blocker', 'blocked')
    
    def perform_create(self, serializer):
        """Block a user and notify admin (Apple App Store Guideline 1.2)"""
        instance = serializer.save(blocker=self.request.user)
        _sync_blocked_chatrooms(
            self.request.user,
            instance.blocked,
            is_blocked=True,
        )
        try:
            from base.email_service import notify_admin_user_blocked
            notify_admin_user_blocked(
                blocker=self.request.user,
                blocked_user=instance.blocked,
                reason=self.request.data.get('reason', ''),
            )
        except Exception:
            pass  # Never let email failure break the block action
    
    @action(detail=False, methods=['post'])
    def unblock(self, request):
        """Unblock a user"""
        blocked_user_id = request.data.get('user_id')
        
        if not blocked_user_id:
            return Response(
                {'error': 'user_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        BlockedUser.objects.filter(
            blocker=request.user,
            blocked_id=blocked_user_id
        ).delete()
        try:
            blocked_user = User.objects.get(id=blocked_user_id)
            _sync_blocked_chatrooms(
                request.user,
                blocked_user,
                is_blocked=False,
            )
        except User.DoesNotExist:
            pass
        
        return Response({'status': 'user unblocked'})


class OnlineStatusViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for checking online status
    """
    serializer_class = OnlineStatusSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Get online status for users"""
        user_ids = self.request.query_params.getlist('user_ids[]')
        
        if user_ids:
            # Create OnlineStatus records for users who don't have one
            for user_id in user_ids:
                try:
                    OnlineStatus.objects.get_or_create(
                        user_id=user_id,
                        defaults={'is_online': False, 'last_seen': timezone.now()}
                    )
                except Exception:
                    pass
            
            return OnlineStatus.objects.filter(
                user_id__in=user_ids
            ).select_related('user')
        
        return OnlineStatus.objects.none()
    
    @action(detail=False, methods=['post'])
    def update_status(self, request):
        """Update current user's online status"""
        is_online = request.data.get('is_online', True)

        if isinstance(is_online, str):
            is_online = is_online.strip().lower() in {'true', '1', 'yes'}
        else:
            is_online = bool(is_online)
        
        online_status, created = OnlineStatus.objects.get_or_create(
            user=request.user,
            defaults={'is_online': is_online, 'last_seen': timezone.now()}
        )
        online_status.set_presence(is_online)
        
        return Response({'status': 'online status updated'})


class TypingStatusViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing typing status
    """
    serializer_class = TypingStatusSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'post', 'patch']
    
    def get_queryset(self):
        """Get typing status for a chatroom"""
        chatroom_id = self.request.query_params.get('chatroom')
        
        if chatroom_id:
            return TypingStatus.objects.filter(
                chatroom_id=chatroom_id
            ).exclude(user=self.request.user).select_related('user')
        
        return TypingStatus.objects.none()
    
    @action(detail=False, methods=['post'])
    def update_typing(self, request):
        """Update typing status"""
        chatroom_id = request.data.get('chatroom')
        is_typing = request.data.get('is_typing', False)

        if isinstance(is_typing, str):
            is_typing = is_typing.strip().lower() in {'true', '1', 'yes'}
        else:
            is_typing = bool(is_typing)
        
        if not chatroom_id:
            return Response(
                {'error': 'chatroom is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        typing_status, created = TypingStatus.objects.get_or_create(
            chatroom_id=chatroom_id,
            user=request.user
        )
        typing_status.is_typing = is_typing
        typing_status.save()

        try:
            chatroom = ChatRoom.objects.select_related('user1', 'user2').get(id=chatroom_id)
            other_user = chatroom.get_other_user(request.user)
            _broadcast_to_user(
                other_user.id,
                {
                    'type': 'typing_status_update',
                    'chatroom_id': str(chatroom_id),
                    'user_id': str(request.user.id),
                    'is_typing': is_typing,
                },
            )
        except ChatRoom.DoesNotExist:
            pass
        
        return Response({'status': 'typing status updated'})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def set_active_chat(request):
    """Set user's active chat session - prevents push notifications when in chat"""
    chatroom_id = request.data.get('chatroom_id')
    
    if not chatroom_id:
        ActiveChatSession.clear_active_chat(request.user)
        OnlineStatus.objects.update_or_create(
            user=request.user,
            defaults={'is_online': True, 'last_seen': timezone.now()}
        )
        return Response({'status': 'active chat cleared'})
    
    try:
        chatroom = ChatRoom.objects.get(id=chatroom_id)
        if chatroom.user1 != request.user and chatroom.user2 != request.user:
            return Response(
                {'error': 'You are not a participant of this chat'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        ActiveChatSession.set_active_chat(request.user, chatroom)
        OnlineStatus.objects.update_or_create(
            user=request.user,
            defaults={'is_online': True, 'last_seen': timezone.now()}
        )
        return Response({'status': 'active chat set', 'chatroom_id': str(chatroom_id)})
    except ChatRoom.DoesNotExist:
        return Response(
            {'error': 'Chatroom not found'},
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def clear_active_chat(request):
    """Clear user's active chat session"""
    ActiveChatSession.clear_active_chat(request.user)
    return Response({'status': 'active chat cleared'})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def heartbeat(request):
    """Update user's online status - call periodically to stay online"""
    online_status, _ = OnlineStatus.objects.get_or_create(
        user=request.user,
        defaults={'is_online': True, 'last_seen': timezone.now()}
    )
    online_status.set_presence(True)
    return Response({'status': 'online', 'timestamp': timezone.now().isoformat()})
