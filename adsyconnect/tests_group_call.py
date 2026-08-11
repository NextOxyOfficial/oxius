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
from datetime import timedelta

from django.utils import timezone
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

        # Only someone the inviter has talked to may be pulled into a call, so
        # the person doing the inviting needs a conversation with each of them
        # — which is exactly what the picker requires before offering them.
        from .models import ChatRoom
        for other in (self.c, self.d):
            ChatRoom.objects.create(user1=self.a, user2=other)

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


class StartGroupCallTests(TestCase):
    """Ringing a whole group chat at once."""

    def setUp(self):
        self.users = []
        for i, (uname, first) in enumerate([
            ('gina', 'Gina'), ('hugo', 'Hugo'), ('iris', 'Iris'),
        ]):
            self.users.append(User.objects.create_user(
                username=uname, email=f'{uname}@example.com', password='x',
                first_name=first, phone=f'+88010000002{i}',
            ))
        self.owner, self.m2, self.m3 = self.users

        self.group = ChatGroup.objects.create(
            name='Test Group', creator=self.owner)
        for user in self.users:
            ChatGroupMembership.objects.create(
                group=self.group, user=user,
                role='admin' if user == self.owner else 'member',
            )

        self.rung = []
        push = patch(
            'adsyconnect.views._send_call_data_message',
            side_effect=lambda *, target_user, payload: (
                self.rung.append((target_user.email, dict(payload)))
                or {'sent_to': 1}
            ),
        )
        push.start()
        self.addCleanup(push.stop)
        for target in ('adsyconnect.views._broadcast_to_user',):
            p = patch(target, return_value=None)
            p.start()
            self.addCleanup(p.stop)
        can_call = patch('adsyconnect.views._can_call', return_value=(True, ''))
        can_call.start()
        self.addCleanup(can_call.stop)

    def start(self, user=None, call_type='audio', group_id=None):
        client = APIClient()
        client.force_authenticate(user=user or self.owner)
        return client.post(
            '/api/adsyconnect/start-group-call/',
            {
                'group_id': str(group_id or self.group.id),
                'channel_name': 'c_group_call_1',
                'call_type': call_type,
            },
            format='json',
        )

    def test_every_other_member_is_rung_once(self):
        response = self.start(call_type='video')
        self.assertEqual(response.status_code, 200, response.content)

        rung_emails = sorted(email for email, _ in self.rung)
        self.assertEqual(
            rung_emails, ['hugo@example.com', 'iris@example.com'])
        # And the caller is never rung for their own call.
        self.assertNotIn('gina@example.com', rung_emails)

        for _, payload in self.rung:
            self.assertEqual(payload['type'], 'incoming_call')
            self.assertEqual(payload['is_group_call'], True)
            self.assertEqual(payload['group_name'], 'Test Group')
            self.assertEqual(payload['call_type'], 'video')

    def test_a_big_group_rings_every_one_of_them(self):
        """The old cap silently left most of a group out of its own call.

        Eight was the ceiling, so ringing a twenty-person group rang seven
        people and skipped the rest with a 'call_full' nobody ever saw.
        """
        for i in range(20):
            user = User.objects.create_user(
                username='crowd%d' % i, email='crowd%d@example.com' % i,
                password='x', first_name='C%d' % i,
                phone='+8801000001%02d' % i)
            ChatGroupMembership.objects.create(group=self.group, user=user)

        response = self.start()
        self.assertEqual(response.status_code, 200, response.content)

        # Everybody but the caller.
        self.assertEqual(len(self.rung), 22)
        self.assertNotIn('gina@example.com', [e for e, _ in self.rung])
        self.assertFalse([
            r for r in response.json().get('skipped', [])
            if r.get('status') == 'call_full'
        ])

    def test_one_phone_that_cannot_be_reached_does_not_sink_the_call(self):
        """The pushes go out together now, so one throwing must be contained.

        Sequentially an exception ended the request; the members after the
        failing one were never rung and the caller got a 500 for a call the
        rest of the group could have joined.
        """
        rung = []

        def flaky(*, target_user, payload):
            if target_user.email == 'hugo@example.com':
                raise RuntimeError('APNs said no')
            rung.append(target_user.email)
            return {'sent_to': 1}

        with patch('adsyconnect.views._send_call_data_message',
                   side_effect=flaky):
            response = self.start()

        self.assertEqual(response.status_code, 200, response.content)
        self.assertIn('iris@example.com', rung)

        by_user = {r['user_id']: r for r in response.json()['results']}
        self.assertFalse(by_user[str(self.m2.id)]['reachable'])
        self.assertEqual(by_user[str(self.m2.id)]['status'], 'unreachable')
        self.assertTrue(by_user[str(self.m3.id)]['reachable'])

    def test_it_is_an_ordinary_call_session_linked_to_the_group(self):
        """The whole point: no second implementation to keep in step."""
        response = self.start()
        session = CallSession.objects.get(id=response.json()['call_id'])

        self.assertEqual(session.caller, self.owner)
        self.assertEqual(session.chat_group_id, self.group.id)
        # One member fills the callee slot, the rest are participants — the
        # exact shape the departure logic already understands.
        self.assertIn(session.callee, [self.m2, self.m3])
        others = {p.user for p in session.participants.all()}
        self.assertEqual(
            others | {session.callee}, {self.m2, self.m3})
        self.assertTrue(session.has_extra_participants())

    def test_one_member_hanging_up_leaves_the_others_talking(self):
        """The group-call fix has to hold for calls that started as groups."""
        response = self.start()
        session = CallSession.objects.get(id=response.json()['call_id'])
        session.update_status(CallSession.STATUS_ACCEPTED)
        self.rung.clear()

        client = APIClient()
        client.force_authenticate(user=self.m3)
        result = client.post(
            '/api/adsyconnect/send-call-status/',
            {
                'receiver_id': str(self.owner.id),
                'channel_name': session.channel_name,
                'status': 'ended',
                'call_type': 'audio',
                'call_id': str(session.id),
            },
            format='json',
        )
        self.assertEqual(result.status_code, 200, result.content)

        session.refresh_from_db()
        self.assertEqual(session.status, CallSession.STATUS_ACCEPTED)
        self.assertEqual(
            {email: p['status'] for email, p in self.rung},
            {
                'gina@example.com': 'participant_left',
                'hugo@example.com': 'participant_left',
            },
        )

    def test_a_non_member_cannot_ring_the_group(self):
        outsider = User.objects.create_user(
            username='mallory', email='mallory@example.com', password='x',
            first_name='Mallory', phone='+880100000099')
        response = self.start(user=outsider)
        self.assertEqual(response.status_code, 403)
        self.assertEqual(self.rung, [])

    def test_a_group_the_caller_is_alone_in_cannot_be_called(self):
        solo = ChatGroup.objects.create(name='Just Me', creator=self.owner)
        ChatGroupMembership.objects.create(
            group=solo, user=self.owner, role='admin')
        response = self.start(group_id=solo.id)
        self.assertEqual(response.status_code, 400)
        self.assertEqual(self.rung, [])

    def test_a_busy_member_is_skipped_not_fatal(self):
        """Hugo is on another call. Iris still gets rung."""
        # The other party must be someone outside this group, or the fixture
        # would make Iris busy too and prove nothing.
        outsider = User.objects.create_user(
            username='nate', email='nate@example.com', password='x',
            first_name='Nate', phone='+880100000098')
        busy_session = CallSession.objects.create(
            channel_name='c_other_call', caller=self.m2, callee=outsider,
            call_type='audio', status=CallSession.STATUS_ACCEPTED,
        )
        self.addCleanup(busy_session.delete)

        response = self.start()
        self.assertEqual(response.status_code, 200, response.content)
        statuses = {r['user_id']: r['status'] for r in response.json()['results']}
        self.assertEqual(statuses[str(self.m2.id)], 'busy')
        self.assertEqual(statuses[str(self.m3.id)], 'ringing')
        self.assertEqual([e for e, _ in self.rung], ['iris@example.com'])


