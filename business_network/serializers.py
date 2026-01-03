from rest_framework import serializers

from base.serializers import UserSerializer

from .models import *


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
        author_data = UserSerializer(obj.author).data
        
        # Add follow status if request user is authenticated
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            is_following = BusinessNetworkFollowerModel.objects.filter(
                follower=request.user, following=obj.author
            ).exists()
            author_data["isFollowing"] = is_following
        else:
            author_data["isFollowing"] = False
        
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
        user_data = UserSerializer(obj.user).data

        # Add follow status if request user is authenticated
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            is_following = BusinessNetworkFollowerModel.objects.filter(
                follower=request.user, following=obj.user
            ).exists()
            user_data["isFollowing"] = is_following
        else:
            user_data["isFollowing"] = False

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
        author_data = UserSerializer(obj.author).data
        
        # Add follow status if request user is authenticated
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            is_following = BusinessNetworkFollowerModel.objects.filter(
                follower=request.user, following=obj.author
            ).exists()
            author_data["isFollowing"] = is_following
        else:
            author_data["isFollowing"] = False
        
        return author_data

    def get_post_comments(self, obj):
        """Get post comments with context for follow status"""
        return BusinessNetworkPostCommentSerializer(
            obj.post_comments.all(), many=True, context=self.context
        ).data

    def get_post_likes(self, obj):
        # Return all likes without artificial device-based limitations
        request = self.context.get("request")
        device_level = (
            getattr(request, "query_params", {}).get("device_level", "medium")
            if request
            else "medium"
        )

        if device_level == "low":
            return []  # No detailed likes for low-end devices to save bandwidth
        else:
            # Return all likes for medium and high-end devices
            return BusinessNetworkPostLikeSerializer(
                obj.post_likes.all(), many=True, context=self.context
            ).data

    def get_like_count(self, obj):
        return obj.post_likes.count()

    def get_comment_count(self, obj):
        return obj.post_comments.count()

    def get_follower_count(self, obj):
        return obj.post_followers.count()
    
    def get_is_liked(self, obj):
        """Check if the current user has liked this post"""
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            return obj.post_likes.filter(user=request.user).exists()
        return False
    
    def get_is_saved(self, obj):
        """Check if the current user has saved this post"""
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            from .models import UserSavedPosts
            return UserSavedPosts.objects.filter(user=request.user, post=obj).exists()
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
