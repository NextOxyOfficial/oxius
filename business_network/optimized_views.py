from datetime import timedelta

from django.core.cache import cache
from django.db.models import (Case, Count, IntegerField, Prefetch, Q, Value,
                              When)
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.decorators import api_view
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from base.models import User

from .models import *
from .pagination import *
from .serializers import *


class OptimizedBusinessNetworkPostSerializer(BusinessNetworkPostSerializer):
    """Optimized serializer for medium-level devices"""
    
    def get_post_likes(self, obj):
        # Return all likes without artificial limitations
        return BusinessNetworkPostLikeSerializer(obj.post_likes.all(), many=True).data
    
    def to_representation(self, instance):
        # Use cached counts if available
        cache_key = f"post_counts_{instance.id}"
        cached_counts = cache.get(cache_key)
        
        if cached_counts:
            instance._like_count = cached_counts['likes']
            instance._comment_count = cached_counts['comments'] 
            instance._follower_count = cached_counts['followers']
        
        return super().to_representation(instance)

class OptimizedBusinessNetworkPostListView(generics.ListAPIView):
    """Optimized feed view for medium-level devices"""
    serializer_class = OptimizedBusinessNetworkPostSerializer
    pagination_class = MediumDevicePagination
    permission_classes = [AllowAny]  # Changed for testing, use IsAuthenticated in production
    
    def get_queryset(self):
        """
        Optimized feed with minimal database queries and caching
        """
        # Handle both authenticated and unauthenticated users for testing
        if not self.request.user.is_authenticated:
            return BusinessNetworkPost.objects.select_related('author').annotate(
                like_count=Count('post_likes', distinct=True),
                comment_count=Count('post_comments', distinct=True),
                follower_count=Count('post_followers', distinct=True)
            ).order_by('-created_at')
        
        user = self.request.user
        
        # Cache user relationships for 5 minutes
        cache_key = f"user_relationships_{user.id}"
        cached_relationships = cache.get(cache_key)
        
        if not cached_relationships:
            # Get user relationships efficiently
            following_ids = list(BusinessNetworkFollowerModel.objects.filter(
                follower=user
            ).values_list('following_id', flat=True))
            
            follower_ids = list(BusinessNetworkFollowerModel.objects.filter(
                following=user
            ).values_list('follower_id', flat=True))
            
            cached_relationships = {
                'following_ids': following_ids,
                'follower_ids': follower_ids
            }
            cache.set(cache_key, cached_relationships, 300)  # Cache for 5 minutes
        
        following_ids = cached_relationships['following_ids']
        follower_ids = cached_relationships['follower_ids']
        
        # Simplified priority logic for better performance
        recent_threshold = timezone.now() - timedelta(hours=24)
        
        queryset = BusinessNetworkPost.objects.annotate(
            # Simplified priority with fewer cases
            priority=Case(
                When(author=user, created_at__gte=recent_threshold, then=Value(1)),
                When(author_id__in=following_ids, then=Value(2)),
                When(author_id__in=follower_ids, then=Value(3)),
                default=Value(4),
                output_field=IntegerField()
            ),
            # Pre-calculate counts to avoid N+1 queries
            like_count=Count('post_likes', distinct=True),
            comment_count=Count('post_comments', distinct=True),
            follower_count=Count('post_followers', distinct=True)        ).select_related(
            'author'  # Only fetch author details
        ).prefetch_related(
            # Optimized prefetch with limited data
            Prefetch('media', queryset=BusinessNetworkMedia.objects.all()[:3]),
            Prefetch('tags', queryset=BusinessNetworkPostTag.objects.all()[:5]),
            Prefetch('post_likes', queryset=BusinessNetworkPostLike.objects.select_related('user')),
            Prefetch('post_comments', queryset=BusinessNetworkPostComment.objects.select_related('author').order_by('-created_at'))
        ).order_by(
            'priority',
            '-created_at'
        )
        
        return queryset

