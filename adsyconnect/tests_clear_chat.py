# -*- coding: utf-8 -*-
"""Clearing a chat must clear its preview in the list, for the person who
cleared it and nobody else.

Both previews matter. last_message is computed and was already hidden; the
app falls back to last_message_preview when it is null, and that one is a
column on the room — the same string for both people, knowing nothing about
a clear only one of them performed. So the message just deleted came back as
the chat-list preview.
"""
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.test import TestCase
from rest_framework.test import APIRequestFactory

from .models import ChatGroup, ChatGroupMembership, ChatRoom, Message
from .serializers import ChatGroupSerializer, ChatRoomSerializer

User = get_user_model()


def make(name, n):
    return User.objects.create_user(
        username=name, email='%s@example.com' % name, password='x',
        first_name=name.title(), phone='+8801000001%03d' % n,
    )


class ClearedChatPreviewTests(TestCase):
    def setUp(self):
        self.a = make('mina', 1)
        self.b = make('raju', 2)
        self.room = ChatRoom.objects.create(user1=self.a, user2=self.b)
        self.message = Message.objects.create(
            chatroom=self.room, sender=self.b, receiver=self.a,
            content='see you at eight',
        )
        self.room.last_message_preview = 'see you at eight'
        self.room.last_message_at = self.message.created_at
        self.room.save(update_fields=['last_message_preview', 'last_message_at'])
        self.factory = APIRequestFactory()

    def serialize_for(self, user):
        request = self.factory.get('/')
        request.user = user
        return ChatRoomSerializer(self.room, context={'request': request}).data

    def clear_for(self, user):
        field = 'cleared_at_user1' if user == self.a else 'cleared_at_user2'
        setattr(self.room, field, timezone.now())
        self.room.save(update_fields=[field])

    def test_before_clearing_both_see_the_preview(self):
        for user in (self.a, self.b):
            data = self.serialize_for(user)
            self.assertEqual(data['last_message_preview'], 'see you at eight')
            self.assertIsNotNone(data['last_message'])

    def test_the_person_who_cleared_sees_neither_preview(self):
        self.clear_for(self.a)
        data = self.serialize_for(self.a)

        self.assertIsNone(data['last_message'])
        # The one the app falls back to — this is the bug being fixed.
        self.assertIsNone(data['last_message_preview'])

    def test_the_other_person_is_unaffected(self):
        """A clear is one-sided; it must not wipe the other person's list."""
        self.clear_for(self.a)
        data = self.serialize_for(self.b)

        self.assertEqual(data['last_message_preview'], 'see you at eight')
        self.assertIsNotNone(data['last_message'])

    def test_a_message_after_the_clear_comes_back(self):
        """Clearing hides history, it does not mute the conversation."""
        self.clear_for(self.a)

        later = Message.objects.create(
            chatroom=self.room, sender=self.b, receiver=self.a,
            content='are you coming',
        )
        self.room.last_message_preview = 'are you coming'
        self.room.last_message_at = later.created_at
        self.room.save(
            update_fields=['last_message_preview', 'last_message_at'])

        data = self.serialize_for(self.a)
        self.assertEqual(data['last_message_preview'], 'are you coming')
        self.assertIsNotNone(data['last_message'])


class ClearedGroupPreviewTests(TestCase):
    def setUp(self):
        self.a = make('tara', 11)
        self.b = make('sami', 12)
        self.group = ChatGroup.objects.create(name='Studio', creator=self.a)
        self.mine = ChatGroupMembership.objects.create(
            group=self.group, user=self.a, role='admin')
        ChatGroupMembership.objects.create(group=self.group, user=self.b)
        self.group.last_message_preview = 'load in at nine'
        self.group.last_message_at = timezone.now()
        self.group.save(
            update_fields=['last_message_preview', 'last_message_at'])
        self.factory = APIRequestFactory()

    def serialize_for(self, user):
        request = self.factory.get('/')
        request.user = user
        return ChatGroupSerializer(self.group, context={'request': request}).data

    def test_the_member_who_cleared_sees_no_preview(self):
        self.mine.cleared_at = timezone.now()
        self.mine.save(update_fields=['cleared_at'])

        self.assertIsNone(self.serialize_for(self.a)['last_message_preview'])

    def test_other_members_are_unaffected(self):
        self.mine.cleared_at = timezone.now()
        self.mine.save(update_fields=['cleared_at'])

        self.assertEqual(
            self.serialize_for(self.b)['last_message_preview'],
            'load in at nine',
        )
