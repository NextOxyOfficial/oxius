import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from django.utils import timezone
from .models import ChatRoom, Message, OnlineStatus, TypingStatus
from .serializers import MessageSerializer

User = get_user_model()
logger = logging.getLogger(__name__)


class ChatConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for real-time chat functionality
    """
    
    async def connect(self):
        """Handle WebSocket connection"""
        self.user_id = self.scope['url_route']['kwargs']['user_id']
        self.user_group_name = f'user_{self.user_id}'
        
        # Verify user exists and is authenticated
        user = await self.get_user(self.user_id)
        if not user:
            await self.close()
            return
        
        self.user = user
        
        # Join user's personal group
        await self.channel_layer.group_add(
            self.user_group_name,
            self.channel_name
        )
        
        # Accept the connection
        await self.accept()
        
        # Update user's online status
        await self.update_online_status(True)
        
        # Notify other users that this user is online
        await self.broadcast_online_status(True)
        
        logger.info(f"User {self.user.username} connected to chat")

    async def disconnect(self, close_code):
        """Handle WebSocket disconnection"""
        if hasattr(self, 'user'):
            # Leave user's personal group
            await self.channel_layer.group_discard(
                self.user_group_name,
                self.channel_name
            )
            
            # Update user's online status
            await self.update_online_status(False)
            
            # Notify other users that this user is offline
            await self.broadcast_online_status(False)
            
            logger.info(f"User {self.user.username} disconnected from chat")

    async def receive(self, text_data):
        """Handle incoming WebSocket messages"""
        try:
            data = json.loads(text_data)
            message_type = data.get('type')
            
            if message_type == 'send_message':
                await self.handle_send_message(data)
            elif message_type == 'typing_status':
                await self.handle_typing_status(data)
            elif message_type == 'mark_as_read':
                await self.handle_mark_as_read(data)
            else:
                logger.warning(f"Unknown message type: {message_type}")
                
        except json.JSONDecodeError:
            logger.error("Invalid JSON received")
        except Exception as e:
            logger.error(f"Error handling WebSocket message: {e}")

    async def handle_send_message(self, data):
        """Handle sending a new message"""
        try:
            message_data = data.get('message', {})
            chatroom_id = message_data.get('chatroom')
            content = message_data.get('content')
            
            if not chatroom_id or not content:
                return
            
            # Get chatroom and verify user has access
            chatroom = await self.get_chatroom(chatroom_id)
            if not chatroom or not await self.user_has_access_to_chatroom(chatroom):
                return
            
            # Create the message
            message = await self.create_message(chatroom, content)
            if not message:
                return
            
            # Serialize message
            message_data = await self.serialize_message(message)
            
            # Get other user in the chat
            other_user = await self.get_other_user_in_chat(chatroom)
            if other_user:
                # Send to other user's group
                await self.channel_layer.group_send(
                    f'user_{other_user.id}',
                    {
                        'type': 'new_message',
                        'message': message_data
                    }
                )
            
            # Send confirmation back to sender
            await self.send(text_data=json.dumps({
                'type': 'message_sent',
                'message': message_data
            }))
            
        except Exception as e:
            logger.error(f"Error sending message: {e}")

    async def handle_typing_status(self, data):
        """Handle typing status updates"""
        try:
            chatroom_id = data.get('chatroom_id')
            is_typing = data.get('is_typing', False)
            
            if not chatroom_id:
                return
            
            # Get chatroom and verify access
            chatroom = await self.get_chatroom(chatroom_id)
            if not chatroom or not await self.user_has_access_to_chatroom(chatroom):
                return
            
            # Update typing status
            await self.update_typing_status(chatroom, is_typing)
            
            # Get other user and notify them
            other_user = await self.get_other_user_in_chat(chatroom)
            if other_user:
                await self.channel_layer.group_send(
                    f'user_{other_user.id}',
                    {
                        'type': 'typing_status_update',
                        'chatroom_id': chatroom_id,
                        'user_id': str(self.user.id),
                        'is_typing': is_typing
                    }
                )
                
        except Exception as e:
            logger.error(f"Error handling typing status: {e}")

    async def handle_mark_as_read(self, data):
        """Handle marking messages as read"""
        try:
            message_id = data.get('message_id')
            
            if not message_id:
                return
            
            # Mark message as read
            message = await self.mark_message_as_read(message_id)
            if not message:
                return
            
            # Notify the sender that their message was read
            await self.channel_layer.group_send(
                f'user_{message.sender.id}',
                {
                    'type': 'message_read_update',
                    'message_id': message_id
                }
            )
            
        except Exception as e:
            logger.error(f"Error marking message as read: {e}")

    # WebSocket event handlers
    async def new_message(self, event):
        """Send new message to WebSocket"""
        await self.send(text_data=json.dumps({
            'type': 'new_message',
            'message': event['message']
        }))

    async def typing_status_update(self, event):
        """Send typing status update to WebSocket"""
        await self.send(text_data=json.dumps({
            'type': 'typing_status',
            'chatroom_id': event['chatroom_id'],
            'user_id': event['user_id'],
            'is_typing': event['is_typing']
        }))

    async def message_read_update(self, event):
        """Send message read status update to WebSocket"""
        await self.send(text_data=json.dumps({
            'type': 'message_read',
            'message_id': event['message_id']
        }))

    async def user_online_status(self, event):
        """Send user online status update to WebSocket"""
        await self.send(text_data=json.dumps({
            'type': 'user_online_status',
            'user_id': event['user_id'],
            'is_online': event['is_online']
        }))

    # Database operations
    @database_sync_to_async
    def get_user(self, user_id):
        """Get user by ID"""
        try:
            return User.objects.get(id=user_id)
        except User.DoesNotExist:
            return None

    @database_sync_to_async
    def get_chatroom(self, chatroom_id):
        """Get chatroom by ID"""
        try:
            return ChatRoom.objects.select_related('user1', 'user2').get(id=chatroom_id)
        except ChatRoom.DoesNotExist:
            return None

    @database_sync_to_async
    def user_has_access_to_chatroom(self, chatroom):
        """Check if user has access to chatroom"""
        return self.user == chatroom.user1 or self.user == chatroom.user2

    @database_sync_to_async
    def get_other_user_in_chat(self, chatroom):
        """Get the other user in the chatroom"""
        return chatroom.user2 if chatroom.user1 == self.user else chatroom.user1

    @database_sync_to_async
    def create_message(self, chatroom, content):
        """Create a new message"""
        try:
            other_user = chatroom.user2 if chatroom.user1 == self.user else chatroom.user1
            
            message = Message.objects.create(
                chatroom=chatroom,
                sender=self.user,
                receiver=other_user,
                content=content,
                message_type='text'
            )
            
            # Update chatroom's last message info
            chatroom.last_message_at = message.created_at
            chatroom.last_message_preview = message.get_preview()
            chatroom.save(update_fields=['last_message_at', 'last_message_preview'])
            
            return message
        except Exception as e:
            logger.error(f"Error creating message: {e}")
            return None

    @database_sync_to_async
    def serialize_message(self, message):
        """Serialize message for WebSocket transmission"""
        serializer = MessageSerializer(message)
        return serializer.data

    @database_sync_to_async
    def mark_message_as_read(self, message_id):
        """Mark a message as read"""
        try:
            message = Message.objects.select_related('sender', 'receiver').get(
                id=message_id,
                receiver=self.user
            )
            message.mark_as_read()
            return message
        except Message.DoesNotExist:
            return None

    @database_sync_to_async
    def update_online_status(self, is_online):
        """Update user's online status"""
        try:
            online_status, created = OnlineStatus.objects.get_or_create(
                user=self.user,
                defaults={'is_online': is_online}
            )
            if not created:
                online_status.is_online = is_online
                online_status.save(update_fields=['is_online'])
                
            if not is_online:
                online_status.update_last_seen()
                
        except Exception as e:
            logger.error(f"Error updating online status: {e}")

    @database_sync_to_async
    def update_typing_status(self, chatroom, is_typing):
        """Update typing status for a chatroom"""
        try:
            typing_status, created = TypingStatus.objects.get_or_create(
                chatroom=chatroom,
                user=self.user,
                defaults={'is_typing': is_typing}
            )
            if not created:
                typing_status.is_typing = is_typing
                typing_status.save(update_fields=['is_typing'])
        except Exception as e:
            logger.error(f"Error updating typing status: {e}")

    async def broadcast_online_status(self, is_online):
        """Broadcast online status to all users who have chats with this user"""
        try:
            # Get all users who have chats with this user
            connected_users = await self.get_connected_users()
            
            for user_id in connected_users:
                await self.channel_layer.group_send(
                    f'user_{user_id}',
                    {
                        'type': 'user_online_status',
                        'user_id': str(self.user.id),
                        'is_online': is_online
                    }
                )
        except Exception as e:
            logger.error(f"Error broadcasting online status: {e}")

    @database_sync_to_async
    def get_connected_users(self):
        """Get list of user IDs who have chats with this user"""
        try:
            from django.db.models import Q
            
            chatrooms = ChatRoom.objects.filter(
                Q(user1=self.user) | Q(user2=self.user)
            ).select_related('user1', 'user2')
            
            user_ids = []
            for chatroom in chatrooms:
                other_user = chatroom.user2 if chatroom.user1 == self.user else chatroom.user1
                user_ids.append(str(other_user.id))
            
            return user_ids
        except Exception as e:
            logger.error(f"Error getting connected users: {e}")
            return []


