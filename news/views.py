from django.shortcuts import render, get_object_or_404
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.pagination import *
from rest_framework.renderers import JSONRenderer, BrowsableAPIRenderer
from .models import *
from .serializers import *

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


class NewsCategoryList(generics.ListCreateAPIView):
    queryset = NewsCategory.objects.all()
    serializer_class = NewsCategorySerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    pagination_class = AdvancedPagination

class NewsCategoryDetail(generics.RetrieveUpdateDestroyAPIView):
    queryset = NewsCategory.objects.all()
    serializer_class = NewsCategorySerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

class TipsAndSuggestionListCreateView(generics.ListCreateAPIView):
    serializer_class = TipsAndSuggestionSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]  # Allow any user to read
    pagination_class = AdvancedPagination
    renderer_classes = [JSONRenderer, BrowsableAPIRenderer]

    def get_queryset(self):
        return TipsAndSuggestion.objects.all()
    
    def perform_create(self, serializer):
        serializer.save(author=self.request.user)

class TipsAndSuggestionDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = TipsAndSuggestion.objects.all()
    serializer_class = TipsAndSuggestionSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    lookup_field = 'id'
    renderer_classes = [JSONRenderer, BrowsableAPIRenderer]
    
    def get_object(self):
        # Check if the lookup value is a valid slug
        lookup_url_kwarg = self.lookup_url_kwarg or self.lookup_field
        lookup_value = self.kwargs[lookup_url_kwarg]
        filter_kwargs = {self.lookup_field: lookup_value}
        
        # Try to find by id first
        obj = get_object_or_404(TipsAndSuggestion, **filter_kwargs)
        self.check_object_permissions(self.request, obj)
        return obj
    
    def perform_update(self, serializer):
        instance = self.get_object()
        # Only allow author to update their own tips/suggestions
        if instance.author == self.request.user:
            serializer.save()
        else:
            return Response({"error": "You don't have permission to update this tip/suggestion."}, 
                           status=status.HTTP_403_FORBIDDEN)
    
    def perform_destroy(self, instance):
        # Only allow author to delete their own tips/suggestions
        if instance.author == self.request.user:
            instance.delete()
        else:
            return Response({"error": "You don't have permission to delete this tip/suggestion."}, 
                           status=status.HTTP_403_FORBIDDEN)

class TipsAndSuggestionBySlugView(generics.RetrieveAPIView):
    queryset = TipsAndSuggestion.objects.all()
    serializer_class = TipsAndSuggestionSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    lookup_field = 'slug'
    lookup_url_kwarg = 'slug'
    renderer_classes = [JSONRenderer, BrowsableAPIRenderer]
    template_name = None
    
    def get_object(self):
        lookup_url_kwarg = self.lookup_url_kwarg or self.lookup_field
        lookup_value = self.kwargs[lookup_url_kwarg]
        
        # Try to find by slug
        obj = get_object_or_404(TipsAndSuggestion, slug=lookup_value)
        self.check_object_permissions(self.request, obj)
        return obj
    
    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return Response(serializer.data)
