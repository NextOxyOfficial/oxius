from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.db.models import Count, Q

from base.upload_limits import check_upload
from .models import (
    ChatRoom, Message, MessageReport,
    BlockedUser, TypingStatus, OnlineStatus,
    ChatGroup, ChatGroupMembership, GroupMessage,
)

User = get_user_model()


class UserBasicSerializer(serializers.ModelSerializer):
    """Basic user info for chat"""
    avatar = serializers.SerializerMethodField()
    is_online = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        # is_active/is_suspended let chat clients label deleted/suspended
        # accounts and disable their profile links.
        fields = ['id', 'username', 'first_name', 'last_name', 'avatar',
                  'is_online', 'profession', 'is_pro', 'kyc',
                  'is_active', 'is_suspended']
    
    def get_avatar(self, obj):
        if hasattr(obj, 'image') and obj.image:
            request = self.context.get('request')
            if request:
                url = request.build_absolute_uri(obj.image.url)
                # Ensure HTTPS in production
                if url.startswith('http://') and not request.get_host().startswith('127.0.0.1') and not request.get_host().startswith('localhost'):
                    url = url.replace('http://', 'https://', 1)
                return url
            return obj.image.url
        return None
    
    def get_is_online(self, obj):
        try:
            return obj.online_status.is_effectively_online()
        except Exception:
            return False


def _reaction_payload(obj, context):
    """[{emoji, count, reacted_by_me}] for a message — shared by 1:1 + group."""
    request = context.get("request")
    me = getattr(getattr(request, "user", None), "id", None)
    counts, mine = {}, None
    for r in obj.reactions.all():
        counts[r.emoji] = counts.get(r.emoji, 0) + 1
        if me is not None and str(r.user_id) == str(me):
            mine = r.emoji
    return [
        {"emoji": e, "count": c, "reacted_by_me": e == mine}
        for e, c in sorted(counts.items(), key=lambda kv: -kv[1])
    ]


class MessageSerializer(serializers.ModelSerializer):
    """Message serializer"""
    sender = UserBasicSerializer(read_only=True)
    receiver = UserBasicSerializer(read_only=True)
    media_url = serializers.SerializerMethodField()
    thumbnail_url = serializers.SerializerMethodField()
    display_content = serializers.SerializerMethodField()
    time_display = serializers.SerializerMethodField()
    reactions = serializers.SerializerMethodField()

    def get_reactions(self, obj):
        return _reaction_payload(obj, self.context)

    class Meta:
        model = Message
        fields = [
            'id', 'chatroom', 'sender', 'receiver', 'message_type', 
            'content', 'display_content', 'media_url', 'thumbnail_url', 
            'file_name', 'file_size', 'voice_duration', 'is_read', 'read_at', 
            'is_deleted', 'is_edited', 'edited_at', 'created_at', 'updated_at', 'time_display',
            'reactions',
        ]
        read_only_fields = ['id', 'sender', 'receiver', 'created_at', 
                           'updated_at', 'read_at', 'is_edited', 'edited_at']
    
    def get_media_url(self, obj):
        if obj.media_file:
            request = self.context.get('request')
            if request:
                url = request.build_absolute_uri(obj.media_file.url)
                # Ensure HTTPS in production
                if url.startswith('http://') and not request.get_host().startswith('127.0.0.1') and not request.get_host().startswith('localhost'):
                    url = url.replace('http://', 'https://', 1)
                return url
        return None
    
    def get_thumbnail_url(self, obj):
        if obj.media_thumbnail:
            request = self.context.get('request')
            if request:
                url = request.build_absolute_uri(obj.media_thumbnail.url)
                # Ensure HTTPS in production
                if url.startswith('http://') and not request.get_host().startswith('127.0.0.1') and not request.get_host().startswith('localhost'):
                    url = url.replace('http://', 'https://', 1)
                return url
        return None
    
    def get_display_content(self, obj):
        """Return 'Message removed' for deleted messages"""
        return obj.get_display_content()
    
    def get_time_display(self, obj):
        """Return smart time display or None if within same minute"""
        return obj.get_time_display()


class MessageCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating messages"""
    
    class Meta:
        model = Message
        fields = [
            'chatroom', 'receiver', 'message_type', 'content', 
            'media_file', 'file_name', 'voice_duration'
        ]
    
    def validate(self, data):
        message_type = data.get('message_type')
        content = data.get('content')
        media_file = data.get('media_file')
        request = self.context.get('request')
        sender = getattr(request, 'user', None)
        receiver = data.get('receiver')
        chatroom = data.get('chatroom')
        
        # Validate based on message type
        if message_type == 'text' and not content:
            raise serializers.ValidationError("Text messages must have content")
        
        if message_type in ['image', 'video', 'document', 'voice'] and not media_file:
            raise serializers.ValidationError(f"{message_type} messages must have a media file")

        # Nothing capped the size of this before. FILE_UPLOAD_MAX_MEMORY_SIZE
        # only decides when Django stops holding the bytes in RAM, so a 500MB
        # "video" was accepted, spooled to disk and streamed on to R2.
        if media_file is not None:
            check_upload(media_file, declared_kind=message_type)

        if sender and receiver and chatroom:
            is_chat_blocked = bool(chatroom.is_blocked)
            is_user_blocked = BlockedUser.objects.filter(
                Q(blocker=sender, blocked=receiver) |
                Q(blocker=receiver, blocked=sender)
            ).exists()
            if is_chat_blocked or is_user_blocked:
                raise serializers.ValidationError(
                    "Messaging is disabled because one of the users has blocked this conversation."
                )
        
        return data
    
    def create(self, validated_data):
        # Set sender from request user
        validated_data['sender'] = self.context['request'].user
        return super().create(validated_data)


class ChatRoomSerializer(serializers.ModelSerializer):
    """ChatRoom serializer with user details"""
    other_user = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    blocked_by_me = serializers.SerializerMethodField()
    is_archived = serializers.SerializerMethodField()
    is_muted = serializers.SerializerMethodField()
    # Chat-list tab classification.
    i_follow_them = serializers.SerializerMethodField()
    they_follow_me = serializers.SerializerMethodField()
    is_mutual = serializers.SerializerMethodField()
    is_spam = serializers.SerializerMethodField()
    last_message_preview = serializers.SerializerMethodField()

    class Meta:
        model = ChatRoom
        fields = [
            'id', 'other_user', 'last_message_at', 'last_message_preview',
            'unread_count', 'last_message', 'is_blocked', 'blocked_by',
            'blocked_by_me', 'is_archived', 'is_muted',
            'i_follow_them', 'they_follow_me', 'is_mutual', 'is_spam',
            'created_at', 'updated_at'
        ]

    def get_is_archived(self, obj):
        user = getattr(self.context.get('request'), 'user', None)
        return obj.is_archived_for(user) if user else False

    def get_is_muted(self, obj):
        user = getattr(self.context.get('request'), 'user', None)
        return obj.is_muted_for(user) if user else False

    # ── per-list caches ─────────────────────────────────────────────────
    #
    # A SerializerMethodField runs once per row, so anything that queries
    # inside one is a query per conversation. These four each answer for every
    # room in the list in a single round trip, computed on first use and held
    # for the life of the serializer (one request).

    def _room_ids(self):
        """The rooms in this list, whether it is a list or a single room."""
        instance = self.instance
        if instance is None:
            return []
        if isinstance(instance, ChatRoom):
            return [instance.id]
        try:
            return [room.id for room in instance]
        except TypeError:
            return []

    def _blocked_by_me_ids(self):
        """Users the viewer has blocked — one query for the whole list."""
        if not hasattr(self, '_blocked_cache'):
            user = getattr(self.context.get('request'), 'user', None)
            if not user or not getattr(user, 'is_authenticated', False):
                self._blocked_cache = set()
            else:
                self._blocked_cache = {
                    str(uid) for uid in BlockedUser.objects.filter(
                        blocker=user
                    ).values_list('blocked_id', flat=True)
                }
        return self._blocked_cache

    def _last_messages(self):
        """{room_id: Message} — the newest message in each room, in one query.

        DISTINCT ON is Postgres-specific, which this project is, and is the
        only way to get one row per group without a query per room or pulling
        every message in the conversation into memory.
        """
        if not hasattr(self, '_last_message_cache'):
            room_ids = self._room_ids()
            if not room_ids:
                self._last_message_cache = {}
            else:
                rows = (
                    Message.objects.filter(chatroom_id__in=room_ids)
                    .select_related('sender')
                    .order_by('chatroom_id', '-created_at')
                    .distinct('chatroom_id')
                )
                self._last_message_cache = {
                    str(m.chatroom_id): m for m in rows
                }
        return self._last_message_cache

    def _unread_counts(self):
        """{room_id: count} — every room's unread total in one grouped query."""
        if not hasattr(self, '_unread_cache'):
            user = getattr(self.context.get('request'), 'user', None)
            room_ids = self._room_ids()
            if not user or not room_ids:
                self._unread_cache = {}
            else:
                rows = (
                    Message.objects.filter(
                        chatroom_id__in=room_ids, is_read=False,
                    )
                    .exclude(sender=user)
                    .values('chatroom_id')
                    .annotate(n=Count('id'))
                )
                self._unread_cache = {
                    str(row['chatroom_id']): row['n'] for row in rows
                }
        return self._unread_cache

    def _spam_room_ids(self):
        """Rooms where the other person has sent something marked spam."""
        if not hasattr(self, '_spam_cache'):
            user = getattr(self.context.get('request'), 'user', None)
            room_ids = self._room_ids()
            if not user or not room_ids:
                self._spam_cache = set()
            else:
                self._spam_cache = {
                    str(cid) for cid in Message.objects.filter(
                        chatroom_id__in=room_ids, is_spam=True,
                        is_deleted=False,
                    ).exclude(sender=user).values_list(
                        'chatroom_id', flat=True
                    ).distinct()
                }
        return self._spam_cache

    def _follow_sets(self):
        """(i_follow ids, they_follow ids) for the current user, computed once
        per request and shared across every room in the list (avoids N+1)."""
        request = self.context.get('request')
        user = getattr(request, 'user', None)
        if not user or not getattr(user, 'is_authenticated', False):
            return set(), set()
        cache = getattr(request, '_adsy_follow_sets', None)
        if cache is not None:
            return cache
        from business_network.models import BusinessNetworkFollowerModel as F_

        i_follow = set(
            F_.objects.filter(follower=user).values_list('following_id', flat=True)
        )
        follow_me = set(
            F_.objects.filter(following=user).values_list('follower_id', flat=True)
        )
        cache = (i_follow, follow_me)
        request._adsy_follow_sets = cache
        return cache

    def _other_id(self, obj):
        user = getattr(self.context.get('request'), 'user', None)
        if not user:
            return None
        return obj.user2_id if obj.user1_id == user.id else obj.user1_id

    def get_i_follow_them(self, obj):
        other = self._other_id(obj)
        return other in self._follow_sets()[0] if other else False

    def get_they_follow_me(self, obj):
        other = self._other_id(obj)
        return other in self._follow_sets()[1] if other else False

    def get_is_mutual(self, obj):
        return self.get_i_follow_them(obj) and self.get_they_follow_me(obj)

    def get_is_spam(self, obj):
        return str(obj.id) in self._spam_room_ids()

    def get_blocked_by_me(self, obj):
        """True if the current user is the one who blocked this conversation.

        The frontend uses this to decide whether to show the 'Unblock' action:
        only the user who placed the block can lift it. Computed from the
        canonical BlockedUser table so it stays correct regardless of which
        surface (chat or business-network profile) created the block.
        """
        user = getattr(self.context.get('request'), 'user', None)
        if user and user.is_authenticated:
            other_user = obj.get_other_user(user)
            if other_user:
                return str(other_user.id) in self._blocked_by_me_ids()
        return False
    
    def get_other_user(self, obj):
        request = self.context.get('request')
        if request and request.user:
            other_user = obj.get_other_user(request.user)
            return UserBasicSerializer(other_user, context=self.context).data
        return None
    
    def get_unread_count(self, obj):
        request = self.context.get('request')
        if request and request.user:
            return self._unread_counts().get(str(obj.id), 0)
        return 0
    
    def _cleared_at_for(self, obj):
        """When this viewer cleared the chat, if they did."""
        user = getattr(self.context.get('request'), 'user', None)
        if user is None:
            return None
        if user == obj.user1:
            return obj.cleared_at_user1
        if user == obj.user2:
            return obj.cleared_at_user2
        return None

    def get_last_message_preview(self, obj):
        """The denormalised preview, hidden from whoever cleared the chat.

        A column on the room, so it is the same string for both people and
        knows nothing about a clear that only one of them performed. The app
        falls back to it when last_message is null — which is exactly what
        the clear makes it — so the message the user had just deleted came
        straight back as the chat-list preview. Both now answer to the clear.
        """
        cleared_at = self._cleared_at_for(obj)
        if cleared_at is not None:
            last_at = obj.last_message_at
            if last_at is None or last_at <= cleared_at:
                return None
        return obj.last_message_preview

    def get_last_message(self, obj):
        # Include deleted messages so frontend can show "Message removed"
        last_msg = self._last_messages().get(str(obj.id))

        # Respect a per-user clear: the participant who cleared must not see a
        # pre-clear message resurface as the chat-list preview.
        cleared_at = self._cleared_at_for(obj)
        if (last_msg is not None
                and cleared_at is not None
                and last_msg.created_at <= cleared_at):
            return None

        if last_msg:
            return {
                'id': str(last_msg.id),
                'content': last_msg.get_preview(),
                'message_type': last_msg.message_type,
                'created_at': last_msg.created_at,
                'is_me': last_msg.sender == self.context.get('request').user,
                'is_deleted': last_msg.is_deleted  # Include deleted status
            }
        return None


