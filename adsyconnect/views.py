from rest_framework import viewsets, status, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q, Max
from django.shortcuts import get_object_or_404
from django.utils import timezone
from .models import (
    ChatRoom, Message, MessageReport, 
    BlockedUser, TypingStatus, OnlineStatus
)
from .serializers import (
    ChatRoomSerializer, MessageSerializer, MessageCreateSerializer,
    MessageReportSerializer, BlockedUserSerializer, 
    OnlineStatusSerializer, TypingStatusSerializer
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
        
        # Check if user is trying to chat with themselves
        if str(other_user_id) == str(request.user.id):
            return Response(
                {'error': 'Cannot create chat with yourself'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get or create chat room
        chatroom = ChatRoom.objects.filter(
            Q(user1=request.user, user2_id=other_user_id) |
            Q(user1_id=other_user_id, user2=request.user)
        ).first()
        
        if not chatroom:
            # Create new chat room
            chatroom = ChatRoom.objects.create(
                user1=request.user,
                user2_id=other_user_id
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
    
    def get_serializer_class(self):
        if self.action == 'create':
            return MessageCreateSerializer
        return MessageSerializer
    
    def get_queryset(self):
        """Get messages for current user"""
        user = self.request.user
        chatroom_id = self.request.query_params.get('chatroom')
        
        queryset = Message.objects.filter(
            Q(sender=user) | Q(receiver=user),
            is_deleted=False
        ).select_related('sender', 'receiver', 'chatroom')
        
        if chatroom_id:
            queryset = queryset.filter(chatroom_id=chatroom_id)
        
        return queryset
    
    def perform_create(self, serializer):
        """Create a new message"""
        message = serializer.save(sender=self.request.user)
        
        # Update chatroom's last message
        chatroom = message.chatroom
        chatroom.last_message_at = message.created_at
        chatroom.last_message_preview = message.get_preview()
        chatroom.save()
    
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
        """Soft delete a message"""
        message = self.get_object()
        
        if message.sender != request.user:
            return Response(
                {'error': 'You can only delete your own messages'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        message.soft_delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


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
