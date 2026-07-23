import base64
import random

from django.core.cache import cache
from django.core.files.base import ContentFile
from django.db import transaction
from django.db.models import (
    BigIntegerField,
    Case,
    Count,
    Exists,
    ExpressionWrapper,
    F,
    FloatField,
    IntegerField,
    OuterRef,
    Q,
    Subquery,
    Sum,
    Value,
    When,
)
from django.db.models.functions import Cast, Extract, Mod, Now, Power
from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from base.models import User
from adsyconnect.models import BlockedUser

from .models import *
from .pagination import *
from .serializers import *


# Upload caps — reject oversized payloads BEFORE and AFTER decode so a
# malicious client can't OOM the worker with a ~1GB base64 body.
_MAX_IMAGE_BYTES = 12 * 1024 * 1024   # 12 MB
_MAX_VIDEO_BYTES = 200 * 1024 * 1024  # 200 MB


def base64ToFile(base64_data):
    # Remove the prefix if it exists (e.g., "data:image/png;base64,")
    if base64_data.startswith("data:image"):
        base64_data = base64_data.split("base64,")[1]

    # base64 inflates ~33%; bound the encoded length before decoding.
    if len(base64_data) > _MAX_IMAGE_BYTES * 4 // 3 + 1024:
        raise ValidationError({"images": "Image is too large (max 12 MB)."})

    # Decode the Base64 string into bytes
    file_data = base64.b64decode(base64_data)
    if len(file_data) > _MAX_IMAGE_BYTES:
        raise ValidationError({"images": "Image is too large (max 12 MB)."})

    # Create a Django ContentFile object from the bytes
    file = ContentFile(file_data)

    # You can create a filename, e.g., using the current timestamp or other logic
    filename = "uploaded_image.png"  # Customize as needed

    # Save the file to the appropriate storage (e.g., media directory)
    file.name = filename
    return file


def base64ToVideoFile(base64_data):
    """Convert base64 video data to a Django ContentFile"""
    content_type = "video/mp4"
    raw = base64_data

    if isinstance(raw, str) and "," in raw and "base64" in raw:
        header, payload = raw.split(",", 1)
        if ":" in header and ";" in header:
            content_type = header.split(":", 1)[1].split(";", 1)[0].strip() or content_type
        raw = payload
    elif isinstance(raw, str) and (raw.startswith("data:video") or raw.startswith("data:application")):
        parts = raw.split("base64,", 1)
        raw = parts[1] if len(parts) == 2 else ""

    ext = "mp4"
    ct = (content_type or "").lower()
    if "webm" in ct:
        ext = "webm"
    elif "quicktime" in ct or "mov" in ct:
        ext = "mov"
    elif "x-matroska" in ct or "mkv" in ct:
        ext = "mkv"
    elif "mp4" in ct:
        ext = "mp4"

    if len(raw) > _MAX_VIDEO_BYTES * 4 // 3 + 1024:
        raise ValidationError({"videos": "Video is too large (max 200 MB)."})

    try:
        file_data = base64.b64decode(raw)
    except Exception:
        file_data = base64.b64decode(raw + "===")

    if len(file_data) > _MAX_VIDEO_BYTES:
        raise ValidationError({"videos": "Video is too large (max 200 MB)."})

    file = ContentFile(file_data)

    import time

    filename = f"uploaded_video_{int(time.time())}.{ext}"
    file.name = filename
    return file


def generate_video_thumbnail(video_path):
    """Generate a thumbnail from the first frame of a video.
    Tries moviepy -> opencv -> ffmpeg (subprocess) in order.
    """
    import tempfile
    import os
    
    try:
        # Try using moviepy first
        from moviepy.editor import VideoFileClip
        
        clip = VideoFileClip(video_path)
        frame_time = min(0.5, clip.duration / 2) if clip.duration > 0 else 0
        
        with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as tmp:
            tmp_path = tmp.name
        
        clip.save_frame(tmp_path, t=frame_time)
        clip.close()
        
        with open(tmp_path, 'rb') as f:
            thumb_data = f.read()
        os.unlink(tmp_path)
        
        thumb_file = ContentFile(thumb_data)
        thumb_file.name = f"thumb_{os.path.basename(video_path).rsplit('.', 1)[0]}.jpg"
        return thumb_file
        
    except Exception as e:
        print(f"generate_video_thumbnail moviepy failed: {e}")

    try:
        import cv2
        
        cap = cv2.VideoCapture(video_path)
        ret, frame = cap.read()
        cap.release()
        
        if not ret:
            raise Exception("cv2 could not read frame")
        
        _, buffer = cv2.imencode('.jpg', frame)
        thumb_data = buffer.tobytes()
        
        thumb_file = ContentFile(thumb_data)
        thumb_file.name = f"thumb_{os.path.basename(video_path).rsplit('.', 1)[0]}.jpg"
        return thumb_file
        
    except Exception as e:
        print(f"generate_video_thumbnail opencv failed: {e}")

    try:
        import subprocess
        import shutil

        ffmpeg_bin = shutil.which("ffmpeg")
        if not ffmpeg_bin:
            for p in ["/snap/bin/ffmpeg", "/usr/bin/ffmpeg", "/usr/local/bin/ffmpeg"]:
                if os.path.isfile(p):
                    ffmpeg_bin = p
                    break
        if not ffmpeg_bin:
            raise Exception("ffmpeg not found on PATH or known locations")

        with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as tmp:
            tmp_path = tmp.name

        for ss_time in ["0", "00:00:00.500"]:
            result = subprocess.run(
                [
                    ffmpeg_bin, "-y",
                    "-i", video_path,
                    "-ss", ss_time,
                    "-vframes", "1",
                    "-q:v", "2",
                    tmp_path,
                ],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=30,
            )

            if os.path.exists(tmp_path) and os.path.getsize(tmp_path) > 0:
                with open(tmp_path, 'rb') as f:
                    thumb_data = f.read()
                os.unlink(tmp_path)

                thumb_file = ContentFile(thumb_data)
                thumb_file.name = f"thumb_{os.path.basename(video_path).rsplit('.', 1)[0]}.jpg"
                return thumb_file

        if os.path.exists(tmp_path):
            os.unlink(tmp_path)
        stderr_out = result.stderr.decode("utf-8", errors="replace")[-500:] if result.stderr else "no stderr"
        raise Exception(f"ffmpeg produced empty output. stderr: {stderr_out}")
    except Exception as e:
        print(f"generate_video_thumbnail ffmpeg failed: {e}")

    print("Warning: All thumbnail generation methods failed for: " + video_path)
    return None


def _clear_business_network_social_cache(*users):
    """Clear small relationship/feed caches touched by social actions."""
    for user in users:
        user_id = getattr(user, "id", user)
        if not user_id:
            continue
        cache.delete(f"user_feed_relationships_{user_id}")
        cache.delete(f"user_relationships_{user_id}")
        cache.delete(f"bn_user_suggestions_{user_id}")


# user search generics view


class UserSearchView(generics.ListAPIView):
    serializer_class = UserSerializer
    pagination_class = StandardResultsSetPagination

    # permission_classes = [IsAuthenticated]
    def get_queryset(self):
        query = self.request.query_params.get("q", "")

        # Handle empty query
        if not query or not query.strip():
            return User.objects.none()

        # The new-chat picker passes exclude_self=1 — you can't chat with
        # yourself, so don't offer yourself. (Default keeps self so features
        # like @mention-ing yourself in a post still work.)
        exclude_self = self.request.query_params.get("exclude_self") in ("1", "true")

        # Normalize query for better matching
        normalized_query = query.strip()

        # Remove hashtag for user search if present
        if normalized_query.startswith("#"):
            normalized_query = normalized_query[1:]

        if not normalized_query:  # If query was just a # symbol
            return User.objects.none()

        # Use a single query with annotations for scoring/priority
        from django.db.models import Case, When, Value, IntegerField
        from django.db.models.functions import Lower
        
        # Split query into parts for multi-word searches
        name_parts = normalized_query.split()
        
        # Build a comprehensive search query
        search_query = Q()
        
        # Search in username, first_name, last_name and the standalone
        # display-name field (registration may fill `name` without splitting
        # it into first/last — those users must still be findable).
        search_query |= Q(username__icontains=normalized_query)
        search_query |= Q(first_name__icontains=normalized_query)
        search_query |= Q(last_name__icontains=normalized_query)
        search_query |= Q(name__icontains=normalized_query)

        # For multi-word queries, search in name parts
        if len(name_parts) > 1:
            for part in name_parts:
                if len(part) > 2:  # Only search parts longer than 2 chars
                    search_query |= Q(first_name__icontains=part)
                    search_query |= Q(last_name__icontains=part)
                    search_query |= Q(name__icontains=part)

        # Get all matching users (excluding superusers)
        users = User.objects.filter(search_query).exclude(is_superuser=True)
        if exclude_self and self.request.user.is_authenticated:
            users = users.exclude(id=self.request.user.id)

        # Hide only accounts with no usable display name at all (nothing
        # human-readable to show in results). New users who registered with a
        # name are searchable immediately — the old rule also required phone
        # and date_of_birth, which silently hid every new member until they
        # finished full profile onboarding.
        users = users.exclude(
            (Q(first_name__isnull=True) | Q(first_name=""))
            & (Q(last_name__isnull=True) | Q(last_name=""))
            & (Q(name__isnull=True) | Q(name=""))
        )

        # Hide blocked relationships in BOTH directions: a user I blocked must
        # not appear in my search, and a user who blocked me must not appear in
        # my search either (and vice-versa) — until the block is removed.
        request_user = self.request.user
        if request_user.is_authenticated:
            blocked_ids = BlockedUser.objects.filter(
                blocker=request_user
            ).values_list("blocked_id", flat=True)
            blocked_by_ids = BlockedUser.objects.filter(
                blocked=request_user
            ).values_list("blocker_id", flat=True)
            users = users.exclude(id__in=blocked_ids).exclude(
                id__in=blocked_by_ids
            )

        # Add priority scoring for ordering
        users = users.annotate(
            priority=Case(
                # Priority 1: Exact username match
                When(username__iexact=normalized_query, then=Value(1)),
                # Priority 2: Exact first or last name match
                When(Q(first_name__iexact=normalized_query) | Q(last_name__iexact=normalized_query), then=Value(2)),
                # Priority 3: Username starts with query
                When(username__istartswith=normalized_query, then=Value(3)),
                # Priority 4: First or last name starts with query
                When(Q(first_name__istartswith=normalized_query) | Q(last_name__istartswith=normalized_query), then=Value(4)),
                # Priority 5: Contains in username
                When(username__icontains=normalized_query, then=Value(5)),
                # Priority 6: Contains in name
                default=Value(6),
                output_field=IntegerField(),
            )
        ).order_by('priority', 'first_name', 'last_name').distinct()
        
        return users


# @api_view(['GET'])
# def user_search(request):
#     query = request.GET.get('q', '')
#     users = User.objects.filter(Q(username__icontains=query) | Q(first_name__icontains=query) | Q(last_name__icontains=query))
#     serializer = UserSerializer(users, many=True)
#     return Response(serializer.data, status=status.HTTP_200_OK)


