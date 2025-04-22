from django.urls import path
from .views import *

urlpatterns = [
    # News Post endpoints
    path('posts/', NewsPostList.as_view(), name='post-list'),
    path('posts/<slug:slug>/', NewsPostDetail.as_view(), name='post-detail'),
    
    # Comments endpoints
    path('posts/<int:pk>/comments/', NewsPostCommentList.as_view(), name='post-comments'),
    path('comments/<int:pk>/', NewsPostCommentDetail.as_view(), name='comment-detail'),
    
    # Tags endpoints
    path('posts/<int:pk>/tags/', NewsPostTagList.as_view(), name='post-tags'),
    path('tags/<int:pk>/', NewsPostTagDetail.as_view(), name='tag-detail'),
    path('tags/', AllNewsPostTagList.as_view(), name='all-tags'),  # New endpoint for all tags
    
    # Media endpoints
    path('media/', NewsMediaList.as_view(), name='media-list'),
    path('media/<int:pk>/', NewsMediaDetail.as_view(), name='media-detail'),
]