# -*- coding: utf-8 -*-
"""The chat list must not ask the database a question per conversation.

Measured on production before this was fixed: 51 conversations, 311 queries,
589 ms — an online-status lookup, an unread COUNT, a last-message SELECT, a
block EXISTS and a spam EXISTS, each once per room. The web client polls this
endpoint every few seconds, so the cost was paid over and over.

These tests assert the SHAPE rather than an exact number: doubling the number
of conversations must not change the query count. A number would go stale the
first time anyone added a field; linear growth is the actual defect.
"""
from django.contrib.auth import get_user_model
from django.db import connection
from django.test import TestCase
from django.test.utils import CaptureQueriesContext
from rest_framework.test import APIClient

from .models import BlockedUser, ChatRoom, Message

User = get_user_model()


class ChatListQueryCountTests(TestCase):
    def setUp(self):
        self.me = User.objects.create_user(
            username='ql1', email='ql1@example.com', password='x',
            first_name='Me', phone='+880100000501')
        self.client = APIClient()
        self.client.force_authenticate(user=self.me)
        self._next = 0

    def add_conversations(self, count, *, with_messages=True):
        """Give the viewer [count] more conversations, each with traffic."""
        rooms = []
        for _ in range(count):
            self._next += 1
            other = User.objects.create_user(
                username='qlp%d' % self._next,
                email='qlp%d@example.com' % self._next,
                password='x', first_name='P%d' % self._next,
                phone='+8801000006%02d' % self._next)
            room = ChatRoom.objects.create(user1=self.me, user2=other)
            if with_messages:
                # Unread from them, read from me, and one marked spam: enough
                # to make every per-room field do real work.
                Message.objects.create(
                    chatroom=room, sender=other, receiver=self.me,
                    content='hi', message_type='text', is_read=False)
                Message.objects.create(
                    chatroom=room, sender=other, receiver=self.me,
                    content='buy now', message_type='text', is_read=False,
                    is_spam=True)
                Message.objects.create(
                    chatroom=room, sender=self.me, receiver=other,
                    content='hello', message_type='text', is_read=True)
            rooms.append(room)
        return rooms

    def fetch(self):
        with CaptureQueriesContext(connection) as ctx:
            response = self.client.get('/api/adsyconnect/chatrooms/')
        self.assertEqual(response.status_code, 200)
        return response.json(), len(ctx.captured_queries)

    # ── the shape ───────────────────────────────────────────────────────────

    def test_the_query_count_does_not_grow_with_the_conversations(self):
        self.add_conversations(3)
        rooms_a, queries_a = self.fetch()
        self.assertEqual(len(rooms_a), 3)

        self.add_conversations(9)
        rooms_b, queries_b = self.fetch()
        self.assertEqual(len(rooms_b), 12)

        self.assertEqual(
            queries_a, queries_b,
            'four times the conversations cost %d queries instead of %d — '
            'something in the serializer is querying per row again'
            % (queries_b, queries_a))

    def test_a_long_list_stays_well_under_the_old_cost(self):
        """A guard rail with a real number, generous enough to survive edits.

        Twenty conversations used to be ~120 queries. Anything near that means
        the per-row queries are back.
        """
        self.add_conversations(20)
        _rooms, queries = self.fetch()
        self.assertLess(queries, 25, '%d queries for 20 conversations' % queries)

    # ── and it still answers correctly ──────────────────────────────────────

    def test_unread_counts_are_right_per_room(self):
        rooms = self.add_conversations(3)
        # Two more unread in the first room only.
        other = rooms[0].get_other_user(self.me)
        for _ in range(2):
            Message.objects.create(
                chatroom=rooms[0], sender=other, receiver=self.me,
                content='more', message_type='text', is_read=False)

        data, _ = self.fetch()
        by_id = {row['id']: row for row in data}
        self.assertEqual(by_id[str(rooms[0].id)]['unread_count'], 4)
        self.assertEqual(by_id[str(rooms[1].id)]['unread_count'], 2)

    def test_the_last_message_is_the_newest_one_in_that_room(self):
        rooms = self.add_conversations(2)
        other = rooms[1].get_other_user(self.me)
        newest = Message.objects.create(
            chatroom=rooms[1], sender=other, receiver=self.me,
            content='the newest thing', message_type='text')

        data, _ = self.fetch()
        by_id = {row['id']: row for row in data}
        self.assertEqual(
            by_id[str(rooms[1].id)]['last_message']['id'], str(newest.id))
        self.assertEqual(
            by_id[str(rooms[1].id)]['last_message']['content'],
            'the newest thing')
        # The other room keeps its own last message, not the newest overall.
        self.assertEqual(
            by_id[str(rooms[0].id)]['last_message']['content'], 'hello')

    def test_is_me_on_the_last_message_still_works(self):
        rooms = self.add_conversations(1)
        data, _ = self.fetch()
        self.assertTrue(data[0]['last_message']['is_me'])

        other = rooms[0].get_other_user(self.me)
        Message.objects.create(
            chatroom=rooms[0], sender=other, receiver=self.me,
            content='theirs', message_type='text')
        data, _ = self.fetch()
        self.assertFalse(data[0]['last_message']['is_me'])

    def test_a_conversation_with_no_messages_is_not_listed_at_all(self):
        """The viewset filters those out; the caches must cope regardless."""
        room = self.add_conversations(1, with_messages=False)[0]
        data, _ = self.fetch()
        self.assertEqual(data, [])

        # And asked for directly it serialises with nothing rather than
        # blowing up on an empty cache.
        response = self.client.get('/api/adsyconnect/chatrooms/%s/' % room.id)
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertIsNone(body['last_message'])
        self.assertEqual(body['unread_count'], 0)
        self.assertFalse(body['is_spam'])

    def test_spam_is_flagged_on_the_right_room_only(self):
        self.add_conversations(1)                       # has a spam message
        clean = self.add_conversations(1, with_messages=False)[0]
        other = clean.get_other_user(self.me)
        Message.objects.create(
            chatroom=clean, sender=other, receiver=self.me,
            content='normal', message_type='text')

        data, _ = self.fetch()
        by_id = {row['id']: row for row in data}
        self.assertFalse(by_id[str(clean.id)]['is_spam'])
        spam_rooms = [r for r in data if r['is_spam']]
        self.assertEqual(len(spam_rooms), 1)

    def test_my_own_spam_does_not_flag_my_own_chat(self):
        """The bucket is "they sent me spam", not "this room contains spam"."""
        room = self.add_conversations(1, with_messages=False)[0]
        other = room.get_other_user(self.me)
        Message.objects.create(
            chatroom=room, sender=self.me, receiver=other,
            content='mine', message_type='text', is_spam=True)
        data, _ = self.fetch()
        self.assertFalse(data[0]['is_spam'])

    def test_blocked_by_me_is_right_per_room(self):
        rooms = self.add_conversations(2)
        blocked = rooms[0].get_other_user(self.me)
        BlockedUser.objects.create(blocker=self.me, blocked=blocked)

        data, _ = self.fetch()
        by_id = {row['id']: row for row in data}
        self.assertTrue(by_id[str(rooms[0].id)]['blocked_by_me'])
        self.assertFalse(by_id[str(rooms[1].id)]['blocked_by_me'])

    def test_somebody_blocking_me_is_not_blocked_by_me(self):
        room = self.add_conversations(1)[0]
        other = room.get_other_user(self.me)
        BlockedUser.objects.create(blocker=other, blocked=self.me)
        data, _ = self.fetch()
        self.assertFalse(data[0]['blocked_by_me'])

    def test_online_status_survives_the_join(self):
        room = self.add_conversations(1)[0]
        other = room.get_other_user(self.me)
        other.online_status.register_connection()

        data, queries = self.fetch()
        self.assertTrue(data[0]['other_user']['is_online'])
        self.assertLess(queries, 25)

    def test_a_single_room_detail_still_serialises(self):
        """The caches key off the serializer's instance, list or not."""
        room = self.add_conversations(1)[0]
        response = self.client.get('/api/adsyconnect/chatrooms/%s/' % room.id)
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body['unread_count'], 2)
        self.assertEqual(body['last_message']['content'], 'hello')
        self.assertTrue(body['is_spam'])


