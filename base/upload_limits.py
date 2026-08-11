# -*- coding: utf-8 -*-
"""How big an upload is allowed to be.

There was no cap at all. FILE_UPLOAD_MAX_MEMORY_SIZE (5MB) reads like one but is
only the threshold at which Django stops holding a file in RAM and spools it to
disk — a 500MB video was accepted, written to a temp file, and streamed on to
R2. One request could fill the box's disk, and the bill is per gigabyte.

The limits are per KIND rather than one number, because "too big" means
completely different things for a voice note and a video.

nginx's client_max_body_size is the real edge guard and should agree with the
largest value here; this is the application-level check, which is the one that
can return a message the app can actually show the user.
"""
from rest_framework import serializers

#: Bytes. Generous on purpose — the point is to stop the pathological case, not
#: to make an ordinary phone photo or a normal clip fail.
LIMITS = {
    # A modern phone photo is 3-8MB, so this is very generous — deliberately.
    # One Business Network path already enforced 64MB, and tightening an
    # established limit would break uploads that work today for no real gain;
    # the pathological case is video, not stills.
    'image': 64 * 1024 * 1024,
    # A minute of 720p is roughly 15-25MB, so this is around twenty minutes.
    #
    # The one video endpoint that DID have a limit used 4GB, which on a box with
    # 3.8GB of RAM and 61GB free is not a limit — eight concurrent uploads would
    # fill the disk. 512MB is still far more than any real phone upload over
    # mobile data completes, and it is 8x safer.
    'video': 512 * 1024 * 1024,
    # A long voice note is a couple of MB at any sane bitrate.
    'audio': 25 * 1024 * 1024,
    # Documents shared in chat.
    'file': 50 * 1024 * 1024,
}

#: Anything whose kind we cannot work out.
DEFAULT_LIMIT = LIMITS['file']

_KIND_BY_PREFIX = (
    ('image/', 'image'),
    ('video/', 'video'),
    ('audio/', 'audio'),
)

_KIND_BY_SUFFIX = (
    ('image', ('.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.bmp')),
    ('video', ('.mp4', '.mov', '.m4v', '.avi', '.mkv', '.webm', '.3gp')),
    ('audio', ('.mp3', '.m4a', '.aac', '.wav', '.ogg', '.opus', '.amr')),
)


def guess_kind(upload, declared=None):
    """'image' | 'video' | 'audio' | 'file' for an uploaded file.

    A declared kind wins — the chat sends message_type, and the client knows
    what it meant better than a filename does.
    """
    if declared:
        declared = str(declared).strip().lower()
        if declared in LIMITS:
            return declared
        # The chat's own vocabulary.
        if declared == 'voice':
            return 'audio'

    content_type = (getattr(upload, 'content_type', '') or '').lower()
    for prefix, kind in _KIND_BY_PREFIX:
        if content_type.startswith(prefix):
            return kind

    name = (getattr(upload, 'name', '') or '').lower()
    for kind, suffixes in _KIND_BY_SUFFIX:
        if name.endswith(suffixes):
            return kind

    return 'file'


def human(size_bytes):
    mb = size_bytes / (1024 * 1024)
    return '%dMB' % round(mb) if mb >= 1 else '%dKB' % round(size_bytes / 1024)


def check_upload(upload, *, declared_kind=None, raise_error=True):
    """Validate one uploaded file's size. Returns an error string, or None.

    With [raise_error] (the default) a serializers.ValidationError is raised
    instead, so this drops straight into a serializer's validate_*.
    """
    if upload is None:
        return None
    size = getattr(upload, 'size', None)
    if not size:
        return None

    kind = guess_kind(upload, declared_kind)
    limit = LIMITS.get(kind, DEFAULT_LIMIT)
    if size <= limit:
        return None

    message = (
        'ফাইলটি অনেক বড় (%s)। সর্বোচ্চ %s পর্যন্ত পাঠানো যাবে।'
        % (human(size), human(limit))
    )
    if raise_error:
        raise serializers.ValidationError(message)
    return message


def check_uploads(files, *, declared_kind=None):
    """Validate every file in an iterable — a multi-media post."""
    for upload in files or ():
        check_upload(upload, declared_kind=declared_kind)
