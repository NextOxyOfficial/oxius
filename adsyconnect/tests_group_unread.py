# -*- coding: utf-8 -*-
"""A group's unread badge must survive the app being in a pocket.

Fetching a group's messages marks it read, which is right when somebody has
just opened it. The app also POLLS that endpoint on a timer, and the timer
kept running while the app was backgrounded with the screen still mounted —
so messages that arrived then were marked read and no badge ever appeared.
"""
from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from .models import ChatGroup, ChatGroupMembership, GroupMessage
from .serializers import ChatGroupSerializer

User = get_user_model()


class GroupUnreadTests(TestCase):
    def setUp(self):
        self.me = User.objects.create_user(
            username='ur1', email='ur1@example.com', password='x',
            first_name='Me', phone='+880100000401')
        self.mate = User.objects.create_user(
            username='ur2', email='ur2@example.com', password='x',
            first_name='Mate', phone='+880100000402')

        self.group = ChatGroup.objects.create(name='Unread', creator=self.me)
        for user in (self.me, self.mate):
            ChatGroupMembership.objects.create(group=self.group, user=user)

        self.client = APIClient()
        self.client.force_authenticate(user=self.me)

    # ── helpers ─────────────────────────────────────────────────────────────

    def they_say(self, text='hello'):
        return GroupMessage.objects.create(
            group=self.group, sender=self.mate, content=text,
            message_type='text')

    def fetch(self, *, mark_read=None):
        url = '/api/adsyconnect/groups/%s/messages/' % self.group.id
        if mark_read is not None:
            url += '?mark_read=%s' % mark_read
        return self.client.get(url)

    def unread(self):
        request = self.client.request().wsgi_request
        request.user = self.me
        return ChatGroupSerializer(
            self.group, context={'request': request}
        ).data['unread_count']

    def last_read_at(self):
        return self.group.memberships.get(user=self.me).last_read_at

    # ── the bug ─────────────────────────────────────────────────────────────

    def test_a_background_refresh_does_not_mark_the_group_read(self):
        self.they_say()
        self.assertEqual(self.unread(), 1)

        response = self.fetch(mark_read=0)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.json()), 1)   # still returns the messages
        self.assertIsNone(self.last_read_at())
        self.assertEqual(self.unread(), 1)          # ...and the badge survives

    def test_a_background_refresh_never_moves_an_existing_stamp(self):
        """Even a member who HAS read before must not have it pushed forward."""
        self.fetch()                                # a real read
        stamp = self.last_read_at()
        self.assertIsNotNone(stamp)

        self.they_say('while the phone was in a pocket')
        self.fetch(mark_read=0)

        self.assertEqual(self.last_read_at(), stamp)
        self.assertEqual(self.unread(), 1)

    # ── still marking read when someone really is reading ──────────────────

    def test_opening_the_group_marks_it_read(self):
        self.they_say()
        self.fetch()
        self.assertIsNotNone(self.last_read_at())
        self.assertEqual(self.unread(), 0)

    def test_an_older_app_that_sends_nothing_still_marks_read(self):
        """The default has to stay on, or shipped builds stop clearing badges."""
        self.they_say()
        self.fetch()                                # no query parameter at all
        self.assertEqual(self.unread(), 0)

    def test_the_flag_is_read_forgivingly(self):
        for value in ('0', 'false', 'FALSE', 'no', ' 0 '):
            ChatGroupMembership.objects.filter(
                group=self.group, user=self.me).update(last_read_at=None)
            self.fetch(mark_read=value)
            self.assertIsNone(
                self.last_read_at(), 'mark_read=%r should not mark read' % value)

        for value in ('1', 'true', 'yes', 'anything-else'):
            ChatGroupMembership.objects.filter(
                group=self.group, user=self.me).update(last_read_at=None)
            self.fetch(mark_read=value)
            self.assertIsNotNone(
                self.last_read_at(), 'mark_read=%r should mark read' % value)

    # ── the badge itself ────────────────────────────────────────────────────

    def test_my_own_messages_are_never_unread(self):
        GroupMessage.objects.create(
            group=self.group, sender=self.me, content='mine',
            message_type='text')
        self.assertEqual(self.unread(), 0)

    def test_system_messages_do_not_raise_a_badge(self):
        GroupMessage.objects.create(
            group=self.group, sender=self.mate, content='X joined',
            message_type='system')
        self.assertEqual(self.unread(), 0)

    def test_a_deleted_message_stops_counting(self):
        msg = self.they_say()
        self.assertEqual(self.unread(), 1)
        msg.is_deleted = True
        msg.save(update_fields=['is_deleted'])
        self.assertEqual(self.unread(), 0)

    def test_a_new_member_does_not_inherit_the_whole_history(self):
        self.they_say('said before they joined')
        newcomer = User.objects.create_user(
            username='ur3', email='ur3@example.com', password='x',
            first_name='New', phone='+880100000403')
        ChatGroupMembership.objects.create(
            group=self.group, user=newcomer, joined_at=timezone.now())

        client = APIClient()
        client.force_authenticate(user=newcomer)
        request = client.request().wsgi_request
        request.user = newcomer
        data = ChatGroupSerializer(
            self.group, context={'request': request}).data
        self.assertEqual(data['unread_count'], 0)

    def test_a_non_member_is_refused_and_marks_nothing(self):
        outsider = User.objects.create_user(
            username='ur4', email='ur4@example.com', password='x',
            first_name='Out', phone='+880100000404')
        client = APIClient()
        client.force_authenticate(user=outsider)
        response = client.get(
            '/api/adsyconnect/groups/%s/messages/' % self.group.id)
        self.assertIn(response.status_code, (403, 404))


