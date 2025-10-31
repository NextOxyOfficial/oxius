from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q, Max
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.contrib.auth import get_user_model
from .models import (
    ChatRoom, Message, MessageReport, 
    BlockedUser, TypingStatus, OnlineStatus
)
from .serializers import (
    ChatRoomSerializer, MessageSerializer, MessageCreateSerializer,
    MessageReportSerializer, BlockedUserSerializer, 
    OnlineStatusSerializer, TypingStatusSerializer
)

User = get_user_model()


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
        
        # Mark all unread messages from other user as read
        Message.objects.filter(
            chatroom=chatroom,
            is_read=False
        ).exclude(sender=request.user).update(
            is_read=True,
            read_at=timezone.now()
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
        
        # Return full message serialization with all fields
        output_serializer = MessageSerializer(message, context={'request': request})
        return Response(output_serializer.data, status=status.HTTP_201_CREATED)
    
    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """Mark a message as read"""
        message = self.get_object()
        
        if message.receiver == request.user:
            message.mark_as_read()
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
            return OnlineStatus.objects.filter(
                user_id__in=user_ids
            ).select_related('user')
        
        return OnlineStatus.objects.none()
    
    @action(detail=False, methods=['post'])
    def update_status(self, request):
        """Update current user's online status"""
        is_online = request.data.get('is_online', True)
        
        online_status, created = OnlineStatus.objects.get_or_create(
            user=request.user
        )
        online_status.is_online = is_online
        online_status.update_last_seen()
        
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
        
        return Response({'status': 'typing status updated'})
