import json
from datetime import timedelta
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
    #: How many Business Network posts one socket may follow at once. Scrolling
    #: a feed subscribes and unsubscribes as cards come and go; this is the
    #: backstop for a client that forgets the second half.
    MAX_POST_SUBSCRIPTIONS = 30

    """
    WebSocket consumer for real-time chat functionality
    """
    
    async def connect(self):
        """Handle WebSocket connection"""
        requested_user_id = self.scope['url_route']['kwargs']['user_id']
        authenticated_user = self.scope.get('user')

        if not authenticated_user or authenticated_user.is_anonymous:
            await self.close()
            return

        if str(authenticated_user.id) != str(requested_user_id):
            await self.close()
            return

        self.user_id = str(authenticated_user.id)
        self.user_group_name = f'user_{self.user_id}'
        self.user = authenticated_user
        # Business Network posts this socket is currently reading.
        self._post_groups = set()
        
        # Join user's personal group
        await self.channel_layer.group_add(
            self.user_group_name,
            self.channel_name
        )
        
        # Accept the connection
        await self.accept()

        # Greet the client immediately.
        #
        # Nothing else here ever sends a frame to the CONNECTING socket —
        # broadcast_online_status fans out to the other party only — so a
        # client had no way to tell a working socket from one that accepted
        # and then went silent. It needs that signal to decide whether its
        # safety poll can back off.
        await self.send(text_data=json.dumps({
            'type': 'connection_ready',
            'user_id': self.user_id,
        }))

        # Update user's online status. Only the FIRST socket is news: a
        # second device arriving does not change whether this user is online,
        # and telling every chat partner again costs one message per partner.
        first, last_seen = await self.register_connection()
        if first:
            await self.broadcast_online_status(True, last_seen=last_seen)

        logger.info(f"User {self.user.username} connected to chat")

    async def disconnect(self, close_code):
        """Handle WebSocket disconnection"""
        if hasattr(self, 'user'):
            # Leave user's personal group
            await self.channel_layer.group_discard(
                self.user_group_name,
                self.channel_name
            )
            # ...and any post groups, or the layer keeps a dead channel in
            # every post this socket ever opened.
            for group_name in list(getattr(self, '_post_groups', ())):
                await self.channel_layer.group_discard(
                    group_name, self.channel_name)
            self._post_groups = set()
            
            # Going offline is only true once the LAST socket closes.
            # Marking it on the first close is what showed a user as offline
            # while they were still holding their phone.
            last, last_seen = await self.release_connection()
            if last:
                await self.broadcast_online_status(False, last_seen=last_seen)

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
            elif message_type == 'ping':
                await self.update_online_status(True)
                await self.send(text_data=json.dumps({'type': 'pong'}))
            elif message_type == 'subscribe_post':
                await self.handle_subscribe_post(data)
            elif message_type == 'unsubscribe_post':
                await self.handle_unsubscribe_post(data)
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

    async def handle_subscribe_post(self, data):
        """Follow a Business Network post while it is on screen.

        Notifications reach the person a thing happened to, over their own
        user group. A comment arriving on a post is news to everybody READING
        that post, which needs a group per post — joined while it is open and
        left when it is not, so a client is never fed activity for a hundred
        posts it scrolled past.
        """
        post_id = str(data.get('post_id') or '').strip()
        if not post_id or len(post_id) > 64:
            return
        from business_network.realtime import post_group
        group_name = post_group(post_id)
        if group_name in self._post_groups:
            return
        # A hard ceiling: a client that forgets to unsubscribe must not end up
        # in every group in the database.
        if len(self._post_groups) >= self.MAX_POST_SUBSCRIPTIONS:
            oldest = next(iter(self._post_groups))
            self._post_groups.discard(oldest)
            await self.channel_layer.group_discard(oldest, self.channel_name)
        self._post_groups.add(group_name)
        await self.channel_layer.group_add(group_name, self.channel_name)

    async def handle_unsubscribe_post(self, data):
        post_id = str(data.get('post_id') or '').strip()
        if not post_id:
            return
        from business_network.realtime import post_group
        group_name = post_group(post_id)
        if group_name not in self._post_groups:
            return
        self._post_groups.discard(group_name)
        await self.channel_layer.group_discard(group_name, self.channel_name)

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
                    'message_id': message_id,
                    'chatroom_id': str(message.chatroom_id),
                    'read_at': message.read_at.isoformat() if message.read_at else None,
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

    async def group_message(self, event):
        """Forward a group-chat message to this member's socket."""
        await self.send(text_data=json.dumps({
            'type': 'group_message',
            'message': event['message']
        }))

    async def message_edited(self, event):
        """Forward an in-place edit of a 1:1 message.

        group_send dispatches on the event type NAME — without this method the
        broadcast dies here with "No handler for message type message_edited"
        and the peer never hears about the edit at all.
        """
        await self.send(text_data=json.dumps({
            'type': 'message_edited',
            'message': event['message']
        }))

    async def message_deleted(self, event):
        """Forward a soft-delete of a 1:1 message."""
        await self.send(text_data=json.dumps({
            'type': 'message_deleted',
            'message': event['message']
        }))

    async def message_reaction(self, event):
        """A reaction was added/changed/cleared on a message this user can see.

        Sent to every participant so a reaction shows up immediately instead of
        waiting for the next poll — the group thread only polls every 30s while
        the socket is up, so without this reactions looked like they needed a
        reload. `user_ids` per emoji lets each client work out its own
        "reacted_by_me" without a per-recipient payload.
        """
        await self.send(text_data=json.dumps({
            'type': 'message_reaction',
            'scope': event.get('scope'),
            'message_id': event.get('message_id'),
            'reactions': event.get('reactions'),
        }))

    async def group_updated(self, event):
        """A group this user belongs to was created, changed, or lost.

        Forwards the WHOLE contract, not just `group`. The senders add two more
        keys and this handler used to drop both, which killed the entire
        "you were removed from the group" path end to end:

          * `removed` — set for the person who was removed, who left, or whose
            group was deleted. Without it their client fell through to the
            ordinary update branch, left the screen open, kept the composer
            live, and handed them a member list they were no longer entitled
            to; the first sign anything had happened was a 403 on send.
          * `group_id` — the only identifier present when a group is DELETED,
            because `group` is None by then. Without it the client could not
            tell which group the event was about and discarded it.

        Both are read by the app already (group_chat_screen and the chat list),
        so this needs no client change to take effect.
        """
        await self.send(text_data=json.dumps({
            'type': 'group_updated',
            'group': event.get('group'),
            'removed': bool(event.get('removed', False)),
            # Fall back to the group body's own id for the ordinary
            # update case, where the senders do not set group_id.
            'group_id': (
                event.get('group_id')
                or (event.get('group') or {}).get('id')
            ),
        }))

    async def typing_status_update(self, event):
        """Send typing status update to WebSocket.

        Carries chatroom_id for a 1:1 chat and group_id for a group, so one
        event type serves both and a client only reacts to the conversation it
        has open.
        """
        await self.send(text_data=json.dumps({
            'type': 'typing_status',
            'chatroom_id': event.get('chatroom_id'),
            'group_id': event.get('group_id'),
            'user_id': event['user_id'],
            'user_name': event.get('user_name'),
            'is_typing': event['is_typing'],
        }))

    async def message_read_update(self, event):
        """Send message read status update to WebSocket"""
        await self.send(text_data=json.dumps({
            'type': 'message_read',
            'message_id': event.get('message_id'),
            'message_ids': event.get('message_ids'),
            'chatroom_id': event.get('chatroom_id'),
            'read_at': event.get('read_at'),
        }))

    async def user_online_status(self, event):
        """Send user online status update to WebSocket"""
        await self.send(text_data=json.dumps({
            'type': 'user_online_status',
            'user_id': event['user_id'],
            'is_online': event['is_online'],
            'last_seen': event.get('last_seen')
        }))

    async def bn_notification_event(self, event):
        """A Business Network notification, live rather than only as push."""
        await self.send(text_data=json.dumps(event['payload']))

    async def bn_post_activity_event(self, event):
        """Something happened on a post this socket is reading."""
        await self.send(text_data=json.dumps(event['payload']))

    async def incoming_call_event(self, event):
        """Send incoming call event to WebSocket."""
        await self.send(text_data=json.dumps(event['payload']))

    async def call_status_event(self, event):
        """Send call status event to WebSocket."""
        await self.send(text_data=json.dumps(event['payload']))

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
    def register_connection(self):
        """Record this socket. Returns (is_first, last_seen_iso)."""
        try:
            online_status, _ = OnlineStatus.objects.get_or_create(
                user=self.user,
                defaults={'is_online': True, 'last_seen': timezone.now()},
            )
            first = online_status.register_connection()
            return first, online_status.last_seen.isoformat()
        except Exception as e:
            logger.error(f"Error registering connection: {e}")
            # Announce it rather than leaving the peer with a stale "offline"
            # — a duplicate online event is harmless.
            return True, None

    @database_sync_to_async
    def release_connection(self):
        """Drop this socket. Returns (was_last, last_seen_iso)."""
        try:
            online_status = OnlineStatus.objects.filter(user=self.user).first()
            if online_status is None:
                return True, None
            last = online_status.release_connection()
            return last, online_status.last_seen.isoformat()
        except Exception as e:
            logger.error(f"Error releasing connection: {e}")
            return False, None

    @database_sync_to_async
    def update_online_status(self, is_online):
        """Update user's online status"""
        try:
            online_status, created = OnlineStatus.objects.get_or_create(
                user=self.user,
                defaults={'is_online': is_online, 'last_seen': timezone.now()}
            )
            if created:
                online_status.set_presence(is_online)
            else:
                online_status.set_presence(is_online)
            return online_status.last_seen.isoformat()
        except Exception as e:
            logger.error(f"Error updating online status: {e}")
            return None

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

    async def broadcast_online_status(self, is_online, last_seen=None):
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
                        'is_online': is_online,
                        'last_seen': last_seen,
                    }
                )
        except Exception as e:
            logger.error(f"Error broadcasting online status: {e}")

    #: Nobody who has not spoken to this user in this long is looking at a
    #: presence dot for them. A real account had 84 conversations, so every
    #: reconnect — and mobile reconnects constantly — meant 84 messages, nearly
    #: all of them to people whose app was not even open on that chat.
    PRESENCE_AUDIENCE_DAYS = 30
    #: A hard ceiling for an account with thousands of conversations, newest
    #: first. Beyond this the fan-out costs more than the dot is worth.
    PRESENCE_AUDIENCE_LIMIT = 60

    @database_sync_to_async
    def get_connected_users(self):
        """Who should hear that this user came online or went offline.

        Not "everyone they have ever messaged": the people they have spoken to
        recently, newest conversation first. Anyone else still sees correct
        presence — the REST serializers read it from the row, which is always
        up to date; they just do not get a push about it.
        """
        try:
            from django.db.models import Q

            cutoff = timezone.now() - timedelta(days=self.PRESENCE_AUDIENCE_DAYS)
            chatrooms = (
                ChatRoom.objects.filter(
                    Q(user1=self.user) | Q(user2=self.user),
                )
                .filter(Q(last_message_at__gte=cutoff)
                        | Q(last_message_at__isnull=True,
                            created_at__gte=cutoff))
                .order_by('-last_message_at')
                .values_list('user1_id', 'user2_id')[
                    :self.PRESENCE_AUDIENCE_LIMIT]
            )

            my_id = str(self.user.id)
            user_ids = []
            seen = {my_id}
            for user1_id, user2_id in chatrooms:
                other = str(user2_id if str(user1_id) == my_id else user1_id)
                if other in seen:
                    continue
                seen.add(other)
                user_ids.append(other)

            # Group co-members too. Presence was fanned out to one-to-one chat
            # partners only, so somebody you only ever talk to in a group never
            # saw you come online.
            #
            # Same recency and same overall cap: a member of a group nobody has
            # posted in for a month is not watching for a dot.
            if len(user_ids) < self.PRESENCE_AUDIENCE_LIMIT:
                from .models import ChatGroup, ChatGroupMembership

                active_groups = ChatGroup.objects.filter(
                    memberships__user=self.user,
                ).filter(
                    Q(last_message_at__gte=cutoff)
                    | Q(last_message_at__isnull=True, created_at__gte=cutoff)
                ).values_list('id', flat=True)[:20]

                room = self.PRESENCE_AUDIENCE_LIMIT - len(user_ids)
                for member_id in (
                    ChatGroupMembership.objects
                    .filter(group_id__in=list(active_groups))
                    .exclude(user=self.user)
                    .values_list('user_id', flat=True)
                    .distinct()[:room]
                ):
                    other = str(member_id)
                    if other in seen:
                        continue
                    seen.add(other)
                    user_ids.append(other)

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
        requested_user_id = self.scope['url_route']['kwargs']['user_id']
        authenticated_user = self.scope.get('user')

        if not authenticated_user or authenticated_user.is_anonymous:
            await self.close()
            return

        if str(authenticated_user.id) != str(requested_user_id):
            await self.close()
            return

        self.user_id = str(authenticated_user.id)
        self.notification_group_name = f'notifications_{self.user_id}'
        self.user = authenticated_user
        
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
