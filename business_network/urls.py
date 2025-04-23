from django.urls import path
from .views import *

urlpatterns = [
    # Post endpoints
    path('posts/', BusinessNetworkPostListCreateView.as_view(), name='post-list-create'),
    path('posts/<slug:slug>/', BusinessNetworkPostRetrieveUpdateDestroyView.as_view(), name='post-detail'),
    path('user/<int:user_id>/posts/', UserPostsListView.as_view(), name='user-posts'),
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
]