class LeavingAGroupCallFreesYouTests(TestCase):
    """Two bugs that only exist because a group call outlives its leavers.

    Before group calls, hanging up ended the session, so "still a member of a
    live call" and "still on a call" were the same statement. They are not
    any more, and both checks that conflated them were wrong.
    """

    def setUp(self):
        names = [('opal', 'Opal'), ('pete', 'Pete'), ('quin', 'Quin')]
        self.a, self.b, self.c = [
            User.objects.create_user(
                username=u, email=f'{u}@example.com', password='x',
                first_name=f, phone=f'+88010000003{i}')
            for i, (u, f) in enumerate(names)
        ]
        self.session = CallSession.objects.create(
            channel_name='c_leave_frees',
            caller=self.a, callee=self.b, call_type='audio',
            status=CallSession.STATUS_ACCEPTED,
        )
        CallParticipant.objects.create(
            session=self.session, user=self.c, invited_by=self.a,
            status=CallParticipant.STATUS_ACCEPTED,
        )

        self.sent = []
        push = patch(
            'adsyconnect.views._send_call_data_message',
            side_effect=lambda *, target_user, payload: (
                self.sent.append((target_user.email, dict(payload))) or {}
            ),
        )
        push.start()
        self.addCleanup(push.stop)
        ws = patch('adsyconnect.views._broadcast_to_user', return_value=None)
        ws.start()
        self.addCleanup(ws.stop)

    def hang_up(self, who, receiver):
        client = APIClient()
        client.force_authenticate(user=who)
        return client.post(
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

    def test_leaving_a_group_call_stops_you_looking_busy(self):
        """The caller walks out. B and C keep talking. A is free.

        _active_call_for_user matched on caller/callee regardless of whether
        they had left, so A stayed 'busy' for the 90-second window — unable
        to place a call, and reported busy to anyone calling them.
        """
        from adsyconnect.views import _active_call_for_user

        self.hang_up(self.a, self.b)
        self.session.refresh_from_db()
        self.assertEqual(self.session.status, CallSession.STATUS_ACCEPTED)

        self.assertIsNone(
            _active_call_for_user(self.a),
            'a caller who left a still-running group call is not on a call',
        )
        # The people still talking are, of course, still busy.
        self.assertIsNotNone(_active_call_for_user(self.b))
        self.assertIsNotNone(_active_call_for_user(self.c))

    def test_hanging_up_works_when_your_original_peer_already_left(self):
        """A's client still names B, who is gone. C must still be told.

        The receiver membership check refused any receiver who had left,
        which 403'd the whole request — so C was never told A had gone and
        the session was never ended.
        """
        self.hang_up(self.b, self.a)          # B leaves first
        self.sent.clear()

        response = self.hang_up(self.a, self.b)  # A still addresses B
        self.assertEqual(response.status_code, 200, response.content)

        self.session.refresh_from_db()
        # Only C is left, so the call is genuinely over.
        self.assertEqual(self.session.status, CallSession.STATUS_ENDED)
        self.assertEqual(
            {email for email, _ in self.sent}, {'quin@example.com'})

    def test_someone_who_was_never_on_the_call_is_still_refused(self):
        """Relaxing the receiver check must not open it to strangers."""
        stranger = User.objects.create_user(
            username='rita', email='rita@example.com', password='x',
            first_name='Rita', phone='+880100000039')
        response = self.hang_up(self.a, stranger)
        self.assertEqual(response.status_code, 403)
        self.assertEqual(self.sent, [])

    def test_a_departed_member_cannot_act_on_the_call_again(self):
        """Leaving is one-way: no minting tokens for a call you walked out of."""
        self.hang_up(self.a, self.b)
        self.sent.clear()

        response = self.hang_up(self.a, self.b)
        self.assertEqual(response.status_code, 404)
        self.assertEqual(self.sent, [])


class InvitingIntoARealGroupCallTests(TestCase):
    """A call started from a real group must not grow that group's roster.

    Adding someone to a call and adding someone to a conversation are
    different acts. The call-becomes-a-group path made them the same, which
    would have handed an outsider permanent membership of a group they were
    never invited to.
    """

    def setUp(self):
        names = [('sara', 'Sara'), ('theo', 'Theo'), ('umar', 'Umar')]
        self.owner, self.member, self.outsider = [
            User.objects.create_user(
                username=u, email=f'{u}@example.com', password='x',
                first_name=f, phone=f'+88010000004{i}')
            for i, (u, f) in enumerate(names)
        ]
        self.group = ChatGroup.objects.create(
            name='Real Group', creator=self.owner)
        for user in (self.owner, self.member):
            ChatGroupMembership.objects.create(group=self.group, user=user)

        self.session = CallSession.objects.create(
            channel_name='c_real_group_call',
            caller=self.owner, callee=self.member, call_type='audio',
            status=CallSession.STATUS_ACCEPTED,
            chat_group=self.group,
        )
        # See above: an invite needs a prior conversation. This suite is about
        # what happens to the GROUP's roster afterwards, not about the gate.
        from .models import ChatRoom
        ChatRoom.objects.create(user1=self.owner, user2=self.outsider)

        for target in ('adsyconnect.views._send_call_data_message',
                       'adsyconnect.views._broadcast_to_user'):
            p = patch(target, return_value={'sent_to': 1})
            p.start()
            self.addCleanup(p.stop)
        for target, value in (
            ('adsyconnect.views._can_call', (True, '')),
            ('adsyconnect.views._active_call_for_user', None),
        ):
            p = patch(target, return_value=value)
            p.start()
            self.addCleanup(p.stop)

    def invite(self, invitee):
        client = APIClient()
        client.force_authenticate(user=self.owner)
        return client.post(
            '/api/adsyconnect/invite-to-call/',
            {
                'channel_name': self.session.channel_name,
                'call_id': str(self.session.id),
                'invitee_ids': [str(invitee.id)],
            },
            format='json',
        )

    def test_the_outsider_joins_the_call_but_not_the_group(self):
        before = set(
            self.group.memberships.values_list('user_id', flat=True))

        response = self.invite(self.outsider)
        self.assertEqual(response.status_code, 200, response.content)

        # On the call…
        self.assertTrue(
            self.session.participants.filter(user=self.outsider).exists())
        # …and nowhere near the group's member list.
        after = set(self.group.memberships.values_list('user_id', flat=True))
        self.assertEqual(after, before)
        self.assertNotIn(self.outsider.id, after)

    def test_no_system_message_is_posted_into_the_real_group(self):
        from .models import GroupMessage

        self.invite(self.outsider)
        self.assertEqual(
            GroupMessage.objects.filter(group=self.group).count(), 0)

    def test_a_call_born_group_does_still_grow(self):
        """The behaviour this is protecting must keep working."""
        plain = CallSession.objects.create(
            channel_name='c_plain_pair',
            caller=self.owner, callee=self.member, call_type='audio',
            status=CallSession.STATUS_ACCEPTED,
        )
        client = APIClient()
        client.force_authenticate(user=self.owner)
        client.post(
            '/api/adsyconnect/invite-to-call/',
            {
                'channel_name': plain.channel_name,
                'call_id': str(plain.id),
                'invitee_ids': [str(self.outsider.id)],
            },
            format='json',
        )

        plain.refresh_from_db()
        self.assertIsNotNone(plain.chat_group)
        self.assertTrue(plain.chat_group.created_from_call)
        self.assertIn(
            self.outsider.id,
            set(plain.chat_group.memberships.values_list('user_id', flat=True)),
        )


class AcceptedCallCannotBeUnansweredTests(TestCase):
    """A call that was answered must not be un-answered by a late signal.

    'rejected', 'busy' and 'missed' all mean "nobody picked up". Arriving
    after somebody has, each one is read as terminal by the caller's screen
    and tears down a conversation that is in progress. They do arrive:
    CallKit can emit a decline behind an accept, a retry can land late, and
    a second device that was also ringing reports its own timeout once the
    first device answers.
    """

    def setUp(self):
        self.caller = User.objects.create_user(
            username='vic', email='vic@example.com', password='x',
            first_name='Vic', phone='+880100000051')
        self.callee = User.objects.create_user(
            username='wren', email='wren@example.com', password='x',
            first_name='Wren', phone='+880100000052')
        self.session = CallSession.objects.create(
            channel_name='c_accept_race',
            caller=self.caller, callee=self.callee, call_type='audio',
            status=CallSession.STATUS_RINGING,
        )

        self.sent = []
        push = patch(
            'adsyconnect.views._send_call_data_message',
            side_effect=lambda *, target_user, payload: (
                self.sent.append((target_user.email, dict(payload))) or {}
            ),
        )
        push.start()
        self.addCleanup(push.stop)
        ws = patch('adsyconnect.views._broadcast_to_user', return_value=None)
        ws.start()
        self.addCleanup(ws.stop)

    def post(self, sender, status_value, receiver):
        client = APIClient()
        client.force_authenticate(user=sender)
        return client.post(
            '/api/adsyconnect/send-call-status/',
            {
                'receiver_id': str(receiver.id),
                'channel_name': self.session.channel_name,
                'status': status_value,
                'call_type': 'audio',
                'call_id': str(self.session.id),
            },
            format='json',
        )

    def accept(self):
        response = self.post(self.callee, 'accepted', self.caller)
        self.assertEqual(response.status_code, 200)
        self.session.refresh_from_db()
        self.assertEqual(self.session.status, CallSession.STATUS_ACCEPTED)
        self.assertIsNotNone(self.session.accepted_at)
        self.sent.clear()

    def test_a_decline_after_an_accept_is_ignored(self):
        self.accept()

        response = self.post(self.callee, 'rejected', self.caller)

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json()['ignored'])
        self.session.refresh_from_db()
        self.assertEqual(self.session.status, CallSession.STATUS_ACCEPTED)
        # And crucially: the caller is told nothing at all.
        self.assertEqual(self.sent, [])

    def test_busy_and_missed_after_an_accept_are_ignored_too(self):
        # Through the real endpoint, so accepted_at is stamped the way a real
        # accept stamps it — that timestamp, not the status, is what marks a
        # call as having been answered, and it outlives the call ending.
        self.accept()

        for late in ('busy', 'missed'):
            with self.subTest(status=late):
                self.sent.clear()

                response = self.post(self.callee, late, self.caller)

                self.assertEqual(response.status_code, 200)
                self.assertTrue(response.json()['ignored'])
                self.session.refresh_from_db()
                self.assertEqual(
                    self.session.status, CallSession.STATUS_ACCEPTED)
                self.assertEqual(self.sent, [])

    def test_hanging_up_an_accepted_call_still_works(self):
        """The guard must not make an answered call impossible to end."""
        self.accept()

        response = self.post(self.callee, 'ended', self.caller)

        self.assertEqual(response.status_code, 200)
        self.assertNotIn('ignored', response.json())
        self.session.refresh_from_db()
        self.assertEqual(self.session.status, CallSession.STATUS_ENDED)
        self.assertEqual(
            {e: p['status'] for e, p in self.sent},
            {'vic@example.com': 'ended'},
        )

    def test_declining_a_call_nobody_answered_still_works(self):
        """The ordinary decline is untouched."""
        response = self.post(self.callee, 'rejected', self.caller)

        self.assertEqual(response.status_code, 200)
        self.assertNotIn('ignored', response.json())
        self.session.refresh_from_db()
        self.assertEqual(self.session.status, CallSession.STATUS_REJECTED)
        self.assertEqual(
            {e: p['status'] for e, p in self.sent},
            {'vic@example.com': 'rejected'},
        )


