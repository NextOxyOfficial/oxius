import base64

from django.core.files.base import ContentFile
from django.db.models import Case, Count, IntegerField, Q, Subquery, Value, When
from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.decorators import api_view
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from base.models import User

from .models import *
from .pagination import *
from .serializers import *


def base64ToFile(base64_data):
    # Remove the prefix if it exists (e.g., "data:image/png;base64,")
    if base64_data.startswith("data:image"):
        base64_data = base64_data.split("base64,")[1]

    # Decode the Base64 string into bytes
    file_data = base64.b64decode(base64_data)

    # Create a Django ContentFile object from the bytes
    file = ContentFile(file_data)

    # You can create a filename, e.g., using the current timestamp or other logic
    filename = "uploaded_image.png"  # Customize as needed

    # Save the file to the appropriate storage (e.g., media directory)
    file.name = filename
    return file


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

        # Normalize query for better matching
        normalized_query = query.strip()

        # Remove hashtag for user search if present
        if normalized_query.startswith("#"):
            normalized_query = normalized_query[1:]

        if not normalized_query:  # If query was just a # symbol
            return User.objects.none()

        # Enhanced user search with better prioritization

        # 1. Exact username matches (highest priority)
        exact_username_match = User.objects.filter(
            username__iexact=normalized_query
        ).exclude(is_superuser=True)

        # 2. Full name exact matches (first + last name combined)
        # Split the query into parts to check against first and last name combinations
        name_parts = normalized_query.split()
        full_name_query = Q()

        # Exact full name match
        full_name_query |= Q(first_name__iexact=normalized_query) | Q(
            last_name__iexact=normalized_query
        )

        # Handle when the search query consists of multiple words (first and last name)
        if len(name_parts) > 1:
            # Check for the complete query in both first_name and last_name fields
            full_name_query |= Q(first_name__icontains=normalized_query) | Q(
                last_name__icontains=normalized_query
            )

            # Try matching full name exactly in format "first last"
            # This helps when searching for "Md Alimul Islam"
            first_name_contains = Q()
            last_name_contains = Q()

            # Try different combinations of the name parts
            for i in range(1, len(name_parts)):
                first_part = " ".join(name_parts[:i])
                last_part = " ".join(name_parts[i:])

                # Match where first part is first_name and second part is last_name
                full_name_query |= Q(first_name__iexact=first_part) & Q(
                    last_name__iexact=last_part
                )

                # Also check for partial matches within first and last name
                full_name_query |= Q(first_name__icontains=first_part) & Q(
                    last_name__icontains=last_part
                )

                # Individual name part matching
                for part in name_parts:
                    first_name_contains |= Q(first_name__icontains=part)
                    last_name_contains |= Q(last_name__icontains=part)

            # Add individual name part matches as a lower priority
            full_name_query |= first_name_contains & last_name_contains

        full_name_matches = User.objects.filter(full_name_query).exclude(
            is_superuser=True
        )

        # 3. Username starts with query
        username_starts_with = (
            User.objects.filter(username__istartswith=normalized_query)
            .exclude(
                username__iexact=normalized_query  # Exclude exact matches to avoid duplicates
            )
            .exclude(is_superuser=True)
        )

        # 4. First or last name starts with query
        name_starts_with = (
            User.objects.filter(
                Q(first_name__istartswith=normalized_query)
                | Q(last_name__istartswith=normalized_query)
            )
            .exclude(
                Q(first_name__iexact=normalized_query)
                | Q(last_name__iexact=normalized_query)
            )
            .exclude(is_superuser=True)
        )

        # 5. Contains matches for username or name (lowest priority)
        partial_matches = (
            User.objects.filter(
                Q(username__icontains=normalized_query)
                | Q(first_name__icontains=normalized_query)
                | Q(last_name__icontains=normalized_query)
                | Q(email__icontains=normalized_query)
            )
            .exclude(
                # Exclude all previous matches to avoid duplicates
                Q(username__iexact=normalized_query)
                | Q(username__istartswith=normalized_query)
                | Q(first_name__iexact=normalized_query)
                | Q(first_name__istartswith=normalized_query)
                | Q(last_name__iexact=normalized_query)
                | Q(last_name__istartswith=normalized_query)
                | Q(
                    id__in=[user.id for user in list(full_name_matches)]
                )  # Exclude full name matches
            )
            .exclude(is_superuser=True)
        )

        # Combine all matches with priority ordering
        combined_results = (
            list(exact_username_match)
            + list(full_name_matches)
            + list(username_starts_with)
            + list(name_starts_with)
            + list(partial_matches)
        )

        # Return combined and deduplicated results
        return combined_results


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

    def get_queryset(self):
        """
        Optimized prioritized post feed logic for medium devices:
        """
        if not self.request.user.is_authenticated:
            # For unauthenticated users, show recent posts with minimal data
            return BusinessNetworkPost.objects.select_related("author").order_by(
                "-created_at"
            )

        user = self.request.user

        # Check for device-specific optimization
        device_level = self.request.query_params.get("device_level", "medium")

        if device_level == "low":
            # Ultra-simplified query for low-end devices
            return (
                BusinessNetworkPost.objects.annotate(
                    like_count=Count("post_likes"), comment_count=Count("post_comments")
                )
                .select_related("author")
                .order_by("-created_at")
            )

        # Cache frequently used subqueries for better performance
        from django.core.cache import cache

        cache_key = f"user_feed_relationships_{user.id}"
        cached_data = cache.get(cache_key)

        if not cached_data:
            # Pre-calculate relationships
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

            cached_data = {"following": users_following, "followers": users_followers}
            cache.set(cache_key, cached_data, 300)  # Cache for 5 minutes

        users_following = cached_data["following"]
        users_followers = cached_data["followers"]

        # Simplified priority logic for better performance
        from datetime import timedelta

        from django.utils import timezone

        recent_threshold = timezone.now() - timedelta(hours=24)

        queryset = (
            BusinessNetworkPost.objects.annotate(
                # Simplified priority with fewer database operations
                priority=Case(
                    When(author=user, created_at__gte=recent_threshold, then=Value(1)),
                    When(author_id__in=users_following, then=Value(2)),
                    When(author_id__in=users_followers, then=Value(3)),
                    default=Value(4),
                    output_field=IntegerField(),
                ),
                # Pre-calculate counts to avoid N+1 queries
                like_count=Count("post_likes", distinct=True),
                comment_count=Count("post_comments", distinct=True),
                follower_count=Count("post_followers", distinct=True),
            )
            .select_related(
                "author"  # Optimize author queries
            )
            .prefetch_related(
                # Limited prefetch for better performance
                "media__media_likes__user",
                "tags",
                "post_likes__user",
                "post_comments__author",
            )
            .order_by("priority", "-created_at")
        )

        return queryset

    def create(self, request, *args, **kwargs):
        images_data = request.data.pop("images", None)
        tags_data = request.data.pop("tags", None)
        serializer = self.get_serializer(
            data={
                "title": request.data["title"],
                "content": request.data["content"],
                "author": request.user.id,
            }
        )

        serializer.is_valid(raise_exception=True)
        post = serializer.save()

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
                        post_media = BusinessNetworkMedia.objects.create(
                            image=image_file
                        )
                        post.media.add(post_media)
                except Exception as e:
                    # Log error but continue processing
                    print(f"Error processing image: {str(e)}")

        if tags_data:
            if tags_data and isinstance(tags_data, list):
                for tag_data in tags_data:
                    tag, _ = BusinessNetworkPostTag.objects.get_or_create(tag=tag_data)
                    post.tags.add(tag)

        headers = self.get_success_headers(serializer.data)
        return Response(
            serializer.data, status=status.HTTP_201_CREATED, headers=headers
        )


