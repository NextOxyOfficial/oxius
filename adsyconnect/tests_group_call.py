# -*- coding: utf-8 -*-
"""One person leaving a group call must not hang up on everyone else.

The reported bug: A calls B, A adds C, C hangs up — and the call dies for
all three. These tests walk that exact sequence through the real endpoints
and assert on what the other people are actually sent.

The one-to-one cases are here too, and matter just as much: the group
behaviour is new, and the two-person path it branches away from is the one
almost every call takes.
"""
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from .models import CallParticipant, CallSession, ChatGroup, ChatGroupMembership

User = get_user_model()


class GroupCallDepartureTests(TestCase):
    def setUp(self):
        self.a = User.objects.create_user(
            username='alice', email='alice@example.com', password='x',
            first_name='Alice', phone='+880100000001')
        self.b = User.objects.create_user(
            username='bob', email='bob@example.com', password='x',
            first_name='Bob', phone='+880100000002')
        self.c = User.objects.create_user(
            username='carol', email='carol@example.com', password='x',
            first_name='Carol', phone='+880100000003')

        self.session = CallSession.objects.create(
            channel_name='c_test_group_1',
            caller=self.a,
            callee=self.b,
            call_type='audio',
            status=CallSession.STATUS_ACCEPTED,
        )

        # Every push and socket send is recorded instead of attempted, so the
        # assertions can be about who was told what.
        self.sent = []
        self.broadcasts = []

        push = patch(
            'adsyconnect.views._send_call_data_message',
            side_effect=lambda *, target_user, payload: (
                self.sent.append((target_user.email, dict(payload))) or {}
            ),
        )
        ws = patch(
            'adsyconnect.views._broadcast_to_user',
            side_effect=lambda user_id, event: self.broadcasts.append(
                (str(user_id), event)
            ),
        )
        push.start()
        ws.start()
        self.addCleanup(push.stop)
        self.addCleanup(ws.stop)

    def client_for(self, user):
        client = APIClient()
        client.force_authenticate(user=user)
        return client

    def hang_up(self, who, *, receiver):
        return self.client_for(who).post(
            '/api/adsyconnect/send-call-status/',
            {
                'receiver_id': str(receiver.id),
                'channel_name': self.session.channel_name,
                'status': 'ended',
                'call_type': 'audio',
                'call_id': str(self.session.id),
            },
            format='json',
        )

    def statuses_sent(self):
        return {email: p['status'] for email, p in self.sent}

    # ---------------------------------------------------------------- 1:1

    def test_one_to_one_hangup_still_ends_the_call(self):
        """The path almost every call takes must be untouched."""
        response = self.hang_up(self.b, receiver=self.a)
        self.assertEqual(response.status_code, 200)

        self.session.refresh_from_db()
        self.assertEqual(self.session.status, CallSession.STATUS_ENDED)
        self.assertIsNotNone(self.session.ended_at)
        self.assertEqual(self.statuses_sent(), {'alice@example.com': 'ended'})

    # -------------------------------------------------------------- group

    def add_carol(self):
        CallParticipant.objects.create(
            session=self.session,
            user=self.c,
            invited_by=self.a,
            status=CallParticipant.STATUS_ACCEPTED,
        )

    def test_invited_person_leaving_keeps_the_call_alive(self):
        """C hangs up. A and B keep talking. This is the reported bug."""
        self.add_carol()
        self.sent.clear()

        response = self.hang_up(self.c, receiver=self.a)
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json()['group_call'])
        self.assertEqual(response.json()['remaining'], 2)

        self.session.refresh_from_db()
        self.assertEqual(self.session.status, CallSession.STATUS_ACCEPTED)
        self.assertIsNone(self.session.ended_at)

        participation = self.session.participants.get(user=self.c)
        self.assertEqual(participation.status, CallParticipant.STATUS_LEFT)

        # Both remaining people are told, and neither is told the call ended.
        self.assertEqual(self.statuses_sent(), {
            'alice@example.com': 'participant_left',
            'bob@example.com': 'participant_left',
        })
        payload = self.sent[0][1]
        self.assertEqual(payload['left_user_id'], str(self.c.id))
        self.assertEqual(payload['remaining'], '2')

    def test_original_caller_leaving_keeps_the_call_alive(self):
        """A started the call, but B and C are mid-conversation."""
        self.add_carol()
        self.sent.clear()

        self.hang_up(self.a, receiver=self.b)

        self.session.refresh_from_db()
        self.assertEqual(self.session.status, CallSession.STATUS_ACCEPTED)
        self.assertIsNotNone(self.session.caller_left_at)
        self.assertIsNone(self.session.callee_left_at)
        self.assertEqual(self.statuses_sent(), {
            'bob@example.com': 'participant_left',
            'carol@example.com': 'participant_left',
        })

    def test_call_ends_when_only_one_person_is_left(self):
        """Two departures out of three. Nobody is left to talk to."""
        self.add_carol()
        self.hang_up(self.c, receiver=self.a)
        self.sent.clear()

        self.hang_up(self.b, receiver=self.a)

        self.session.refresh_from_db()
        self.assertEqual(self.session.status, CallSession.STATUS_ENDED)
        self.assertIsNotNone(self.session.ended_at)
        self.assertEqual(self.statuses_sent(), {'alice@example.com': 'ended'})

    def test_a_ringing_invitee_still_counts_as_present(self):
        """C's phone is ringing when B hangs up.

        A is alone right now but C is mid-answer; ending the call here would
        cut off someone in the act of picking up.
        """
        CallParticipant.objects.create(
            session=self.session, user=self.c, invited_by=self.a,
            status=CallParticipant.STATUS_RINGING,
        )
        self.sent.clear()

        self.hang_up(self.b, receiver=self.a)

        self.session.refresh_from_db()
        self.assertEqual(self.session.status, CallSession.STATUS_ACCEPTED)

    def test_declining_an_invitation_says_nothing_about_the_call(self):
        """C never joined. A and B are unaffected."""
        CallParticipant.objects.create(
            session=self.session, user=self.c, invited_by=self.a,
            status=CallParticipant.STATUS_RINGING,
        )
        self.sent.clear()

        self.client_for(self.c).post(
            '/api/adsyconnect/send-call-status/',
            {
                'receiver_id': str(self.a.id),
                'channel_name': self.session.channel_name,
                'status': 'rejected',
                'call_type': 'audio',
                'call_id': str(self.session.id),
            },
            format='json',
        )

        self.session.refresh_from_db()
        self.assertEqual(self.session.status, CallSession.STATUS_ACCEPTED)
        self.assertEqual(
            self.session.participants.get(user=self.c).status,
            CallParticipant.STATUS_REJECTED,
        )