class LateAcceptRevivesTheCallTests(TestCase):
    """A human answering beats an automatic status that got there first.

    Measured in production: of 38 answered calls in a day, 7 never reached
    media, and every one logged a terminal status BEFORE the accept — the
    callee's own device sending 'ended' or 'busy' seconds before the person
    pressed Accept. The session was terminal by then, the token endpoint
    409'd, and the call could never connect.
    """

    def setUp(self):
        self.caller = User.objects.create_user(
            username='xan', email='xan@example.com', password='x',
            first_name='Xan', phone='+880100000061')
        self.callee = User.objects.create_user(
            username='yara', email='yara@example.com', password='x',
            first_name='Yara', phone='+880100000062')
        self.session = CallSession.objects.create(
            channel_name='c_late_accept',
            caller=self.caller, callee=self.callee, call_type='audio',
            status=CallSession.STATUS_RINGING,
        )
        for target in ('adsyconnect.views._send_call_data_message',
                       'adsyconnect.views._broadcast_to_user'):
            p = patch(target, return_value={})
            p.start()
            self.addCleanup(p.stop)

    def post(self, sender, status_value, receiver):
        client = APIClient()
        client.force_authenticate(user=sender)
        return client.post(
            '/api/adsyconnect/send-call-status/',
            {
                'receiver_id': str(receiver.id),
                'channel_name': self.session.channel_name,
                'status': status_value,
                'call_type': 'audio',
                'call_id': str(self.session.id),
            },
            format='json',
        )

    def test_accept_after_a_stray_ended_revives_the_call(self):
        self.post(self.callee, 'ended', self.caller)
        self.session.refresh_from_db()
        self.assertEqual(self.session.status, CallSession.STATUS_ENDED)

        self.post(self.callee, 'accepted', self.caller)

        self.session.refresh_from_db()
        self.assertEqual(self.session.status, CallSession.STATUS_ACCEPTED)
        self.assertIsNotNone(self.session.accepted_at)
        # ended_at cleared, or the token endpoint keeps refusing the call.
        self.assertIsNone(self.session.ended_at)

    def test_accept_after_an_automatic_busy_revives_the_call(self):
        self.post(self.callee, 'busy', self.caller)
        self.post(self.callee, 'accepted', self.caller)

        self.session.refresh_from_db()
        self.assertEqual(self.session.status, CallSession.STATUS_ACCEPTED)
        self.assertIsNone(self.session.ended_at)

    def test_a_deliberate_decline_is_not_undone(self):
        """Rejecting is a person's decision; a late accept must not reverse it."""
        self.post(self.callee, 'rejected', self.caller)
        self.post(self.callee, 'accepted', self.caller)

        self.session.refresh_from_db()
        self.assertEqual(self.session.status, CallSession.STATUS_REJECTED)

    def test_a_caller_giving_up_is_not_undone(self):
        self.post(self.caller, 'cancelled', self.callee)
        self.post(self.callee, 'accepted', self.caller)

        self.session.refresh_from_db()
        self.assertEqual(self.session.status, CallSession.STATUS_CANCELLED)

    def test_an_old_dead_call_is_not_revived(self):
        """Only a fresh mistake is worth undoing."""
        from django.utils import timezone as tz
        self.post(self.callee, 'ended', self.caller)
        self.session.refresh_from_db()
        self.session.ended_at = tz.now() - tz.timedelta(minutes=5)
        self.session.save(update_fields=['ended_at'])

        self.post(self.callee, 'accepted', self.caller)

        self.session.refresh_from_db()
        self.assertEqual(self.session.status, CallSession.STATUS_ENDED)

    def test_cancelled_after_an_accept_is_recorded_as_ended(self):
        """Wrong word, right intent — the call was answered, then it stopped."""
        self.post(self.callee, 'accepted', self.caller)
        self.post(self.callee, 'cancelled', self.caller)

        self.session.refresh_from_db()
        self.assertEqual(self.session.status, CallSession.STATUS_ENDED)
        self.assertIsNotNone(self.session.accepted_at)


