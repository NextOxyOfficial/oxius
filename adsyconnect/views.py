import logging

from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.db.models import Q, Max
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.contrib.auth import get_user_model
from .models import (
    ChatRoom, Message, MessageReport, 
    BlockedUser, TypingStatus, OnlineStatus, ActiveChatSession
)
from .serializers import (
    ChatRoomSerializer, MessageSerializer, MessageCreateSerializer,
    MessageReportSerializer, BlockedUserSerializer, 
    OnlineStatusSerializer, TypingStatusSerializer
)

User = get_user_model()
logger = logging.getLogger(__name__)


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
def send_call_notification(request):
    """Send incoming call signal via websocket and FCM fallback."""
    try:
        from base.models import FCMToken

        callee_id = request.data.get('callee_id')
        channel_name = request.data.get('channel_name')
        call_id = request.data.get('call_id')
        call_type = request.data.get('call_type', 'audio')

        if not callee_id or not channel_name:
            return Response({'error': 'callee_id and channel_name are required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            callee = User.objects.get(id=callee_id)
        except User.DoesNotExist:
            return Response({'error': 'Callee not found'}, status=status.HTTP_404_NOT_FOUND)

        caller = request.user
        caller_name = caller.get_full_name() or caller.username

        caller_avatar = None
        if hasattr(caller, 'profile_image') and caller.profile_image:
            caller_avatar = caller.profile_image.url
        elif hasattr(caller, 'image') and caller.image:
            caller_avatar = caller.image.url

        import time
        timestamp = int(time.time() * 1000)  # milliseconds for call age validation

        payload = {
            'type': 'incoming_call',
            'channel_name': str(channel_name),
            **({'call_id': str(call_id)} if call_id else {}),
            'caller_id': str(caller.id),
            'caller_name': caller_name,
            'call_type': call_type,
            'caller_avatar': caller_avatar or '',
            'timestamp': str(timestamp),
        }

        _broadcast_to_user(
            callee.id,
            {
                'type': 'incoming_call_event',
                'payload': payload,
            },
        )
        
        success_count = 0
        total_tokens = 0
        last_send_error = None

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

            fcm_tokens = FCMToken.objects.filter(user=callee, is_active=True)
            total_tokens = fcm_tokens.count()

            for fcm_token in fcm_tokens:
                try:
                    message = messaging.Message(
                        data=payload,
                        android=messaging.AndroidConfig(
                            priority='high',
                            ttl=datetime.timedelta(seconds=30),
                        ),
                        apns=messaging.APNSConfig(
                            headers={'apns-priority': '10'},
                            payload=messaging.APNSPayload(
                                aps=messaging.Aps(content_available=True),
                            ),
                        ),
                        token=fcm_token.token,
                    )
                    messaging.send(message)
                    success_count += 1
                except Exception as e:
                    last_send_error = str(e)
                    logger.warning(
                        'Failed to send incoming call FCM to token %s...: %s',
                        fcm_token.token[:20],
                        e,
                    )
        except Exception as e:
            last_send_error = str(e)
            logger.warning('Incoming call FCM fallback failed: %s', e)

        return Response({
            'success': True,
            'sent_to_ws': True,
            'sent_to': success_count,
            'total_tokens': total_tokens,
            'fcm_error': last_send_error,
        })
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def send_call_status(request):
    """Send call status via websocket and FCM fallback."""
    try:
        from base.models import FCMToken

        receiver_id = request.data.get('receiver_id')
        channel_name = request.data.get('channel_name')
        call_type = request.data.get('call_type', 'audio')
        status_value = request.data.get('status')

        if not receiver_id or not channel_name or not status_value:
            return Response(
                {'error': 'receiver_id, channel_name and status are required'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            receiver = User.objects.get(id=receiver_id)
        except User.DoesNotExist:
            return Response({'error': 'Receiver not found'}, status=status.HTTP_404_NOT_FOUND)

        sender = request.user

        payload = {
            'type': 'call_status',
            'channel_name': str(channel_name),
            'call_type': str(call_type),
            'status': str(status_value),
            'sender_id': str(sender.id),
        }

        _broadcast_to_user(
            receiver.id,
            {
                'type': 'call_status_event',
                'payload': payload,
            },
        )

        success_count = 0
        total_tokens = 0
        last_send_error = None

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

            fcm_tokens = FCMToken.objects.filter(user=receiver, is_active=True)
            total_tokens = fcm_tokens.count()

            for fcm_token in fcm_tokens:
                try:
                    message = messaging.Message(
                        data=payload,
                        android=messaging.AndroidConfig(
                            priority='high',
                            ttl=datetime.timedelta(seconds=30),
                        ),
                        apns=messaging.APNSConfig(
                            headers={'apns-priority': '10'},
                            payload=messaging.APNSPayload(
                                aps=messaging.Aps(content_available=True),
                            ),
                        ),
                        token=fcm_token.token,
                    )
                    messaging.send(message)
                    success_count += 1
                except Exception as e:
                    last_send_error = str(e)
                    logger.warning(
                        'Failed to send call status FCM to token %s...: %s',
                        fcm_token.token[:20],
                        e,
                    )
        except Exception as e:
            last_send_error = str(e)
            logger.warning('Call status FCM fallback failed: %s', e)

        return Response({
            'success': True,
            'sent_to_ws': True,
            'sent_to': success_count,
            'total_tokens': total_tokens,
            'fcm_error': last_send_error,
        })
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


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
        
        serializer = self.get_serializer(chatroom)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def mark_as_read(self, request, pk=None):
        """Mark all messages in chat room as read"""
        chatroom = self.get_object()
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
            read_at=timezone.now()
        )

        for message_id, sender_id in unread_messages:
            _broadcast_to_user(
                sender_id,
                {
                    'type': 'message_read_update',
                    'message_id': str(message_id),
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
        """Block a user"""
        serializer.save(blocker=self.request.user)
    
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
