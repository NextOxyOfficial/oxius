from rest_framework import serializers

from base.serializers import UserSerializer, viewer_relation_sets

from .models import *


def _is_following(context, user_id):
    """Follow status from the request-scoped relation sets (1 query per
    request) instead of one EXISTS query per serialized author/liker."""
    request = context.get("request") if context else None
    rel = viewer_relation_sets(request)
    return user_id in rel["following"] if rel is not None else False


class BusinessNetworkPostTagSerializer(serializers.ModelSerializer):
    class Meta:
        model = BusinessNetworkPostTag
        fields = "__all__"
        read_only_fields = ["id", "created_at"]


class BusinessNetworkPostCommentSerializer(serializers.ModelSerializer):
    author_details = serializers.SerializerMethodField()
    formatted_content = serializers.SerializerMethodField()

    class Meta:
        model = BusinessNetworkPostComment
        fields = [
            "id",
            "post",
            "author",
            "author_details",
            "parent_comment",
            "content",
            "formatted_content",
            "created_at",
            "updated_at",
            "is_gift_comment",
            "diamond_amount",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def get_author_details(self, obj):
        """Get author details with follow status"""
        # Pass the context so UserSerializer's per-request memo kicks in —
        # the same author across many comments costs one stats lookup, not N.
        author_data = UserSerializer(obj.author, context=self.context).data
        author_data["isFollowing"] = _is_following(self.context, obj.author_id)
        return author_data

    def get_formatted_content(self, obj):
        if obj.is_gift_comment and obj.diamond_amount > 0:
            # Create fancy gift message with emojis and styling
            diamond_count = obj.diamond_amount
            message = (
                obj.content.strip()
                if obj.content
                else f"Sent a gift of {diamond_count} diamonds!"
            )

            # Create a fancy formatted message with sparkles and diamonds
            formatted_message = f"✨💎 {message} [{diamond_count} 💎] ✨"

            # For larger gifts, add more embellishment
            if diamond_count >= 100:
                formatted_message = f"🌟🎁 {message} [{diamond_count} 💎💎💎] 🎁🌟"
            elif diamond_count >= 50:
                formatted_message = f"🎁✨ {message} [{diamond_count} 💎💎] ✨🎁"

            return formatted_message
        return obj.content


class BusinessNetworkMediaLikeSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source="user", read_only=True)

    class Meta:
        model = BusinessNetworkMediaLike
        fields = "__all__"
        read_only_fields = ["id", "created_at"]


class BusinessNetworkMediaCommentSerializer(serializers.ModelSerializer):
    author_details = UserSerializer(source="author", read_only=True)

    class Meta:
        model = BusinessNetworkMediaComment
        fields = "__all__"
        read_only_fields = ["id", "created_at", "updated_at"]


class BusinessNetworkMediaSerializer(serializers.ModelSerializer):
    media_likes = BusinessNetworkMediaLikeSerializer(many=True, read_only=True)
    media_comments = BusinessNetworkMediaCommentSerializer(many=True, read_only=True)

    def to_representation(self, instance):
        try:
            if getattr(instance, "type", None) == "video" and not getattr(instance, "thumbnail", None):
                ensure = getattr(instance, "ensure_thumbnail", None)
                if callable(ensure):
                    ensure()
        except Exception:
            pass
        return super().to_representation(instance)

    class Meta:
        model = BusinessNetworkMedia
        fields = "__all__"
        read_only_fields = ["id", "created_at", "views"]


class BusinessNetworkPostLikeSerializer(serializers.ModelSerializer):
    user_details = serializers.SerializerMethodField()

    class Meta:
        model = BusinessNetworkPostLike
        fields = ["id", "post", "user", "user_details", "created_at"]
        read_only_fields = ["id", "created_at"]

    def get_user_details(self, obj):
        user_data = UserSerializer(obj.user, context=self.context).data
        user_data["isFollowing"] = _is_following(self.context, obj.user_id)
        return user_data


class BusinessNetworkPostFollowSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source="user", read_only=True)

    class Meta:
        model = BusinessNetworkPostFollow
        fields = ["id", "post", "user", "user_details", "created_at"]
        read_only_fields = ["id", "created_at"]


class BusinessNetworkPostSerializer(serializers.ModelSerializer):
    author_details = serializers.SerializerMethodField()
    post_media = BusinessNetworkMediaSerializer(
        source="media", many=True, read_only=True
    )
    post_likes = serializers.SerializerMethodField()
    post_comments = serializers.SerializerMethodField()
    post_tags = BusinessNetworkPostTagSerializer(
        many=True, read_only=True, source="tags"
    )
    post_followers = BusinessNetworkPostFollowSerializer(many=True, read_only=True)
    like_count = serializers.SerializerMethodField()
    comment_count = serializers.SerializerMethodField()
    follower_count = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()
    is_saved = serializers.SerializerMethodField()

    class Meta:
        model = BusinessNetworkPost
        fields = [
            "id",
            "slug",
            "author",
            "author_details",
            "title",
            "content",
            "visibility",
            "created_at",
            "updated_at",
            "post_media",
            "post_likes",
            "post_comments",
            "post_tags",
            "post_followers",
            "like_count",
            "comment_count",
            "follower_count",
            "is_liked",
            "is_saved",
        ]
        read_only_fields = ["id", "slug", "created_at", "updated_at"]

    def get_author_details(self, obj):
        """Get author details with follow status"""
        author_data = UserSerializer(obj.author, context=self.context).data
        author_data["isFollowing"] = _is_following(self.context, obj.author_id)
        return author_data

    # In the feed/list, popular posts would otherwise ship EVERY comment and
    # EVERY like inline — hundreds of KB per post. The app only needs a small
    # comment preview there (full list + all likers load on the post-detail
    # screen), and it derives like state from is_liked/like_count, not the
    # array. So we cap in list responses and only send everything when a view
    # explicitly asks via context {"full_detail": True}.
    FEED_COMMENT_PREVIEW = 6

    def get_post_comments(self, obj):
        """Post comments — capped in the feed, full on the detail screen."""
        qs = obj.post_comments.all()
        if not self.context.get("full_detail"):
            qs = qs[: self.FEED_COMMENT_PREVIEW]
        return BusinessNetworkPostCommentSerializer(
            qs, many=True, context=self.context
        ).data

    def get_post_likes(self, obj):
        # Only the detail screen needs the full liker list; the feed uses
        # like_count + is_liked, so skip the array there to shrink the payload.
        if not self.context.get("full_detail"):
            return []
        return BusinessNetworkPostLikeSerializer(
            obj.post_likes.all(), many=True, context=self.context
        ).data

    # Counts reuse the view's prefetch_related cache when present (feed lists
    # prefetch these relations), so a 20-post page costs 0 extra COUNT
    # queries; detail views without a prefetch still fall back to COUNT.
    def _prefetched(self, obj, name):
        cache = getattr(obj, "_prefetched_objects_cache", None)
        return cache.get(name) if cache else None

    def get_like_count(self, obj):
        likes = self._prefetched(obj, "post_likes")
        return len(likes) if likes is not None else obj.post_likes.count()

    def get_comment_count(self, obj):
        comments = self._prefetched(obj, "post_comments")
        return len(comments) if comments is not None else obj.post_comments.count()

    def get_follower_count(self, obj):
        followers = self._prefetched(obj, "post_followers")
        return (
            len(followers) if followers is not None else obj.post_followers.count()
        )

    def get_is_liked(self, obj):
        """Check if the current user has liked this post"""
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            likes = self._prefetched(obj, "post_likes")
            if likes is not None:
                return any(like.user_id == request.user.id for like in likes)
            return obj.post_likes.filter(user=request.user).exists()
        return False

    def get_is_saved(self, obj):
        """Check if the current user has saved this post — answered from a
        per-request set of saved post ids (1 query per request, not per post)."""
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            saved = getattr(request, "_bn_saved_post_ids", None)
            if saved is None:
                from .models import UserSavedPosts

                saved = set(
                    UserSavedPosts.objects.filter(user=request.user).values_list(
                        "post_id", flat=True
                    )
                )
                request._bn_saved_post_ids = saved
            return obj.id in saved
        return False