class ReconnectRelayTests(TestCase):
    """"Rejoin, both of us" — a request, not a state change.

    Each side already retried its own join, and that is what did not work: a
    side that rejoins while the other has stalled arrives in an empty room and
    its ladder declares failure. This relay is how they rejoin together, so it
    must reach the peer while touching nothing about the call.
    """

    def setUp(self):
        self.caller = User.objects.create_user(
            username='zed', email='zed@example.com', password='x',
            first_name='Zed', phone='+880100000071')
        self.callee = User.objects.create_user(
            username='ada', email='ada@example.com', password='x',
            first_name='Ada', phone='+880100000072')
        self.session = CallSession.objects.create(
            channel_name='c_reconnect',
            caller=self.caller, callee=self.callee, call_type='audio',
            status=CallSession.STATUS_ACCEPTED,
        )
        self.sent = []
        push = patch(
            'adsyconnect.views._send_call_data_message',
            side_effect=lambda *, target_user, payload: (
                self.sent.append((target_user.email, dict(payload))) or {}
            ),
        )
        push.start()
        self.addCleanup(push.stop)
        ws = patch('adsyconnect.views._broadcast_to_user', return_value=None)
        ws.start()
        self.addCleanup(ws.stop)

    def ask(self, sender, receiver, channel=None):
        client = APIClient()
        client.force_authenticate(user=sender)
        return client.post(
            '/api/adsyconnect/send-call-status/',
            {
                'receiver_id': str(receiver.id),
                'channel_name': channel or self.session.channel_name,
                'status': 'reconnect',
                'call_type': 'audio',
                'call_id': str(self.session.id),
            },
            format='json',
        )

    def test_it_reaches_the_peer(self):
        response = self.ask(self.callee, self.caller)

        self.assertEqual(response.status_code, 200, response.content)
        self.assertTrue(response.json()['relayed_only'])
        self.assertEqual(
            [(e, p['status']) for e, p in self.sent],
            [('zed@example.com', 'reconnect')],
        )

    def test_it_changes_nothing_about_the_call(self):
        before = CallSession.objects.get(pk=self.session.pk)

        self.ask(self.callee, self.caller)

        after = CallSession.objects.get(pk=self.session.pk)
        self.assertEqual(after.status, before.status)
        self.assertEqual(after.accepted_at, before.accepted_at)
        self.assertEqual(after.ended_at, before.ended_at)
        self.assertEqual(after.last_status_at, before.last_status_at)

    def test_it_works_on_a_call_that_is_still_ringing(self):
        """Media can fail before anyone has pressed accept."""
        self.session.status = CallSession.STATUS_RINGING
        self.session.accepted_at = None
        self.session.save(update_fields=['status', 'accepted_at'])

        response = self.ask(self.callee, self.caller)

        self.assertEqual(response.status_code, 200)
        self.session.refresh_from_db()
        self.assertEqual(self.session.status, CallSession.STATUS_RINGING)

    def test_a_stranger_cannot_ask(self):
        """The relay sits behind the same membership checks as everything else."""
        stranger = User.objects.create_user(
            username='eve', email='eve@example.com', password='x',
            first_name='Eve', phone='+880100000079')

        response = self.ask(stranger, self.caller)

        self.assertEqual(response.status_code, 404)
        self.assertEqual(self.sent, [])

    def test_it_cannot_be_aimed_at_someone_outside_the_call(self):
        outsider = User.objects.create_user(
            username='mal', email='mal@example.com', password='x',
            first_name='Mal', phone='+880100000078')

        response = self.ask(self.callee, outsider)

        self.assertEqual(response.status_code, 403)
        self.assertEqual(self.sent, [])


