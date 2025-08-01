from django.urls import include, path

from .optimized_views import CachedBusinessNetworkStatsView, get_device_optimized_feed
from .prioritized_feed import PrioritizedFeedView
from .views import *
from .views_fixed import FixedUserSuggestionsView

urlpatterns = [
    # Post endpoints
    path(
        "posts/", BusinessNetworkPostListCreateView.as_view(), name="post-list-create"
    ),
    path("posts/optimized/", get_device_optimized_feed, name="optimized-feed"),
    path(
        "posts/prioritized-feed/",
        PrioritizedFeedView.as_view(),
        name="prioritized-feed",
    ),
    path("posts/save/", UserSavedPostListCreateView.as_view(), name="user-saved-posts"),
    path("posts/search/", BusinessNetworkPostSearchView.as_view(), name="post-search"),
    path(
        "saved-posts/delete/<str:post_id>/",
        delete_saved_post,
        name="delete-saved-posts",
    ),
    path(
        "posts/<str:id>/",
        BusinessNetworkPostRetrieveUpdateDestroyView.as_view(),
        name="post-detail",
    ),
    path("user/<uuid:user_id>/posts/", UserPostsListView.as_view(), name="user-posts"),
    path("user-search/", UserSearchView.as_view(), name="user-search"),
    path(
        "users/search/", UserSearchView.as_view(), name="users-search"
    ),  # Alternative endpoint for frontend compatibility
    path("stats/", CachedBusinessNetworkStatsView.as_view(), name="cached-stats"),
    # Media endpoints
    path(
        "posts/<int:post_id>/media/",
        BusinessNetworkMediaCreateView.as_view(),
        name="post-media-create",
    ),
    path(
        "media/<str:pk>/",
        BusinessNetworkMediaDestroyView.as_view(),
        name="post-media-delete",
    ),
    # Like endpoints
    path(
        "posts/<str:post_id>/like/",
        BusinessNetworkPostLikeCreateView.as_view(),
        name="post-like",
    ),
    path(
        "posts/<str:post_id>/unlike/",
        BusinessNetworkPostLikeDestroyView.as_view(),
        name="post-unlike",
    ),
    # Follow endpoints
    path(
        "posts/<str:post_id>/follow/",
        BusinessNetworkPostFollowCreateView.as_view(),
        name="post-follow",
    ),
    path(
        "posts/<str:post_id>/unfollow/",
        BusinessNetworkPostFollowDestroyView.as_view(),
        name="post-unfollow",
    ),
    # Comment endpoints
    path(
        "posts/<str:post_id>/comments/",
        BusinessNetworkPostCommentListCreateView.as_view(),
        name="post-comments",
    ),
    path(
        "comments/<str:pk>/",
        BusinessNetworkPostCommentRetrieveUpdateDestroyView.as_view(),
        name="comment-detail",
    ),
    # Tag endpoints
    path("tags/", BusinessNetworkPostTagListCreateView.as_view(), name="post-tags"),
    path("top-tags/", TopTagsView.as_view(), name="top-tags"),
    path(
        "tags/<str:pk>/", BusinessNetworkPostTagDestroyView.as_view(), name="tag-delete"
    ),
    # business_network_workspace endpoints
    path(
        "workspaces/",
        BusinessNetworkWorkspaceListCreateView.as_view(),
        name="workspace-list-create",
    ),
    # user follow endpoints
    path(
        "users/<uuid:user_id>/follow/",
        UserFollowCreateView.as_view(),
        name="user-follow",
    ),
    path(
        "users/<uuid:user_id>/unfollow/",
        UserUnfollowDestroyView.as_view(),
        name="user-unfollow",
    ),
    path(
        "users/<uuid:user_id>/followers/",
        UserFollowersListView.as_view(),
        name="user-followers-list",
    ),
    path(
        "users/<uuid:user_id>/following/",
        UserFollowingListView.as_view(),
        name="user-following-list",
    ),
    path(
        "check-follow-status/<uuid:follower_id>/<uuid:following_id>/",
        CheckUserFollowStatusView.as_view(),
        name="check-follow-status",
    ),
    path(
        "user-suggestions/", FixedUserSuggestionsView.as_view(), name="user-suggestions"
    ),
    path(
        "simple-user-suggestions/",
        SimpleUserSuggestionsView.as_view(),
        name="simple-user-suggestions",
    ),
    # media like endpoints
    path(
        "media/<str:media_id>/like/",
        BusinessNetworkMediaLikeCreateView.as_view(),
        name="media-like",
    ),
    path(
        "media/<str:media_id>/unlike/",
        BusinessNetworkMediaLikeDestroyView.as_view(),
        name="media-unlike",
    ),
    # media comment endpoints
    path(
        "media/<str:media_id>/comments/",
        BusinessNetworkMediaCommentListCreateView.as_view(),
        name="media-comments",
    ),
    path(
        "media/comments/<str:pk>/",
        BusinessNetworkMediaCommentRetrieveUpdateDestroyView.as_view(),
        name="media-comment-detail",
    ),
    # abn-ads endpoints
    path(
        "abn-ads-panels/",
        AbnAdsPanelListCreateView.as_view(),
        name="abn-ads-panel-list-create",
    ),
    path(
        "abn-ads-categories/",
        AbnAdsPanelCategoryListCreateView.as_view(),
        name="abn-ads-panel-category-list-create",
    ),
    path(
        "abn-ads-panels/<str:pk>/",
        AbnAdsPanelRetrieveUpdateDestroyView.as_view(),
        name="abn-ads-panel-detail",
    ),
    path(
        "abn-ads-panels/filter/",
        AbnAdsPanelFilterView.as_view(),
        name="abn-ads-panel-filter",
    ),
    # business_network mindforce endpoints
    path(
        "mindforce/categories/",
        BusinessNetworkMindforceCategoryListView.as_view(),
        name="mindforce-category-list",
    ),
    path(
        "mindforce/",
        BusinessNetworkMindForceListCreateView.as_view(),
        name="mindforce-list-create",
    ),
    path(
        "mindforce/<str:id>/",
        BusinessNetworkMindforceRetrieveUpdateDestroyView.as_view(),
        name="mindforce-detail",
    ),
    # business-network minforce comments endpoints
    path(
        "mindforce/<str:mindforce_id>/comments/",
        BusinessNetworkMindforceCommentsListCreateView.as_view(),
        name="mindforce-comment-list-create",
    ),
    path(
        "mindforce/comments/<str:id>/",
        BusinessNetworkMindforceCommentDetailView.as_view(),
        name="mindforce-comment-detail",
    ),
    # Notification endpoints
    path(
        "notifications/",
        BusinessNetworkNotificationListView.as_view(),
        name="notification-list",
    ),
    path(
        "notifications/<str:id>/read/",
        BusinessNetworkNotificationReadView.as_view(),
        name="notification-read",
    ),
    path(
        "notifications/mark-all-read/",
        BusinessNetworkMarkAllNotificationsReadView.as_view(),
        name="mark-all-notifications-read",
    ),
    path(
        "notifications/unread-count/",
        BusinessNetworkUnreadNotificationCountView.as_view(),
        name="unread-notification-count",
    ),
    # Gold Sponsors endpoints
    path("gold-sponsors/", include("business_network.gold_sponsors.urls")),
]