class BusinessNetworkWorkspaceSerializer(serializers.ModelSerializer):
    class Meta:
        model = BusinessNetworkWorkspace
        fields = "__all__"
        read_only_fields = ["id", "created_at"]


class BusinessNetworkFollowerSerializer(serializers.ModelSerializer):
    follower_details = UserSerializer(source="follower", read_only=True)
    following_details = UserSerializer(source="following", read_only=True)

    class Meta:
        model = BusinessNetworkFollowerModel
        fields = "__all__"
        read_only_fields = ["id", "created_at"]


class AbnAdsPanelCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = AbnAdsPanelCategory
        fields = "__all__"
        read_only_fields = ["id", "created_at"]


class AbnAdsPanelMediaSerializer(serializers.ModelSerializer):
    class Meta:
        model = AbnAdsPanelMedia
        fields = "__all__"
        read_only_fields = ["id", "created_at"]


class AbnAdsPanelSerializer(serializers.ModelSerializer):
    media = AbnAdsPanelMediaSerializer(many=True, read_only=True)
    user_details = UserSerializer(source="user", read_only=True)
    category_details = AbnAdsPanelCategorySerializer(source="category", read_only=True)

    class Meta:
        model = AbnAdsPanel
        fields = "__all__"
        read_only_fields = ["id", "created_at", "updated_at"]


class BusinessNetworkMindforceCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = BusinessNetworkMindforceCategory
        fields = "__all__"
        read_only_fields = ["id", "created_at"]


class BusinessNetworkMindforceMediaSerializer(serializers.ModelSerializer):
    class Meta:
        model = BusinessNetworkMindforceMedia
        fields = "__all__"
        read_only_fields = ["id", "created_at"]


class BusinessNetworkMindforceCommentMediaSerializer(serializers.ModelSerializer):
    class Meta:
        model = BusinessNetworkMindforceCommentMedia
        fields = "__all__"


class BusinessNetworkMindforceCommentSerializer(serializers.ModelSerializer):
    author_details = UserSerializer(source="author", read_only=True)
    media = BusinessNetworkMindforceCommentMediaSerializer(many=True, read_only=True)

    class Meta:
        model = BusinessNetworkMindforceComment
        fields = [
            "id",
            "mindforce_problem",
            "author",
            "author_details",
            "content",
            "media",
            "is_solved",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at"]


class BusinessNetworkMindforceSerializer(serializers.ModelSerializer):
    media = BusinessNetworkMindforceMediaSerializer(many=True, read_only=True)
    user_details = UserSerializer(source="user", read_only=True)
    category_details = BusinessNetworkMindforceCategorySerializer(
        source="category", read_only=True
    )
    mindforce_comments = BusinessNetworkMindforceCommentSerializer(
        many=True, read_only=True
    )

    class Meta:
        model = BusinessNetworkMindforce
        fields = "__all__"
        read_only_fields = ["id", "created_at"]


class UserSavedPostSerializer(serializers.ModelSerializer):
    post_details = BusinessNetworkPostSerializer(source="post", read_only=True)

    class Meta:
        model = UserSavedPosts
        fields = "__all__"
        read_only_fields = ["id", "created_at"]


class FrequentTagSerializer(serializers.Serializer):
    id = serializers.CharField()
    tag = serializers.CharField()
    count = serializers.IntegerField()


class UserMinimalSerializer(serializers.ModelSerializer):
    """Minimal user information for notifications"""

    class Meta:
        model = User
        fields = ("id", "name", "image", "kyc")


class BusinessNetworkNotificationSerializer(serializers.ModelSerializer):
    """Serializer for business network notifications"""

    actor = UserMinimalSerializer(read_only=True)

    class Meta:
        model = BusinessNetworkNotification
        fields = (
            "id",
            "actor",
            "type",
            "read",
            "target_id",
            "parent_id",
            "content",
            "created_at",
        )