class InviteRequiresAPriorChatTests(TestCase):
    """You may only pull into a call someone you have talked to.

    The picker offers the inviter's own conversations, but that is a list in
    an app — it decides what is easy, not what is possible. Without the rule
    here, a posted user id would be enough to make a stranger's phone ring.
    """

    def setUp(self):
        self.a = User.objects.create_user(
            username='ivy', email='ivy@example.com', password='x',
            first_name='Ivy', phone='+880100000091')
        self.b = User.objects.create_user(
            username='jon', email='jon@example.com', password='x',
            first_name='Jon', phone='+880100000092')
        self.stranger = User.objects.create_user(
            username='kim', email='kim@example.com', password='x',
            first_name='Kim', phone='+880100000093')

        self.session = CallSession.objects.create(
            channel_name='c_invite_gate',
            caller=self.a, callee=self.b, call_type='audio',
            status=CallSession.STATUS_ACCEPTED,
        )
        for target in ('adsyconnect.views._send_call_data_message',
                       'adsyconnect.views._broadcast_to_user'):
            p = patch(target, return_value={'sent_to': 1})
            p.start()
            self.addCleanup(p.stop)
        for target, value in (
            ('adsyconnect.views._can_call', (True, '')),
            ('adsyconnect.views._active_call_for_user', None),
        ):
            p = patch(target, return_value=value)
            p.start()
            self.addCleanup(p.stop)

    def invite(self, invitee):
        client = APIClient()
        client.force_authenticate(user=self.a)
        return client.post(
            '/api/adsyconnect/invite-to-call/',
            {
                'channel_name': self.session.channel_name,
                'call_id': str(self.session.id),
                'invitee_ids': [str(invitee.id)],
            },
            format='json',
        )

    def test_a_stranger_cannot_be_added(self):
        response = self.invite(self.stranger)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json()['results'][0]['status'], 'not_allowed')
        self.assertFalse(
            self.session.participants.filter(user=self.stranger).exists())

    def test_someone_you_have_chatted_with_can_be_added(self):
        from adsyconnect.models import ChatRoom
        ChatRoom.objects.create(user1=self.a, user2=self.stranger)

        response = self.invite(self.stranger)

        self.assertEqual(response.status_code, 200)
        self.assertIn(
            response.json()['results'][0]['status'], ('ringing', 'unreachable'))
        self.assertTrue(
            self.session.participants.filter(user=self.stranger).exists())

    def test_the_chat_counts_in_either_direction(self):
        """Who opened the conversation does not matter."""
        from adsyconnect.models import ChatRoom
        ChatRoom.objects.create(user1=self.stranger, user2=self.a)

        response = self.invite(self.stranger)

        self.assertIn(
            response.json()['results'][0]['status'], ('ringing', 'unreachable'))