# Post Views
class BusinessNetworkPostListCreateView(generics.ListCreateAPIView):
    serializer_class = BusinessNetworkPostSerializer
    pagination_class = MediumDevicePagination  # Changed for better performance
    permission_classes = [IsAuthenticated]
    feed_cache_ttl = 60 * 20
    seen_cache_ttl = 60 * 60 * 12
    seen_cache_limit = 300

    def get_permissions(self):
        if self.request.method == "GET":
            return []
        return super().get_permissions()

    def _page_number(self):
        raw_page = self.request.query_params.get("page") or "1"
        try:
            return max(1, int(raw_page))
        except (TypeError, ValueError):
            return 1

    def _extract_response_post_ids(self, data):
        rows = data.get("results", data) if isinstance(data, dict) else data
        if not isinstance(rows, list):
            return []

        post_ids = []
        for row in rows:
            if isinstance(row, dict) and row.get("id"):
                post_ids.append(str(row["id"]))
        return post_ids

    def list(self, request, *args, **kwargs):
        response = super().list(request, *args, **kwargs)
        if not request.user.is_authenticated or response.status_code >= 400:
            return response

        post_ids = self._extract_response_post_ids(response.data)
        if post_ids:
            seen_cache_key = f"business_network_seen_posts:{request.user.id}"
            existing_seen_ids = cache.get(seen_cache_key, [])
            merged_seen_ids = list(dict.fromkeys(post_ids + existing_seen_ids))[
                : self.seen_cache_limit
            ]
            cache.set(seen_cache_key, merged_seen_ids, self.seen_cache_ttl)

            # Persist impressions so seen-demotion survives cache restarts
            # (the cache-only list evaporated and let the same posts pin the
            # top again). bulk upsert: insert new pairs, touch existing.
            try:
                from .models import PostSeen

                existing = set(
                    PostSeen.objects.filter(
                        user=request.user, post_id__in=post_ids
                    ).values_list("post_id", flat=True)
                )
                fresh = [pid for pid in post_ids if pid not in existing]
                if fresh:
                    PostSeen.objects.bulk_create(
                        [
                            PostSeen(user=request.user, post_id=pid)
                            for pid in fresh
                        ],
                        ignore_conflicts=True,
                    )
                if existing:
                    from django.db.models import F as _F
                    from django.utils import timezone as _tz

                    PostSeen.objects.filter(
                        user=request.user, post_id__in=list(existing)
                    ).update(
                        times_seen=_F("times_seen") + 1,
                        last_seen_at=_tz.now(),
                    )
            except Exception:  # pragma: no cover — never break the feed
                pass

        return response

    def get_queryset(self):
        """
        Society feed ranking:
        - Fresh public posts stay broadly visible so everyone can discover updates.
        - Direct society: people I follow and people following me.
        - Extended society: people followed by people I follow.
        - Interest graph: tags and posts my trusted network engages with.
        - Own posts remain visible but are intentionally demoted from the top.
        - Same freshness band gets a stable per-user shuffle to avoid a stale wall.

        `?feed=following` bypasses the ranked feed entirely: newest-first posts
        from people the user follows only (used by the Shorts "Following" tab).
        `&media=video` additionally keeps only posts that carry a video.
        """
        if self.request.query_params.get("feed") == "following":
            if not self.request.user.is_authenticated:
                return BusinessNetworkPost.objects.none()
            following_ids = list(
                BusinessNetworkFollowerModel.objects.filter(
                    follower=self.request.user
                ).values_list("following_id", flat=True)
            )
            qs = (
                BusinessNetworkPost.objects.filter(
                    author_id__in=following_ids,
                    is_banned=False,
                    visibility__in=["public", "followers"],
                )
                .select_related("author")
                .order_by("-created_at")
            )
            if self.request.query_params.get("media") == "video":
                qs = qs.filter(media__type="video").distinct()
            return qs

        if not self.request.user.is_authenticated:
            # For unauthenticated users, show recent PUBLIC posts only —
            # followers-only/private posts and banned content must not leak
            # into the anonymous feed.
            return (
                BusinessNetworkPost.objects.filter(
                    visibility="public", is_banned=False
                )
                .select_related("author")
                .order_by("-created_at")
            )

        user = self.request.user

        device_level = self.request.query_params.get("device_level", "medium")
        cache_key = f"user_feed_relationships_{user.id}"
        cached_data = cache.get(cache_key)

        if not cached_data:
            users_following = list(
                BusinessNetworkFollowerModel.objects.filter(follower=user).values_list(
                    "following_id", flat=True
                )
            )

            users_followers = list(
                BusinessNetworkFollowerModel.objects.filter(following=user).values_list(
                    "follower_id", flat=True
                )
            )

            second_degree_users = list(
                BusinessNetworkFollowerModel.objects.filter(
                    follower_id__in=users_following
                )
                .exclude(following=user)
                .exclude(following_id__in=users_following)
                .values_list("following_id", flat=True)
                .distinct()
            )

            interacted_post_ids = set(
                BusinessNetworkPostLike.objects.filter(user=user).values_list(
                    "post_id", flat=True
                )
            )
            interacted_post_ids.update(
                BusinessNetworkPostComment.objects.filter(author=user).values_list(
                    "post_id", flat=True
                )
            )
            interacted_post_ids.update(
                UserSavedPosts.objects.filter(user=user).values_list(
                    "post_id", flat=True
                )
            )

            interest_tags = set(
                BusinessNetworkPostTag.objects.filter(
                    Q(business_network_posts__author=user)
                    | Q(business_network_posts__id__in=interacted_post_ids)
                )
                .values_list("tag", flat=True)
                .distinct()[:80]
            )

            co_engaged_author_ids = set(
                BusinessNetworkPost.objects.filter(id__in=interacted_post_ids)
                .exclude(author=user)
                .values_list("author_id", flat=True)
                .distinct()[:80]
            )
            co_engaged_author_ids.update(
                BusinessNetworkPostComment.objects.filter(
                    post__author=user
                )
                .exclude(author=user)
                .values_list("author_id", flat=True)
                .distinct()[:80]
            )
            co_engaged_author_ids.update(
                BusinessNetworkPostLike.objects.filter(post__author=user)
                .exclude(user=user)
                .values_list("user_id", flat=True)
                .distinct()[:80]
            )

            cached_data = {
                "following": users_following,
                "followers": users_followers,
                "second_degree": second_degree_users,
                "interest_tags": list(interest_tags),
                "co_engaged_authors": list(co_engaged_author_ids),
            }
            cache.set(cache_key, cached_data, 300)  # Cache for 5 minutes

        users_following = cached_data["following"]
        users_followers = cached_data["followers"]
        second_degree_users = cached_data.get("second_degree", [])
        interest_tags = cached_data.get("interest_tags", [])
        co_engaged_author_ids = cached_data.get("co_engaged_authors", [])
        trusted_network_user_ids = list(
            {
                user.id,
                *users_following,
                *users_followers,
                *second_degree_users,
                *co_engaged_author_ids,
            }
        )

        from datetime import timedelta

        from django.utils import timezone

        now = timezone.now()
        page_number = self._page_number()

        seen_cache_key = f"business_network_seen_posts:{user.id}"
        active_seen_cache_key = f"business_network_active_seen_posts:{user.id}"
        if page_number == 1:
            seen_post_ids = cache.get(seen_cache_key, [])[: self.seen_cache_limit]
            # Durable impressions from the DB (survive cache restarts) — the
            # union keeps demotion working even right after a deploy.
            try:
                from .models import PostSeen

                db_seen = PostSeen.objects.filter(
                    user=user,
                    last_seen_at__gte=now - timedelta(days=14),
                ).order_by("-last_seen_at").values_list("post_id", flat=True)[
                    : self.seen_cache_limit
                ]
                seen_post_ids = list(
                    dict.fromkeys([*seen_post_ids, *db_seen])
                )[: self.seen_cache_limit]
            except Exception:  # pragma: no cover
                pass
            cache.set(active_seen_cache_key, seen_post_ids, self.feed_cache_ttl)
        else:
            seen_post_ids = cache.get(active_seen_cache_key, [])

        raw_feed_seed = self.request.query_params.get("feed_seed")
        if raw_feed_seed:
            try:
                request_feed_seed = int(raw_feed_seed)
            except (TypeError, ValueError):
                request_feed_seed = 0
        else:
            feed_seed_cache_key = f"business_network_feed_seed:{user.id}"
            request_feed_seed = (
                None if page_number == 1 else cache.get(feed_seed_cache_key)
            )
            if request_feed_seed is None:
                request_feed_seed = random.SystemRandom().randint(1, 1000000)
                cache.set(feed_seed_cache_key, request_feed_seed, self.feed_cache_ttl)

        feed_shuffle_seed = (
            user.id.int + int(now.strftime("%j")) + request_feed_seed
        ) % 997
        one_day_ago = now - timedelta(days=1)
        three_days_ago = now - timedelta(days=3)
        seven_days_ago = now - timedelta(days=7)
        fourteen_days_ago = now - timedelta(days=14)
        thirty_days_ago = now - timedelta(days=30)

        hidden_post_ids = HiddenPost.objects.filter(user=user).values_list(
            "post_id", flat=True
        )
        reported_post_ids = PostReport.objects.filter(user=user).values_list(
            "post_id", flat=True
        )
        # Mutual block invisibility: hide posts from users I blocked AND from
        # users who blocked me (Facebook-style — neither side sees the other).
        blocked_user_ids = BlockedUser.objects.filter(blocker=user).values_list(
            "blocked_id", flat=True
        )
        blocked_by_user_ids = BlockedUser.objects.filter(blocked=user).values_list(
            "blocker_id", flat=True
        )

        author_location_query = Q()
        if user.city:
            author_location_query |= Q(author__city__iexact=user.city)
        if user.state:
            author_location_query |= Q(author__state__iexact=user.state)

        # Followers-only posts are visible to the people who follow the author
        # (and to the author, covered by Q(author=user) below).
        followed_author_ids = BusinessNetworkFollowerModel.objects.filter(
            follower=user
        ).values("following_id")

        queryset = BusinessNetworkPost.objects.filter(
            Q(visibility="public")
            | Q(author=user)
            | Q(visibility="followers", author_id__in=followed_author_ids),
            is_banned=False,
        ).exclude(
            Q(id__in=hidden_post_ids)
            | Q(id__in=reported_post_ids)
            | Q(author_id__in=blocked_user_ids)
            | Q(author_id__in=blocked_by_user_ids)
        )

        # ── Join-free relevance scoring ──────────────────────────────────
        # The score is built ONLY from Case/F/arithmetic and the model's
        # DENORMALIZED counters (like_count/comment_count/save_count) plus a
        # single Exists subquery for interest tags. It deliberately uses NO
        # Count() aggregates: mixing per-row Count() (which forces a GROUP BY)
        # with the Case/ExpressionWrapper terms produced an invalid grouped
        # query whose blended score collapsed to a constant — so relationship,
        # freshness, engagement and seen-demotion never actually affected the
        # order (the feed felt static and one post pinned the top). Everything
        # here is per-row, so the score works and stays fast.
        if interest_tags:
            queryset = queryset.annotate(
                _has_interest_tag=Exists(
                    BusinessNetworkPostTag.objects.filter(
                        business_network_posts=OuterRef("pk"),
                        tag__in=interest_tags,
                    )
                )
            )
            interest_case = Case(
                When(_has_interest_tag=True, then=Value(30.0)),
                default=Value(0.0),
                output_field=FloatField(),
            )
        else:
            interest_case = Value(0.0, output_field=FloatField())

        location_case = (
            Case(
                When(author_location_query, then=Value(12.0)),
                default=Value(0.0),
                output_field=FloatField(),
            )
            if author_location_query
            else Value(0.0, output_field=FloatField())
        )
        profession_case = (
            Case(
                When(author__profession__iexact=user.profession, then=Value(8.0)),
                default=Value(0.0),
                output_field=FloatField(),
            )
            if user.profession
            else Value(0.0, output_field=FloatField())
        )

        queryset = (
            queryset.annotate(
                _age_hours=ExpressionWrapper(
                    Extract(Now() - F("created_at"), "epoch") / 3600.0,
                    output_field=FloatField(),
                ),
            )
            .annotate(
                relationship_score=Case(
                    When(author_id__in=users_following, then=Value(150.0)),
                    When(author_id__in=users_followers, then=Value(115.0)),
                    When(author_id__in=second_degree_users, then=Value(95.0)),
                    When(author_id__in=co_engaged_author_ids, then=Value(85.0)),
                    When(author=user, then=Value(30.0)),
                    default=Value(-60.0),
                    output_field=FloatField(),
                ),
                recency_score=Case(
                    When(created_at__gte=one_day_ago, then=Value(140.0)),
                    When(created_at__gte=three_days_ago, then=Value(100.0)),
                    When(created_at__gte=seven_days_ago, then=Value(60.0)),
                    When(created_at__gte=thirty_days_ago, then=Value(16.0)),
                    default=Value(0.0),
                    output_field=FloatField(),
                ),
                # Time-decayed engagement "heat" from the denormalized counters:
                # engagement / (age_hours + 2)^1.5 — fresh activity outweighs
                # stale viral. No COUNT join.
                heat_score=ExpressionWrapper(
                    (
                        F("like_count") * 3.0
                        + F("comment_count") * 5.0
                        + F("save_count") * 4.0
                    )
                    / Power(F("_age_hours") + 2.0, 1.5)
                    * 30.0,
                    output_field=FloatField(),
                ),
                interest_score=interest_case,
                location_score=location_case,
                profession_score=profession_case,
                # Seen-demotion. A FRESH seen post gets -55 (drops it below an
                # unseen 3-day post) so nothing pins the top across refreshes;
                # older seen posts drop further.
                # A seen post is demoted HARD — big enough to dethrone even a
                # dominant top post (relationship 150 + recency 140 + heat), so
                # the #1 slot rotates on the very next reload instead of the
                # same post staying pinned while only the tail reshuffles. The
                # first page's impressions are persisted as it's served, so the
                # post you just saw at the top drops next time.
                seen_penalty=Case(
                    When(
                        Q(id__in=seen_post_ids) & Q(created_at__lt=thirty_days_ago),
                        then=Value(-320.0),
                    ),
                    When(
                        Q(id__in=seen_post_ids) & Q(created_at__lt=seven_days_ago),
                        then=Value(-300.0),
                    ),
                    When(
                        Q(id__in=seen_post_ids) & Q(created_at__lt=three_days_ago),
                        then=Value(-280.0),
                    ),
                    When(Q(id__in=seen_post_ids), then=Value(-260.0)),
                    default=Value(0.0),
                    output_field=FloatField(),
                ),
                # Your own post never pins its own feed — it appears below your
                # network's content and climbs only on real engagement.
                own_post_penalty=Case(
                    When(author=user, then=Value(-165.0)),
                    default=Value(0.0),
                    output_field=FloatField(),
                ),
                # Per-refresh jitter (0-99) folded INTO the score so the feed
                # reorders on every pull instead of a static wall — wide enough
                # to reshuffle a cluster of similarly-scored fresh posts (a
                # relationship tier is 20-35 pts apart) without drowning out
                # relevance across tiers.
                jitter=Mod(
                    Cast("id", BigIntegerField()) * Value(2654435) + Value(feed_shuffle_seed),
                    Value(100),
                ),
                shuffle_score=Mod(
                    Cast("id", BigIntegerField()) + Value(feed_shuffle_seed),
                    Value(997),
                ),
            )
            .annotate(
                final_score=ExpressionWrapper(
                    F("relationship_score")
                    + F("recency_score")
                    + F("heat_score")
                    + F("interest_score")
                    + F("location_score")
                    + F("profession_score")
                    + F("seen_penalty")
                    + F("own_post_penalty")
                    + F("jitter"),
                    output_field=FloatField(),
                ),
            )
            .select_related("author")
            .prefetch_related(
                "media__media_likes__user",
                "tags",
                "post_likes__user",
                "post_comments__author",
                "post_followers__user",
            )
            .order_by(
                "-final_score",
                "shuffle_score",
                "-created_at",
            )
        )

        return queryset

    def create(self, request, *args, **kwargs):
        def _get_list_value(key):
            data = request.data
            if hasattr(data, "getlist"):
                values = data.getlist(key)
                if not values:
                    values = data.getlist(f"{key}[]")
                if values:
                    return values
            value = data.get(key)
            if value is None:
                return []
            if isinstance(value, list):
                return value
            return [value]

        def _get_file_list(key):
            files = request.FILES
            values = []
            if hasattr(files, "getlist"):
                values = files.getlist(key)
                if not values:
                    values = files.getlist(f"{key}[]")
            return values or []

        images_data = _get_list_value("images")
        videos_data = _get_list_value("videos")
        tags_data = _get_list_value("tags")

        image_files = _get_file_list("images")
        video_files = _get_file_list("videos")

        with transaction.atomic():
            serializer = self.get_serializer(
                data={
                    "title": request.data.get("title"),
                    "content": request.data.get("content"),
                    "visibility": request.data.get("visibility", "public"),
                }
            )

            serializer.is_valid(raise_exception=True)
            # author is read-only on the serializer — bind it here.
            post = serializer.save(author=request.user)

            if image_files:
                for image_file in image_files:
                    try:
                        post_media = BusinessNetworkMedia.objects.create(type="image", image=image_file)
                        post.media.add(post_media)
                    except Exception as e:
                        raise ValidationError({"images": f"Error processing image file: {str(e)}"})

            if images_data:
                for image_data in images_data:
                    try:
                        if isinstance(image_data, dict):
                            image_data = image_data.get("base64") or image_data.get("image") or image_data.get("data")

                        if not isinstance(image_data, str) or not image_data:
                            continue

                        if image_data.startswith("data:image"):
                            image_file = base64ToFile(image_data)
                        elif "base64," in image_data:
                            image_file = base64ToFile(image_data)
                        else:
                            image_file = base64ToFile(f"data:image/png;base64,{image_data}")

                        post_media = BusinessNetworkMedia.objects.create(type="image", image=image_file)
                        post.media.add(post_media)
                    except Exception as e:
                        raise ValidationError({"images": f"Error processing image: {str(e)}"})

            if video_files:
                for video_file in video_files:
                    try:
                        post_media = BusinessNetworkMedia.objects.create(type="video", video=video_file)
                        post.media.add(post_media)

                        try:
                            if post_media.video and post_media.video.path:
                                thumb_file = generate_video_thumbnail(post_media.video.path)
                                if thumb_file:
                                    post_media.thumbnail = thumb_file
                                    post_media.save()
                        except Exception as thumb_err:
                            print(f"Could not generate video thumbnail: {thumb_err}")
                    except Exception as e:
                        raise ValidationError({"videos": f"Error processing video file: {str(e)}"})

            if videos_data:
                for video_data in videos_data:
                    try:
                        if isinstance(video_data, dict):
                            video_data = video_data.get("base64") or video_data.get("video") or video_data.get("data")

                        if not isinstance(video_data, str) or not video_data:
                            continue

                        if "base64," in video_data:
                            video_file = base64ToVideoFile(video_data)
                        else:
                            video_file = base64ToVideoFile(f"data:video/mp4;base64,{video_data}")

                        post_media = BusinessNetworkMedia.objects.create(type="video", video=video_file)
                        post.media.add(post_media)

                        try:
                            if post_media.video and post_media.video.path:
                                thumb_file = generate_video_thumbnail(post_media.video.path)
                                if thumb_file:
                                    post_media.thumbnail = thumb_file
                                    post_media.save()
                        except Exception as thumb_err:
                            print(f"Could not generate video thumbnail: {thumb_err}")
                    except Exception as e:
                        raise ValidationError({"videos": f"Error processing video: {str(e)}"})

            if tags_data:
                for tag_data in tags_data:
                    if not isinstance(tag_data, str):
                        continue
                    tag_data = tag_data.strip()
                    if not tag_data:
                        continue
                    tag, _ = BusinessNetworkPostTag.objects.get_or_create(tag=tag_data)
                    post.tags.add(tag)

        _clear_business_network_social_cache(request.user)
        response_serializer = self.get_serializer(post)
        headers = self.get_success_headers(response_serializer.data)
        return Response(
            response_serializer.data, status=status.HTTP_201_CREATED, headers=headers
        )


