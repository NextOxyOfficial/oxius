from django.shortcuts import render, get_object_or_404
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.pagination import LimitOffsetPagination, CursorPagination
from .models import NewsPost, NewsPostComment, NewsPostTag, NewsMedia
from .serializers import (
    NewsPostListSerializer, 
    NewsPostDetailSerializer, 
    NewsPostCommentSerializer, 
    NewsPostTagSerializer,
    NewsMediaSerializer
)

# Advanced pagination classes
class AdvancedPagination(LimitOffsetPagination):
    default_limit = 10
    max_limit = 100
    limit_query_param = 'limit'
    offset_query_param = 'offset'

class CursorBasedPagination(CursorPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100
    cursor_query_param = 'cursor'
    ordering = '-created_at'

class NewsPostList(generics.ListCreateAPIView):
    queryset = NewsPost.objects.all().order_by('-created_at')
    serializer_class = NewsPostListSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    pagination_class = AdvancedPagination
    
    def perform_create(self, serializer):
        serializer.save(author=self.request.user)

class NewsPostDetail(generics.RetrieveUpdateDestroyAPIView):
    queryset = NewsPost.objects.all()
    serializer_class = NewsPostDetailSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    lookup_field = 'slug'

class NewsPostCommentList(generics.ListCreateAPIView):
    serializer_class = NewsPostCommentSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    pagination_class = AdvancedPagination
    
    def get_queryset(self):
        post_id = self.kwargs.get('pk')
        return NewsPostComment.objects.filter(post_id=post_id)
    
    def perform_create(self, serializer):
        post_id = self.kwargs.get('pk')
        post = get_object_or_404(NewsPost, id=post_id)
        serializer.save(author=self.request.user, post=post)

class NewsPostCommentDetail(generics.RetrieveUpdateDestroyAPIView):
    queryset = NewsPostComment.objects.all()
    serializer_class = NewsPostCommentSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

class NewsPostTagList(generics.ListCreateAPIView):
    serializer_class = NewsPostTagSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    pagination_class = AdvancedPagination
    
    def get_queryset(self):
        post_id = self.kwargs.get('pk')
        return NewsPostTag.objects.filter(post_id=post_id)
    
    def perform_create(self, serializer):
        post_id = self.kwargs.get('pk')
        post = get_object_or_404(NewsPost, id=post_id)
        serializer.save(post=post)

class NewsPostTagDetail(generics.RetrieveUpdateDestroyAPIView):
    queryset = NewsPostTag.objects.all()
    serializer_class = NewsPostTagSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

class AllNewsPostTagList(generics.ListAPIView):
    queryset = NewsPostTag.objects.all().order_by('tag')
    serializer_class = NewsPostTagSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    pagination_class = AdvancedPagination

class NewsMediaList(generics.ListCreateAPIView):
    queryset = NewsMedia.objects.all()
    serializer_class = NewsMediaSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    pagination_class = AdvancedPagination

class NewsMediaDetail(generics.RetrieveUpdateDestroyAPIView):
    queryset = NewsMedia.objects.all()
    serializer_class = NewsMediaSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