class JoiningACallInProgressTests(TestCase):
    """Missing the ring must not mean missing the call.

    A group call used to be enterable only by answering the ring for it. Join
    the group afterwards, decline by accident, or simply have your phone in
    another room, and the call carried on with no way back in.
    """

    def setUp(self):
        self.users = []
        for i, (uname, first) in enumerate([
            ('jack', 'Jack'), ('kate', 'Kate'), ('liam', 'Liam'),
            ('mona', 'Mona'),
        ]):
            self.users.append(User.objects.create_user(
                username=uname, email='%s@example.com' % uname, password='x',
                first_name=first, phone='+88010000004%d' % i,
            ))
        self.owner, self.m2, self.latecomer, self.outsider = self.users

        self.group = ChatGroup.objects.create(
            name='Join Group', creator=self.owner)
        for user in (self.owner, self.m2, self.latecomer):
            ChatGroupMembership.objects.create(
                group=self.group, user=user,
                role='admin' if user == self.owner else 'member',
            )

        # The call the group is already on: owner and m2 talking, and the
        # latecomer never answered — the case the banner exists for.
        self.session = CallSession.objects.create(
            channel_name='c_join_1',
            caller=self.owner,
            callee=self.m2,
            call_type='audio',
            status=CallSession.STATUS_ACCEPTED,
            # What answering actually records. Only the callee's own accept
            # reaches update_status — an invited participant accepting is
            # written to their own row — so this is the mark of the callee
            # having picked up, and _is_on_call reads it as exactly that.
            accepted_at=timezone.now(),
            chat_group=self.group,
        )

        self.broadcasts = []
        ws = patch(
            'adsyconnect.views._broadcast_to_user',
            side_effect=lambda user_id, event: self.broadcasts.append(
                (str(user_id), event)
            ),
        )
        ws.start()
        self.addCleanup(ws.stop)
        push = patch('adsyconnect.views._send_call_data_message',
                     return_value={})
        push.start()
        self.addCleanup(push.stop)

    def ask(self, user, group_id=None):
        client = APIClient()
        client.force_authenticate(user=user)
        return client.get('/api/adsyconnect/groups/%s/active-call/'
                          % (group_id or self.group.id))

    def join(self, user, group_id=None):
        client = APIClient()
        client.force_authenticate(user=user)
        return client.post(
            '/api/adsyconnect/join-group-call/',
            {'group_id': str(group_id or self.group.id)},
            format='json',
        )

    # ── seeing it ───────────────────────────────────────────────────────────

    def test_a_member_who_is_not_on_the_call_is_offered_a_way_in(self):
        response = self.ask(self.latecomer)
        self.assertEqual(response.status_code, 200, response.content)
        body = response.json()

        self.assertTrue(body['active'])
        self.assertEqual(body['channel_name'], 'c_join_1')
        self.assertEqual(body['call_type'], 'audio')
        self.assertEqual(body['call_id'], str(self.session.id))
        self.assertEqual(body['participant_count'], 2)
        self.assertFalse(body['is_full'])
        # Named, so the banner can say who is talking.
        names = {p['name'] for p in body['participants']}
        self.assertIn('Jack', names)
        self.assertIn('Kate', names)

    def test_somebody_already_on_the_call_is_not_offered_a_way_in(self):
        """The banner would be a door into the room they are standing in."""
        for member in (self.owner, self.m2):
            body = self.ask(member).json()
            self.assertFalse(body['active'])
            self.assertEqual(body['reason'], 'already_in_call')

    def test_a_non_member_is_refused(self):
        self.assertEqual(self.ask(self.outsider).status_code, 403)
        self.assertEqual(self.join(self.outsider).status_code, 403)

    def test_no_call_means_no_banner(self):
        self.session.status = CallSession.STATUS_ENDED
        self.session.save(update_fields=['status'])
        self.assertFalse(self.ask(self.latecomer).json()['active'])

    def test_an_ended_call_is_never_offered_even_with_a_live_one_before_it(self):
        """Terminal is terminal, whichever way the session got there."""
        for terminal in CallSession.TERMINAL_STATUSES:
            self.session.status = terminal
            self.session.save(update_fields=['status'])
            self.assertFalse(
                self.ask(self.latecomer).json()['active'],
                'status=%s was still offered as joinable' % terminal)

    # ── walking in ──────────────────────────────────────────────────────────

    def test_joining_puts_them_on_the_call_for_real(self):
        response = self.join(self.latecomer)
        self.assertEqual(response.status_code, 200, response.content)
        body = response.json()

        self.assertTrue(body['success'])
        self.assertEqual(body['channel_name'], 'c_join_1')
        self.assertEqual(body['call_id'], str(self.session.id))
        self.assertEqual(body['group_id'], str(self.group.id))
        self.assertEqual(body['participant_count'], 3)

        # Accepted, not ringing: nobody rang them.
        participant = CallParticipant.objects.get(
            session=self.session, user=self.latecomer)
        self.assertEqual(participant.status, CallParticipant.STATUS_ACCEPTED)
        self.assertIsNotNone(participant.responded_at)
        self.assertIn(self.latecomer.id, self.session.live_member_ids())

    def test_the_token_endpoint_will_now_serve_them(self):
        """Without this the join is a row in a table and nothing more.

        _call_membership_q is what every "may this person touch this call?"
        check runs through, and it is the reason the participant row has to
        exist before the client asks for a token.
        """
        from .views import _call_membership_q

        self.assertFalse(
            CallSession.objects.filter(
                _call_membership_q(self.latecomer), id=self.session.id
            ).exists())

        self.assertEqual(self.join(self.latecomer).status_code, 200)

        self.assertTrue(
            CallSession.objects.filter(
                _call_membership_q(self.latecomer), id=self.session.id
            ).exists())

    def test_the_people_talking_are_told_somebody_arrived(self):
        self.broadcasts.clear()
        self.join(self.latecomer)

        told = {}
        for user_id, event in self.broadcasts:
            payload = event.get('payload', {})
            if payload.get('status') == 'participant_joined':
                told[user_id] = payload

        self.assertEqual(
            sorted(told), sorted([str(self.owner.id), str(self.m2.id)]))
        for payload in told.values():
            self.assertEqual(payload['joined_user_id'], str(self.latecomer.id))
            self.assertEqual(payload['joined_user_name'], 'Liam')
            self.assertEqual(payload['channel_name'], 'c_join_1')
        # And the joiner is not sent news of their own arrival.
        self.assertNotIn(str(self.latecomer.id), told)

    def test_joining_twice_is_harmless(self):
        self.assertEqual(self.join(self.latecomer).status_code, 200)
        self.broadcasts.clear()
        self.assertEqual(self.join(self.latecomer).status_code, 200)

        self.assertEqual(
            CallParticipant.objects.filter(
                session=self.session, user=self.latecomer).count(), 1)
        # Nobody is told twice that the same person arrived.
        self.assertFalse([
            1 for _, event in self.broadcasts
            if event.get('payload', {}).get('status') == 'participant_joined'
        ])

    def test_a_big_call_is_not_a_full_call(self):
        """There is no ceiling on how many people a call may hold.

        There used to be one at eight, which turned "your phone will work
        harder" into "you cannot join". The media layer handles the load —
        adaptive stream pauses video nobody is looking at — so the twentieth
        person gets in exactly like the third.
        """
        for i in range(20):
            user = User.objects.create_user(
                username='filler%d' % i, email='filler%d@example.com' % i,
                password='x', first_name='F%d' % i,
                phone='+8801000000%d' % (50 + i))
            ChatGroupMembership.objects.create(group=self.group, user=user)
            CallParticipant.objects.create(
                session=self.session, user=user,
                status=CallParticipant.STATUS_ACCEPTED)

        self.assertEqual(len(self.session.live_member_ids()), 22)

        body = self.ask(self.latecomer).json()
        self.assertTrue(body['active'])
        self.assertFalse(body['is_full'])
        self.assertEqual(body['participant_count'], 22)

        response = self.join(self.latecomer)
        self.assertEqual(response.status_code, 200, response.content)
        self.assertEqual(response.json()['participant_count'], 23)
        self.assertEqual(
            CallParticipant.objects.get(
                session=self.session, user=self.latecomer).status,
            CallParticipant.STATUS_ACCEPTED)

    def test_somebody_mid_call_elsewhere_is_refused(self):
        """Joining must not silently drop the call they are already on."""
        other = CallSession.objects.create(
            channel_name='c_elsewhere',
            caller=self.latecomer,
            callee=self.outsider,
            call_type='audio',
            status=CallSession.STATUS_ACCEPTED,
        )

        response = self.join(self.latecomer)
        self.assertEqual(response.status_code, 409)
        self.assertIn('active call', response.json()['error'].lower())
        self.assertFalse(CallParticipant.objects.filter(
            session=self.session, user=self.latecomer).exists())

        other.status = CallSession.STATUS_ENDED
        other.save(update_fields=['status'])
        self.assertEqual(self.join(self.latecomer).status_code, 200)

    def test_being_rung_for_this_very_call_does_not_block_joining(self):
        """The commonest case: rung, ignored it, taps Join a minute later."""
        CallParticipant.objects.create(
            session=self.session, user=self.latecomer,
            status=CallParticipant.STATUS_RINGING)

        self.assertEqual(self.join(self.latecomer).status_code, 200)
        participant = CallParticipant.objects.get(
            session=self.session, user=self.latecomer)
        self.assertEqual(participant.status, CallParticipant.STATUS_ACCEPTED)

    def test_someone_who_declined_can_still_change_their_mind(self):
        CallParticipant.objects.create(
            session=self.session, user=self.latecomer,
            status=CallParticipant.STATUS_REJECTED)

        self.assertTrue(self.ask(self.latecomer).json()['active'])
        self.assertEqual(self.join(self.latecomer).status_code, 200)
        self.assertEqual(
            CallParticipant.objects.get(
                session=self.session, user=self.latecomer).status,
            CallParticipant.STATUS_ACCEPTED)

    def test_a_call_that_ended_between_the_banner_and_the_tap(self):
        self.assertTrue(self.ask(self.latecomer).json()['active'])
        self.session.status = CallSession.STATUS_ENDED
        self.session.save(update_fields=['status'])

        response = self.join(self.latecomer)
        self.assertEqual(response.status_code, 404)
        self.assertFalse(CallParticipant.objects.filter(
            session=self.session, user=self.latecomer).exists())

    def test_a_one_to_one_call_is_not_offered_to_a_group(self):
        """Only calls that belong to this group are joinable from it."""
        self.session.chat_group = None
        self.session.save(update_fields=['chat_group'])

        self.assertFalse(self.ask(self.latecomer).json()['active'])
        self.assertEqual(self.join(self.latecomer).status_code, 404)

    def test_a_missing_group_is_a_404_not_a_crash(self):
        import uuid as _uuid
        ghost = _uuid.uuid4()
        self.assertEqual(self.ask(self.latecomer, group_id=ghost).status_code,
                         404)
        self.assertEqual(self.join(self.latecomer, group_id=ghost).status_code,
                         404)

    def test_group_id_is_required(self):
        client = APIClient()
        client.force_authenticate(user=self.latecomer)
        response = client.post('/api/adsyconnect/join-group-call/', {},
                               format='json')
        self.assertEqual(response.status_code, 400)

    def test_the_callee_who_never_answered_is_still_offered_a_way_in(self):
        """The server picks who fills the callee slot; missing the ring there
        must not be different from missing it as an invitee.

        Somebody else answering marks the session accepted at the top level,
        which is why "the call was answered" cannot stand in for "you
        answered it".
        """
        unanswered = CallSession.objects.create(
            channel_name='c_join_3',
            caller=self.owner,
            callee=self.latecomer,
            call_type='audio',
            status=CallSession.STATUS_ACCEPTED,
            chat_group=self.group,
        )
        # m2 was an invitee and picked up; the callee's phone rang out.
        CallParticipant.objects.create(
            session=unanswered, user=self.m2,
            status=CallParticipant.STATUS_ACCEPTED)

        body = self.ask(self.latecomer).json()
        self.assertTrue(body['active'])
        self.assertEqual(body['call_id'], str(unanswered.id))
        self.assertEqual(self.join(self.latecomer).status_code, 200)

    def test_somebody_who_left_can_come_back(self):
        """Leaving a group call is not being thrown out of the group."""
        self.session.callee_left_at = timezone.now()
        self.session.save(update_fields=['callee_left_at'])
        self.assertNotIn(self.m2.id, self.session.live_member_ids())

        self.assertTrue(self.ask(self.m2).json()['active'])
        self.assertEqual(self.join(self.m2).status_code, 200)

        self.session.refresh_from_db()
        # Back through the timestamp they are tracked by, NOT a participant
        # row — mark_member_left only knows about the timestamp, so a row
        # would leave them counted as live for ever after they next hang up.
        self.assertIsNone(self.session.callee_left_at)
        self.assertIn(self.m2.id, self.session.live_member_ids())
        self.assertFalse(CallParticipant.objects.filter(
            session=self.session, user=self.m2).exists())

    def test_an_invitee_who_accepted_is_not_offered_a_way_in(self):
        CallParticipant.objects.create(
            session=self.session, user=self.latecomer,
            status=CallParticipant.STATUS_ACCEPTED)
        body = self.ask(self.latecomer).json()
        self.assertFalse(body['active'])
        self.assertEqual(body['reason'], 'already_in_call')

    def test_a_call_that_rang_out_is_not_offered(self):
        """A client that dies mid-ring never writes its own ending.

        Without an age limit that session stays non-terminal for ever and the
        banner offers a way into an empty room.
        """
        self.session.status = CallSession.STATUS_RINGING
        self.session.accepted_at = None
        self.session.started_at = timezone.now() - timedelta(minutes=10)
        self.session.save(
            update_fields=['status', 'accepted_at', 'started_at'])

        self.assertFalse(self.ask(self.latecomer).json()['active'])
        self.assertEqual(self.join(self.latecomer).status_code, 404)

    def test_a_call_still_ringing_moments_ago_is_offered(self):
        self.session.status = CallSession.STATUS_RINGING
        self.session.accepted_at = None
        self.session.save(update_fields=['status', 'accepted_at'])
        self.assertTrue(self.ask(self.latecomer).json()['active'])

    def test_a_call_nobody_is_left_in_is_not_offered(self):
        self.session.caller_left_at = timezone.now()
        self.session.callee_left_at = timezone.now()
        self.session.save(
            update_fields=['caller_left_at', 'callee_left_at'])
        self.assertEqual(self.session.live_member_ids(), [])

        self.assertFalse(self.ask(self.latecomer).json()['active'])

    def test_a_call_from_yesterday_is_not_offered(self):
        self.session.started_at = timezone.now() - timedelta(hours=30)
        self.session.save(update_fields=['started_at'])
        self.assertFalse(self.ask(self.latecomer).json()['active'])

    def test_the_newest_call_is_the_one_offered(self):
        """Two live sessions on one group: show the one they are looking for."""
        newer = CallSession.objects.create(
            channel_name='c_join_2',
            caller=self.m2,
            callee=self.owner,
            call_type='video',
            status=CallSession.STATUS_RINGING,
            chat_group=self.group,
        )
        body = self.ask(self.latecomer).json()
        self.assertEqual(body['call_id'], str(newer.id))
        self.assertEqual(body['call_type'], 'video')