class BusinessNetworkPostRetrieveUpdateDestroyView(
    generics.RetrieveUpdateDestroyAPIView
):
    queryset = BusinessNetworkPost.objects.all()
    serializer_class = BusinessNetworkPostSerializer
    lookup_field = "id"

    def get_serializer_context(self):
        # Single-post detail view: send the full comment thread + all likers.
        ctx = super().get_serializer_context()
        ctx["full_detail"] = True
        return ctx

    def get_object(self):
        # Accept either the post id (PK) or its slug, so shared hash-slug links
        # (adsyclub.com/business-network/posts/<slug>) open the right post.
        ident = self.kwargs.get(self.lookup_field) or self.kwargs.get("id")
        post = (
            BusinessNetworkPost.objects.filter(id=ident).first()
            or BusinessNetworkPost.objects.filter(slug=ident).first()
        )
        if post is None:
            from django.http import Http404

            raise Http404("Post not found")
        self._enforce_visibility(post)
        self.check_object_permissions(self.request, post)
        return post

    def _enforce_visibility(self, post):
        """A non-public post must 404 (not 403 — don't confirm it exists) for
        anyone who isn't allowed to see it, even with a direct id/slug link."""
        from django.http import Http404

        user = self.request.user
        is_author = user.is_authenticated and post.author_id == user.id
        if is_author:
            return
        if post.is_banned or post.visibility == "private":
            raise Http404("Post not found")
        if post.visibility == "followers":
            follows = user.is_authenticated and (
                BusinessNetworkFollowerModel.objects.filter(
                    follower=user, following_id=post.author_id
                ).exists()
            )
            if not follows:
                raise Http404("Post not found")

    def get_permissions(self):
        if self.request.method == "GET":
            return []
        else:
            return [IsAuthenticated()]

    def perform_update(self, serializer):
        # Only the author may update. NOTE: returning a Response from
        # perform_update is silently DISCARDED by DRF — the old code skipped
        # the save but still answered 200, so the client believed the edit
        # succeeded. Raising is the correct contract (-> real 403).
        if serializer.instance.author != self.request.user:
            raise PermissionDenied("You do not have permission to edit this post.")
        post = serializer.save()

        # Tags are read-only on the serializer (created manually on POST), so
        # the edit screen could never change them. When the client sends a
        # `tags` list, replace the post's tag set with it.
        raw_tags = self.request.data.get("tags", None)
        if raw_tags is not None:
            if isinstance(raw_tags, str):
                raw_tags = [raw_tags]
            if isinstance(raw_tags, (list, tuple)):
                post.tags.clear()
                for tag_data in raw_tags:
                    if not isinstance(tag_data, str):
                        continue
                    tag_data = tag_data.strip().lstrip("#").strip()
                    if not tag_data:
                        continue
                    tag, _ = BusinessNetworkPostTag.objects.get_or_create(
                        tag=tag_data
                    )
                    post.tags.add(tag)

        # Media edits. `remove_media_ids` detaches + deletes existing media;
        # `images` appends new base64 photos (same format the create endpoint
        # accepts). Videos can only be attached at create time — they need the
        # multipart upload path.
        remove_ids = self.request.data.get("remove_media_ids")
        if isinstance(remove_ids, (list, tuple)) and remove_ids:
            ids = [int(i) for i in remove_ids if str(i).isdigit()]
            for media in post.media.filter(id__in=ids):
                post.media.remove(media)
                media.delete()

        new_images = self.request.data.get("images")
        if isinstance(new_images, (list, tuple)):
            for image_data in new_images:
                if isinstance(image_data, dict):
                    image_data = (
                        image_data.get("base64")
                        or image_data.get("image")
                        or image_data.get("data")
                    )
                if not isinstance(image_data, str) or not image_data:
                    continue
                try:
                    if "base64," in image_data:
                        image_file = base64ToFile(image_data)
                    else:
                        image_file = base64ToFile(
                            f"data:image/png;base64,{image_data}"
                        )
                    media = BusinessNetworkMedia.objects.create(
                        type="image", image=image_file
                    )
                    post.media.add(media)
                except Exception as e:
                    raise ValidationError(
                        {"images": f"Error processing image: {str(e)}"}
                    )

    def perform_destroy(self, instance):
        # Only the author may delete (same raising contract as above).
        if instance.author != self.request.user:
            raise PermissionDenied("You do not have permission to delete this post.")
        instance.delete()


