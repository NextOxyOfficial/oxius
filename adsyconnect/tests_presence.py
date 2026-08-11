# -*- coding: utf-8 -*-
"""Presence must not claim someone is offline while they are holding a phone.

A boolean flag cannot answer "is this user still connected?", so the first
socket to close marked them offline for every chat partner — closing a tablet
while using the phone, or a mobile network flap where the replacement socket
connects before the old one's disconnect arrives. The 30-second heartbeat then
repaired the row and told nobody, so the peer's screen stayed wrong until its
own status poll came round.
"""
from datetime import timedelta
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from .models import ChatRoom, OnlineStatus

User = get_user_model()


class ConnectionCountingTests(TestCase):
    """The model half: counting sockets rather than flipping a flag."""

    def setUp(self):
        self.user = User.objects.create_user(
            username='pres1', email='pres1@example.com', password='x',
            first_name='Pres', phone='+880100000301')
        # A row already exists for every user, so take that one rather than
        # trying to create a second.
        self.status, _ = OnlineStatus.objects.get_or_create(user=self.user)
        self.status.connection_count = 0
        self.status.is_online = False
        self.status.save(update_fields=['connection_count', 'is_online'])

    def test_the_first_socket_is_the_one_worth_announcing(self):
        self.assertTrue(self.status.register_connection())
        self.assertTrue(self.status.is_online)
        self.assertEqual(self.status.connection_count, 1)

        # A second device is not news — the user was already online.
        self.assertFalse(self.status.register_connection())
        self.assertEqual(self.status.connection_count, 2)

    def test_closing_one_of_two_devices_keeps_the_user_online(self):
        self.status.register_connection()
        self.status.register_connection()

        self.assertFalse(self.status.release_connection())
        self.status.refresh_from_db()
        self.assertTrue(self.status.is_online)
        self.assertTrue(self.status.is_effectively_online())
        self.assertEqual(self.status.connection_count, 1)

    def test_the_last_socket_closing_is_what_takes_them_offline(self):
        self.status.register_connection()
        self.assertTrue(self.status.release_connection())
        self.status.refresh_from_db()
        self.assertFalse(self.status.is_online)
        self.assertFalse(self.status.is_effectively_online())
        self.assertEqual(self.status.connection_count, 0)

    def test_a_reconnect_that_arrives_before_the_old_socket_goes(self):
        """The flap that made a connected user look offline.

        On a mobile network the replacement socket often connects first and
        the dead one's disconnect lands afterwards. Ordered that way, the old
        code's disconnect wrote is_online=False on a user who was, at that
        moment, connected.
        """
        self.status.register_connection()          # original socket
        self.status.register_connection()          # replacement connects
        self.status.release_connection()           # original finally drops

        self.status.refresh_from_db()
        self.assertTrue(self.status.is_online)
        self.assertEqual(self.status.connection_count, 1)

    def test_a_duplicate_disconnect_cannot_push_the_count_below_zero(self):
        """Otherwise the next connect looks like a second one and is silent."""
        self.status.register_connection()
        self.status.release_connection()
        self.status.release_connection()           # spurious repeat

        self.status.refresh_from_db()
        self.assertEqual(self.status.connection_count, 0)
        # And the next real connection still announces itself.
        self.assertTrue(self.status.register_connection())

    def test_a_leaked_count_cannot_strand_someone_online_for_ever(self):
        """A worker killed mid-disconnect leaves the count too high.

        That must not read as online indefinitely — the staleness window is
        what makes the counter safe to be approximate.
        """
        self.status.register_connection()
        self.status.register_connection()
        OnlineStatus.objects.filter(pk=self.status.pk).update(
            last_seen=timezone.now() - timedelta(seconds=200))
        self.status.refresh_from_db()

        self.assertEqual(self.status.connection_count, 2)
        self.assertTrue(self.status.is_online)
        self.assertFalse(self.status.is_effectively_online())