class MessageReportSerializer(serializers.ModelSerializer):
    """Message report serializer"""
    reporter = UserBasicSerializer(read_only=True)
    reported_user = serializers.PrimaryKeyRelatedField(queryset=User.objects.all())
    reported_user_info = UserBasicSerializer(source='reported_user', read_only=True)
    
    class Meta:
        model = MessageReport
        fields = [
            'id', 'reporter', 'reported_user', 'message', 'reason',
            'reported_user_info', 'description', 'status', 'created_at'
        ]
        read_only_fields = ['id', 'reporter', 'status', 'created_at']
    
    def create(self, validated_data):
        validated_data['reporter'] = self.context['request'].user
        return super().create(validated_data)


class BlockedUserSerializer(serializers.ModelSerializer):
    """Blocked user serializer"""
    blocker = UserBasicSerializer(read_only=True)
    blocked = serializers.PrimaryKeyRelatedField(queryset=User.objects.all())
    blocked_info = UserBasicSerializer(source='blocked', read_only=True)
    
    class Meta:
        model = BlockedUser
        fields = ['id', 'blocker', 'blocked', 'blocked_info', 'reason', 'created_at']
        read_only_fields = ['id', 'blocker', 'created_at']
    
    def create(self, validated_data):
        validated_data['blocker'] = self.context['request'].user
        return super().create(validated_data)