class UserPostsListView(generics.ListAPIView):
    serializer_class = BusinessNetworkPostSerializer
    pagination_class = StandardResultsSetPagination
    # permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user_id = self.kwargs.get("user_id")
        viewer = self.request.user
        queryset = BusinessNetworkPost.objects.filter(
            author__id=user_id, is_banned=False
        )

        is_own_profile = viewer.is_authenticated and str(viewer.id) == str(user_id)
        if not is_own_profile:
            if viewer.is_authenticated:
                # Hide this profile's posts if EITHER side blocked the other, so
                # a blocked user can't browse the blocker's posts and vice-versa.
                is_blocked = BlockedUser.objects.filter(
                    Q(blocker=viewer, blocked_id=user_id)
                    | Q(blocker_id=user_id, blocked=viewer)
                ).exists()
                if is_blocked:
                    return BusinessNetworkPost.objects.none()
                follows = BusinessNetworkFollowerModel.objects.filter(
                    follower=viewer, following_id=user_id
                ).exists()
                allowed = (
                    ["public", "followers"] if follows else ["public"]
                )
            else:
                allowed = ["public"]
            queryset = queryset.filter(visibility__in=allowed)
        return queryset.order_by(
            "-created_at"
        )


class UserSavedPostListCreateView(generics.ListCreateAPIView):
    serializer_class = UserSavedPostSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return UserSavedPosts.objects.filter(user=user.id).order_by("-created_at")

    def create(self, request, *args, **kwargs):
        user = request.user
        post_id = request.data.get("post")
        serializer = self.get_serializer(data={"user": user.id, "post": post_id})
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(
            serializer.data, status=status.HTTP_201_CREATED, headers=headers
        )


@api_view(["DELETE"])
def delete_saved_post(request, post_id):
    try:
        saved_post = UserSavedPosts.objects.get(post=post_id, user=request.user)
        saved_post.delete()
        return Response(
            {"message": "Post deleted from saved posts."}, status=status.HTTP_200_OK
        )
    except UserSavedPosts.DoesNotExist:
        return Response(
            {"error": "Post not found in saved posts."},
            status=status.HTTP_404_NOT_FOUND,
        )


# Media Views
class BusinessNetworkMediaCreateView(generics.CreateAPIView):
    queryset = BusinessNetworkMedia.objects.all()
    serializer_class = BusinessNetworkMediaSerializer
    permission_classes = [IsAuthenticated]


class BusinessNetworkMediaDestroyView(generics.DestroyAPIView):
    queryset = BusinessNetworkMedia.objects.all()
    permission_classes = [IsAuthenticated]

    def perform_destroy(self, instance):
        # Media attaches to posts via M2M (business_network_posts) — there is
        # no `.post`. Only someone who authored a post using this media may
        # delete it. (The old `instance.post` 500'd for everyone.)
        owns = instance.business_network_posts.filter(
            author=self.request.user
        ).exists()
        if not owns:
            raise PermissionDenied(
                "You do not have permission to delete this media."
            )
        instance.delete()


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def increment_media_views(request, media_id):
    """Count a unique view for a media item.

    The counter feeds monetization eligibility, so it must not be pumpable:
    - one increment per (media, user) — repeat calls are no-ops,
    - a viewer who authored a post using this media (self-view) is never
      counted.
    Always returns the current count so the client can display it."""
    try:
        media = BusinessNetworkMedia.objects.filter(id=media_id).first()
        if media is None:
            return Response({"error": "Media not found"}, status=status.HTTP_404_NOT_FOUND)

        # Don't count the owner's own views.
        is_owner = media.business_network_posts.filter(
            author=request.user
        ).exists()
        if is_owner:
            return Response(
                {"message": "Own view not counted", "views": media.views},
                status=status.HTTP_200_OK,
            )

        # First view from this user → record it and bump the counter atomically.
        _, created = BusinessNetworkMediaView.objects.get_or_create(
            media=media, user=request.user
        )
        if created:
            BusinessNetworkMedia.objects.filter(id=media_id).update(
                views=F("views") + 1
            )
            media.refresh_from_db(fields=["views"])

        return Response(
            {"message": "Views incremented" if created else "Already viewed",
             "views": media.views},
            status=status.HTTP_200_OK,
        )
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def add_post_video(request, post_id):
    """Attach a NEW video to an existing post (edit flow).

    Multipart body: {video: <file>}. Author-only, honors the same 2-video
    cap and thumbnail pipeline as post creation. Returns the full updated
    post so the editor can refresh in place.
    """
    post = BusinessNetworkPost.objects.filter(
        id=post_id, is_banned=False
    ).first()
    if post is None:
        return Response({"error": "Post not found"}, status=status.HTTP_404_NOT_FOUND)
    if post.author_id != request.user.id:
        return Response(
            {"error": "You can only edit your own post"},
            status=status.HTTP_403_FORBIDDEN,
        )

    video_file = request.FILES.get("video")
    if video_file is None:
        return Response({"error": "video file required"}, status=400)
    if video_file.size > 200 * 1024 * 1024:
        return Response(
            {"videos": "Video is too large (max 200 MB)."}, status=400
        )
    existing_videos = post.media.filter(type="video").count()
    if existing_videos >= 2:
        return Response(
            {"error": "সর্বোচ্চ ২ টি ভিডিও দেওয়া যাবে"}, status=400
        )

    post_media = BusinessNetworkMedia.objects.create(
        type="video", video=video_file
    )
    try:
        if post_media.video and post_media.video.path:
            thumb_file = generate_video_thumbnail(post_media.video.path)
            if thumb_file:
                post_media.thumbnail = thumb_file
                post_media.save(update_fields=["thumbnail"])
    except Exception as thumb_err:
        print(f"Could not generate video thumbnail: {thumb_err}")
    post.media.add(post_media)

    return Response(
        BusinessNetworkPostSerializer(
            post, context={"request": request, "full_detail": True}
        ).data
    )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def track_post_share(request, post_id):
    """Count a non-repost share (send-to-chat, WhatsApp, copy-to-app, etc.).

    Atomic F() increment — no race with concurrent shares. Returns the new
    total share count so the client can update its badge immediately.
    """
    from django.db.models import F

    updated = BusinessNetworkPost.objects.filter(
        id=post_id, is_banned=False
    ).update(external_share_count=F("external_share_count") + 1)
    if not updated:
        return Response({"error": "Post not found"}, status=status.HTTP_404_NOT_FOUND)
    post = BusinessNetworkPost.objects.get(id=post_id)
    return Response({
        "share_count": post.reshares.count() + post.external_share_count,
    })


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def reshare_post(request, post_id):
    """Reshare (repost) another user's post to your own profile/feed.

    Body: {caption?}. Creates a new post whose shared_from points at the ROOT
    original (so resharing a reshare still embeds the source), and notifies the
    original author.
    """
    import logging as _logging

    original = BusinessNetworkPost.objects.filter(
        id=post_id, is_banned=False
    ).first()
    if original is None:
        return Response(
            {"error": "Post not found"}, status=status.HTTP_404_NOT_FOUND
        )

    root = original.shared_from or original
    caption = (request.data.get("caption") or "").strip()

    reshare = BusinessNetworkPost.objects.create(
        author=request.user,
        content=caption or None,
        shared_from=root,
        visibility="public",
    )

    try:
        if root.author_id != request.user.id:
            BusinessNetworkNotification.objects.create(
                recipient=root.author,
                actor=request.user,
                type="share",
                target_id=str(root.id),
                content=(caption[:140] if caption else None),
            )
            # FCM push (mirrors like/comment notifications).
            from base.models import FCMToken
            from base.fcm_service import send_fcm_notification_async

            actor_name = (
                request.user.get_full_name()
                or getattr(request.user, "name", "")
                or request.user.email
            )
            for tok in FCMToken.objects.filter(user=root.author, is_active=True):
                send_fcm_notification_async(
                    fcm_token=tok.token,
                    title="Post Shared",
                    body=f"{actor_name} আপনার পোস্ট শেয়ার করেছেন",
                    data={
                        "type": "share",
                        "post_id": str(root.id),
                        "user_id": str(request.user.id),
                        "click_action": "FLUTTER_NOTIFICATION_CLICK",
                    },
                )
    except Exception:
        _logging.getLogger(__name__).exception("[bn] reshare notification failed")

    data = BusinessNetworkPostSerializer(
        reshare, context={"request": request}
    ).data
    return Response(data, status=status.HTTP_201_CREATED)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def reshare_news(request, news_id):
    """Reshare an Adsy News story to your own Business Network feed.

    Body: {caption?}. Creates a BusinessNetworkPost whose shared_news points at
    the story. Unlike post reshares there is no root-collapsing to do — a news
    story is always the source.
    """
    from news.models import NewsPost

    news = NewsPost.objects.filter(id=news_id).first()
    if news is None:
        return Response(
            {"error": "News post not found"}, status=status.HTTP_404_NOT_FOUND
        )

    caption = (request.data.get("caption") or "").strip()

    reshare = BusinessNetworkPost.objects.create(
        author=request.user,
        content=caption or None,
        shared_news=news,
        visibility="public",
    )

    data = BusinessNetworkPostSerializer(
        reshare, context={"request": request}
    ).data
    return Response(data, status=status.HTTP_201_CREATED)


# Like Views
class BusinessNetworkPostLikeCreateView(generics.ListCreateAPIView):
    serializer_class = BusinessNetworkPostLikeSerializer
    pagination_class = StandardResultsSetPagination
    # permission_classes = [IsAuthenticated]

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context["request"] = self.request
        return context

    def get_queryset(self):
        post_id = self.kwargs.get("post_id")
        if post_id:
            return BusinessNetworkPostLike.objects.filter(post_id=post_id)
        return BusinessNetworkPostLike.objects.none()

    def create(self, request, *args, **kwargs):
        post_id = kwargs.get("post_id")
        post = get_object_or_404(BusinessNetworkPost, pk=post_id)

        # Check if user has already liked the post
        existing_like = BusinessNetworkPostLike.objects.filter(
            post=post, user=request.user
        ).first()
        
        if existing_like:
            # Already liked - return existing like
            serializer = self.get_serializer(existing_like)
            return Response(serializer.data, status=status.HTTP_200_OK)

        like = BusinessNetworkPostLike(post=post, user=request.user)
        like.save()
        _clear_business_network_social_cache(request.user, post.author)
        serializer = self.get_serializer(like)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class BusinessNetworkPostLikeDestroyView(generics.DestroyAPIView):
    permission_classes = [IsAuthenticated]

    def get_object(self):
        post_id = self.kwargs.get("post_id")
        post = get_object_or_404(BusinessNetworkPost, pk=post_id)
        like = get_object_or_404(
            BusinessNetworkPostLike, post=post, user=self.request.user
        )
        return like

    def perform_destroy(self, instance):
        author = instance.post.author
        instance.delete()
        _clear_business_network_social_cache(self.request.user, author)


