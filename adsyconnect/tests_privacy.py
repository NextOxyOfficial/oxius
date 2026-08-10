# -*- coding: utf-8 -*-
"""Who may call, and who may see a follower list.

Both rules decide whether a real person is allowed to reach another, so the
failure mode of getting them wrong is silent: calls that never ring, or a
list shown to someone it was hidden from.
"""
from django.contrib.auth import get_user_model
from django.test import TestCase

from adsyconnect.views import _can_call
from business_network.models import BusinessNetworkFollowerModel as Follow
from business_network.views import can_view_follow_lists

User = get_user_model()


def make(name, n):
    return User.objects.create_user(
        username=name, email='%s@example.com' % name, password='x',
        first_name=name.title(), phone='+8801000000%03d' % n,
    )


class WhoCanCallTests(TestCase):
    def setUp(self):
        self.me = make('owner', 71)
        self.them = make('caller', 72)

    def set_pref(self, value):
        self.me.who_can_call = value
        self.me.save(update_fields=['who_can_call'])

    def follows(self, a, b):
        Follow.objects.create(follower=a, following=b)

    def test_everyone_can_call_by_default(self):
        allowed, _ = _can_call(self.them, self.me)
        self.assertTrue(allowed)

    def test_nobody_blocks_even_a_stranger(self):
        self.set_pref('nobody')
        allowed, reason = _can_call(self.them, self.me)
        self.assertFalse(allowed)
        self.assertTrue(reason)

    def test_followers_only_lets_a_follower_through(self):
        self.set_pref('followers')
        allowed, _ = _can_call(self.them, self.me)
        self.assertFalse(allowed, 'a stranger is not a follower')

        self.follows(self.them, self.me)
        allowed, _ = _can_call(self.them, self.me)
        self.assertTrue(allowed)

    def test_following_only_lets_someone_i_follow_through(self):
        self.set_pref('following')
        self.follows(self.them, self.me)   # they follow me — not the same thing
        allowed, _ = _can_call(self.them, self.me)
        self.assertFalse(allowed)

        self.follows(self.me, self.them)   # now I follow them
        allowed, _ = _can_call(self.them, self.me)
        self.assertTrue(allowed)

    def test_mutual_needs_both_directions(self):
        self.set_pref('mutual')
        self.follows(self.them, self.me)
        allowed, _ = _can_call(self.them, self.me)
        self.assertFalse(allowed, 'one direction is not mutual')

        self.follows(self.me, self.them)
        allowed, _ = _can_call(self.them, self.me)
        self.assertTrue(allowed)

    def test_an_existing_chat_keeps_the_call_button(self):
        """Tightening the setting must not cut off someone you talk to daily."""
        from adsyconnect.models import ChatRoom
        ChatRoom.objects.create(user1=self.them, user2=self.me)
        self.set_pref('followers')

        allowed, _ = _can_call(self.them, self.me)
        self.assertTrue(allowed)

    def test_nobody_beats_even_an_existing_chat(self):
        """The one answer that is about the phone, not about who is asking."""
        from adsyconnect.models import ChatRoom
        ChatRoom.objects.create(user1=self.them, user2=self.me)
        self.set_pref('nobody')

        allowed, _ = _can_call(self.them, self.me)
        self.assertFalse(allowed)


class FollowListVisibilityTests(TestCase):
    def setUp(self):
        self.me = make('lister', 81)
        self.viewer = make('viewer', 82)

    def set_pref(self, value):
        self.me.follow_list_visibility = value
        self.me.save(update_fields=['follow_list_visibility'])

    def test_following_shows_the_list_to_someone_i_follow(self):
        """The requested condition: my lists go to the people I chose."""
        self.set_pref('following')

        Follow.objects.create(follower=self.viewer, following=self.me)
        self.assertFalse(
            can_view_follow_lists(self.viewer, self.me),
            'them following me is not me following them',
        )

        Follow.objects.create(follower=self.me, following=self.viewer)
        self.assertTrue(can_view_follow_lists(self.viewer, self.me))

    def test_owner_always_sees_their_own(self):
        for pref in ('everyone', 'followers', 'following', 'only_me'):
            with self.subTest(pref=pref):
                self.set_pref(pref)
                self.assertTrue(can_view_follow_lists(self.me, self.me))

    def test_only_me_hides_it_from_everyone_else(self):
        self.set_pref('only_me')
        Follow.objects.create(follower=self.me, following=self.viewer)
        Follow.objects.create(follower=self.viewer, following=self.me)
        self.assertFalse(can_view_follow_lists(self.viewer, self.me))

    def test_the_old_options_still_behave(self):
        self.set_pref('everyone')
        self.assertTrue(can_view_follow_lists(self.viewer, self.me))

        self.set_pref('followers')
        self.assertFalse(can_view_follow_lists(self.viewer, self.me))
        Follow.objects.create(follower=self.viewer, following=self.me)
        self.assertTrue(can_view_follow_lists(self.viewer, self.me))
