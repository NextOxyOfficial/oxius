from django.urls import path
from .views import *

urlpatterns = [
    # Post endpoints
    path('posts/', BusinessNetworkPostListCreateView.as_view(), name='post-list-create'),
    path('posts/<slug:slug>/', BusinessNetworkPostRetrieveUpdateDestroyView.as_view(), name='post-detail'),
    path('user/<uuid:user_id>/posts/', UserPostsListView.as_view(), name='user-posts'),
    path('posts/search/', BusinessNetworkPostSearchView.as_view(), name='post-search'),
    
    # Media endpoints
    path('posts/<int:post_id>/media/', BusinessNetworkMediaCreateView.as_view(), name='post-media-create'),
    path('media/<str:pk>/', BusinessNetworkMediaDestroyView.as_view(), name='post-media-delete'),
    
    # Like endpoints
    path('posts/<str:post_id>/like/', BusinessNetworkPostLikeCreateView.as_view(), name='post-like'),
    path('posts/<str:post_id>/unlike/', BusinessNetworkPostLikeDestroyView.as_view(), name='post-unlike'),
    
    # Follow endpoints
    path('posts/<str:post_id>/follow/', BusinessNetworkPostFollowCreateView.as_view(), name='post-follow'),
    path('posts/<str:post_id>/unfollow/', BusinessNetworkPostFollowDestroyView.as_view(), name='post-unfollow'),
    
    # Comment endpoints
    path('posts/<str:post_id>/comments/', BusinessNetworkPostCommentListCreateView.as_view(), name='post-comments'),
    path('comments/<str:pk>/', BusinessNetworkPostCommentRetrieveUpdateDestroyView.as_view(), name='comment-detail'),
    
    # Tag endpoints
    path('tags/', BusinessNetworkPostTagListCreateView.as_view(), name='post-tags'),
    path('tags/<str:pk>/', BusinessNetworkPostTagDestroyView.as_view(), name='tag-delete'),

    # business_network_workspace endpoints
    path('workspaces/', BusinessNetworkWorkspaceListCreateView.as_view(), name='workspace-list-create'),
    
    # user follow endpoints
    path('users/<uuid:user_id>/follow/', UserFollowCreateView.as_view(), name='user-follow'),

    # media like endpoints
    path('media/<str:media_id>/like/', BusinessNetworkMediaLikeCreateView.as_view(), name='media-like'),
    path('media/<str:media_id>/unlike/', BusinessNetworkMediaLikeDestroyView.as_view(), name='media-unlike'),

    # media comment endpoints
    path('media/<str:media_id>/comments/', BusinessNetworkMediaCommentListCreateView.as_view(), name='media-comments'),
    path('media/comments/<str:pk>/', BusinessNetworkMediaCommentRetrieveUpdateDestroyView.as_view(), name='media-comment-detail'),
    
    # abn-ads endpoints
    path('abn-ads-panels/', AbnAdsPanelListCreateView.as_view(), name='abn-ads-panel-list-create'),
    path('abn-ads-panels/<str:pk>/', AbnAdsPanelRetrieveUpdateDestroyView.as_view(), name='abn-ads-panel-detail'),
    path('abn-ads-panels/filter/', AbnAdsPanelFilterView.as_view(), name='abn-ads-panel-filter'),

    # business_network mindforce endpoints
    path('mindforce/categories/', BusinessNetworkMindforceCategoryListView.as_view(), name='mindforce-category-list'),
    path('mindforce/', BusinessNetworkMindForceListCreateView.as_view(), name='mindforce-list-create'),
]