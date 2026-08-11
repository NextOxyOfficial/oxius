# -*- coding: utf-8 -*-
"""Membership and metadata changes have to reach the people they affect.

`group_updated` went out when a group was created and when members were added.
Everything else was silent: being removed left the group sitting in that
person's chat list and, if they had it open, let them keep typing into a group
they were no longer in until a send came back 403. A rename, a new photo, a
promotion, somebody leaving, the whole group being deleted — all invisible
until a reload.
"""
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from .models import ChatGroup, ChatGroupMembership

User = get_user_model()


class GroupUpdateBroadcastTests(TestCase):
    def setUp(self):
        self.admin = User.objects.create_user(
            username='gu1', email='gu1@example.com', password='x',
            first_name='Admin', phone='+880100004001')
        self.member = User.objects.create_user(
            username='gu2', email='gu2@example.com', password='x',
            first_name='Member', phone='+880100004002')
        self.other = User.objects.create_user(
            username='gu3', email='gu3@example.com', password='x',
            first_name='Other', phone='+880100004003')

        self.group = ChatGroup.objects.create(name='Squad', creator=self.admin)
        ChatGroupMembership.objects.create(
            group=self.group, user=self.admin, role='admin')
        for user in (self.member, self.other):
            ChatGroupMembership.objects.create(group=self.group, user=user)

        self.sent = []
        ws = patch(
            'adsyconnect.views._broadcast_to_user',
            side_effect=lambda uid, event: self.sent.append((str(uid), event)),
        )
        ws.start()
        self.addCleanup(ws.stop)

        self.client = APIClient()
        self.client.force_authenticate(user=self.admin)

    # ── helpers ─────────────────────────────────────────────────────────────

    def updates(self):
        return [
            (uid, e) for uid, e in self.sent
            if e.get('type') == 'group_updated'
        ]

    def told(self):
        return sorted(uid for uid, _ in self.updates())

    def event_for(self, user):
        for uid, event in self.updates():
            if uid == str(user.id):
                return event
        return None

    def post(self, action, body=None, user=None):
        client = self.client
        if user is not None:
            client = APIClient()
            client.force_authenticate(user=user)
        return client.post(
            '/api/adsyconnect/groups/%s/%s/' % (self.group.id, action),
            body or {}, format='json')

    # ── removal ─────────────────────────────────────────────────────────────

    def test_the_removed_member_is_told_they_are_out(self):
        response = self.post('remove_member', {'user_id': str(self.member.id)})
        self.assertEqual(response.status_code, 200, response.content)

        event = self.event_for(self.member)
        self.assertIsNotNone(event, 'the removed member was told nothing')
        self.assertTrue(event['removed'])
        self.assertEqual(event['group_id'], str(self.group.id))

    def test_everyone_still_in_the_group_hears_about_it_too(self):
        self.post('remove_member', {'user_id': str(self.member.id)})
        self.assertIn(str(self.admin.id), self.told())
        self.assertIn(str(self.other.id), self.told())

    def test_the_people_still_in_it_are_not_told_they_were_removed(self):
        self.post('remove_member', {'user_id': str(self.member.id)})
        for user in (self.admin, self.other):
            event = self.event_for(user)
            self.assertIsNotNone(event)
            self.assertNotIn('removed', event, '%s' % event)

    def test_the_payload_carries_the_new_member_list(self):
        self.post('remove_member', {'user_id': str(self.member.id)})
        event = self.event_for(self.admin)
        self.assertEqual(event['group']['member_count'], 2)

    def test_removing_somebody_who_is_not_a_member_announces_nothing(self):
        response = self.post('remove_member', {'user_id': str(
            User.objects.create_user(
                username='gu9', email='gu9@example.com', password='x',
                first_name='Nobody', phone='+880100004009').id)})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(self.updates(), [])

    def test_a_non_admin_cannot_remove_and_nothing_is_announced(self):
        response = self.post(
            'remove_member', {'user_id': str(self.other.id)}, user=self.member)
        self.assertEqual(response.status_code, 403)
        self.assertEqual(self.updates(), [])

    # ── leaving ─────────────────────────────────────────────────────────────

    def test_leaving_tells_the_leaver_and_the_rest(self):
        response = self.post('leave', user=self.member)
        self.assertEqual(response.status_code, 200)

        leaver_event = self.event_for(self.member)
        self.assertIsNotNone(leaver_event)
        self.assertTrue(leaver_event['removed'])

        admin_event = self.event_for(self.admin)
        self.assertIsNotNone(admin_event)
        self.assertEqual(admin_event['group']['member_count'], 2)

    def test_the_last_member_leaving_deletes_the_group_quietly(self):
        for user in (self.member, self.other):
            self.post('leave', user=user)
        self.sent.clear()
        response = self.post('leave', user=self.admin)
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json().get('deleted'))
        # Nobody left to tell, and the group is gone.
        self.assertFalse(ChatGroup.objects.filter(pk=self.group.pk).exists())

    # ── metadata ────────────────────────────────────────────────────────────

    def test_a_rename_reaches_every_member(self):
        response = self.client.patch(
            '/api/adsyconnect/groups/%s/' % self.group.id,
            {'name': 'Renamed Squad'}, format='multipart')
        self.assertEqual(response.status_code, 200, response.content)

        self.assertEqual(
            self.told(),
            sorted([str(self.admin.id), str(self.member.id),
                    str(self.other.id)]))
        self.assertEqual(
            self.event_for(self.member)['group']['name'], 'Renamed Squad')

    def test_a_patch_that_changes_nothing_announces_nothing(self):
        response = self.client.patch(
            '/api/adsyconnect/groups/%s/' % self.group.id,
            {'name': 'Squad'}, format='multipart')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(self.updates(), [])

    def test_promoting_an_admin_reaches_everyone(self):
        response = self.post('promote_admin', {'user_id': str(self.member.id)})
        self.assertEqual(response.status_code, 200, response.content)
        self.assertIn(str(self.member.id), self.told())
        # The member's own role is what changed for them.
        self.assertEqual(
            self.group.memberships.get(user=self.member).role, 'admin')

    def test_demoting_an_admin_reaches_everyone(self):
        self.post('promote_admin', {'user_id': str(self.member.id)})
        self.sent.clear()
        response = self.post('demote_admin', {'user_id': str(self.member.id)})
        self.assertEqual(response.status_code, 200, response.content)
        self.assertIn(str(self.member.id), self.told())

    def test_deleting_the_group_tells_every_member_it_is_gone(self):
        member_ids = sorted([
            str(self.admin.id), str(self.member.id), str(self.other.id)])
        response = self.client.delete(
            '/api/adsyconnect/groups/%s/' % self.group.id)
        self.assertEqual(response.status_code, 204)

        self.assertEqual(self.told(), member_ids)
        for uid, event in self.updates():
            self.assertTrue(event['removed'])
            self.assertIsNone(event['group'])
        self.assertFalse(ChatGroup.objects.filter(pk=self.group.pk).exists())

    # ── the broadcast must never break the action ──────────────────────────

    def test_a_dead_socket_does_not_fail_the_removal(self):
        with patch('adsyconnect.views._broadcast_to_user',
                   side_effect=RuntimeError('redis is down')):
            response = self.post(
                'remove_member', {'user_id': str(self.member.id)})
        self.assertEqual(response.status_code, 200)
        self.assertFalse(
            self.group.memberships.filter(user=self.member).exists())