class NotificationConsumer(AsyncWebsocketConsumer):
    """
    WebSocket consumer for general notifications
    """
    
    async def connect(self):
        """Handle WebSocket connection for notifications"""
        self.user_id = self.scope['url_route']['kwargs']['user_id']
        self.notification_group_name = f'notifications_{self.user_id}'
        
        # Verify user exists
        user = await self.get_user(self.user_id)
        if not user:
            await self.close()
            return
        
        self.user = user
        
        # Join notification group
        await self.channel_layer.group_add(
            self.notification_group_name,
            self.channel_name
        )
        
        await self.accept()
        logger.info(f"User {self.user.username} connected to notifications")

    async def disconnect(self, close_code):
        """Handle WebSocket disconnection"""
        if hasattr(self, 'user'):
            await self.channel_layer.group_discard(
                self.notification_group_name,
                self.channel_name
            )
            logger.info(f"User {self.user.username} disconnected from notifications")

    async def receive(self, text_data):
        """Handle incoming notification messages"""
        try:
            data = json.loads(text_data)
            # Handle notification-specific messages if needed
        except json.JSONDecodeError:
            logger.error("Invalid JSON received in notifications")

    # Notification event handlers
    async def chat_notification(self, event):
        """Send chat notification to WebSocket"""
        await self.send(text_data=json.dumps({
            'type': 'chat_notification',
            'data': event['data']
        }))

    async def system_notification(self, event):
        """Send system notification to WebSocket"""
        await self.send(text_data=json.dumps({
            'type': 'system_notification',
            'data': event['data']
        }))

    @database_sync_to_async
    def get_user(self, user_id):
        """Get user by ID"""
        try:
            return User.objects.get(id=user_id)
        except User.DoesNotExist:
            return None
