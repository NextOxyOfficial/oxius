from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Q, Max, Count, Case, When, IntegerField
from django.contrib.auth import get_user_model
from .models import ChatRoom, Message, MessageReport, OnlineStatus, TypingStatus
from .serializers import (
    ChatRoomSerializer, MessageSerializer, MessageReportSerializer,
    OnlineStatusSerializer, TypingStatusSerializer
)

User = get_user_model()


class ChatRoomViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing chat rooms
    """
    serializer_class = ChatRoomSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Get chat rooms for the current user"""
        user = self.request.user
        return ChatRoom.objects.filter(
            Q(user1=user) | Q(user2=user)
        ).select_related('user1', 'user2').annotate(
            unread_count=Count(
                Case(
                    When(
                        Q(messages__receiver=user) & Q(messages__is_read=False),
                        then=1
                    ),
                    output_field=IntegerField()
                )
            )
        ).order_by('-last_message_at')

    @action(detail=False, methods=['post'])
    def get_or_create(self, request):
        """Get or create a chat room with another user"""
        user_id = request.data.get('user_id')
        
        if not user_id:
            return Response(
                {'error': 'user_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            other_user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        if other_user == request.user:
            return Response(
                {'error': 'Cannot create chat room with yourself'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if chat room already exists
        chatroom = ChatRoom.objects.filter(
            Q(user1=request.user, user2=other_user) |
            Q(user1=other_user, user2=request.user)
        ).first()
        
        if chatroom:
            serializer = self.get_serializer(chatroom)
            return Response(serializer.data)
        
        # Create new chat room
        chatroom = ChatRoom.objects.create(
            user1=request.user,
            user2=other_user
        )
        
        serializer = self.get_serializer(chatroom)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def mark_as_read(self, request, pk=None):
        """Mark all messages in a chat room as read"""
        chatroom = self.get_object()
        
        # Update all unread messages where current user is receiver
        Message.objects.filter(
            chatroom=chatroom,
            receiver=request.user,
            is_read=False
        ).update(is_read=True)
        
        return Response({'status': 'messages marked as read'})

    @action(detail=True, methods=['post'])
    def block(self, request, pk=None):
        """Block a user in this chat room"""
        chatroom = self.get_object()
        
        # Determine which user to block
        if chatroom.user1 == request.user:
            blocked_user = chatroom.user2
        else:
            blocked_user = chatroom.user1
        
        # Import BlockedUser here to avoid circular imports
        from .models import BlockedUser
        
        BlockedUser.objects.get_or_create(
            blocker=request.user,
            blocked=blocked_user
        )
        
        return Response({'status': 'user blocked'})


class MessageViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing messages
    """
    serializer_class = MessageSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Get messages for a specific chat room"""
        chatroom_id = self.request.query_params.get('chatroom')
        
        if chatroom_id:
            return Message.objects.filter(
                chatroom_id=chatroom_id
            ).select_related('sender', 'receiver').order_by('created_at')
        
        return Message.objects.none()

    def perform_create(self, serializer):
        """Create a new message"""
        serializer.save(sender=self.request.user)

    def destroy(self, request, *args, **kwargs):
        """Delete a message (only sender can delete)"""
        message = self.get_object()
        
        if message.sender != request.user:
            return Response(
                {'error': 'You can only delete your own messages'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        return super().destroy(request, *args, **kwargs)


class MessageReportViewSet(viewsets.ModelViewSet):
    """
    ViewSet for reporting messages or users
    """
    serializer_class = MessageReportSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'post']

    def get_queryset(self):
        """Get reports created by current user"""
        return MessageReport.objects.filter(
            reporter=self.request.user
        ).select_related('reporter', 'reported_user', 'message')

    def perform_create(self, serializer):
        """Create a new report"""
        serializer.save(reporter=self.request.user)


class OnlineStatusViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing online status
    """
    serializer_class = OnlineStatusSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'post']

    def get_queryset(self):
        """Get online status for all users"""
        return OnlineStatus.objects.all().select_related('user')

    @action(detail=False, methods=['post'])
    def update_status(self, request):
        """Update current user's online status"""
        is_online = request.data.get('is_online', True)
        
        online_status, created = OnlineStatus.objects.get_or_create(
            user=request.user
        )
        online_status.is_online = is_online
        online_status.save()
        
        serializer = self.get_serializer(online_status)
        return Response(serializer.data)


class TypingStatusViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing typing indicators
    """
    serializer_class = TypingStatusSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'post']

    def get_queryset(self):
        """Get typing status for chat rooms user is part of"""
        return TypingStatus.objects.filter(
            chatroom__user1=self.request.user
        ) | TypingStatus.objects.filter(
            chatroom__user2=self.request.user
        )

    @action(detail=False, methods=['post'])
    def update_typing(self, request):
        """Update typing status for a chat room"""
        chatroom_id = request.data.get('chatroom_id')
        is_typing = request.data.get('is_typing', False)
        
        if not chatroom_id:
            return Response(
                {'error': 'chatroom_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            chatroom = ChatRoom.objects.get(id=chatroom_id)
        except ChatRoom.DoesNotExist:
            return Response(
                {'error': 'Chat room not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        typing_status, created = TypingStatus.objects.get_or_create(
            chatroom=chatroom,
            user=request.user
        )
        typing_status.is_typing = is_typing
        typing_status.save()
        
        serializer = self.get_serializer(typing_status)
        return Response(serializer.data)