class MarkGroupReadEndpointTests(TestCase):
    """Reading a socket-delivered message must not cost a page load.

    Before this endpoint the only way to mark a group read was to GET its last
    hundred messages, so a group where people were talking re-downloaded the
    whole thread on every member's phone per message.
    """

    def setUp(self):
        self.me = User.objects.create_user(
            username='mr1', email='mr1@example.com', password='x',
            first_name='Me', phone='+880100000901')
        self.mate = User.objects.create_user(
            username='mr2', email='mr2@example.com', password='x',
            first_name='Mate', phone='+880100000902')
        self.outsider = User.objects.create_user(
            username='mr3', email='mr3@example.com', password='x',
            first_name='Out', phone='+880100000903')
        self.group = ChatGroup.objects.create(name='MarkRead', creator=self.me)
        for user in (self.me, self.mate):
            ChatGroupMembership.objects.create(group=self.group, user=user)

        self.client = APIClient()
        self.client.force_authenticate(user=self.me)

    def mark(self, user=None):
        client = self.client
        if user is not None:
            client = APIClient()
            client.force_authenticate(user=user)
        return client.post(
            '/api/adsyconnect/groups/%s/mark-read/' % self.group.id)

    def unread_for(self, user):
        client = APIClient()
        client.force_authenticate(user=user)
        request = client.request().wsgi_request
        request.user = user
        return ChatGroupSerializer(
            self.group, context={'request': request}).data['unread_count']

    def test_it_clears_the_badge(self):
        GroupMessage.objects.create(
            group=self.group, sender=self.mate, content='hi',
            message_type='text')
        self.assertEqual(self.unread_for(self.me), 1)

        response = self.mark()
        self.assertEqual(response.status_code, 200)
        self.assertEqual(self.unread_for(self.me), 0)

    def test_it_marks_only_the_caller_read(self):
        GroupMessage.objects.create(
            group=self.group, sender=self.mate, content='hi',
            message_type='text')
        self.mark()
        # The sender had nothing unread anyway; check the reverse direction.
        GroupMessage.objects.create(
            group=self.group, sender=self.me, content='mine',
            message_type='text')
        self.assertEqual(self.unread_for(self.mate), 1)

    def test_a_non_member_is_refused(self):
        response = self.mark(user=self.outsider)
        self.assertIn(response.status_code, (403, 404))

    def test_it_is_idempotent(self):
        self.assertEqual(self.mark().status_code, 200)
        first = self.group.memberships.get(user=self.me).last_read_at
        self.assertEqual(self.mark().status_code, 200)
        second = self.group.memberships.get(user=self.me).last_read_at
        self.assertGreaterEqual(second, first)
        self.assertEqual(self.unread_for(self.me), 0)