class LightweightBusinessNetworkPostSerializer(serializers.ModelSerializer):
    """Ultra-lightweight serializer for low-end devices"""
    author_name = serializers.SerializerMethodField()
    like_count = serializers.IntegerField(read_only=True)
    comment_count = serializers.IntegerField(read_only=True)
    has_media = serializers.SerializerMethodField()
    
    class Meta:
        model = BusinessNetworkPost
        fields = [
            'id', 'slug', 'author_name', 'title', 'content', 
            'created_at', 'like_count', 'comment_count', 'has_media'
        ]
    
    def get_author_name(self, obj):
        return f"{obj.author.first_name} {obj.author.last_name}".strip() or obj.author.username
    
    def get_has_media(self, obj):
        return obj.media.exists()

class LightweightBusinessNetworkPostListView(generics.ListAPIView):
    """Ultra-lightweight feed for very low-end devices"""
    serializer_class = LightweightBusinessNetworkPostSerializer
    pagination_class = LowDevicePagination
    permission_classes = [AllowAny]  # Changed for testing
    
    def get_queryset(self):
        # Extremely simplified query for low-end devices
        return BusinessNetworkPost.objects.annotate(
            like_count=Count('post_likes'),
            comment_count=Count('post_comments')
        ).select_related('author').order_by('-created_at')

@api_view(['GET'])
def get_device_optimized_feed(request):
    """
    Returns appropriate feed based on device capability
    Query parameter: device_level (high/medium/low)
    """
    device_level = request.query_params.get('device_level', 'medium')
    
    if device_level == 'low':
        view = LightweightBusinessNetworkPostListView()
    elif device_level == 'high':
        # Import here to avoid circular imports
        from .views import BusinessNetworkPostListCreateView
        view = BusinessNetworkPostListCreateView()
    else:  # medium (default)
        view = OptimizedBusinessNetworkPostListView()
    
    # Set up the view with the request
    view.request = request
    view.format_kwarg = None
    
    # Get the response from the view
    response = view.list(request)
    return response

class CachedBusinessNetworkStatsView(generics.GenericAPIView):
    """Cached statistics for dashboard"""
    permission_classes = [AllowAny]  # Changed for testing
    
    def get(self, request):
        # Return simple stats for testing - in production, add authentication logic
        stats = {
            'following_count': 0,
            'followers_count': 0, 
            'posts_count': BusinessNetworkPost.objects.count(),
            'total_likes_received': 0
        }
        
        if request.user.is_authenticated:
            user = request.user
            cache_key = f"user_stats_{user.id}"
            
            cached_stats = cache.get(cache_key)
            if not cached_stats:
                cached_stats = {
                    'following_count': BusinessNetworkFollowerModel.objects.filter(follower=user).count(),
                    'followers_count': BusinessNetworkFollowerModel.objects.filter(following=user).count(),
                    'posts_count': BusinessNetworkPost.objects.filter(author=user).count(),
                    'total_likes_received': BusinessNetworkPostLike.objects.filter(post__author=user).count()
                }
                cache.set(cache_key, cached_stats, 600)  # Cache for 10 minutes
            stats = cached_stats
        
        return Response(stats, status=status.HTTP_200_OK)

class OptimizedUserSearchView(generics.ListAPIView):
    """Optimized user search with minimal data"""
    serializer_class = UserSerializer
    pagination_class = SmallResultsSetPagination
    
    def get_queryset(self):
        query = self.request.query_params.get('q', '').strip()
        
        if not query or len(query) < 2:
            return User.objects.none()
        
        # Simplified search for better performance
        return User.objects.filter(
            Q(username__icontains=query) |
            Q(first_name__icontains=query) |
            Q(last_name__icontains=query)
        ).exclude(is_superuser=True).only('id', 'username', 'first_name', 'last_name', 'image')[:20]
            Q(username__icontains=query) |
            Q(first_name__icontains=query) |
            Q(last_name__icontains=query)
        ).exclude(is_superuser=True).only('id', 'username', 'first_name', 'last_name', 'image')[:20]