class LastMemberLeavingTests(TestCase):
    """The last member leaving used to 500 and orphan the group.

    get_object() prefetches memberships__user, so `group.memberships.all()`
    handed back the cache from before the departing row was deleted.
    `.exists()` read that cache and said yes, so the branch that deletes an
    empty group was skipped; the admin-rescue below it then ran `.first()`,
    which DOES hit the database, got None, and `oldest.role = 'admin'` raised.
    """

    def setUp(self):
        self.solo = User.objects.create_user(
            username='lm1', email='lm1@example.com', password='x',
            first_name='Solo', phone='+880100004101')
        self.mate = User.objects.create_user(
            username='lm2', email='lm2@example.com', password='x',
            first_name='Mate', phone='+880100004102')
        for target in ('adsyconnect.views._broadcast_to_user',):
            p = patch(target, return_value=None)
            p.start()
            self.addCleanup(p.stop)

    def group_of(self, *users, admin=None):
        group = ChatGroup.objects.create(name='Leaving', creator=users[0])
        for user in users:
            ChatGroupMembership.objects.create(
                group=group, user=user,
                role='admin' if user == (admin or users[0]) else 'member')
        return group

    def leave(self, group, user):
        client = APIClient()
        client.force_authenticate(user=user)
        return client.post('/api/adsyconnect/groups/%s/leave/' % group.id)

    def test_the_only_member_leaving_deletes_the_group(self):
        group = self.group_of(self.solo)
        response = self.leave(group, self.solo)

        self.assertEqual(response.status_code, 200, response.content)
        self.assertTrue(response.json().get('deleted'))
        self.assertFalse(ChatGroup.objects.filter(pk=group.pk).exists())

    def test_the_last_of_two_leaving_deletes_the_group(self):
        group = self.group_of(self.solo, self.mate)
        self.assertEqual(self.leave(group, self.mate).status_code, 200)
        response = self.leave(group, self.solo)

        self.assertEqual(response.status_code, 200, response.content)
        self.assertTrue(response.json().get('deleted'))
        self.assertFalse(ChatGroup.objects.filter(pk=group.pk).exists())

    def test_the_last_admin_leaving_promotes_somebody(self):
        group = self.group_of(self.solo, self.mate, admin=self.solo)
        self.assertEqual(self.leave(group, self.solo).status_code, 200)

        self.assertTrue(ChatGroup.objects.filter(pk=group.pk).exists())
        self.assertEqual(
            ChatGroupMembership.objects.get(group=group, user=self.mate).role,
            'admin')

    def test_a_group_with_members_left_is_not_deleted(self):
        third = User.objects.create_user(
            username='lm3', email='lm3@example.com', password='x',
            first_name='Third', phone='+880100004103')
        group = self.group_of(self.solo, self.mate, third)
        self.assertEqual(self.leave(group, self.mate).status_code, 200)
        self.assertTrue(ChatGroup.objects.filter(pk=group.pk).exists())
        self.assertEqual(group.memberships.count(), 2)
