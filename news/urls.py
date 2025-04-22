from django.urls import path, re_path
from .views import *

urlpatterns = [
    # News Post endpoints
    path('posts/', NewsPostList.as_view(), name='post-list'),
    re_path(r'^posts/(?P<slug>[\w\-\u0980-\u09FF]+)/$', NewsPostDetail.as_view(), name='post-detail'),
    
    # Comments endpoints
    path('posts/<int:pk>/comments/', NewsPostCommentList.as_view(), name='post-comments'),
    path('comments/<int:pk>/', NewsPostCommentDetail.as_view(), name='comment-detail'),
    
    # Categories endpoints
    path('categories/', NewsCategoryList.as_view(), name='category-list'),
    re_path(r'^categories/(?P<slug>[\w\-\u0980-\u09FF]+)/$', NewsCategoryDetail.as_view(), name='category-detail'),
    
    # Posts by category endpoint
    re_path(r'^categories/(?P<slug>[\w\-\u0980-\u09FF]+)/posts/$', PostsByCategory.as_view(), name='posts-by-category'),
    
    # Tips and Suggestions URLs
    path('tips-suggestions/', TipsAndSuggestionListCreateView.as_view(), name='tips-suggestions-list'),
    path('tips-suggestions/id/<str:id>/', TipsAndSuggestionDetailView.as_view(), name='tips-suggestions-detail'),
    re_path(r'^tips-suggestions/(?P<slug>[\w\-\u0980-\u09FF]+)/$', TipsAndSuggestionBySlugView.as_view(), name='tips-suggestions-by-slug'),
    
    # Breaking News URLs
    path('breaking-news/', BreakingNewsListView.as_view(), name='breaking-news-list'),
    ]