# -*- coding: utf-8 -*-
"""A group message needs to say whether anybody has seen it.

Group messages carried no read state at all, so a sender had no idea whether
their message had been read — while the one-to-one chat has had receipts from
the start.

Derived from the last_read_at that ChatGroupMembership already keeps for the
unread badge, rather than a row per message per member. A join table would mean
one write per member per message read, to answer a question the badge's own
timestamp already answers.
"""
from datetime import timedelta

from django.contrib.auth import get_user_model
from django.db import connection
from django.test import TestCase
from django.test.utils import CaptureQueriesContext
from django.utils import timezone
from rest_framework.test import APIClient

from .models import ChatGroup, ChatGroupMembership, GroupMessage
from .serializers import GroupMessageSerializer

User = get_user_model()


class GroupReadReceiptTests(TestCase):
    def setUp(self):
        self.sender = User.objects.create_user(
            username='rr1', email='rr1@example.com', password='x',
            first_name='Sender', phone='+880100005001')
        self.a = User.objects.create_user(
            username='rr2', email='rr2@example.com', password='x',
            first_name='A', phone='+880100005002')
        self.b = User.objects.create_user(
            username='rr3', email='rr3@example.com', password='x',
            first_name='B', phone='+880100005003')

        self.group = ChatGroup.objects.create(name='Receipts',
                                              creator=self.sender)
        self.joined = timezone.now() - timedelta(days=1)
        for user in (self.sender, self.a, self.b):
            ChatGroupMembership.objects.create(
                group=self.group, user=user, joined_at=self.joined)

        self.msg = GroupMessage.objects.create(
            group=self.group, sender=self.sender, content='hello',
            message_type='text')

    def state(self, message=None):
        data = GroupMessageSerializer(message or self.msg).data
        return data['read_count'], data['read_by_all']

    def mark_read(self, user, when=None):
        ChatGroupMembership.objects.filter(
            group=self.group, user=user
        ).update(last_read_at=when or timezone.now())

    # ── counting ────────────────────────────────────────────────────────────

    def test_nobody_has_read_it_yet(self):
        self.assertEqual(self.state(), (0, False))

    def test_one_reader_counts_once(self):
        self.mark_read(self.a)
        self.assertEqual(self.state(), (1, False))

    def test_everybody_reading_it_is_read_by_all(self):
        self.mark_read(self.a)
        self.mark_read(self.b)
        self.assertEqual(self.state(), (2, True))

    def test_the_sender_is_not_counted_as_a_reader(self):
        """Otherwise every message would start out half-read."""
        self.mark_read(self.sender)
        self.assertEqual(self.state(), (0, False))

    def test_a_read_stamp_from_before_the_message_does_not_count(self):
        self.mark_read(self.a, when=self.msg.created_at - timedelta(minutes=5))
        self.assertEqual(self.state(), (0, False))

    def test_a_read_stamp_exactly_on_the_message_counts(self):
        self.mark_read(self.a, when=self.msg.created_at)
        self.assertEqual(self.state(), (1, False))

    def test_clearing_the_chat_counts_as_having_seen_it(self):
        """cleared_at is the badge's fallback cutoff, so it must agree here."""
        ChatGroupMembership.objects.filter(
            group=self.group, user=self.a
        ).update(last_read_at=None, cleared_at=timezone.now())
        self.assertEqual(self.state(), (1, False))

    # ── membership changes ──────────────────────────────────────────────────

    def test_somebody_who_joined_after_the_message_is_not_expected_to_read_it(self):
        """Otherwise "seen by all" could never be reached again."""
        latecomer = User.objects.create_user(
            username='rr4', email='rr4@example.com', password='x',
            first_name='Late', phone='+880100005004')
        ChatGroupMembership.objects.create(
            group=self.group, user=latecomer,
            joined_at=timezone.now() + timedelta(minutes=1))

        self.mark_read(self.a)
        self.mark_read(self.b)
        self.assertEqual(self.state(), (2, True))

    def test_a_removed_member_stops_being_expected_to_read_it(self):
        ChatGroupMembership.objects.filter(
            group=self.group, user=self.b).delete()
        self.mark_read(self.a)
        self.assertEqual(self.state(), (1, True))

    def test_a_message_in_a_group_of_one_is_never_read_by_all(self):
        """There is nobody to read it, so claiming "seen by all" would lie."""
        ChatGroupMembership.objects.filter(group=self.group).exclude(
            user=self.sender).delete()
        self.assertEqual(self.state(), (0, False))

    # ── cost ────────────────────────────────────────────────────────────────

    def test_a_page_of_messages_costs_one_membership_query(self):
        """A receipt per message must not become a query per message."""
        for i in range(40):
            GroupMessage.objects.create(
                group=self.group, sender=self.sender, content='m%d' % i,
                message_type='text')
        self.mark_read(self.a)

        # The SAME queryset shape the endpoint builds — measuring a bare
        # .all() would be measuring the test, not production.
        messages = list(
            self.group.messages.select_related(
                'sender', 'reply_to__sender',
                'sender__online_status', 'reply_to__sender__online_status',
            ).prefetch_related('reactions')
        )
        with CaptureQueriesContext(connection) as ctx:
            data = GroupMessageSerializer(messages, many=True).data
        self.assertEqual(len(data), 41)
        self.assertTrue(all(row['read_count'] == 1 for row in data))
        # One for the memberships. The point is that it does not scale with the
        # 41 messages.
        self.assertLess(
            len(ctx.captured_queries), 6,
            '%d queries for 41 messages' % len(ctx.captured_queries))

    # ── end to end ──────────────────────────────────────────────────────────

    def test_the_endpoint_returns_the_receipt(self):
        self.mark_read(self.a)
        client = APIClient()
        client.force_authenticate(user=self.sender)
        response = client.get(
            '/api/adsyconnect/groups/%s/messages/' % self.group.id)
        self.assertEqual(response.status_code, 200)
        row = response.json()[0]
        self.assertEqual(row['read_count'], 1)
        self.assertFalse(row['read_by_all'])

    def test_reading_through_the_mark_read_endpoint_moves_the_receipt(self):
        client = APIClient()
        client.force_authenticate(user=self.a)
        self.assertEqual(
            client.post('/api/adsyconnect/groups/%s/mark-read/'
                        % self.group.id).status_code, 200)

        sender_client = APIClient()
        sender_client.force_authenticate(user=self.sender)
        row = sender_client.get(
            '/api/adsyconnect/groups/%s/messages/' % self.group.id
        ).json()[0]
        self.assertEqual(row['read_count'], 1)

    def test_messages_from_two_groups_do_not_share_a_receipt_cache(self):
        """A single list cache would answer with the first group's members."""
        other_group = ChatGroup.objects.create(name='Other',
                                               creator=self.sender)
        for user in (self.sender, self.a, self.b):
            ChatGroupMembership.objects.create(
                group=other_group, user=user, joined_at=self.joined)
        # Nobody has read anything in the second group.
        other_msg = GroupMessage.objects.create(
            group=other_group, sender=self.sender, content='elsewhere',
            message_type='text')

        # ...while both members have read the first group's message.
        self.mark_read(self.a)
        self.mark_read(self.b)

        serializer = GroupMessageSerializer([self.msg, other_msg], many=True)
        first, second = serializer.data
        self.assertEqual(first['read_count'], 2)
        self.assertTrue(first['read_by_all'])
        self.assertEqual(second['read_count'], 0)
        self.assertFalse(second['read_by_all'])
