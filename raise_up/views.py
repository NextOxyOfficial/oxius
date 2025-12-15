from rest_framework import generics, status, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, IsAuthenticatedOrReadOnly
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Q, Sum
from django.db import models
from .models import RaiseUpPost, RaiseUpPostDetail, UserProfile
from .serializers import RaiseUpPostSerializer, RaiseUpPostCreateSerializer, RaiseUpPostDetailSerializer

class RaiseUpPostPagination(PageNumberPagination):
    page_size = 12
    page_size_query_param = 'page_size'
    max_page_size = 50

class RaiseUpPostListView(generics.ListCreateAPIView):
    queryset = RaiseUpPost.objects.filter(is_active=True)
    serializer_class = RaiseUpPostSerializer
    pagination_class = RaiseUpPostPagination
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['stage', 'sector', 'risk_level', 'funding_type']
    search_fields = ['title', 'summary', 'sector', 'city', 'poster__username', 'poster__first_name', 'poster__last_name']
    ordering_fields = ['created_at', 'raised', 'goal', 'progress_percent']
    ordering = ['-created_at']
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return RaiseUpPostCreateSerializer
        return RaiseUpPostSerializer
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        # Custom filtering
        sort_by = self.request.query_params.get('sort_by')
        if sort_by == 'funded':
            # Sort by funding percentage (raised/goal ratio)
            queryset = queryset.extra(
                select={'funding_ratio': 'raised / goal'},
                order_by=['-funding_ratio']
            )
        elif sort_by == 'newest':
            queryset = queryset.order_by('-created_at')
        elif sort_by == 'ending':
            # For now, just sort by goal amount (could add deadline field later)
            queryset = queryset.order_by('goal')
            
        return queryset

class RaiseUpPostDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = RaiseUpPost.objects.filter(is_active=True)
    serializer_class = RaiseUpPostSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
    
    def get_permissions(self):
        if self.request.method in ['PUT', 'PATCH', 'DELETE']:
            return [IsAuthenticated()]
        return [IsAuthenticatedOrReadOnly()]
    
    def perform_update(self, serializer):
        # Only allow poster to update their own posts
        if serializer.instance.poster != self.request.user:
            raise PermissionError("You can only update your own posts")
        serializer.save()
    
    def perform_destroy(self, instance):
        # Only allow poster to delete their own posts
        if instance.poster != self.request.user:
            raise PermissionError("You can only delete your own posts")
        # Soft delete
        instance.is_active = False
        instance.save()

@api_view(['GET'])
def featured_posts(request):
    """Get featured raise-up posts for homepage carousel"""
    posts = RaiseUpPost.objects.filter(is_active=True, is_featured=True)[:6]
    serializer = RaiseUpPostSerializer(posts, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def post_stats(request):
    """Get overall statistics for raise-up posts"""
    total_posts = RaiseUpPost.objects.filter(is_active=True).count()
    total_raised = RaiseUpPost.objects.filter(is_active=True).aggregate(
        total=models.Sum('raised')
    )['total'] or 0
    
    return Response({
        'total_posts': total_posts,
        'total_raised': float(total_raised),
        'total_supporters': total_posts * 12  # Mock calculation
    })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def invest_in_post(request, post_id):
    """Mock investment endpoint"""
    try:
        post = RaiseUpPost.objects.get(id=post_id, is_active=True)
        amount = request.data.get('amount', 0)
        
        # Mock investment logic
        return Response({
            'success': True,
            'message': f'Investment of ৳{amount} in "{post.title}" recorded',
            'post_id': post_id,
            'amount': amount
        })
    except RaiseUpPost.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Post not found'
        }, status=status.HTTP_404_NOT_FOUND)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def donate_to_post(request, post_id):
    """Mock donation endpoint"""
    try:
        post = RaiseUpPost.objects.get(id=post_id, is_active=True)
        amount = request.data.get('amount', 0)
        
        # Mock donation logic
        return Response({
            'success': True,
            'message': f'Donation of ৳{amount} to "{post.title}" recorded',
            'post_id': post_id,
            'amount': amount
        })
    except RaiseUpPost.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Post not found'
        }, status=status.HTTP_404_NOT_FOUND)
