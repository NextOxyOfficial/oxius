# -*- coding: utf-8 -*-
"""Typing in a group has to reach the other members over the socket.

The endpoint only wrote a timestamp, so a group had no realtime typing path at
all: every member's app polled it every three seconds to find out — twenty
requests a minute each, for something the socket delivers instantly. The 1:1
chat had broadcast this from the start.
"""
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from .models import ChatGroup, ChatGroupMembership

User = get_user_model()


class GroupTypingBroadcastTests(TestCase):
    def setUp(self):
        self.me = User.objects.create_user(
            username='ty1', email='ty1@example.com', password='x',
            first_name='Rahim', phone='+880100000801')
        self.mate = User.objects.create_user(
            username='ty2', email='ty2@example.com', password='x',
            first_name='Karim', phone='+880100000802')
        self.third = User.objects.create_user(
            username='ty3', email='ty3@example.com', password='x',
            first_name='Sumon', phone='+880100000803')
        self.outsider = User.objects.create_user(
            username='ty4', email='ty4@example.com', password='x',
            first_name='Out', phone='+880100000804')

        self.group = ChatGroup.objects.create(name='Typing', creator=self.me)
        for user in (self.me, self.mate, self.third):
            ChatGroupMembership.objects.create(group=self.group, user=user)

        self.sent = []
        ws = patch(
            'adsyconnect.views._broadcast_to_user',
            side_effect=lambda uid, event: self.sent.append((str(uid), event)),
        )
        ws.start()
        self.addCleanup(ws.stop)

    def type_as(self, user, group_id=None):
        client = APIClient()
        client.force_authenticate(user=user)
        return client.post(
            '/api/adsyconnect/groups/%s/typing/' % (group_id or self.group.id))

    def who_was_told(self):
        return sorted(
            uid for uid, e in self.sent
            if e.get('type') == 'typing_status_update'
        )

    # ── the broadcast ───────────────────────────────────────────────────────

    def test_the_other_members_are_told(self):
        response = self.type_as(self.me)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            self.who_was_told(),
            sorted([str(self.mate.id), str(self.third.id)]))

    def test_the_typist_is_not_told_about_themselves(self):
        self.type_as(self.me)
        self.assertNotIn(str(self.me.id), self.who_was_told())

    def test_the_payload_says_which_group_and_who(self):
        self.type_as(self.me)
        _uid, event = self.sent[0]
        self.assertEqual(event['type'], 'typing_status_update')
        self.assertEqual(event['group_id'], str(self.group.id))
        self.assertEqual(event['user_id'], str(self.me.id))
        self.assertEqual(event['user_name'], 'Rahim')
        self.assertTrue(event['is_typing'])
        # chatroom_id is present and null, so a 1:1 handler reading it cannot
        # mistake this for a direct chat.
        self.assertIsNone(event['chatroom_id'])

    def test_it_still_records_the_timestamp_for_the_poll_fallback(self):
        """A client with a dead socket still asks; that path must keep working."""
        self.type_as(self.me)
        membership = self.group.memberships.get(user=self.me)
        self.assertIsNotNone(membership.typing_at)

        client = APIClient()
        client.force_authenticate(user=self.mate)
        response = client.get(
            '/api/adsyconnect/groups/%s/typing/' % self.group.id)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()['typing'], ['Rahim'])

    def test_the_person_asking_is_never_in_their_own_typing_list(self):
        self.type_as(self.mate)
        client = APIClient()
        client.force_authenticate(user=self.mate)
        self.assertEqual(
            client.get(
                '/api/adsyconnect/groups/%s/typing/' % self.group.id
            ).json()['typing'],
            [])

    def test_two_people_typing_are_both_reported(self):
        self.type_as(self.me)
        self.type_as(self.third)
        client = APIClient()
        client.force_authenticate(user=self.mate)
        names = client.get(
            '/api/adsyconnect/groups/%s/typing/' % self.group.id
        ).json()['typing']
        self.assertEqual(sorted(names), ['Rahim', 'Sumon'])

    # ── the edges ───────────────────────────────────────────────────────────

    def test_a_non_member_cannot_type_into_the_group(self):
        response = self.type_as(self.outsider)
        self.assertIn(response.status_code, (403, 404))
        self.assertEqual(self.who_was_told(), [])

    def test_a_broadcast_failure_does_not_fail_the_request(self):
        """A typing bubble is not worth a 500 on a heartbeat sent every 2.5s."""
        with patch('adsyconnect.views._broadcast_to_user',
                   side_effect=RuntimeError('redis is down')):
            self.assertEqual(self.type_as(self.me).status_code, 200)
        self.assertIsNotNone(
            self.group.memberships.get(user=self.me).typing_at)

    def test_a_one_to_one_typing_event_still_carries_its_chatroom(self):
        """The shared event type must not have broken the 1:1 path."""
        from .models import ChatRoom
        room = ChatRoom.objects.create(user1=self.me, user2=self.mate)
        client = APIClient()
        client.force_authenticate(user=self.me)
        response = client.post(
            '/api/adsyconnect/typing-status/update_typing/',
            {'chatroom': str(room.id), 'is_typing': True}, format='json')
        self.assertEqual(response.status_code, 200)

        events = [e for _uid, e in self.sent
                  if e.get('type') == 'typing_status_update']
        self.assertEqual(len(events), 1)
        self.assertEqual(events[0]['chatroom_id'], str(room.id))
        self.assertNotIn('group_id', events[0])
