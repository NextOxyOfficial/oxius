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
from django.db.models import F, Q, Max
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.contrib.auth import get_user_model
from .models import (
    ChatRoom, Message, MessageReport,
    BlockedUser, TypingStatus, OnlineStatus, ActiveChatSession, CallSession,
    ChatGroup, ChatGroupMembership, GroupMessage
)
from .serializers import (
    ChatRoomSerializer, MessageSerializer, MessageCreateSerializer,
    MessageReportSerializer, BlockedUserSerializer,
    OnlineStatusSerializer, TypingStatusSerializer,
    ChatGroupSerializer, GroupMessageSerializer
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
    # Any session on this channel where the requester is a participant.
    base_qs = CallSession.objects.filter(channel_name=channel_name).filter(
        Q(caller=user) | Q(callee=user)
    )

    # Prefer an exact call_id match when one is supplied, but DO NOT let a
    # stale/mismatched call_id block a legitimate participant: if the id match
    # finds nothing, fall back to the latest session on this channel. The
    # client occasionally sends an outdated call_id (e.g. the incoming-call
    # push and the WebSocket event carry different ids, or a previous call's id
    # lingers in state). Without this fallback the token request 404s and the
    # join silently fails — the other side just sees "Connecting…" forever.
    if call_id:
        session = base_qs.filter(id=call_id).order_by('-started_at').first()
        if session is not None:
            return session

    return base_qs.order_by('-started_at').first()


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
                # CRITICAL: an incoming_call ring and a terminal call_status
                # (cancel/missed/ended) must NOT share a collapse_key. FCM keeps
                # only the LAST message per collapse_key while a device is
                # offline/Doze (app killed). If they shared one, a quick
                # caller-side cancel would replace the still-undelivered
                # incoming_call and the callee's phone would never ring.
                msg_type = str_payload.get('type', '')
                if channel_name_val:
                    _ck_prefix = 'callstatus' if msg_type == 'call_status' else 'call'
                    collapse_key = f"{_ck_prefix}_{channel_name_val}"
                else:
                    collapse_key = None

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


def _can_message(sender, recipient):
    """Enforce the recipient's who_can_message privacy for a NEW conversation.
    Returns (allowed: bool, reason: str)."""
    pref = getattr(recipient, 'who_can_message', 'everyone') or 'everyone'
    if pref == 'everyone':
        return True, ''
    from business_network.models import BusinessNetworkFollowerModel as F_

    sender_follows_recipient = F_.objects.filter(
        follower=sender, following=recipient
    ).exists()
    recipient_follows_sender = F_.objects.filter(
        follower=recipient, following=sender
    ).exists()

    if pref == 'followers':  # only people who follow the recipient
        ok = sender_follows_recipient
    elif pref == 'following':  # only people the recipient follows
        ok = recipient_follows_sender
    elif pref == 'mutual':
        ok = sender_follows_recipient and recipient_follows_sender
    else:
        ok = True
    if ok:
        return True, ''
    return False, 'এই ব্যবহারকারী শুধু নির্দিষ্ট মানুষের মেসেজ গ্রহণ করেন।'


def _receiver_follows_sender(message):
    """True when the message receiver follows the sender — used to spare
    trusted senders from the spam filter."""
    from business_network.models import BusinessNetworkFollowerModel as F_

    return F_.objects.filter(
        follower_id=message.receiver_id, following_id=message.sender_id
    ).exists()


def _json_safe(value):
    """Recursively convert UUIDs/datetimes to strings so the channel layer's
    msgpack/json encoder never chokes. Group-message broadcasts carried raw
    UUID objects from serializer .data and SILENTLY failed — realtime group
    delivery was down and clients only saw new messages via polling."""
    import datetime as _dt

    if isinstance(value, dict):
        return {k: _json_safe(v) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [_json_safe(v) for v in value]
    if isinstance(value, (uuid.UUID, _dt.datetime, _dt.date)):
        return str(value)
    return value


def _broadcast_to_user(user_id, event):
    channel_layer = get_channel_layer()
    if channel_layer is None:
        return
    try:
        async_to_sync(channel_layer.group_send)(
            f'user_{user_id}', _json_safe(event)
        )
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


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def agora_config(request):
    """Expose the Agora project the backend is configured for, so the app can
    source the App ID from server settings instead of hardcoding it.

    Returns the App ID and whether tokens are required (i.e. whether the project
    has an App Certificate). The App ID is not secret — it ships in every RTC
    client regardless — so exposing it is safe.
    """
    app_id = str(getattr(settings, 'AGORA_APP_ID', '') or '').strip()
    app_certificate = str(
        getattr(settings, 'AGORA_APP_CERTIFICATE', '') or ''
    ).strip()
    return Response(
        {
            'app_id': app_id,
            'token_required': bool(app_certificate),
        }
    )


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
        """Get chat rooms for current user.

        By default the main list hides rooms this user archived; pass
        ?archived=true to get ONLY the archived ones (the Archived tab).
        """
        user = self.request.user
        qs = ChatRoom.objects.filter(
            Q(user1=user) | Q(user2=user)
        ).select_related('user1', 'user2', 'blocked_by')

        # The archived split only makes sense for the list view. Detail actions
        # (retrieve, archive/unarchive, mute, …) must still resolve an archived
        # room by id — otherwise unarchiving it would 404 (it's archived, so a
        # filtered queryset would exclude it).
        if self.action != 'list':
            return qs

        archived_param = str(
            self.request.query_params.get('archived', '')
        ).lower()
        want_archived = archived_param in ('1', 'true', 'yes')
        # A room is archived FOR THIS USER if their side's flag is set.
        mine_archived = (
            Q(user1=user, archived_by_user1=True)
            | Q(user2=user, archived_by_user2=True)
        )
        if want_archived:
            qs = qs.filter(mine_archived)
        else:
            qs = qs.exclude(mine_archived)

        # Per-user delete ("চ্যাট মুছুন" = clear): a cleared room must STAY
        # OUT of the list until NEW activity arrives after the clear point.
        # Without this the app removed the row locally but the next 4s poll
        # resurrected it from this endpoint.
        cleared_hidden = (
            Q(user1=user, cleared_at_user1__isnull=False)
            & Q(last_message_at__lte=F('cleared_at_user1'))
        ) | (
            Q(user2=user, cleared_at_user2__isnull=False)
            & Q(last_message_at__lte=F('cleared_at_user2'))
        )
        qs = qs.exclude(cleared_hidden)
        return qs

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
        
        # Check if user is trying to chat with themselves — plain Bangla text;
        # the app shows this message directly (no raw status/body).
        if str(other_user_id) == str(request.user.id):
            return Response(
                {'error': 'নিজের সাথে চ্যাট করা যায় না।'},
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

        # Privacy: honour the target's "who can message me" setting, but only
        # when opening a BRAND NEW conversation (an existing thread stays open).
        if not chatroom:
            allowed, reason = _can_message(request.user, other_user)
            if not allowed:
                return Response({'error': reason},
                                status=status.HTTP_403_FORBIDDEN)
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

    @action(detail=True, methods=['post'])
    def archive(self, request, pk=None):
        """Toggle archive for the calling user. Body: {archived: bool}."""
        chatroom = self.get_object()
        if request.user not in (chatroom.user1, chatroom.user2):
            return Response({'error': 'Not a participant'},
                            status=status.HTTP_403_FORBIDDEN)
        value = bool(request.data.get('archived', True))
        chatroom.set_archived(request.user, value)
        return Response({'status': 'ok', 'archived': value})

    @action(detail=True, methods=['post'])
    def mute(self, request, pk=None):
        """Toggle mute (no push) for the calling user. Body: {muted: bool}."""
        chatroom = self.get_object()
        if request.user not in (chatroom.user1, chatroom.user2):
            return Response({'error': 'Not a participant'},
                            status=status.HTTP_403_FORBIDDEN)
        value = bool(request.data.get('muted', True))
        chatroom.set_muted(request.user, value)
        return Response({'status': 'ok', 'muted': value})

    @action(detail=True, methods=['post'])
    def clear(self, request, pk=None):
        """Clear this conversation for the calling user only.

        The caller stops seeing messages up to now; the other participant's
        view is untouched. When BOTH participants have cleared, messages older
        than both clear-points are visible to no one and are hard-deleted from
        the database.
        """
        chatroom = self.get_object()
        if request.user not in (chatroom.user1, chatroom.user2):
            return Response(
                {'error': 'Not a participant'},
                status=status.HTTP_403_FORBIDDEN,
            )

        now = timezone.now()
        if request.user == chatroom.user1:
            chatroom.cleared_at_user1 = now
        else:
            chatroom.cleared_at_user2 = now
        chatroom.save(
            update_fields=['cleared_at_user1', 'cleared_at_user2']
        )

        purged = 0
        both_cleared = (
            chatroom.cleared_at_user1 is not None
            and chatroom.cleared_at_user2 is not None
        )
        if both_cleared:
            # Only rows neither side can see anymore — messages newer than the
            # earlier clear-point are still visible to that participant.
            cutoff = min(chatroom.cleared_at_user1, chatroom.cleared_at_user2)
            purged, _ = Message.objects.filter(
                chatroom=chatroom, created_at__lte=cutoff
            ).delete()

        return Response({
            'status': 'cleared',
            'both_cleared': both_cleared,
            'purged': purged,
        })


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

        # Per-user clear: a participant who cleared the conversation no longer
        # sees messages up to their clear-point (the other side still does).
        queryset = queryset.filter(
            (
                Q(chatroom__user1=user)
                & (
                    Q(chatroom__cleared_at_user1__isnull=True)
                    | Q(created_at__gt=F('chatroom__cleared_at_user1'))
                )
            )
            | (
                Q(chatroom__user2=user)
                & (
                    Q(chatroom__cleared_at_user2__isnull=True)
                    | Q(created_at__gt=F('chatroom__cleared_at_user2'))
                )
            )
        )

        return queryset
    
    def create(self, request, *args, **kwargs):
        """Create a new message and return full serialization"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # SECURITY: only a participant of the target chatroom may post to it.
        # Without this an attacker could inject/spoof messages into any two
        # users' private conversation by passing an arbitrary chatroom id.
        target_room = serializer.validated_data.get('chatroom')
        if target_room is None or request.user.id not in (
            target_room.user1_id,
            target_room.user2_id,
        ):
            return Response(
                {'detail': 'You are not a participant of this conversation.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        message = serializer.save(sender=request.user)

        # Auto-classify text as spam (powers the "Maybe spam" chat bucket).
        # Only spam from a NON-followed sender is worth flagging — messages from
        # people the receiver follows are trusted and stay in the normal list.
        if message.message_type == 'text' and message.content:
            from .spam_filter import classify_message

            is_spam, category = classify_message(message.content)
            if is_spam and not _receiver_follows_sender(message):
                message.is_spam = True
                message.spam_category = category
                message.save(update_fields=['is_spam', 'spam_category'])

        # Update chatroom's last message
        chatroom = message.chatroom
        chatroom.last_message_at = message.created_at
        chatroom.last_message_preview = message.get_preview()
        chatroom.save()
        
        # Realtime delivery first (in-process, fast) so the sender's request is
        # never held up by anything network-bound.
        output_serializer = MessageSerializer(message, context={'request': request})
        _broadcast_to_user(
            message.receiver_id,
            {
                'type': 'new_message',
                'message': output_serializer.data,
            },
        )

        # Push notification is offloaded to Celery. Each FCM send is a blocking
        # network call, and sending them inline here intermittently exceeded the
        # client's HTTP timeout (the message was still saved, so it "delivered"
        # but the request reported a timeout). The task re-checks whether the
        # receiver is currently in this chat before notifying.
        try:
            # Respect the receiver's mute: no push for a muted conversation.
            receiver_muted = chatroom.is_muted_for(message.receiver_id)
            if not receiver_muted:
                from .tasks import send_chat_push_notification

                sender_name = (
                    request.user.get_full_name()
                    or request.user.username
                    or request.user.email
                )
                send_chat_push_notification.delay(
                    receiver_id=str(message.receiver_id),
                    sender_id=str(request.user.id),
                    sender_name=sender_name,
                    message_preview=message.get_preview(),
                    chatroom_id=str(chatroom.id),
                )
        except Exception as e:
            logger.warning('Failed to enqueue chat push notification: %s', e)

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


class ChatGroupViewSet(viewsets.ModelViewSet):
    """Group chats: create (name/photo/members), message, manage members, leave.

    Kept deliberately separate from the 1-on-1 ChatRoom paths. Realtime uses
    the same per-user channel groups (`user_<id>`) with a `group_message`
    event; clients without the socket fall back to polling `messages`.
    """
    serializer_class = ChatGroupSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'post', 'patch', 'delete']

    def get_queryset(self):
        return (
            ChatGroup.objects.filter(memberships__user=self.request.user)
            .prefetch_related('memberships__user')
            .distinct()
        )

    def create(self, request, *args, **kwargs):
        name = (request.data.get('name') or '').strip()
        if not name:
            return Response({'error': 'গ্রুপের নাম দিন'}, status=400)
        if len(name) > 80:
            name = name[:80]

        raw_ids = request.data.get('member_ids') or []
        if isinstance(raw_ids, str):
            raw_ids = [x for x in raw_ids.split(',') if x.strip()]
        member_ids = [str(x).strip() for x in raw_ids if str(x).strip()]

        members = list(User.objects.filter(id__in=member_ids))
        if not members:
            return Response({'error': 'অন্তত একজন মেম্বার যোগ করুন'}, status=400)

        group = ChatGroup.objects.create(
            name=name,
            creator=request.user,
            image=request.FILES.get('image'),
        )
        ChatGroupMembership.objects.create(
            group=group, user=request.user, role='admin'
        )
        for m in members:
            if m.id == request.user.id:
                continue
            ChatGroupMembership.objects.get_or_create(group=group, user=m)

        # Opening activity notices.
        self._system_msg(group, f'{self._actor_name()} গ্রুপটি তৈরি করেছেন')
        added_names = ', '.join(
            self._display_name(m) for m in members if m.id != request.user.id
        )
        if added_names:
            self._system_msg(
                group, f'{self._actor_name()} {added_names}-কে যোগ করেছেন')

        data = ChatGroupSerializer(group, context={'request': request}).data
        # Tell every member their group list changed.
        for m in members:
            _broadcast_to_user(m.id, {'type': 'group_updated', 'group': data})
        return Response(data, status=status.HTTP_201_CREATED)

    def _actor_name(self):
        u = self.request.user
        return u.first_name or u.username or 'Someone'

    @staticmethod
    def _display_name(user):
        return user.first_name or user.username or 'Someone'

    def _system_msg(self, group, text):
        """Post a centered activity notice into the group and push it to every
        member's socket, so everyone sees what admins/members did."""
        msg = GroupMessage.objects.create(
            group=group,
            sender=self.request.user,
            message_type='system',
            content=text,
        )
        group.last_message_at = msg.created_at
        group.last_message_preview = text[:80]
        group.save(update_fields=['last_message_at', 'last_message_preview'])
        payload = GroupMessageSerializer(
            msg, context={'request': self.request}
        ).data
        for member_id in group.memberships.values_list('user_id', flat=True):
            _broadcast_to_user(member_id, {
                'type': 'group_message',
                'message': payload,
            })

    def _require_member(self, group):
        if not group.is_member(self.request.user):
            return Response({'error': 'আপনি এই গ্রুপের মেম্বার নন'}, status=403)
        return None

    def _require_admin(self, group):
        if not group.is_admin(self.request.user):
            return Response({'error': 'শুধু অ্যাডমিন এটা করতে পারেন'}, status=403)
        return None

    def partial_update(self, request, *args, **kwargs):
        """Admin edits: rename group and/or change photo."""
        group = self.get_object()
        err = self._require_admin(group)
        if err:
            return err
        name = (request.data.get('name') or '').strip()
        updates = []
        renamed_to = None
        if name and name[:80] != group.name:
            renamed_to = name[:80]
            group.name = renamed_to
            updates.append('name')
        photo_changed = 'image' in request.FILES
        if photo_changed:
            group.image = request.FILES['image']
            updates.append('image')
        if updates:
            group.save(update_fields=updates + ['updated_at'])
        if renamed_to:
            self._system_msg(
                group,
                f'{self._actor_name()} গ্রুপের নাম "{renamed_to}" করেছেন')
        if photo_changed:
            self._system_msg(
                group, f'{self._actor_name()} গ্রুপের ছবি বদলেছেন')
        return Response(
            ChatGroupSerializer(group, context={'request': request}).data
        )

    def destroy(self, request, *args, **kwargs):
        """Delete the whole group — admin only."""
        group = self.get_object()
        err = self._require_admin(group)
        if err:
            return err
        group.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=['post'])
    def promote_admin(self, request, pk=None):
        """Make another member an admin — admin only."""
        group = self.get_object()
        err = self._require_admin(group)
        if err:
            return err
        user_id = str(request.data.get('user_id') or '').strip()
        updated = ChatGroupMembership.objects.filter(
            group=group, user_id=user_id
        ).update(role='admin')
        if updated:
            target = User.objects.filter(id=user_id).first()
            if target:
                self._system_msg(
                    group,
                    f'{self._actor_name()} {self._display_name(target)}-কে '
                    'কো-অ্যাডমিন বানিয়েছেন')
        return Response({'promoted': bool(updated)})

    @action(detail=True, methods=['post'])
    def demote_admin(self, request, pk=None):
        """Turn another admin back into a member — admin only. The creator
        can never be demoted, and a group always keeps at least one admin."""
        group = self.get_object()
        err = self._require_admin(group)
        if err:
            return err
        user_id = str(request.data.get('user_id') or '').strip()
        if user_id == str(group.creator_id):
            return Response({'error': 'গ্রুপ ক্রিয়েটরকে demote করা যায় না'},
                            status=400)
        admins = group.memberships.filter(role='admin')
        if admins.count() <= 1:
            return Response({'error': 'গ্রুপে অন্তত একজন অ্যাডমিন থাকতে হবে'},
                            status=400)
        updated = admins.filter(user_id=user_id).update(role='member')
        if updated:
            target = User.objects.filter(id=user_id).first()
            if target:
                self._system_msg(
                    group,
                    f'{self._actor_name()} {self._display_name(target)}-কে '
                    'কো-অ্যাডমিন থেকে সরিয়েছেন')
        return Response({'demoted': bool(updated)})

    @action(detail=True, methods=['post'])
    def mute(self, request, pk=None):
        """Toggle MY notifications for this group. Body: {muted: bool}."""
        group = self.get_object()
        err = self._require_member(group)
        if err:
            return err
        value = bool(request.data.get('muted', True))
        group.memberships.filter(user=request.user).update(muted=value)
        return Response({'muted': value})

    @action(detail=True, methods=['get', 'post'])
    def typing(self, request, pk=None):
        """POST: I'm typing (heartbeat). GET: who else is typing right now."""
        group = self.get_object()
        err = self._require_member(group)
        if err:
            return err
        if request.method == 'POST':
            group.memberships.filter(user=request.user).update(
                typing_at=timezone.now()
            )
            return Response({'ok': True})
        cutoff = timezone.now() - timezone.timedelta(seconds=6)
        names = []
        for m in group.memberships.select_related('user').filter(
            typing_at__gte=cutoff
        ).exclude(user=request.user):
            names.append(
                m.user.first_name or m.user.username or 'Someone'
            )
        return Response({'typing': names})

    @action(detail=True, methods=['post'])
    def add_members(self, request, pk=None):
        group = self.get_object()
        err = self._require_admin(group)
        if err:
            return err
        raw_ids = request.data.get('user_ids') or []
        if isinstance(raw_ids, str):
            raw_ids = [x for x in raw_ids.split(',') if x.strip()]
        added_users = []
        for u in User.objects.filter(id__in=[str(x).strip() for x in raw_ids]):
            _, created = ChatGroupMembership.objects.get_or_create(
                group=group, user=u
            )
            if created:
                added_users.append(u)
                _broadcast_to_user(u.id, {
                    'type': 'group_updated',
                    'group': ChatGroupSerializer(
                        group, context={'request': request}
                    ).data,
                })
        if added_users:
            names = ', '.join(self._display_name(u) for u in added_users)
            self._system_msg(
                group, f'{self._actor_name()} {names}-কে যোগ করেছেন')
        return Response({'added': len(added_users)})

    @action(detail=True, methods=['post'])
    def remove_member(self, request, pk=None):
        group = self.get_object()
        err = self._require_admin(group)
        if err:
            return err
        user_id = str(request.data.get('user_id') or '').strip()
        if user_id == str(request.user.id):
            return Response({'error': 'নিজেকে remove করতে leave ব্যবহার করুন'},
                            status=400)
        target = User.objects.filter(id=user_id).first()
        deleted, _ = ChatGroupMembership.objects.filter(
            group=group, user_id=user_id
        ).delete()
        if deleted and target:
            self._system_msg(
                group,
                f'{self._actor_name()} {self._display_name(target)}-কে '
                'গ্রুপ থেকে বাদ দিয়েছেন')
        return Response({'removed': bool(deleted)})

    @action(detail=True, methods=['post'])
    def leave(self, request, pk=None):
        group = self.get_object()
        err = self._require_member(group)
        if err:
            return err
        ChatGroupMembership.objects.filter(
            group=group, user=request.user
        ).delete()
        remaining = group.memberships.all()
        if not remaining.exists():
            group.delete()
            return Response({'left': True, 'deleted': True})
        # Announce the departure to whoever remains.
        self._system_msg(group, f'{self._actor_name()} গ্রুপ ছেড়েছেন')
        # Never leave a group admin-less.
        if not remaining.filter(role='admin').exists():
            oldest = remaining.order_by('joined_at').first()
            oldest.role = 'admin'
            oldest.save(update_fields=['role'])
        return Response({'left': True})

    @action(detail=True, methods=['get', 'post'])
    def messages(self, request, pk=None):
        group = self.get_object()
        err = self._require_member(group)
        if err:
            return err

        if request.method == 'GET':
            membership = group.memberships.filter(user=request.user).first()
            qs = group.messages.select_related('sender')
            if membership and membership.cleared_at:
                qs = qs.filter(created_at__gt=membership.cleared_at)
            msgs = list(qs.order_by('-created_at')[:100])[::-1]
            return Response(GroupMessageSerializer(
                msgs, many=True, context={'request': request}
            ).data)

        message_type = (request.data.get('message_type') or 'text').strip()
        content = (request.data.get('content') or '').strip()
        media = request.FILES.get('media_file')
        if message_type == 'text' and not content:
            return Response({'error': 'মেসেজ লিখুন'}, status=400)
        if message_type in ('voice', 'image', 'video', 'document')                 and media is None:
            return Response({'error': 'media_file required'}, status=400)
        voice_duration = None
        try:
            raw_dur = request.data.get('voice_duration')
            if raw_dur is not None and str(raw_dur).strip():
                voice_duration = int(str(raw_dur).strip())
        except (TypeError, ValueError):
            voice_duration = None
        message = GroupMessage.objects.create(
            group=group,
            sender=request.user,
            message_type=message_type,
            content=content or None,
            media_file=media,
            file_name=(request.data.get('file_name') or '').strip() or None,
            voice_duration=voice_duration,
        )
        group.last_message_at = message.created_at
        group.last_message_preview = (
            f'{request.user.first_name or request.user.username}: '
            f'{message.get_preview()}'
        )
        group.save(update_fields=['last_message_at', 'last_message_preview'])

        payload = GroupMessageSerializer(
            message, context={'request': request}
        ).data
        for member_id in group.memberships.exclude(
            user=request.user
        ).values_list('user_id', flat=True):
            _broadcast_to_user(member_id, {
                'type': 'group_message',
                'message': payload,
            })

        # Push notifications off-thread (skips members who muted the group).
        try:
            from .tasks import send_group_push_notification

            sender_name = (
                request.user.get_full_name()
                or request.user.username
                or request.user.email
            )
            send_group_push_notification.delay(
                group_id=str(group.id),
                sender_id=str(request.user.id),
                sender_name=sender_name,
                message_preview=message.get_preview(),
            )
        except Exception as e:
            logger.warning('Failed to enqueue group push: %s', e)
        return Response(payload, status=status.HTTP_201_CREATED)
