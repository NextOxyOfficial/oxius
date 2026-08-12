# -*- coding: utf-8 -*-
"""The feed must not ask the database a question per post.

Measured on production before this was fixed: 7 posts cost 62 queries and
666 ms, 15 posts cost 91. It is the app's home screen, so it was the most
expensive thing in the product.

The costs were all batching gaps rather than missing ideas — the batched paths
existed and the feed was not feeding them: prime_user_stats knew about post and
comment authors but not media likers or post followers, get_share_count had no
annotation to prefer, media_comments had no prefetch, and the Following and
anonymous feeds carried no annotations at all.

As with the chat list, these assert the SHAPE: more posts must not mean more
queries. An exact number would go stale the first time anybody added a field.
"""
from django.contrib.auth import get_user_model
from django.db import connection
from django.core.cache import cache
from django.test import TestCase, override_settings
from django.test.utils import CaptureQueriesContext
from rest_framework.test import APIClient

from .models import (
    BusinessNetworkFollowerModel,
    BusinessNetworkMedia,
    BusinessNetworkMediaComment,
    BusinessNetworkMediaLike,
    BusinessNetworkPost,
    BusinessNetworkPostComment,
    BusinessNetworkPostFollow,
    BusinessNetworkPostLike,
)

User = get_user_model()