class GroupListQueryCountTests(TestCase):
    """The group list had the same shape: a membership lookup and a COUNT per
    group, plus a COUNT for the member total. Seven groups cost 51 queries."""

    def setUp(self):
        from .models import ChatGroup, ChatGroupMembership, GroupMessage
        self.ChatGroup = ChatGroup
        self.Membership = ChatGroupMembership
        self.GroupMessage = GroupMessage

        self.me = User.objects.create_user(
            username='gq1', email='gq1@example.com', password='x',
            first_name='Me', phone='+880100000701')
        self.mate = User.objects.create_user(
            username='gq2', email='gq2@example.com', password='x',
            first_name='Mate', phone='+880100000702')
        self.client = APIClient()
        self.client.force_authenticate(user=self.me)
        self._next = 0

    def add_groups(self, count, *, messages=2):
        made = []
        for _ in range(count):
            self._next += 1
            group = self.ChatGroup.objects.create(
                name='G%d' % self._next, creator=self.me)
            for user in (self.me, self.mate):
                self.Membership.objects.create(
                    group=group, user=user,
                    role='admin' if user == self.me else 'member')
            for i in range(messages):
                self.GroupMessage.objects.create(
                    group=group, sender=self.mate, content='m%d' % i,
                    message_type='text')
            made.append(group)
        return made

    def fetch(self):
        with CaptureQueriesContext(connection) as ctx:
            response = self.client.get('/api/adsyconnect/groups/')
        self.assertEqual(response.status_code, 200)
        body = response.json()
        rows = body if isinstance(body, list) else body.get('results', [])
        return rows, len(ctx.captured_queries)

    def test_the_query_count_does_not_grow_with_the_groups(self):
        self.add_groups(2)
        rows_a, queries_a = self.fetch()
        self.assertEqual(len(rows_a), 2)

        self.add_groups(6)
        rows_b, queries_b = self.fetch()
        self.assertEqual(len(rows_b), 8)

        self.assertEqual(
            queries_a, queries_b,
            'four times the groups cost %d queries instead of %d'
            % (queries_b, queries_a))

    def test_unread_is_still_counted_per_member_cutoff(self):
        groups = self.add_groups(2)
        rows, _ = self.fetch()
        by_id = {row['id']: row for row in rows}
        self.assertEqual(by_id[str(groups[0].id)]['unread_count'], 2)

        # Reading the first group must not touch the second one's badge.
        self.client.get(
            '/api/adsyconnect/groups/%s/messages/' % groups[0].id)
        rows, _ = self.fetch()
        by_id = {row['id']: row for row in rows}
        self.assertEqual(by_id[str(groups[0].id)]['unread_count'], 0)
        self.assertEqual(by_id[str(groups[1].id)]['unread_count'], 2)

    def test_a_group_with_no_messages_reads_as_zero(self):
        self.add_groups(1, messages=0)
        rows, _ = self.fetch()
        self.assertEqual(rows[0]['unread_count'], 0)

    def test_member_count_and_role_survive(self):
        self.add_groups(1)
        rows, _ = self.fetch()
        self.assertEqual(rows[0]['member_count'], 2)
        self.assertEqual(rows[0]['my_role'], 'admin')