class HeartbeatAnnouncesTheReturnTests(TestCase):
    """The REST half: coming back must reach the other person's screen."""

    def setUp(self):
        self.me = User.objects.create_user(
            username='pres2', email='pres2@example.com', password='x',
            first_name='Me', phone='+880100000302')
        self.peer = User.objects.create_user(
            username='pres3', email='pres3@example.com', password='x',
            first_name='Peer', phone='+880100000303')
        self.stranger = User.objects.create_user(
            username='pres4', email='pres4@example.com', password='x',
            first_name='Stranger', phone='+880100000304')
        ChatRoom.objects.create(user1=self.me, user2=self.peer)

        self.sent = []
        ws = patch(
            'adsyconnect.views._broadcast_to_user',
            side_effect=lambda uid, event: self.sent.append((str(uid), event)),
        )
        ws.start()
        self.addCleanup(ws.stop)

        self.client = APIClient()
        self.client.force_authenticate(user=self.me)

    def beat(self):
        return self.client.post('/api/adsyconnect/heartbeat/')

    def test_coming_back_online_is_broadcast_to_chat_partners(self):
        OnlineStatus.objects.update_or_create(
            user=self.me,
            defaults={'is_online': False,
                      'last_seen': timezone.now() - timedelta(minutes=5)})

        self.assertEqual(self.beat().status_code, 200)

        told = [(uid, e['payload'] if 'payload' in e else e) for uid, e in self.sent]
        self.assertEqual(len(told), 1, told)
        uid, event = told[0]
        self.assertEqual(uid, str(self.peer.id))
        self.assertEqual(event['type'], 'user_online_status')
        self.assertEqual(event['user_id'], str(self.me.id))
        self.assertTrue(event['is_online'])

    def test_a_stranger_is_not_told_anything(self):
        OnlineStatus.objects.update_or_create(
            user=self.me,
            defaults={'is_online': False,
                      'last_seen': timezone.now() - timedelta(minutes=5)})
        self.beat()
        self.assertNotIn(str(self.stranger.id), [uid for uid, _ in self.sent])
        # Nor is the user told about themselves.
        self.assertNotIn(str(self.me.id), [uid for uid, _ in self.sent])

    def test_a_heartbeat_from_somebody_already_online_says_nothing(self):
        """Otherwise it is one message per partner every 30 seconds, forever."""
        OnlineStatus.objects.update_or_create(
            user=self.me,
            defaults={'is_online': True, 'last_seen': timezone.now()})
        self.assertEqual(self.beat().status_code, 200)
        self.assertEqual(self.sent, [])

    def test_a_stale_row_counts_as_offline_and_is_announced(self):
        """is_online=True but last_seen long past is what a crash leaves."""
        OnlineStatus.objects.update_or_create(
            user=self.me,
            defaults={'is_online': True,
                      'last_seen': timezone.now() - timedelta(minutes=10)})
        self.beat()
        self.assertEqual(len(self.sent), 1)
        self.assertTrue(self.sent[0][1]['is_online'])

    def test_a_heartbeat_from_a_user_with_no_presence_yet_announces_them(self):
        OnlineStatus.objects.filter(user=self.me).delete()
        self.beat()
        self.assertEqual(len(self.sent), 1)
        self.assertTrue(
            OnlineStatus.objects.get(user=self.me).is_effectively_online())

    def test_a_second_heartbeat_is_quiet(self):
        self.beat()
        self.sent.clear()
        self.beat()
        self.assertEqual(self.sent, [])

    def test_a_broadcast_failure_does_not_fail_the_heartbeat(self):
        """Presence is not worth a 500 on a request the client repeats."""
        with patch('adsyconnect.views._broadcast_to_user',
                   side_effect=RuntimeError('redis is down')):
            self.assertEqual(self.beat().status_code, 200)
        self.assertTrue(
            OnlineStatus.objects.get(user=self.me).is_effectively_online())


