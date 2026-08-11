# -*- coding: utf-8 -*-
"""The Business Network had no realtime path at all.

Not one channel-layer call in the whole app: notifications went out as FCM
push, which is right for a phone in a pocket and useless for the person
looking at the screen. The bell's count only moved on a reload, and a comment
on the post you were reading appeared when you pulled to refresh.

These tests assert on what is broadcast and to whom, so the delivery is
checked without needing a live socket.
"""
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase

from .models import (
    BusinessNetworkFollowerModel,
    BusinessNetworkNotification,
    BusinessNetworkPost,
    BusinessNetworkPostComment,
    BusinessNetworkPostLike,
)
from .realtime import notification_payload, post_group

User = get_user_model()


class BusinessNetworkRealtimeTests(TestCase):
    def setUp(self):
        self.author = User.objects.create_user(
            username='bn1', email='bn1@example.com', password='x',
            first_name='Post', last_name='Author', phone='+880100002001')
        self.reader = User.objects.create_user(
            username='bn2', email='bn2@example.com', password='x',
            first_name='Nadia', last_name='Reader', phone='+880100002002')
        self.third = User.objects.create_user(
            username='bn3', email='bn3@example.com', password='x',
            first_name='Third', phone='+880100002003')

        self.post = BusinessNetworkPost.objects.create(
            author=self.author, title='A post', content='Body')

        # Every group_send is recorded instead of attempted.
        self.sent = []
        layer = patch(
            'business_network.realtime._send',
            side_effect=lambda group, payload: (
                self.sent.append((group, payload)) or True),
        )
        layer.start()
        self.addCleanup(layer.stop)

        # The FCM path is not under test here and must not reach the network.
        push = patch('business_network.signals.send_fcm_notification_async',
                     return_value=None)
        push.start()
        self.addCleanup(push.stop)

    # ── helpers ─────────────────────────────────────────────────────────────

    def payloads_to(self, group):
        return [p for g, p in self.sent if g == group]

    def notifications_for(self, user):
        return [
            p['payload'] for g, p in self.sent
            if g == 'user_%s' % user.id
            and p.get('type') == 'bn_notification_event'
        ]

    def post_events(self):
        return [
            p['payload'] for g, p in self.sent
            if g == post_group(self.post.id)
            and p.get('type') == 'bn_post_activity_event'
        ]

    # ── the bell ────────────────────────────────────────────────────────────

    def test_a_like_reaches_the_author_live(self):
        BusinessNetworkPostLike.objects.create(post=self.post, user=self.reader)

        rows = self.notifications_for(self.author)
        self.assertEqual(len(rows), 1)
        note = rows[0]['notification']
        self.assertEqual(note['notification_type'], 'like_post')
        self.assertEqual(note['actor_id'], str(self.reader.id))
        self.assertEqual(note['actor_name'], 'Nadia Reader')
        self.assertEqual(note['target_id'], str(self.post.id))
        self.assertFalse(note['read'])
        # The bell can update its badge without a second request.
        self.assertEqual(rows[0]['unread_count'], 1)

    def test_a_comment_reaches_the_author_live(self):
        BusinessNetworkPostComment.objects.create(
            post=self.post, author=self.reader, content='Nice one')
        rows = self.notifications_for(self.author)
        self.assertEqual(len(rows), 1)
        self.assertEqual(
            rows[0]['notification']['notification_type'], 'comment')
        self.assertEqual(rows[0]['notification']['content'], 'Nice one')

    def test_a_follow_reaches_the_followed_user_live(self):
        BusinessNetworkFollowerModel.objects.create(
            follower=self.reader, following=self.author)
        rows = self.notifications_for(self.author)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]['notification']['notification_type'], 'follow')

    def test_every_notification_type_travels_without_being_wired_up_twice(self):
        """The receiver is on the notification model, not on each signal.

        A type nobody has thought of yet must reach the socket too — that is
        the whole reason it lives in one place.
        """
        BusinessNetworkNotification.objects.create(
            recipient=self.author, actor=self.reader, type='solution',
            target_id=str(self.post.id), content='marked as solution')
        rows = self.notifications_for(self.author)
        self.assertEqual(len(rows), 1)
        self.assertEqual(
            rows[0]['notification']['notification_type'], 'solution')

    def test_the_unread_count_climbs_with_each_one(self):
        BusinessNetworkPostLike.objects.create(post=self.post, user=self.reader)
        BusinessNetworkPostComment.objects.create(
            post=self.post, author=self.third, content='me too')
        counts = [row['unread_count'] for row in self.notifications_for(self.author)]
        self.assertEqual(counts, [1, 2])

    def test_editing_a_notification_does_not_re_announce_it(self):
        note = BusinessNetworkNotification.objects.create(
            recipient=self.author, actor=self.reader, type='follow')
        self.sent.clear()
        note.read = True
        note.save(update_fields=['read'])
        self.assertEqual(self.notifications_for(self.author), [])

    def test_the_actor_is_not_told_about_their_own_action(self):
        BusinessNetworkPostLike.objects.create(post=self.post, user=self.reader)
        self.assertEqual(self.notifications_for(self.reader), [])

    def test_liking_your_own_post_notifies_nobody(self):
        BusinessNetworkPostLike.objects.create(post=self.post, user=self.author)
        self.assertEqual(self.notifications_for(self.author), [])

    # ── the post everyone is reading ───────────────────────────────────────

    def test_a_comment_is_broadcast_to_the_post_not_just_its_author(self):
        """Everyone with the post open, including people who are not the author."""
        comment = BusinessNetworkPostComment.objects.create(
            post=self.post, author=self.reader, content='A long opinion')

        events = self.post_events()
        self.assertEqual(len(events), 1)
        self.assertEqual(events[0]['event'], 'comment_added')
        self.assertEqual(events[0]['comment_id'], str(comment.id))
        self.assertEqual(events[0]['post_id'], str(self.post.id))
        self.assertEqual(events[0]['author_name'], 'Nadia Reader')
        self.assertEqual(events[0]['preview'], 'A long opinion')

    def test_a_like_and_an_unlike_are_both_broadcast(self):
        like = BusinessNetworkPostLike.objects.create(
            post=self.post, user=self.reader)
        like.delete()

        events = [e['event'] for e in self.post_events()]
        self.assertEqual(events, ['like_added', 'like_removed'])

    def test_the_author_commenting_on_their_own_post_still_tells_readers(self):
        """No self-notification, but the thread is still live for everyone else."""
        BusinessNetworkPostComment.objects.create(
            post=self.post, author=self.author, content='replying to myself')
        self.assertEqual(self.notifications_for(self.author), [])
        self.assertEqual(len(self.post_events()), 1)

    def test_the_preview_is_trimmed(self):
        BusinessNetworkPostComment.objects.create(
            post=self.post, author=self.reader, content='x' * 500)
        self.assertEqual(len(self.post_events()[0]['preview']), 140)

    def test_post_groups_are_a_legal_channel_name(self):
        """channels rejects a group name with characters like '-' in it."""
        import re
        name = post_group('0195c0de-dead-beef-0000-000000000001')
        self.assertTrue(re.fullmatch(r'[A-Za-z0-9_.-]+', name), name)
        self.assertNotIn('-', name.split('post_', 1)[1])

    # ── failure must not break the feature ─────────────────────────────────

    def test_a_dead_channel_layer_does_not_break_liking_a_post(self):
        with patch('business_network.realtime._layer', return_value=None):
            like = BusinessNetworkPostLike.objects.create(
                post=self.post, user=self.third)
        self.assertTrue(
            BusinessNetworkPostLike.objects.filter(pk=like.pk).exists())

    def test_a_channel_layer_that_raises_does_not_break_commenting(self):
        """Redis being down must cost the live update, not the comment.

        Deliberately breaks the LAYER rather than _send: _send is where the
        safety net lives, so patching it out would test nothing that happens in
        production.
        """
        class ExplodingLayer:
            async def group_send(self, *args, **kwargs):
                raise RuntimeError('redis is down')

        # Stop the recording stub so the real _send runs against the bad layer.
        patch.stopall()
        push = patch('business_network.signals.send_fcm_notification_async',
                     return_value=None)
        push.start()
        self.addCleanup(push.stop)
        layer = patch('business_network.realtime._layer',
                      return_value=ExplodingLayer())
        layer.start()
        self.addCleanup(layer.stop)

        comment = BusinessNetworkPostComment.objects.create(
            post=self.post, author=self.third, content='still works')
        like = BusinessNetworkPostLike.objects.create(
            post=self.post, user=self.third)

        self.assertTrue(
            BusinessNetworkPostComment.objects.filter(pk=comment.pk).exists())
        self.assertTrue(
            BusinessNetworkPostLike.objects.filter(pk=like.pk).exists())
        # And the notification row was still written, so the bell is right on
        # the next fetch even though nothing was pushed.
        self.assertTrue(BusinessNetworkNotification.objects.filter(
            recipient=self.author, type='comment').exists())