class OnlineStatusSerializer(serializers.ModelSerializer):
    """Online status serializer"""
    user = UserBasicSerializer(read_only=True)
    user_id = serializers.CharField(read_only=True)
    is_online = serializers.SerializerMethodField()
    
    class Meta:
        model = OnlineStatus
        fields = ['user', 'user_id', 'is_online', 'last_seen']
        read_only_fields = ['user', 'last_seen']

    def get_is_online(self, obj):
        return obj.is_effectively_online()


class TypingStatusSerializer(serializers.ModelSerializer):
    """Typing status serializer"""
    user = UserBasicSerializer(read_only=True)
    
    class Meta:
        model = TypingStatus
        fields = ['id', 'chatroom', 'user', 'is_typing', 'updated_at']
        read_only_fields = ['id', 'user', 'updated_at']


class GroupMemberSerializer(serializers.ModelSerializer):
    """A group member with their role."""
    user = UserBasicSerializer(read_only=True)

    class Meta:
        model = ChatGroupMembership
        fields = ['user', 'role', 'joined_at']


class GroupMessageSerializer(serializers.ModelSerializer):
    sender = UserBasicSerializer(read_only=True)
    media_url = serializers.SerializerMethodField()
    # Quote-reply metadata (same shape the 1:1 bubbles consume).
    reply_to = serializers.SerializerMethodField()
    reply_preview = serializers.SerializerMethodField()
    reply_sender_name = serializers.SerializerMethodField()
    reactions = serializers.SerializerMethodField()
    # How many other members have seen this, and whether that is all of them.
    #
    # A group message carried no read state at all, so a sender could not tell
    # whether anybody had seen it — the one-to-one chat has had receipts from
    # the start.
    #
    # DERIVED from the last_read_at that ChatGroupMembership already keeps for
    # the unread badge, rather than a row per message per member: a join table
    # would be one write per member per message read, for a number the badge
    # can already answer.
    read_count = serializers.SerializerMethodField()
    read_by_all = serializers.SerializerMethodField()

    def get_reactions(self, obj):
        return _reaction_payload(obj, self.context)

    def _read_state(self, obj):
        """(read_count, eligible_count) for this message.

        The membership rows are fetched ONCE for the whole page and held on the
        serializer, so a hundred messages cost one query rather than a hundred.
        A ListSerializer reuses a single child instance, which is what makes
        caching on `self` work with many=True.
        """
        group_id = getattr(obj, 'group_id', None)
        if not hasattr(self, '_membership_rows'):
            self._membership_rows = {}
        # Keyed BY GROUP rather than one list for the serializer.
        #
        # Every caller today passes messages from a single group, so a single
        # list would work — and would silently return one group's receipts for
        # another's the first time somebody serialised across groups. One query
        # per group in the page either way.
        if group_id not in self._membership_rows:
            self._membership_rows[group_id] = list(
                ChatGroupMembership.objects
                .filter(group_id=group_id)
                .values_list('user_id', 'joined_at', 'last_read_at',
                             'cleared_at')
            ) if group_id else []
        rows = self._membership_rows[group_id]

        created_at = obj.created_at
        if created_at is None:
            return 0, 0

        read = 0
        eligible = 0
        for user_id, joined_at, last_read_at, cleared_at in rows:
            # The sender is not part of their own receipt.
            if user_id == obj.sender_id:
                continue
            # Somebody who joined after the message was sent never had it to
            # read, so counting them would make "seen by all" unreachable.
            if joined_at is not None and joined_at > created_at:
                continue
            eligible += 1
            stamp = last_read_at or cleared_at
            if stamp is not None and stamp >= created_at:
                read += 1
        return read, eligible

    def get_read_count(self, obj):
        return self._read_state(obj)[0]

    def get_read_by_all(self, obj):
        read, eligible = self._read_state(obj)
        return eligible > 0 and read >= eligible

    class Meta:
        model = GroupMessage
        fields = [
            'id', 'group', 'sender', 'message_type', 'content', 'media_url',
            'file_name', 'voice_duration', 'created_at', 'is_deleted',
            'is_edited', 'edited_at',
            'reply_to', 'reply_preview', 'reply_sender_name', 'reactions',
            'read_count', 'read_by_all',
        ]
        read_only_fields = [
            'id', 'sender', 'created_at', 'is_deleted', 'is_edited', 'edited_at',
        ]

    def get_reply_to(self, obj):
        return str(obj.reply_to_id) if obj.reply_to_id else None

    def get_reply_preview(self, obj):
        r = obj.reply_to
        if not r:
            return None
        if r.is_deleted:
            return 'Message removed'
        return r.get_preview()

    def get_reply_sender_name(self, obj):
        r = obj.reply_to
        if not r or not r.sender:
            return None
        return (
            f'{r.sender.first_name or ""} {r.sender.last_name or ""}'.strip()
            or r.sender.username
        )

    def get_media_url(self, obj):
        if not obj.media_file:
            return None
        request = self.context.get('request')
        url = obj.media_file.url
        if request:
            url = request.build_absolute_uri(url)
            if url.startswith('http://') and 'localhost' not in url and '127.0.0.1' not in url:
                url = url.replace('http://', 'https://', 1)
        return url


class ChatGroupSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()
    member_count = serializers.SerializerMethodField()
    my_role = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    members = GroupMemberSerializer(source='memberships', many=True, read_only=True)
    last_message_preview = serializers.SerializerMethodField()

    class Meta:
        model = ChatGroup
        fields = [
            'id', 'name', 'image_url', 'creator', 'member_count', 'my_role',
            'unread_count', 'members', 'last_message_at',
            'last_message_preview', 'created_at',
        ]
        read_only_fields = fields

    def get_last_message_preview(self, obj):
        """Hidden from a member who cleared the group, same as the 1:1 case.

        ChatGroupMembership.cleared_at is per-member; this column is not.
        """
        user = getattr(self.context.get('request'), 'user', None)
        if user is None or not getattr(user, 'is_authenticated', False):
            return obj.last_message_preview

        membership = next(
            (m for m in obj.memberships.all() if m.user_id == user.id), None)
        cleared_at = getattr(membership, 'cleared_at', None)
        if cleared_at is not None:
            last_at = obj.last_message_at
            if last_at is None or last_at <= cleared_at:
                return None
        return obj.last_message_preview

    def get_image_url(self, obj):
        if not obj.image:
            return None
        request = self.context.get('request')
        url = obj.image.url
        if request:
            url = request.build_absolute_uri(url)
            if url.startswith('http://') and 'localhost' not in url and '127.0.0.1' not in url:
                url = url.replace('http://', 'https://', 1)
        return url

    def get_member_count(self, obj):
        # len() of the prefetched list, not .count() — a COUNT here is one
        # query per group in the chat list, and the members are already loaded
        # for the `members` field anyway.
        return len(obj.memberships.all())

    def _my_membership(self, obj):
        """This viewer's membership row, from the prefetched list.

        .filter(user=...) on the related manager ignores the prefetch and
        issues a query per group — and my_role and unread_count each did one.
        """
        user = getattr(self.context.get('request'), 'user', None)
        if not user or not getattr(user, 'is_authenticated', False):
            return None
        return next(
            (m for m in obj.memberships.all() if m.user_id == user.id), None)

    def get_my_role(self, obj):
        m = self._my_membership(obj)
        return m.role if m else None

    def get_unread_count(self, obj):
        """Messages by others since the member last opened the group.

        Cutoff = last_read_at, else cleared_at, else joined_at — so a fresh
        member doesn't inherit the whole history as unread.
        """
        m = self._my_membership(obj)
        if m is None:
            return 0
        return self._group_unread_counts().get(str(obj.id), 0)

    def _group_ids(self):
        instance = self.instance
        if instance is None:
            return []
        if isinstance(instance, ChatGroup):
            return [instance.id]
        try:
            return [group.id for group in instance]
        except TypeError:
            return []

    def _group_unread_counts(self):
        """{group_id: unread} for every listed group, in ONE query.

        A COUNT per group is one round trip per group in the chat list. Each
        member has their own cutoff, so the counts cannot share a single WHERE
        — but they can share a single query: one OR-ed clause per group, and
        the database does the counting and the grouping.

        Deliberately not "fetch the dates and count in Python": that would
        pull every message in every group into memory, which is worse than the
        COUNT it replaced for any group with real history.
        """
        if not hasattr(self, '_group_unread_cache'):
            user = getattr(self.context.get('request'), 'user', None)
            groups = self._group_ids()
            if not user or not getattr(user, 'is_authenticated', False) or not groups:
                self._group_unread_cache = {}
                return self._group_unread_cache

            instance = self.instance
            rows = [instance] if isinstance(instance, ChatGroup) else list(instance)

            clause = Q(pk__in=[])          # matches nothing, so an empty list is safe
            for group in rows:
                membership = self._my_membership(group)
                if membership is None:
                    continue
                cutoff = (membership.last_read_at or membership.cleared_at
                          or membership.joined_at)
                if cutoff is None:
                    clause |= Q(group_id=group.id)
                else:
                    clause |= Q(group_id=group.id, created_at__gt=cutoff)

            counted = (
                GroupMessage.objects.filter(clause, is_deleted=False)
                .exclude(sender=user)
                .exclude(message_type='system')
                .values('group_id')
                .annotate(n=Count('id'))
            )
            self._group_unread_cache = {
                str(row['group_id']): row['n'] for row in counted
            }
        return self._group_unread_cache
