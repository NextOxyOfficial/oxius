# -*- coding: utf-8 -*-
"""Rate limits for the endpoints where a script does real damage.

There were none anywhere: no DEFAULT_THROTTLE_CLASSES, no view with a throttle.
Message send, post create, comment, follow and the call-ringing endpoints were
all unbounded, so one loop could fill somebody's chat, flood the feed, or ring
a phone continuously.

Deliberately NOT a global default. A DEFAULT_THROTTLE_CLASSES would cover reads
too, and the clients poll — the chat list, the feed, presence, typing. Throttling
those would break the app to defend it. Every limit here is attached to a
specific write endpoint instead.

The rates are set for a real person having a fast conversation, not for the
minimum that would technically work: the point is to stop a script, and a
limit a human can reach is a bug report waiting to happen.

Keyed on the user id when signed in and on the IP otherwise, and counted in the
Redis cache, so the limit holds across gunicorn workers rather than per process.
"""
from rest_framework.throttling import SimpleRateThrottle


class _PerUserThrottle(SimpleRateThrottle):
    """Base: count per authenticated user, falling back to the client IP."""

    def get_cache_key(self, request, view):
        user = getattr(request, 'user', None)
        if user is not None and getattr(user, 'is_authenticated', False):
            ident = str(user.pk)
        else:
            ident = self.get_ident(request)
        return self.cache_format % {'scope': self.scope, 'ident': ident}


class ChatMessageThrottle(_PerUserThrottle):
    """Sending a chat message, one-to-one or group.

    120/minute is two a second sustained. Nobody types that fast for a minute,
    and a burst of short replies — the thing that would be infuriating to block
    — sits nowhere near it.
    """
    scope = 'chat_message'


class CallRingThrottle(_PerUserThrottle):
    """Ringing somebody, or a whole group.

    Redialling after a missed call is normal and must not be blocked, so this is
    generous; it exists to stop a loop making a phone ring continuously.
    """
    scope = 'call_ring'


class PostCreateThrottle(_PerUserThrottle):
    """Creating a Business Network post."""
    scope = 'bn_post'


class CommentThrottle(_PerUserThrottle):
    """Commenting on a post or on media."""
    scope = 'bn_comment'


class FollowThrottle(_PerUserThrottle):
    """Following and unfollowing — the classic mass-follow spam vector."""
    scope = 'bn_follow'


class UploadThrottle(_PerUserThrottle):
    """Anything that accepts a file. Bandwidth is the scarce thing here."""
    scope = 'upload'