class NotificationPayloadTests(TestCase):
    """The payload the bell renders from."""

    def setUp(self):
        self.recipient = User.objects.create_user(
            username='np1', email='np1@example.com', password='x',
            first_name='R', phone='+880100002101')
        self.actor = User.objects.create_user(
            username='np2', email='np2@example.com', password='x',
            phone='+880100002102')

    def test_an_actor_with_no_name_falls_back_to_something_printable(self):
        note = BusinessNetworkNotification.objects.create(
            recipient=self.recipient, actor=self.actor, type='follow')
        payload = notification_payload(note)
        self.assertTrue(payload['notification']['actor_name'])

    def test_a_missing_avatar_is_an_empty_string_not_a_crash(self):
        note = BusinessNetworkNotification.objects.create(
            recipient=self.recipient, actor=self.actor, type='follow')
        self.assertEqual(notification_payload(note)['notification']['actor_avatar'], '')

    def test_null_target_and_content_come_out_as_empty_strings(self):
        note = BusinessNetworkNotification.objects.create(
            recipient=self.recipient, actor=self.actor, type='follow')
        payload = notification_payload(note)['notification']
        self.assertEqual(payload['target_id'], '')
        self.assertEqual(payload['parent_id'], '')
        self.assertEqual(payload['content'], '')
        self.assertIsNotNone(payload['created_at'])