class PresenceAudienceTests(TestCase):
    """Who hears about a presence change, and how many that is.

    Every connect and disconnect used to send one message per conversation the
    user had ever had — 84 for a real account, and mobile clients reconnect
    constantly. Presence itself stays correct for everybody; the REST
    serializers read it from the row. This only bounds who gets pushed.
    """

    def setUp(self):
        from .consumers import ChatConsumer
        self.ChatConsumer = ChatConsumer
        self.me = User.objects.create_user(
            username='aud1', email='aud1@example.com', password='x',
            first_name='Me', phone='+880100001001')
        self._next = 0

    def partner_with_chat(self, *, last_message_days_ago):
        self._next += 1
        other = User.objects.create_user(
            username='audp%d' % self._next,
            email='audp%d@example.com' % self._next,
            password='x', first_name='P%d' % self._next,
            phone='+8801000011%02d' % self._next)
        room = ChatRoom.objects.create(user1=self.me, user2=other)
        when = timezone.now() - timedelta(days=last_message_days_ago)
        ChatRoom.objects.filter(pk=room.pk).update(
            last_message_at=when, created_at=when)
        return other

    def audience(self):
        consumer = self.ChatConsumer()
        consumer.user = self.me
        # The method is wrapped for async use; reach the sync function under it.
        return consumer.get_connected_users.__wrapped__(consumer)

    def test_a_recent_conversation_is_in_the_audience(self):
        recent = self.partner_with_chat(last_message_days_ago=2)
        self.assertIn(str(recent.id), self.audience())

    def test_a_conversation_nobody_has_touched_in_months_is_not(self):
        stale = self.partner_with_chat(last_message_days_ago=200)
        self.assertNotIn(str(stale.id), self.audience())

    def test_the_user_is_never_in_their_own_audience(self):
        self.partner_with_chat(last_message_days_ago=1)
        self.assertNotIn(str(self.me.id), self.audience())

    def test_the_audience_is_capped(self):
        for _ in range(self.ChatConsumer.PRESENCE_AUDIENCE_LIMIT + 15):
            self.partner_with_chat(last_message_days_ago=1)
        audience = self.audience()
        self.assertLessEqual(
            len(audience), self.ChatConsumer.PRESENCE_AUDIENCE_LIMIT)
        # And no duplicates, or the cap would be meaningless.
        self.assertEqual(len(audience), len(set(audience)))

    def test_a_brand_new_conversation_with_no_messages_still_counts(self):
        """Opening a chat and going online must show the dot immediately."""
        fresh = User.objects.create_user(
            username='audfresh', email='audfresh@example.com', password='x',
            first_name='Fresh', phone='+880100001199')
        ChatRoom.objects.create(user1=self.me, user2=fresh)
        self.assertIn(str(fresh.id), self.audience())

    def test_someone_with_no_conversations_has_no_audience(self):
        self.assertEqual(self.audience(), [])


class GroupPresenceAudienceTests(TestCase):
    """Presence went to one-to-one chat partners only.

    Somebody you only ever talk to in a group never saw you come online, which
    is most of the people in a group chat.
    """

    def setUp(self):
        from .consumers import ChatConsumer
        from .models import ChatGroup, ChatGroupMembership
        self.ChatConsumer = ChatConsumer
        self.ChatGroup = ChatGroup
        self.Membership = ChatGroupMembership

        self.me = User.objects.create_user(
            username='gp1', email='gp1@example.com', password='x',
            first_name='Me', phone='+880100005201')
        self.mate = User.objects.create_user(
            username='gp2', email='gp2@example.com', password='x',
            first_name='Mate', phone='+880100005202')
        self.stranger = User.objects.create_user(
            username='gp3', email='gp3@example.com', password='x',
            first_name='Stranger', phone='+880100005203')

    def audience(self):
        consumer = self.ChatConsumer()
        consumer.user = self.me
        return consumer.get_connected_users.__wrapped__(consumer)

    def group_with(self, *users, days_ago=1):
        group = self.ChatGroup.objects.create(name='G', creator=self.me)
        for user in users:
            self.Membership.objects.create(group=group, user=user)
        when = timezone.now() - timedelta(days=days_ago)
        self.ChatGroup.objects.filter(pk=group.pk).update(
            last_message_at=when, created_at=when)
        return group

    def test_a_group_co_member_hears_about_presence(self):
        self.group_with(self.me, self.mate)
        self.assertIn(str(self.mate.id), self.audience())

    def test_somebody_in_no_shared_group_does_not(self):
        self.group_with(self.me, self.mate)
        self.assertNotIn(str(self.stranger.id), self.audience())

    def test_a_group_nobody_has_touched_in_months_is_not_included(self):
        self.group_with(self.me, self.mate, days_ago=200)
        self.assertNotIn(str(self.mate.id), self.audience())

    def test_the_user_is_never_in_their_own_group_audience(self):
        self.group_with(self.me, self.mate)
        self.assertNotIn(str(self.me.id), self.audience())

    def test_a_person_in_both_a_chat_and_a_group_appears_once(self):
        ChatRoom.objects.create(user1=self.me, user2=self.mate)
        self.group_with(self.me, self.mate)
        audience = self.audience()
        self.assertEqual(audience.count(str(self.mate.id)), 1)

    def test_the_overall_cap_still_holds_with_groups(self):
        members = []
        for i in range(self.ChatConsumer.PRESENCE_AUDIENCE_LIMIT + 30):
            members.append(User.objects.create_user(
                username='gpc%d' % i, email='gpc%d@example.com' % i,
                password='x', first_name='C%d' % i,
                phone='+88010000531%03d' % i))
        self.group_with(self.me, *members)
        audience = self.audience()
        self.assertLessEqual(
            len(audience), self.ChatConsumer.PRESENCE_AUDIENCE_LIMIT)
        self.assertEqual(len(audience), len(set(audience)))