class BusinessNetworkPostRetrieveUpdateDestroyView(
    generics.RetrieveUpdateDestroyAPIView
):
    queryset = BusinessNetworkPost.objects.all()
    serializer_class = BusinessNetworkPostSerializer
    lookup_field = "id"

    def get_permissions(self):
        if self.request.method == "GET":
            return []
        else:
            return [IsAuthenticated()]

    def perform_update(self, serializer):
        # Only allow the author to update the post
        if serializer.instance.author == self.request.user:
            serializer.save()
        else:
            return Response(
                {"detail": "You do not have permission to edit this post."},
                status=status.HTTP_403_FORBIDDEN,
            )

    def perform_destroy(self, instance):
        # Only allow the author to delete the post
        if instance.author == self.request.user:
            instance.delete()
        else:
            return Response(
                {"detail": "You do not have permission to delete this post."},
                status=status.HTTP_403_FORBIDDEN,
            )


class UserPostsListView(generics.ListAPIView):
    serializer_class = BusinessNetworkPostSerializer
    pagination_class = StandardResultsSetPagination
    # permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user_id = self.kwargs.get("user_id")
        return BusinessNetworkPost.objects.filter(author__id=user_id).order_by(
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
        # Only allow the post author to delete media
        if instance.post.author == self.request.user:
            instance.delete()
        else:
            return Response(
                {"detail": "You do not have permission to delete this media."},
                status=status.HTTP_403_FORBIDDEN,
            )


# Like Views
class BusinessNetworkPostLikeCreateView(generics.ListCreateAPIView):
    serializer_class = BusinessNetworkPostLikeSerializer
    pagination_class = StandardResultsSetPagination
    # permission_classes = [IsAuthenticated]

    def get_queryset(self):
        post_id = self.kwargs.get("post_id")
        if post_id:
            return BusinessNetworkPostLike.objects.filter(post_id=post_id)
        return BusinessNetworkPostLike.objects.none()

    def create(self, request, *args, **kwargs):
        post_id = kwargs.get("post_id")
        post = get_object_or_404(BusinessNetworkPost, pk=post_id)

        # Check if user has already liked the post
        if BusinessNetworkPostLike.objects.filter(
            post=post, user=request.user
        ).exists():
            return Response(
                {"detail": "You have already liked this post."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        like = BusinessNetworkPostLike(post=post, user=request.user)
        like.save()
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
        # Only allow comment author to update
        if serializer.instance.author == self.request.user:
            serializer.save()
        else:
            return Response(
                {"detail": "You do not have permission to edit this comment."},
                status=status.HTTP_403_FORBIDDEN,
            )

    def perform_destroy(self, instance):
        # Allow comment author or post author to delete
        if (
            instance.author == self.request.user
            or instance.post.author == self.request.user
        ):
            instance.delete()
        else:
            return Response(
                {"detail": "You do not have permission to delete this comment."},
                status=status.HTTP_403_FORBIDDEN,
            )


# Tag Views
class BusinessNetworkPostTagListCreateView(generics.ListCreateAPIView):
    queryset = BusinessNetworkPostTag.objects.all()
    serializer_class = BusinessNetworkPostTagSerializer


class BusinessNetworkPostTagDestroyView(generics.DestroyAPIView):
    queryset = BusinessNetworkPostTag.objects.all()
    permission_classes = [IsAuthenticated]

    def perform_destroy(self, instance):
        # Only post author can delete tags
        if instance.post.author == self.request.user:
            instance.delete()
        else:
            return Response(
                {"detail": "Only the post author can delete tags."},
                status=status.HTTP_403_FORBIDDEN,
            )


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
        serializer = self.get_serializer(
            data={"follower": request.user.id, "following": self.kwargs.get("user_id")}
        )

        if not serializer.is_valid():
            print(serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        self.perform_create(serializer)
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
        # Only allow comment author to update
        if serializer.instance.author == self.request.user:
            serializer.save()
        else:
            return Response(
                {"detail": "You do not have permission to edit this comment."},
                status=status.HTTP_403_FORBIDDEN,
            )

    def perform_destroy(self, instance):
        # Allow comment author or media author to delete
        if (
            instance.author == self.request.user
            or instance.media.author == self.request.user
        ):
            instance.delete()
        else:
            return Response(
                {"detail": "You do not have permission to delete this comment."},
                status=status.HTTP_403_FORBIDDEN,
            )


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
        data = request.data
        data["user"] = request.user.id
        serializer = self.get_serializer(data=data)

        try:
            serializer.is_valid(raise_exception=True)
        except ValidationError as e:
            print(serializer.errors)  # Print validation errors
            raise e
        abn_ads = serializer.save()

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

    def perform_update(self, serializer):
        serializer.save()

    def perform_destroy(self, instance):
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
        images_data = request.data.pop("images", None)
        data = request.data
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
    permission_classes = [IsAuthenticated]
    lookup_field = "id"


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
        """Return notifications for the current user"""
        return BusinessNetworkNotification.objects.filter(recipient=self.request.user)


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


class BusinessNetworkPostListCreateView(generics.ListCreateAPIView):
    serializer_class = BusinessNetworkPostSerializer
    pagination_class = StandardResultsSetPagination
    # permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """
        Optimized prioritized post feed logic:
        1. Posts from users I'm following (Priority 1 - highest)
        2. Posts from followers of users I'm following (Priority 2)
        3. Posts from users who are following me (Priority 3)
        4. Posts from users that my followings are following (Priority 4)
        5. Random posts from users in nearby cities (Priority 5 - lowest)
        """
        if not self.request.user.is_authenticated:
            # For unauthenticated users, show recent posts
            return BusinessNetworkPost.objects.all().order_by("-created_at")

        user = self.request.user

        # Use subqueries for better performance
        users_i_follow_subquery = BusinessNetworkFollowerModel.objects.filter(
            follower=user
        ).values("following_id")

        my_followers_subquery = BusinessNetworkFollowerModel.objects.filter(
            following=user
        ).values("follower_id")

        followers_of_my_followings_subquery = (
            BusinessNetworkFollowerModel.objects.filter(
                following_id__in=Subquery(users_i_follow_subquery)
            ).values("follower_id")
        )

        followings_of_my_followings_subquery = (
            BusinessNetworkFollowerModel.objects.filter(
                follower_id__in=Subquery(users_i_follow_subquery)
            ).values("following_id")
        )

        # Build nearby users subquery
        nearby_users_conditions = Q()
        if user.city:
            # Users from the same city
            nearby_users_conditions |= Q(city__iexact=user.city)

            # Users from the same state/division if different from city
            if user.state and user.state != user.city:
                nearby_users_conditions |= Q(state__iexact=user.state)

        nearby_users_subquery = (
            User.objects.filter(nearby_users_conditions)
            .exclude(id=user.id)
            .values("id")
        )

        # Create prioritized queryset with optimized CASE WHEN
        # Only prioritize user's own posts from the last 24 hours to maintain feed freshness
        from datetime import timedelta

        from django.utils import timezone

        recent_threshold = timezone.now() - timedelta(hours=24)

        queryset = (
            BusinessNetworkPost.objects.annotate(
                priority=Case(
                    # Priority 1: User's own recent posts (last 24 hours only)
                    When(author=user, created_at__gte=recent_threshold, then=Value(1)),
                    # Priority 2: Posts from users I'm following
                    When(
                        author_id__in=Subquery(users_i_follow_subquery), then=Value(2)
                    ),
                    # Priority 3: Posts from followers of users I'm following
                    When(
                        author_id__in=Subquery(followers_of_my_followings_subquery),
                        then=Value(3),
                    ),
                    # Priority 4: Posts from users who are following me
                    When(author_id__in=Subquery(my_followers_subquery), then=Value(4)),
                    # Priority 5: Posts from users that my followings are following
                    When(
                        author_id__in=Subquery(followings_of_my_followings_subquery),
                        then=Value(5),
                    ),
                    # Priority 6: Posts from users in nearby cities
                    When(author_id__in=Subquery(nearby_users_subquery), then=Value(6)),
                    # Priority 7: Other posts (including user's older posts)
                    default=Value(7),
                    output_field=IntegerField(),
                )
            )
            .select_related(
                "author"  # Optimize author queries
            )
            .prefetch_related(
                "media",
                "tags",
                "post_likes",
                "post_comments",  # Optimize related data
            )
            .order_by(
                "priority",  # First by priority (1-7, where 1 is highest)
                "-created_at",  # Then by newest within each priority level
            )
        )

        return queryset

    def create(self, request, *args, **kwargs):
        images_data = request.data.pop("images", None)
        tags_data = request.data.pop("tags", None)
        serializer = self.get_serializer(
            data={
                "title": request.data["title"],
                "content": request.data["content"],
                "author": request.user.id,
            }
        )

        serializer.is_valid(raise_exception=True)
        post = serializer.save()

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
                        post_media = BusinessNetworkMedia.objects.create(
                            image=image_file
                        )
                        post.media.add(post_media)
                except Exception as e:
                    # Log error but continue processing
                    print(f"Error processing image: {str(e)}")

        if tags_data:
            if tags_data and isinstance(tags_data, list):
                for tag_data in tags_data:
                    tag, _ = BusinessNetworkPostTag.objects.get_or_create(tag=tag_data)
                    post.tags.add(tag)

        headers = self.get_success_headers(serializer.data)
        return Response(
            serializer.data, status=status.HTTP_201_CREATED, headers=headers
        )


class BusinessNetworkPostRetrieveUpdateDestroyView(
    generics.RetrieveUpdateDestroyAPIView
):
    queryset = BusinessNetworkPost.objects.all()
    serializer_class = BusinessNetworkPostSerializer
    lookup_field = "id"

    def get_permissions(self):
        if self.request.method == "GET":
            return []
        else:
            return [IsAuthenticated()]

    def perform_update(self, serializer):
        # Only allow the author to update the post
        if serializer.instance.author == self.request.user:
            serializer.save()
        else:
            return Response(
                {"detail": "You do not have permission to edit this post."},
                status=status.HTTP_403_FORBIDDEN,
            )

    def perform_destroy(self, instance):
        # Only allow the author to delete the post
        if instance.author == self.request.user:
            instance.delete()
        else:
            return Response(
                {"detail": "You do not have permission to delete this post."},
                status=status.HTTP_403_FORBIDDEN,
            )


class UserPostsListView(generics.ListAPIView):
    serializer_class = BusinessNetworkPostSerializer
    pagination_class = StandardResultsSetPagination
    # permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user_id = self.kwargs.get("user_id")
        return BusinessNetworkPost.objects.filter(author__id=user_id).order_by(
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
        # Only allow the post author to delete media
        if instance.post.author == self.request.user:
            instance.delete()
        else:
            return Response(
                {"detail": "You do not have permission to delete this media."},
                status=status.HTTP_403_FORBIDDEN,
            )


# Like Views
class BusinessNetworkPostLikeCreateView(generics.ListCreateAPIView):
    serializer_class = BusinessNetworkPostLikeSerializer
    pagination_class = StandardResultsSetPagination
    # permission_classes = [IsAuthenticated]

    def get_queryset(self):
        post_id = self.kwargs.get("post_id")
        if post_id:
            return BusinessNetworkPostLike.objects.filter(post_id=post_id)
        return BusinessNetworkPostLike.objects.none()

    def get_serializer_context(self):
        # Add request context for follow status in user details
        context = super().get_serializer_context()
        context["request"] = self.request
        return context

    def create(self, request, *args, **kwargs):
        post_id = kwargs.get("post_id")
        post = get_object_or_404(BusinessNetworkPost, pk=post_id)

        # Check if user has already liked the post
        if BusinessNetworkPostLike.objects.filter(
            post=post, user=request.user
        ).exists():
            return Response(
                {"detail": "You have already liked this post."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        like = BusinessNetworkPostLike(post=post, user=request.user)
        like.save()
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
        # Only allow comment author to update
        if serializer.instance.author == self.request.user:
            serializer.save()
        else:
            return Response(
                {"detail": "You do not have permission to edit this comment."},
                status=status.HTTP_403_FORBIDDEN,
            )

    def perform_destroy(self, instance):
        # Allow comment author or post author to delete
        if (
            instance.author == self.request.user
            or instance.post.author == self.request.user
        ):
            instance.delete()
        else:
            return Response(
                {"detail": "You do not have permission to delete this comment."},
                status=status.HTTP_403_FORBIDDEN,
            )


# Tag Views
class BusinessNetworkPostTagListCreateView(generics.ListCreateAPIView):
    queryset = BusinessNetworkPostTag.objects.all()
    serializer_class = BusinessNetworkPostTagSerializer


class BusinessNetworkPostTagDestroyView(generics.DestroyAPIView):
    queryset = BusinessNetworkPostTag.objects.all()
    permission_classes = [IsAuthenticated]

    def perform_destroy(self, instance):
        # Only post author can delete tags
        if instance.post.author == self.request.user:
            instance.delete()
        else:
            return Response(
                {"detail": "Only the post author can delete tags."},
                status=status.HTTP_403_FORBIDDEN,
            )


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
        serializer = self.get_serializer(
            data={"follower": request.user.id, "following": self.kwargs.get("user_id")}
        )

        if not serializer.is_valid():
            print(serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        self.perform_create(serializer)
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
        # Only allow comment author to update
        if serializer.instance.author == self.request.user:
            serializer.save()
        else:
            return Response(
                {"detail": "You do not have permission to edit this comment."},
                status=status.HTTP_403_FORBIDDEN,
            )

    def perform_destroy(self, instance):
        # Allow comment author or media author to delete
        if (
            instance.author == self.request.user
            or instance.media.author == self.request.user
        ):
            instance.delete()
        else:
            return Response(
                {"detail": "You do not have permission to delete this comment."},
                status=status.HTTP_403_FORBIDDEN,
            )


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
        data = request.data
        data["user"] = request.user.id
        serializer = self.get_serializer(data=data)

        try:
            serializer.is_valid(raise_exception=True)
        except ValidationError as e:
            print(serializer.errors)  # Print validation errors
            raise e
        abn_ads = serializer.save()

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

    def perform_update(self, serializer):
        serializer.save()

    def perform_destroy(self, instance):
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
        images_data = request.data.pop("images", None)
        data = request.data
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
    permission_classes = [IsAuthenticated]
    lookup_field = "id"


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
        """Return notifications for the current user"""
        return BusinessNetworkNotification.objects.filter(recipient=self.request.user)


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

    def get(self, request):
        """Return count of unread notifications"""
        count = BusinessNetworkNotification.objects.filter(
            recipient=request.user, read=False
        ).count()
        return Response({"count": count}, status=status.HTTP_200_OK)