# These tests count queries, and the ranked feed answers some of them from a
# five-minute relationship cache. The project's real cache is Redis on a shared
# database that Django never clears between tests — so whether a lookup was a
# hit or a miss depended on what earlier tests, and even earlier RUNS, happened
# to leave behind. The count was therefore stable only by luck: it passed for
# months and went red the moment the suite grew, with nothing in the feed
# changed. Pinning a private in-memory cache and clearing it per test makes the
# measurement depend on the feed alone.
@override_settings(CACHES={
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        "LOCATION": "feed-query-tests",
    }
})
class FeedQueryCountTests(TestCase):
    def setUp(self):
        cache.clear()
        self.viewer = User.objects.create_user(
            username='fq0', email='fq0@example.com', password='x',
            first_name='Viewer', phone='+880100003001')
        self.client = APIClient()
        self.client.force_authenticate(user=self.viewer)
        self._next = 0

    def make_user(self, tag):
        self._next += 1
        return User.objects.create_user(
            username='fq%s%d' % (tag, self._next),
            email='fq%s%d@example.com' % (tag, self._next),
            password='x', first_name='U%d' % self._next,
            phone='+8801000031%02d' % self._next)

    def add_posts(self, count):
        """Posts with everything the feed serialises hanging off them."""
        posts = []
        for _ in range(count):
            author = self.make_user('a')
            # The viewer follows the author, so the post is in the ranked feed
            # and the author's own follower stats are non-trivial.
            BusinessNetworkFollowerModel.objects.create(
                follower=self.viewer, following=author)

            post = BusinessNetworkPost.objects.create(
                author=author, title='T', content='C', visibility='public')

            liker = self.make_user('l')
            BusinessNetworkPostLike.objects.create(post=post, user=liker)
            commenter = self.make_user('c')
            BusinessNetworkPostComment.objects.create(
                post=post, author=commenter, content='nice')
            follower = self.make_user('f')
            BusinessNetworkPostFollow.objects.create(post=post, user=follower)

            media = BusinessNetworkMedia.objects.create(type='image')
            post.media.add(media)
            media_liker = self.make_user('m')
            BusinessNetworkMediaLike.objects.create(
                media=media, user=media_liker)
            media_commenter = self.make_user('n')
            BusinessNetworkMediaComment.objects.create(
                media=media, author=media_commenter, content='hi')

            # A reshare, so share_count has something to count.
            BusinessNetworkPost.objects.create(
                author=self.make_user('r'), content='resharing',
                shared_from=post, visibility='public')
            posts.append(post)
        return posts

    def fetch(self, url='/api/bn/posts/'):
        with CaptureQueriesContext(connection) as ctx:
            response = self.client.get(url)
        self.assertEqual(response.status_code, 200, response.content)
        body = response.json()
        rows = body.get('results', body if isinstance(body, list) else [])
        return rows, len(ctx.captured_queries)

    # ── the shape ───────────────────────────────────────────────────────────

    def test_the_query_count_does_not_grow_with_the_posts(self):
        self.add_posts(2)
        # Warm the ranked feed's 5-minute relationship cache (views.py builds it
        # on a miss) BEFORE measuring. Without this the first fetch pays ~10
        # cold cache queries and the second reads them from Redis, so a feed
        # that really was querying per post still measured flat — a false green.
        self.fetch()
        rows_a, queries_a = self.fetch()
        self.assertGreaterEqual(len(rows_a), 2)

        self.add_posts(6)
        rows_b, queries_b = self.fetch()
        self.assertGreater(len(rows_b), len(rows_a))

        # A little slack: the ranked feed's relationship cache and the
        # visibility pass do a fixed amount of extra work as the graph grows.
        self.assertLessEqual(
            queries_b, queries_a + 4,
            'four times the posts cost %d queries instead of %d — something is '
            'querying per post again' % (queries_b, queries_a))

    def test_the_following_feed_is_batched_too(self):
        """That branch carried no annotations at all."""
        self.add_posts(2)
        self.fetch('/api/bn/posts/?feed=following')
        _rows_a, queries_a = self.fetch('/api/bn/posts/?feed=following')
        self.add_posts(6)
        _rows_b, queries_b = self.fetch('/api/bn/posts/?feed=following')
        self.assertLessEqual(
            queries_b, queries_a + 4,
            'the Following feed costs %d queries against %d'
            % (queries_b, queries_a))

    def test_the_anonymous_feed_is_batched_too(self):
        """The feed a first-time visitor lands on."""
        self.add_posts(6)
        anon = APIClient()
        with CaptureQueriesContext(connection) as ctx:
            response = anon.get('/api/bn/posts/')
        self.assertEqual(response.status_code, 200)
        self.assertLess(
            len(ctx.captured_queries), 40,
            '%d queries for the anonymous feed' % len(ctx.captured_queries))

    # ── and it still answers correctly ──────────────────────────────────────

    def test_the_counts_are_still_right(self):
        posts = self.add_posts(1)
        rows, _ = self.fetch()
        row = next(r for r in rows if r['id'] == posts[0].id)
        self.assertEqual(row['like_count'], 1)
        self.assertEqual(row['comment_count'], 1)
        self.assertEqual(row['follower_count'], 1)
        # One reshare, and external shares add on top.
        self.assertEqual(row['share_count'], 1)

    def test_external_shares_are_added_to_the_annotated_reshares(self):
        posts = self.add_posts(1)
        BusinessNetworkPost.objects.filter(pk=posts[0].pk).update(
            external_share_count=4)
        rows, _ = self.fetch()
        row = next(r for r in rows if r['id'] == posts[0].id)
        self.assertEqual(row['share_count'], 5)

    def test_a_post_with_no_reshares_reports_zero(self):
        author = self.make_user('z')
        BusinessNetworkFollowerModel.objects.create(
            follower=self.viewer, following=author)
        post = BusinessNetworkPost.objects.create(
            author=author, content='lonely', visibility='public')
        rows, _ = self.fetch()
        row = next(r for r in rows if r['id'] == post.id)
        self.assertEqual(row['share_count'], 0)
        self.assertEqual(row['like_count'], 0)

    def test_author_stats_survive_the_widened_primer(self):
        posts = self.add_posts(1)
        rows, _ = self.fetch()
        row = next(r for r in rows if r['id'] == posts[0].id)
        # The counts are FLAT keys on author_details, not a nested 'stats'
        # dict — that shape only exists in prime_user_stats' request-local memo
        # and is never serialised. Note the name collision: the POST row also
        # carries a top-level follower_count (its own followers), so the
        # author's has to be read from inside author_details.
        author = row['author_details']
        self.assertEqual(author['post_count'], 1)
        self.assertEqual(author['follower_count'], 1)
        self.assertEqual(author['follow_count'], 0)

    def test_media_comments_still_come_back(self):
        posts = self.add_posts(1)
        rows, _ = self.fetch()
        row = next(r for r in rows if r['id'] == posts[0].id)
        # The field is post_media (source="media"); indexing rather than .get
        # so a rename fails loudly instead of quietly reading as empty.
        media = row['post_media']
        self.assertEqual(len(media), 1)
        self.assertEqual(len(media[0]['media_comments']), 1)
        self.assertEqual(len(media[0]['media_likes']), 1)