class CallBecomesGroupChatTests(TestCase):
    """Adding someone to a call gives the three of them a real group."""

    def setUp(self):
        self.a = User.objects.create_user(
            username='ann', email='ann@example.com', password='x',
            first_name='Ann', phone='+880100000011')
        self.b = User.objects.create_user(
            username='ben', email='ben@example.com', password='x',
            first_name='Ben', phone='+880100000012')
        self.c = User.objects.create_user(
            username='cat', email='cat@example.com', password='x',
            first_name='Cat', phone='+880100000013')
        self.d = User.objects.create_user(
            username='dan', email='dan@example.com', password='x',
            first_name='Dan', phone='+880100000014')

        self.session = CallSession.objects.create(
            channel_name='c_test_group_2',
            caller=self.a,
            callee=self.b,
            call_type='audio',
            status=CallSession.STATUS_ACCEPTED,
        )

        for target in (
            'adsyconnect.views._send_call_data_message',
            'adsyconnect.views._broadcast_to_user',
        ):
            patcher = patch(target, return_value={})
            patcher.start()
            self.addCleanup(patcher.stop)

        can_call = patch('adsyconnect.views._can_call', return_value=(True, ''))
        can_call.start()
        self.addCleanup(can_call.stop)
        # _active_call_for_user would report every invitee as busy — they are
        # all on this very session once invited.
        active = patch('adsyconnect.views._active_call_for_user', return_value=None)
        active.start()
        self.addCleanup(active.stop)

    def invite(self, inviter, invitees):
        client = APIClient()
        client.force_authenticate(user=inviter)
        return client.post(
            '/api/adsyconnect/invite-to-call/',
            {
                'channel_name': self.session.channel_name,
                'call_id': str(self.session.id),
                'invitee_ids': [str(u.id) for u in invitees],
            },
            format='json',
        )

    def test_inviting_a_third_person_creates_the_group(self):
        response = self.invite(self.a, [self.c])
        self.assertEqual(response.status_code, 200)
        self.assertIsNotNone(response.json()['group_id'])

        self.session.refresh_from_db()
        group = self.session.chat_group
        self.assertIsNotNone(group)

        member_ids = set(
            ChatGroupMembership.objects.filter(group=group)
            .values_list('user_id', flat=True)
        )
        self.assertEqual(member_ids, {self.a.id, self.b.id, self.c.id})

        # The person who started the call runs the group.
        self.assertTrue(group.is_admin(self.a))
        # And it reads as a group in the chat list rather than as a blank row.
        self.assertTrue(group.name)
        self.assertTrue(group.last_message_preview)

    def test_a_fourth_invite_joins_the_same_group(self):
        self.invite(self.a, [self.c])
        self.session.refresh_from_db()
        first = self.session.chat_group

        self.invite(self.a, [self.d])
        self.session.refresh_from_db()

        self.assertEqual(self.session.chat_group_id, first.id)
        self.assertEqual(ChatGroup.objects.count(), 1)
        member_ids = set(
            ChatGroupMembership.objects.filter(group=first)
            .values_list('user_id', flat=True)
        )
        self.assertEqual(
            member_ids, {self.a.id, self.b.id, self.c.id, self.d.id})

    def test_nobody_reachable_means_no_group(self):
        """A call that never actually gained anyone is not a group."""
        with patch('adsyconnect.views._can_call', return_value=(False, 'blocked')):
            response = self.invite(self.a, [self.c])

        self.assertEqual(response.status_code, 200)
        self.assertIsNone(response.json()['group_id'])
        self.session.refresh_from_db()
        self.assertIsNone(self.session.chat_group)
        self.assertEqual(ChatGroup.objects.count(), 0)