# Follow Views
class BusinessNetworkPostFollowCreateView(generics.ListCreateAPIView):
    serializer_class = BusinessNetworkPostFollowSerializer
    pagination_class = StandardResultsSetPagination
    # permission_classes = [IsAuthenticated]

    def get_queryset(self):
        post_id = self.kwargs.get("post_id")
        if post_id:
            return BusinessNetworkPostFollow.objects.filter(post_id=post_id)
        return BusinessNetworkPostFollow.objects.none()

    def create(self, request, *args, **kwargs):
        post_id = kwargs.get("post_id")
        post = get_object_or_404(BusinessNetworkPost, pk=post_id)

        # Check if user already follows the post
        if BusinessNetworkPostFollow.objects.filter(
            post=post, user=request.user
        ).exists():
            return Response(
                {"detail": "You are already following this post."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        follow = BusinessNetworkPostFollow(post=post, user=request.user)
        follow.save()
        _clear_business_network_social_cache(request.user, post.author)
        serializer = self.get_serializer(follow)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class BusinessNetworkPostFollowDestroyView(generics.DestroyAPIView):
    permission_classes = [IsAuthenticated]

    def get_object(self):
        post_id = self.kwargs.get("post_id")
        post = get_object_or_404(BusinessNetworkPost, pk=post_id)
        follow = get_object_or_404(
            BusinessNetworkPostFollow, post=post, user=self.request.user
        )
        return follow

    def perform_destroy(self, instance):
        author = instance.post.author
        instance.delete()
        _clear_business_network_social_cache(self.request.user, author)


# Comment Views
class BusinessNetworkPostCommentListCreateView(generics.ListCreateAPIView):
    serializer_class = BusinessNetworkPostCommentSerializer
    pagination_class = StandardResultsSetPagination
    # permission_classes = [IsAuthenticated]

    def get_queryset(self):
        post_id = self.kwargs.get("post_id")
        return BusinessNetworkPostComment.objects.filter(post__id=post_id).order_by(
            "-created_at"
        )

    def perform_create(self, serializer):
        post_id = self.kwargs.get("post_id")
        post = get_object_or_404(BusinessNetworkPost, pk=post_id)
        serializer.save(post=post, author=self.request.user)

    def create(self, request, *args, **kwargs):
        content = request.data.get("content")
        if not content or not content.strip():
            return Response(
                {"detail": "Comment content cannot be empty."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Fetch the post using the post_id from URL
        post_id = self.kwargs.get("post_id")
        try:
            post = get_object_or_404(BusinessNetworkPost, pk=post_id)
            post_author_id = post.author.id

            # Create data object with all required fields
            data = {"content": content, "post": post_id, "author": request.user.id}
            
            # Include parent_comment if provided (for replies)
            parent_comment_id = request.data.get("parent_comment")
            if parent_comment_id:
                data["parent_comment"] = parent_comment_id

            # Create the serializer with our prepared data
            serializer = self.get_serializer(data=data)

            # Validate but handle the validation ourselves
            if not serializer.is_valid():
                # If there are errors other than post and author, return them
                errors = serializer.errors.copy()
                errors.pop("post", None)
                errors.pop("author", None)
                if errors:
                    return Response(errors, status=status.HTTP_400_BAD_REQUEST)

            # Custom save to ensure post and author are set correctly
            comment = serializer.save(post=post, author=request.user)
            _clear_business_network_social_cache(request.user, post.author)

            # Include post author ID in the response
            response_data = serializer.data
            response_data["post_author_id"] = post_author_id

            headers = self.get_success_headers(serializer.data)
            return Response(
                response_data, status=status.HTTP_201_CREATED, headers=headers
            )

        except Exception as e:
            return Response(
                {"detail": f"Error creating comment: {str(e)}"},
                status=status.HTTP_400_BAD_REQUEST,
            )


class BusinessNetworkPostCommentRetrieveUpdateDestroyView(
    generics.RetrieveUpdateDestroyAPIView
):
    serializer_class = BusinessNetworkPostCommentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return BusinessNetworkPostComment.objects.all()

    def perform_update(self, serializer):
        # Only the comment author may edit. (Returning a Response from
        # perform_update is silently discarded by DRF, so raise instead — a
        # returned 403 was answered as 200.)
        if serializer.instance.author != self.request.user:
            raise PermissionDenied(
                "You do not have permission to edit this comment."
            )
        serializer.save()

    def perform_destroy(self, instance):
        # Comment author or post author may delete.
        if (
            instance.author != self.request.user
            and instance.post.author != self.request.user
        ):
            raise PermissionDenied(
                "You do not have permission to delete this comment."
            )
        instance.delete()


# Tag Views
class BusinessNetworkPostTagListCreateView(generics.ListCreateAPIView):
    queryset = BusinessNetworkPostTag.objects.all()
    serializer_class = BusinessNetworkPostTagSerializer


class BusinessNetworkPostTagDestroyView(generics.DestroyAPIView):
    queryset = BusinessNetworkPostTag.objects.all()
    permission_classes = [IsAuthenticated]

    def perform_destroy(self, instance):
        # Tags are shared across posts (M2M, get_or_create by name) and have no
        # `.post`. Deleting the tag OBJECT would strip it from every post that
        # uses it, so only detach it from the caller's own posts — never delete
        # the shared row. (The old `instance.post` 500'd for everyone; the edit
        # flow sets tags via the post-update `tags` list, not this endpoint.)
        my_posts = instance.business_network_posts.filter(
            author=self.request.user
        )
        if not my_posts.exists():
            raise PermissionDenied("Only the post author can remove tags.")
        for post in my_posts:
            post.tags.remove(instance)


# Search and Discovery
class BusinessNetworkPostSearchView(generics.ListAPIView):
    serializer_class = BusinessNetworkPostSerializer
    pagination_class = StandardResultsSetPagination
    # permission_classes = [IsAuthenticated]

    def get_queryset(self):
        query = self.request.query_params.get("q", "")
        tag = self.request.query_params.get("tag", "")

        queryset = BusinessNetworkPost.objects.all()
        # Store original queryset for combining with tag results later
        content_query_results = None
        tag_query_results = None

        if query:
            # Normalize query for better matching
            normalized_query = query.strip()

            # Remove # if the query is a hashtag search
            if normalized_query.startswith("#"):
                normalized_query = normalized_query[1:]

            # Enhanced search: look in title, content, and author name fields with different weights
            # Use Case insensitive containment for broader matches
            author_search_query = Q()

            # Basic author field searches
            author_search_query |= Q(author__username__icontains=normalized_query)
            author_search_query |= Q(author__first_name__icontains=normalized_query)
            author_search_query |= Q(author__last_name__icontains=normalized_query)

            # Enhanced full name search for multi-word queries
            name_parts = normalized_query.split()
            if len(name_parts) > 1:
                # For multi-word searches like "Alimul Islam", also search for combinations
                for i in range(1, len(name_parts)):
                    first_part = " ".join(name_parts[:i])
                    last_part = " ".join(name_parts[i:])

                    # Match where first part is in first_name and second part is in last_name
                    author_search_query |= Q(
                        author__first_name__icontains=first_part
                    ) & Q(author__last_name__icontains=last_part)

                    # Also try the reverse (in case names are stored differently)
                    author_search_query |= Q(
                        author__first_name__icontains=last_part
                    ) & Q(author__last_name__icontains=first_part)

                # Also check if the complete query matches across first_name + last_name combined
                # This handles cases where someone searches "Alimul Islam" and user has first_name="Md Alimul" last_name="Islam"
                for part in name_parts:
                    author_search_query |= Q(author__first_name__icontains=part)
                    author_search_query |= Q(author__last_name__icontains=part)

            # Combine all search criteria
            content_query_results = queryset.filter(
                Q(title__icontains=normalized_query)
                | Q(content__icontains=normalized_query)
                | author_search_query
            )
            queryset = content_query_results

        if tag:
            # Normalize tag for better matching (remove # if present)
            normalized_tag = tag.strip()
            if normalized_tag.startswith("#"):
                normalized_tag = normalized_tag[1:]

            # Create a query for tag search that checks against the tag field
            # Use iexact for exact tag matches but case insensitive
            tag_query_exact = BusinessNetworkPost.objects.filter(
                tags__tag__iexact=normalized_tag
            )

            # Also include partial matches with lower priority
            tag_query_partial = BusinessNetworkPost.objects.filter(
                tags__tag__icontains=normalized_tag
            ).exclude(
                tags__tag__iexact=normalized_tag  # Exclude exact matches to avoid duplicates
            )

            # Combine exact and partial matches, with exact matches first
            tag_query_results = list(tag_query_exact) + list(tag_query_partial)

            if content_query_results is not None:
                # Combine content and tag results, removing duplicates
                combined_results = list(content_query_results) + [
                    post
                    for post in tag_query_results
                    if post not in content_query_results
                ]

                # Convert back to queryset (needed for pagination)
                post_ids = [post.id for post in combined_results]
                queryset = BusinessNetworkPost.objects.filter(id__in=post_ids)
            else:
                # If only tag search, convert list back to queryset
                post_ids = [post.id for post in tag_query_results]
                queryset = BusinessNetworkPost.objects.filter(id__in=post_ids)

        # Mutual block invisibility: hide posts whose author is in a block
        # relationship with the current user, in EITHER direction. A blocked
        # user's posts must not surface in my search, and my posts must not
        # surface in a blocker's search — until the block is removed.
        request_user = self.request.user
        if request_user.is_authenticated:
            blocked_ids = BlockedUser.objects.filter(
                blocker=request_user
            ).values_list("blocked_id", flat=True)
            blocked_by_ids = BlockedUser.objects.filter(
                blocked=request_user
            ).values_list("blocker_id", flat=True)
            queryset = queryset.exclude(author_id__in=blocked_ids).exclude(
                author_id__in=blocked_by_ids
            )

        # Ensure we always return distinct results
        return queryset.distinct().order_by("-created_at")


class BusinessNetworkWorkspaceListCreateView(generics.ListCreateAPIView):
    queryset = BusinessNetworkWorkspace.objects.all()
    serializer_class = BusinessNetworkWorkspaceSerializer
    permission_classes = [IsAuthenticated]


class UserFollowCreateView(generics.CreateAPIView):
    queryset = BusinessNetworkFollowerModel.objects.all()
    serializer_class = BusinessNetworkFollowerSerializer
    permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        user_id = self.kwargs.get("user_id")

        # Nobody can follow themselves — plain-text message the app can show.
        if str(user_id) == str(request.user.id):
            return Response(
                {"detail": "নিজেকে ফলো করা যায় না।"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Check if already following
        existing_follow = BusinessNetworkFollowerModel.objects.filter(
            follower=request.user,
            following_id=user_id
        ).first()
        
        if existing_follow:
            # Already following - return the existing relationship
            serializer = self.get_serializer(existing_follow)
            return Response(serializer.data, status=status.HTTP_200_OK)
        
        serializer = self.get_serializer(
            data={"follower": request.user.id, "following": user_id}
        )

        if not serializer.is_valid():
            print(serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        self.perform_create(serializer)
        _clear_business_network_social_cache(request.user, user_id)
        headers = self.get_success_headers(serializer.data)
        return Response(
            serializer.data, status=status.HTTP_201_CREATED, headers=headers
        )


class UserUnfollowDestroyView(generics.DestroyAPIView):
    permission_classes = [IsAuthenticated]

    def get_object(self):
        user_id = self.kwargs.get("user_id")
        following_user = get_object_or_404(User, pk=user_id)
        follow = get_object_or_404(
            BusinessNetworkFollowerModel,
            follower=self.request.user,
            following=following_user,
        )
        return follow

    def perform_destroy(self, instance):
        following = instance.following
        instance.delete()
        _clear_business_network_social_cache(self.request.user, following)


class UserFollowersListView(generics.ListAPIView):
    serializer_class = BusinessNetworkFollowerSerializer
    pagination_class = StandardResultsSetPagination

    def get_queryset(self):
        user_id = self.kwargs.get("user_id")
        return BusinessNetworkFollowerModel.objects.filter(following=user_id).order_by(
            "-created_at"
        )


class UserFollowingListView(generics.ListAPIView):
    serializer_class = BusinessNetworkFollowerSerializer
    pagination_class = StandardResultsSetPagination

    def get_queryset(self):
        user_id = self.kwargs.get("user_id")
        return BusinessNetworkFollowerModel.objects.filter(follower=user_id).order_by(
            "-created_at"
        )


class UserSuggestionsView(generics.ListAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user

        # Get users that the current user is already following
        following_users = BusinessNetworkFollowerModel.objects.filter(
            follower=user
        ).values_list("following_id", flat=True)

        # Exclude current user and users they're already following
        base_queryset = User.objects.exclude(Q(id=user.id) | Q(id__in=following_users))

        # Strategy 1: Users followed by people you follow (mutual connections)
        mutual_connections = (
            base_queryset.filter(
                business_network_followers__follower__in=following_users
            )
            .annotate(
                mutual_connections=Count(
                    "business_network_followers__follower", distinct=True
                )
            )
            .filter(mutual_connections__gt=0)
        )

        # Strategy 2: Active users with posts
        active_users = base_queryset.annotate(
            post_count=Count("business_network_posts", distinct=True),
            follower_count=Count("business_network_followers", distinct=True),
        ).filter(post_count__gt=0)

        # Strategy 3: Users with similar interests (same hashtags)
        user_hashtags = (
            BusinessNetworkPostTag.objects.filter(post__author=user)
            .values_list("tag", flat=True)
            .distinct()
        )

        similar_interest_users = (
            base_queryset.filter(
                business_network_posts__post_tags__tag__in=user_hashtags
            )
            .annotate(
                common_tags=Count(
                    "business_network_posts__post_tags__tag", distinct=True
                )
            )
            .filter(common_tags__gt=0)
            if user_hashtags
            else User.objects.none()
        )

        # Combine all strategies with priority
        # Priority: mutual connections > active users > similar interests
        suggestions = (
            mutual_connections.order_by("-mutual_connections", "-follower_count")[:3]
            | active_users.order_by("-follower_count", "-post_count")[:5]
            | similar_interest_users.order_by("-common_tags", "-follower_count")[:2]
        ).distinct()

        # Annotate with follower count and mutual connections for frontend
        return suggestions.annotate(
            follower_count=Count("business_network_followers", distinct=True),
            post_count=Count("business_network_posts", distinct=True),
            mutual_connections=Count(
                "business_network_followers__follower",
                filter=Q(business_network_followers__follower__in=following_users),
                distinct=True,
            ),
        )[:10]  # Limit to 10 suggestions

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)

        return Response(
            {"success": True, "data": serializer.data, "count": len(serializer.data)},
            status=status.HTTP_200_OK,
        )


# Simple User Suggestions View (Fixed version)
class SimpleUserSuggestionsView(generics.ListAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user

        # Get users that the current user is already following
        following_users = BusinessNetworkFollowerModel.objects.filter(
            follower=user
        ).values_list("following_id", flat=True)

        # Exclude current user and users they're already following
        base_queryset = User.objects.exclude(Q(id=user.id) | Q(id__in=following_users))

        # If we have any users, return them
        if base_queryset.exists():
            return base_queryset.annotate(
                follower_count=Count("business_network_followers", distinct=True),
                post_count=Count("business_network_posts", distinct=True),
                mutual_connections=Value(0, output_field=IntegerField()),
            ).order_by("-date_joined")[:10]

        # If no users available, return empty queryset
        return User.objects.none()

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)

        return Response(
            {"success": True, "data": serializer.data, "count": len(serializer.data)},
            status=status.HTTP_200_OK,
        )


class BusinessNetworkMediaLikeCreateView(generics.ListCreateAPIView):
    serializer_class = BusinessNetworkMediaLikeSerializer

    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        media_id = self.kwargs.get("media_id")
        if media_id:
            return BusinessNetworkMediaLike.objects.filter(media_id=media_id)
        return BusinessNetworkMediaLike.objects.none()

    def create(self, request, *args, **kwargs):
        media_id = kwargs.get("media_id")
        media = get_object_or_404(BusinessNetworkMedia, pk=media_id)

        # Check if user has already liked the media
        if BusinessNetworkMediaLike.objects.filter(
            media=media, user=request.user
        ).exists():
            return Response(
                {"detail": "You have already liked this media."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        like = BusinessNetworkMediaLike(media=media, user=request.user)
        like.save()
        serializer = self.get_serializer(like)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class BusinessNetworkMediaLikeDestroyView(generics.DestroyAPIView):
    permission_classes = [IsAuthenticated]

    def get_object(self):
        media_id = self.kwargs.get("media_id")
        media = get_object_or_404(BusinessNetworkMedia, pk=media_id)
        like = get_object_or_404(
            BusinessNetworkMediaLike, media=media, user=self.request.user
        )
        return like


class BusinessNetworkMediaCommentListCreateView(generics.ListCreateAPIView):
    serializer_class = BusinessNetworkMediaCommentSerializer
    permission_classes = [IsAuthenticated]
    # pagination_class = StandardResultsSetPagination

    def get_queryset(self):
        media_id = self.kwargs.get("media_id")
        return BusinessNetworkMediaComment.objects.filter(media__id=media_id).order_by(
            "-created_at"
        )

    def perform_create(self, serializer):
        media_id = self.kwargs.get("media_id")
        media = get_object_or_404(BusinessNetworkMedia, pk=media_id)
        serializer.save(media=media, author=self.request.user)

    def create(self, request, *args, **kwargs):
        content = request.data.get("content")
        if not content or not content.strip():
            return Response(
                {"detail": "Comment content cannot be empty."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            media_id = self.kwargs.get("media_id")
            media = get_object_or_404(BusinessNetworkMedia, pk=media_id)

            data = {"content": content, "media": media_id, "author": request.user.id}

            serializer = self.get_serializer(data=data)

            if not serializer.is_valid():
                # Log all errors for debugging
                print(f"Serializer validation errors: {serializer.errors}")

                # Filter out media and author errors if they exist
                errors = serializer.errors.copy()
                errors.pop("media", None)
                errors.pop("author", None)

                # Return all original errors for better debugging
                if errors:
                    return Response(
                        {
                            "detail": "Validation errors in comment data",
                            "errors": errors,
                            "all_errors": serializer.errors,  # Include all errors for debugging
                        },
                        status=status.HTTP_400_BAD_REQUEST,
                    )

            comment = serializer.save(media=media, author=request.user)
            headers = self.get_success_headers(serializer.data)
            return Response(
                serializer.data, status=status.HTTP_201_CREATED, headers=headers
            )

        except Exception as e:
            import traceback

            print(f"Error creating comment: {str(e)}")
            print(traceback.format_exc())  # Print stack trace for debugging
            return Response(
                {"detail": f"Error creating comment: {str(e)}"},
                status=status.HTTP_400_BAD_REQUEST,
            )


class BusinessNetworkMediaCommentRetrieveUpdateDestroyView(
    generics.RetrieveUpdateDestroyAPIView
):
    serializer_class = BusinessNetworkMediaCommentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return BusinessNetworkMediaComment.objects.all()

    def perform_update(self, serializer):
        # Only the comment author may edit (raise so DRF returns a real 403).
        if serializer.instance.author != self.request.user:
            raise PermissionDenied(
                "You do not have permission to edit this comment."
            )
        serializer.save()

    def perform_destroy(self, instance):
        # Comment author, or the author of a post that uses this media, may
        # delete. (Media has no `.author` — the old check 500'd for non-authors;
        # media links to posts via M2M.)
        is_media_post_author = instance.media.business_network_posts.filter(
            author=self.request.user
        ).exists()
        if instance.author != self.request.user and not is_media_post_author:
            raise PermissionDenied(
                "You do not have permission to delete this comment."
            )
        instance.delete()


class AbnAdsPanelCategoryListCreateView(generics.ListCreateAPIView):
    queryset = AbnAdsPanelCategory.objects.all()
    serializer_class = AbnAdsPanelCategorySerializer
    permission_classes = [IsAuthenticated]


class AbnAdsPanelListCreateView(generics.ListCreateAPIView):
    queryset = AbnAdsPanel.objects.all()
    serializer_class = AbnAdsPanelSerializer
    permission_classes = [IsAuthenticated]
    # pagination_class = StandardResultsSetPagination

    def get_queryset(self):
        queryset = AbnAdsPanel.objects.all().order_by("-created_at")

        # Filter by category if provided
        category = self.request.query_params.get("category", None)
        if category:
            queryset = queryset.filter(category__id=category)

        # Filter by gender if provided
        gender = self.request.query_params.get("gender", None)
        if gender:
            queryset = queryset.filter(gender=gender)

        # Filter by country if provided
        country = self.request.query_params.get("country", None)
        if country:
            queryset = queryset.filter(country=country)

        # Filter by ad_type if provided
        ad_type = self.request.query_params.get("ad_type", None)
        if ad_type:
            queryset = queryset.filter(ad_type=ad_type)

        return queryset

    def create(self, request, *args, **kwargs):
        images_data = request.data.pop("images", None)
        companion_b64 = request.data.pop("companion_banner_b64", None)
        media_ids = request.data.pop("media_ids", None)  # pre-uploaded videos
        data = request.data
        data["user"] = request.user.id
        serializer = self.get_serializer(data=data)

        try:
            serializer.is_valid(raise_exception=True)
        except ValidationError as e:
            print(serializer.errors)  # Print validation errors
            raise e

        # Billing: the budget is deducted from the AdsyClub balance up front;
        # a rejected ad refunds it (admin action). Estimated views come from
        # the configured CPV rate — never from the client.
        from decimal import Decimal

        from .models import AdsSystemConfig

        cfg = AdsSystemConfig.get()
        budget = Decimal(str(serializer.validated_data.get("budget") or 0))
        if budget <= 0:
            return Response({"error": "Invalid budget"}, status=400)
        if request.user.balance < budget:
            return Response(
                {"error": "Insufficient balance",
                 "detail": "আপনার ব্যালেন্সে পর্যাপ্ত টাকা নেই।"},
                status=400,
            )
        request.user.balance -= budget
        request.user.save(update_fields=["balance"])

        estimated = int(budget / Decimal(str(cfg.cpv_rate))) if cfg.cpv_rate else 0
        abn_ads = serializer.save(
            status="review", estimated_views=estimated
        )

        # Companion banner (base64) — shown under video creatives.
        if companion_b64 and isinstance(companion_b64, str) and \
                companion_b64.startswith("data:image"):
            try:
                abn_ads.companion_banner = base64ToFile(companion_b64)
                abn_ads.save(update_fields=["companion_banner"])
            except Exception as e:
                print(f"Error processing companion banner: {e}")

        # Pre-uploaded video media (from /ads/upload-video/).
        if media_ids:
            if not isinstance(media_ids, list):
                media_ids = [media_ids]
            for mid in media_ids[:2]:
                media = AbnAdsPanelMedia.objects.filter(pk=str(mid)).first()
                if media:
                    abn_ads.media.add(media)

        # Print or log the serializer errors

        if images_data:
            # Handle both list of images and single image
            if not isinstance(images_data, list):
                images_data = [images_data]

            for image_data in images_data:
                try:
                    if isinstance(image_data, str) and image_data.startswith(
                        "data:image"
                    ):
                        # Process base64 image
                        image_file = base64ToFile(image_data)
                        abn_ads_media = AbnAdsPanelMedia.objects.create(
                            image=image_file
                        )
                        abn_ads.media.add(abn_ads_media)
                except Exception as e:
                    # Log error but continue processing
                    print(f"Error processing image: {str(e)}")

        headers = self.get_success_headers(serializer.data)
        return Response(
            serializer.data, status=status.HTTP_201_CREATED, headers=headers
        )


class AbnAdsPanelRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    queryset = AbnAdsPanel.objects.all()
    serializer_class = AbnAdsPanelSerializer
    permission_classes = [IsAuthenticated]

    # IDOR guard: reads are public, but a user may only modify/delete their own
    # ad panel (staff may manage any).
    def _assert_owner(self, instance):
        if not (self.request.user.is_staff
                or instance.user_id == self.request.user.id):
            raise PermissionDenied("You do not have permission to modify this ad.")

    def perform_update(self, serializer):
        self._assert_owner(serializer.instance)
        serializer.save()

    def perform_destroy(self, instance):
        self._assert_owner(instance)
        instance.delete()


class AbnAdsPanelFilterView(generics.ListAPIView):
    serializer_class = AbnAdsPanelSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = StandardResultsSetPagination

    def get_queryset(self):
        queryset = AbnAdsPanel.objects.all().order_by("-created_at")

        # Get user demographic data
        user_age = self.request.query_params.get("age", None)
        user_gender = self.request.query_params.get("gender", None)
        user_country = self.request.query_params.get("country", None)

        # Apply demographic filters
        if user_age:
            user_age = int(user_age)
            queryset = queryset.filter(
                models.Q(min_age__isnull=True) | models.Q(min_age__lte=user_age),
                models.Q(max_age__isnull=True) | models.Q(max_age__gte=user_age),
            )

        if user_gender:
            queryset = queryset.filter(
                models.Q(gender=user_gender) | models.Q(gender="other")
            )

        if user_country:
            queryset = queryset.filter(country=user_country)

        return queryset


class BusinessNetworkMindforceCategoryListView(generics.ListAPIView):
    queryset = BusinessNetworkMindforceCategory.objects.all()
    serializer_class = BusinessNetworkMindforceCategorySerializer
    permission_classes = [IsAuthenticated]


class BusinessNetworkMindForceListCreateView(generics.ListCreateAPIView):
    serializer_class = BusinessNetworkMindforceSerializer

    def get_queryset(self):
        queryset = BusinessNetworkMindforce.objects.all().order_by("-created_at")

        # Filter by category if provided
        category = self.request.query_params.get("category", None)
        if category:
            queryset = queryset.filter(category__id=category)

        return queryset

    def get_permissions(self):
        if self.request.method == "POST":
            return [IsAuthenticated()]
        else:
            return [AllowAny()]

    def create(self, request, *args, **kwargs):
        print(request.data)
        # Create a mutable copy of request.data
        data = request.data.copy()
        images_data = data.pop("images", None)
        data["user"] = request.user.id
        serializer = self.get_serializer(data=data)

        serializer.is_valid(raise_exception=True)
        mindforce = serializer.save()

        if images_data:
            # Handle both list of images and single image
            if not isinstance(images_data, list):
                images_data = [images_data]

            for image_data in images_data:
                try:
                    if isinstance(image_data, str) and image_data.startswith(
                        "data:image"
                    ):
                        # Process base64 image
                        image_file = base64ToFile(image_data)
                        mindforce_media = BusinessNetworkMindforceMedia.objects.create(
                            image=image_file
                        )
                        mindforce.media.add(mindforce_media)
                except Exception as e:
                    # Log error but continue processing
                    print(f"Error processing image: {str(e)}")

        headers = self.get_success_headers(serializer.data)
        return Response(
            serializer.data, status=status.HTTP_201_CREATED, headers=headers
        )


class BusinessNetworkMindforceRetrieveUpdateDestroyView(
    generics.RetrieveUpdateDestroyAPIView
):
    queryset = BusinessNetworkMindforce.objects.all()
    serializer_class = BusinessNetworkMindforceSerializer
    lookup_field = "id"

    def get_permissions(self):
        # Anyone can read a problem; only authenticated users may edit/delete.
        if self.request.method == "GET":
            return []
        return [IsAuthenticated()]

    def perform_update(self, serializer):
        # Only the author may edit (raise -> real 403; a returned Response
        # from perform_* is silently discarded by DRF).
        if serializer.instance.user_id != self.request.user.id:
            raise PermissionDenied("You can only edit your own problem.")
        serializer.save()

    def perform_destroy(self, instance):
        # Only the author may delete their problem.
        if instance.user_id != self.request.user.id:
            raise PermissionDenied("You can only delete your own problem.")
        instance.delete()


class BusinessNetworkMindforceCommentsListCreateView(generics.ListCreateAPIView):
    serializer_class = BusinessNetworkMindforceCommentSerializer

    def get_permissions(self):
        if self.request.method == "GET":
            return []
        else:
            return [IsAuthenticated()]

    def get_queryset(self):
        mindforce_id = self.kwargs["mindforce_id"]
        return BusinessNetworkMindforceComment.objects.filter(
            mindforce_problem=mindforce_id
        ).order_by("-created_at")

    def create(self, request, *args, **kwargs):
        data = request.data
        images_data = data.pop("images", None) if "images" in data else None

        data["author"] = request.user.id
        mindforce_id = kwargs["mindforce_id"]
        mindforce_problem = get_object_or_404(BusinessNetworkMindforce, id=mindforce_id)
        data["mindforce_problem"] = mindforce_id
        # If the problem is already solved, prevent commenting
        if mindforce_problem.status == "solved":
            return Response(
                {"detail": "Cannot comment on solved problems"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Create comment with initial data
        serializer = self.get_serializer(data=data)
        serializer.is_valid(raise_exception=True)
        comment = serializer.save()
        # Process any media files
        if images_data:
            # Handle both list of images and single image
            if not isinstance(images_data, list):
                images_data = [images_data]
            successful_images = 0
            failed_images = 0
            errors = []

            for index, image_data in enumerate(images_data):
                try:
                    # Handle case where image_data is a dictionary with base64 data
                    if isinstance(image_data, dict) and "data" in image_data:
                        image_data = image_data["data"]
                    elif isinstance(image_data, dict) and any(
                        key
                        for key in image_data
                        if "base64" in str(key)
                        or "base64" in str(image_data.get(key, ""))
                    ):
                        # Try to find a key containing base64 data
                        for key, value in image_data.items():
                            if isinstance(value, str) and "base64" in value:
                                image_data = value
                                break
                        else:
                            # If no base64 data found in values, try keys
                            for key in image_data.keys():
                                if "base64" in key:
                                    image_data = image_data[key]
                                    break

                    # Process base64 image
                    image_file = base64ToFile(image_data)
                    mindforce_comment_media = (
                        BusinessNetworkMindforceCommentMedia.objects.create(
                            image=image_file
                        )
                    )
                    comment.media.add(mindforce_comment_media)
                    successful_images += 1
                    print(f"Image {index + 1} processed successfully")
                except Exception as e:
                    # Log error but continue processing
                    error_msg = f"Error processing image {index + 1}: {str(e)}"
                    print(error_msg)
                    errors.append(error_msg)
                    failed_images += 1
            # Report on image processing
            if successful_images > 0:
                print(f"Successfully added {successful_images} image(s)")
            if failed_images > 0:
                print(f"Failed to add {failed_images} image(s)")
                for error in errors:
                    print(f"- {error}")

        # Add image processing results to the response
        response_data = serializer.data
        if images_data:
            response_data["image_results"] = {
                "total_images": len(images_data)
                if isinstance(images_data, list)
                else 1,
                "successful": successful_images,
                "failed": failed_images,
                "errors": errors if failed_images > 0 else [],
            }

        headers = self.get_success_headers(serializer.data)
        return Response(response_data, status=status.HTTP_201_CREATED, headers=headers)


class BusinessNetworkMindforceCommentDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = BusinessNetworkMindforceComment.objects.all()
    serializer_class = BusinessNetworkMindforceCommentSerializer
    permission_classes = [IsAuthenticated]
    lookup_field = "id"

    # IDOR guard: only the comment's author may edit/delete it.
    def _assert_owner(self, instance):
        author_id = getattr(instance, "author_id", None) or getattr(
            instance, "user_id", None
        )
        if not (self.request.user.is_staff or author_id == self.request.user.id):
            raise PermissionDenied(
                "You do not have permission to modify this comment."
            )

    def perform_update(self, serializer):
        self._assert_owner(serializer.instance)
        serializer.save()

    def perform_destroy(self, instance):
        self._assert_owner(instance)
        instance.delete()


class CheckUserFollowStatusView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, follower_id, following_id):
        try:
            # Check if follower_id follows following_id
            follow_exists = BusinessNetworkFollowerModel.objects.filter(
                follower_id=follower_id, following_id=following_id
            ).exists()

            return Response({"is_following": follow_exists}, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class TopTagsView(APIView):
    def get(self, request):
        # Access the auto-generated ManyToMany "through" table
        through_model = BusinessNetworkPost.tags.through

        # Step 1: Count how many times each tag (by tag_id) was used in posts
        tag_usage = (
            through_model.objects.values("businessnetworkposttag")  # FK to tag
            .annotate(count=Count("businessnetworkpost"))
            .order_by("-count")[:100]
        )

        # Step 2: Get the corresponding tag objects
        tag_ids = [item["businessnetworkposttag"] for item in tag_usage]
        tag_objects = BusinessNetworkPostTag.objects.in_bulk(tag_ids)

        # Step 3: Combine tag object + count
        results = []
        for item in tag_usage:
            tag_obj = tag_objects.get(item["businessnetworkposttag"])
            if tag_obj:
                results.append(
                    {"id": tag_obj.id, "tag": tag_obj.tag, "count": item["count"]}
                )

        serializer = FrequentTagSerializer(results, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class BusinessNetworkNotificationListView(generics.ListAPIView):
    """List view for user notifications"""

    serializer_class = BusinessNetworkNotificationSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = StandardResultsSetPagination

    def get_queryset(self):
        """Return notifications for the current user, ordered by most recent first"""
        return BusinessNetworkNotification.objects.filter(
            recipient=self.request.user
        ).select_related('actor').order_by('-created_at')


class BusinessNetworkNotificationReadView(generics.UpdateAPIView):
    """View to mark a notification as read"""

    serializer_class = BusinessNetworkNotificationSerializer
    permission_classes = [IsAuthenticated]
    lookup_field = "id"

    def get_queryset(self):
        """Only allow users to mark their own notifications as read"""
        return BusinessNetworkNotification.objects.filter(recipient=self.request.user)

    def update(self, request, *args, **kwargs):
        notification = self.get_object()
        notification.read = True
        notification.save()
        return Response({"status": "success"}, status=status.HTTP_200_OK)


class BusinessNetworkMarkAllNotificationsReadView(generics.GenericAPIView):
    """View to mark all notifications as read"""

    permission_classes = [IsAuthenticated]

    def put(self, request):
        """Mark all of a user's notifications as read"""
        BusinessNetworkNotification.objects.filter(
            recipient=request.user, read=False
        ).update(read=True)
        return Response({"status": "success"}, status=status.HTTP_200_OK)


class BusinessNetworkUnreadNotificationCountView(generics.GenericAPIView):
    """View to get count of unread notifications"""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        """Return count of unread notifications"""
        count = BusinessNetworkNotification.objects.filter(
            recipient=request.user, read=False
        ).count()
        return Response({"count": count}, status=status.HTTP_200_OK)


# Hide Post Views
class HidePostView(APIView):
    """View to hide a post from user's feed"""
    permission_classes = [IsAuthenticated]

    def post(self, request, post_id):
        """Hide a post"""
        try:
            post = BusinessNetworkPost.objects.get(id=post_id)
            hidden_post, created = HiddenPost.objects.get_or_create(
                user=request.user,
                post=post
            )
            _clear_business_network_social_cache(request.user, post.author)
            
            if created:
                return Response(
                    {"message": "Post hidden successfully"},
                    status=status.HTTP_201_CREATED
                )
            else:
                return Response(
                    {"message": "Post already hidden"},
                    status=status.HTTP_200_OK
                )
        except BusinessNetworkPost.DoesNotExist:
            return Response(
                {"error": "Post not found"},
                status=status.HTTP_404_NOT_FOUND
            )

    def delete(self, request, post_id):
        """Unhide a post"""
        try:
            hidden_post = HiddenPost.objects.get(
                user=request.user,
                post_id=post_id
            )
            hidden_post.delete()
            _clear_business_network_social_cache(request.user, post_id)
            return Response(
                {"message": "Post unhidden successfully"},
                status=status.HTTP_200_OK
            )
        except HiddenPost.DoesNotExist:
            return Response(
                {"error": "Post is not hidden"},
                status=status.HTTP_404_NOT_FOUND
            )


# Report Post Views
class ReportPostView(APIView):
    """View to report a post"""
    permission_classes = [IsAuthenticated]

    def post(self, request, post_id):
        """Report a post"""
        try:
            post = BusinessNetworkPost.objects.get(id=post_id)
            reason = request.data.get('reason')
            description = request.data.get('description', '')

            # Validate reason
            valid_reasons = [choice[0] for choice in PostReport.REPORT_REASONS]
            if reason not in valid_reasons:
                return Response(
                    {"error": "Invalid report reason"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Create or get existing report
            report, created = PostReport.objects.get_or_create(
                user=request.user,
                post=post,
                reason=reason,
                defaults={'description': description}
            )
            _clear_business_network_social_cache(request.user, post.author)

            if created:
                return Response(
                    {
                        "message": "Post reported successfully",
                        "report_id": report.id
                    },
                    status=status.HTTP_201_CREATED
                )
            else:
                return Response(
                    {"message": "You have already reported this post for this reason"},
                    status=status.HTTP_200_OK
                )
        except BusinessNetworkPost.DoesNotExist:
            return Response(
                {"error": "Post not found"},
                status=status.HTTP_404_NOT_FOUND
            )


class ReportProfileView(APIView):
    """Report a user's profile (e.g. fake / impersonating accounts)."""
    permission_classes = [IsAuthenticated]

    def post(self, request, user_id):
        if str(user_id) == str(request.user.id):
            return Response(
                {"error": "You cannot report your own profile"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        reported = User.objects.filter(id=user_id).first()
        if reported is None:
            return Response(
                {"error": "User not found"}, status=status.HTTP_404_NOT_FOUND
            )
        reason = request.data.get('reason')
        valid = [c[0] for c in ProfileReport.REPORT_REASONS]
        if reason not in valid:
            return Response(
                {"error": "Invalid report reason"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        report, created = ProfileReport.objects.get_or_create(
            reporter=request.user,
            reported_user=reported,
            reason=reason,
            defaults={'description': request.data.get('description', '')},
        )
        if created:
            return Response(
                {"message": "Profile reported. Our team will review it."},
                status=status.HTTP_201_CREATED,
            )
        return Response(
            {"message": "You have already reported this profile."},
            status=status.HTTP_200_OK,
        )


class UserHiddenPostsView(generics.ListAPIView):
    """View to list all posts hidden by the user"""
    permission_classes = [IsAuthenticated]
    serializer_class = BusinessNetworkPostSerializer
    pagination_class = StandardResultsSetPagination

    def get_queryset(self):
        hidden_post_ids = HiddenPost.objects.filter(
            user=self.request.user
        ).values_list('post_id', flat=True)
        
        return BusinessNetworkPost.objects.filter(
            id__in=hidden_post_ids
        ).order_by('-created_at')


# ── Content Monetization ────────────────────────────────────────────────────


def _monetization_stats(user):
    """Followers, total content views, and video/photo post counts."""
    from .models import (
        BusinessNetworkFollowerModel,
        BusinessNetworkMedia,
        BusinessNetworkPost,
    )

    followers = BusinessNetworkFollowerModel.objects.filter(following=user).count()
    views = (
        BusinessNetworkMedia.objects.filter(
            business_network_posts__author=user
        ).aggregate(total=Sum("views"))["total"]
        or 0
    )
    video_posts = (
        BusinessNetworkPost.objects.filter(author=user, media__type="video")
        .distinct()
        .count()
    )
    image_posts = (
        BusinessNetworkPost.objects.filter(author=user, media__type="image")
        .distinct()
        .count()
    )
    return {
        "followers": followers,
        "views": views,
        "video_posts": video_posts,
        "image_posts": image_posts,
    }


def _monetization_requirements(user):
    """The bar this user must clear: global settings, with any per-user
    custom override taking precedence field by field."""
    from .models import (
        ContentMonetizationCustomRequirement,
        ContentMonetizationSettings,
    )

    conf = ContentMonetizationSettings.current()
    req = {
        "followers": conf.required_followers,
        "views": conf.required_views,
        "video_posts": conf.required_video_posts,
        "image_posts": conf.required_image_posts,
    }
    custom = ContentMonetizationCustomRequirement.objects.filter(user=user).first()
    if custom:
        if custom.required_followers is not None:
            req["followers"] = custom.required_followers
        if custom.required_views is not None:
            req["views"] = custom.required_views
        if custom.required_video_posts is not None:
            req["video_posts"] = custom.required_video_posts
        if custom.required_image_posts is not None:
            req["image_posts"] = custom.required_image_posts
    return req


class ContentMonetizationStatusView(APIView):
    """Progress toward monetization + the state of any existing application."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        from .models import ContentMonetizationApplication

        stats = _monetization_stats(request.user)
        req = _monetization_requirements(request.user)
        app = ContentMonetizationApplication.objects.filter(
            user=request.user
        ).first()
        return Response(
            {
                "followers": stats["followers"],
                "views": stats["views"],
                "video_posts": stats["video_posts"],
                "image_posts": stats["image_posts"],
                "required_followers": req["followers"],
                "required_views": req["views"],
                "required_video_posts": req["video_posts"],
                "required_image_posts": req["image_posts"],
                "eligible": all(stats[k] >= req[k] for k in req),
                "applied": app is not None,
                "application_status": app.status if app else None,
                "applied_at": app.created_at if app else None,
            }
        )


class ContentMonetizationApplyView(APIView):
    """Create a monetization application (requires accepted terms + met bar)."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        from .models import ContentMonetizationApplication

        if ContentMonetizationApplication.objects.filter(user=request.user).exists():
            return Response(
                {"error": "You have already applied for content monetization."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if not request.data.get("terms_accepted"):
            return Response(
                {
                    "error": "You must accept the Terms & Community Guidelines to apply."
                },
                status=status.HTTP_400_BAD_REQUEST,
            )
        stats = _monetization_stats(request.user)
        req = _monetization_requirements(request.user)
        if any(stats[k] < req[k] for k in req):
            return Response(
                {
                    "error": (
                        "Not eligible yet — you need "
                        f"{req['followers']} followers, {req['views']} views, "
                        f"{req['video_posts']} video posts and "
                        f"{req['image_posts']} photo posts."
                    ),
                    **stats,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )
        app = ContentMonetizationApplication.objects.create(
            user=request.user,
            followers_at_apply=stats["followers"],
            views_at_apply=stats["views"],
            video_posts_at_apply=stats["video_posts"],
            image_posts_at_apply=stats["image_posts"],
            terms_accepted=True,
        )
        return Response(
            {
                "message": "Application submitted — we'll review it shortly.",
                "application_status": app.status,
                "applied_at": app.created_at,
            },
            status=status.HTTP_201_CREATED,
        )


class ContentMonetizationEarningsView(APIView):
    """Approved creator's earnings: live points for the current month, the
    stored pool share (refreshed by the daily compute job) and history."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        from .models import (
            ContentMonetizationApplication,
            ContentMonetizationSettings,
            CreatorMonthlyEarning,
        )
        from .monetization import (
            creator_content_breakdown,
            creator_points,
            current_period,
            period_bounds,
        )

        app = ContentMonetizationApplication.objects.filter(
            user=request.user, status="approved"
        ).first()
        if app is None:
            return Response(
                {"error": "Monetization is not active on this account."},
                status=status.HTTP_403_FORBIDDEN,
            )

        from datetime import timedelta

        conf = ContentMonetizationSettings.current()
        period = current_period()
        start, end = period_bounds(period)
        # Month close + holdback review window = when cleared earnings pay out.
        expected_payout = (end + timedelta(days=conf.holdback_days)).date()

        # Live personal points (cheap: only this creator's rows this month).
        # Fraud-signal internals stay server-side.
        points = creator_points(request.user, start, end, conf)
        points.pop("top10_share", None)
        points.pop("young_share", None)

        # Pool share comes from the stored row the daily job refreshes —
        # computing every creator's points on-request would be too heavy.
        row = CreatorMonthlyEarning.objects.filter(
            user=request.user, period=period
        ).first()

        # Per-content breakdown + daily views for the analytics section.
        breakdown = creator_content_breakdown(request.user, start, end, conf)
        # Attribute the stored month amount across content by point share so
        # the user sees roughly which content earned what.
        from decimal import Decimal

        my_points = points.get("total_points") or 0
        amount = row.amount if row else None
        for c in breakdown["top_content"]:
            if amount is not None and my_points > 0:
                share = (amount * c["points"] / my_points).quantize(
                    Decimal("0.01")
                )
                c["estimated_amount"] = str(share)
            else:
                c["estimated_amount"] = None

        history = [
            {
                "period": e.period,
                "valid_views": e.valid_views,
                "likes": e.likes,
                "comments": e.comments,
                "followers_gained": e.followers_gained,
                "total_points": e.total_points,
                "amount": str(e.amount),
                "status": e.status,
            }
            for e in CreatorMonthlyEarning.objects.filter(
                user=request.user
            ).exclude(period=period)[:12]
        ]

        return Response(
            {
                "period": period,
                "points": points,
                "weights": {
                    "view": conf.point_view,
                    "like": conf.point_like,
                    "comment": conf.point_comment,
                    "follower": conf.point_follower,
                },
                "pool_amount": str(conf.monthly_pool_amount),
                "estimated_amount": str(row.amount) if row else None,
                "current_status": row.status if row else "accruing",
                "fraud_flagged": bool(row and row.status == "held"),
                "min_payout": str(conf.min_payout),
                "holdback_days": conf.holdback_days,
                "expected_payout_date": expected_payout.strftime("%d-%m-%Y"),
                "top_content": breakdown["top_content"],
                "daily_views": breakdown["daily_views"],
                "history": history,
            }
        )
