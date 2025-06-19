from rest_framework import generics, status, permissions
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, IsAuthenticatedOrReadOnly
from rest_framework.pagination import PageNumberPagination
from django.shortcuts import get_object_or_404
from django.db.models import Q
from .models import Review, ReviewHelpful, ProductRatingStats
from .serializers import (
    ReviewSerializer, ReviewCreateSerializer, 
    ProductRatingStatsSerializer, ReviewHelpfulSerializer
)
from base.models import Product, User


class ReviewPagination(PageNumberPagination):
    page_size = 10  # Show 10 reviews per page for store reviews
    page_size_query_param = 'page_size'
    max_page_size = 50


class ProductReviewListCreateView(generics.ListCreateAPIView):
    """
    List reviews for a product or create a new review
    """
    permission_classes = [IsAuthenticatedOrReadOnly]
    pagination_class = ReviewPagination
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ReviewCreateSerializer
        return ReviewSerializer
    
    def get_queryset(self):
        product_id = self.kwargs.get('product_id')
        return Review.objects.filter(
            product_id=product_id,
            is_approved=True
        ).select_related('user', 'product').order_by('-created_at')
    
    def perform_create(self, serializer):
        product_id = self.kwargs.get('product_id')
        product = get_object_or_404(Product, id=product_id)
        serializer.save(product=product)


class ReviewDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Retrieve, update or delete a review
    """
    serializer_class = ReviewSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Review.objects.filter(user=self.request.user)


class ProductRatingStatsView(generics.RetrieveAPIView):
    """
    Get rating statistics for a product
    """
    serializer_class = ProductRatingStatsSerializer
    
    def get_object(self):
        product_id = self.kwargs.get('product_id')
        product = get_object_or_404(Product, id=product_id)
        
        # Get or create rating stats
        stats, created = ProductRatingStats.objects.get_or_create(
            product=product
        )
        
        # Update stats if they don't exist or are outdated
        if created or not stats.total_reviews:
            stats.update_stats()
        
        return stats


@api_view(['POST', 'DELETE'])
@permission_classes([IsAuthenticated])
def toggle_review_helpful(request, review_id):
    """
    Toggle helpful vote for a review
    """
    review = get_object_or_404(Review, id=review_id)
    
    if request.method == 'POST':
        # Add helpful vote
        helpful, created = ReviewHelpful.objects.get_or_create(
            review=review,
            user=request.user
        )
        
        if created:
            return Response({
                'message': 'Review marked as helpful',
                'is_helpful': True,
                'helpful_count': review.helpful_count
            }, status=status.HTTP_201_CREATED)
        else:
            return Response({
                'message': 'Already marked as helpful',
                'is_helpful': True,
                'helpful_count': review.helpful_count
            }, status=status.HTTP_200_OK)
    
    elif request.method == 'DELETE':
        # Remove helpful vote
        try:
            helpful = ReviewHelpful.objects.get(
                review=review,
                user=request.user
            )
            helpful.delete()
            return Response({
                'message': 'Helpful vote removed',
                'is_helpful': False,
                'helpful_count': review.helpful_count
            }, status=status.HTTP_200_OK)
        except ReviewHelpful.DoesNotExist:
            return Response({
                'message': 'No helpful vote found',
                'is_helpful': False,
                'helpful_count': review.helpful_count
            }, status=status.HTTP_200_OK)


@api_view(['GET'])
def user_review_for_product(request, product_id):
    """
    Get current user's review for a specific product
    """
    if not request.user.is_authenticated:
        return Response({'detail': 'Authentication required'}, status=status.HTTP_401_UNAUTHORIZED)
    
    try:
        review = Review.objects.get(
            product_id=product_id,
            user=request.user
        )
        serializer = ReviewSerializer(review, context={'request': request})
        return Response(serializer.data)
    except Review.DoesNotExist:
        return Response({'detail': 'No review found'}, status=status.HTTP_404_NOT_FOUND)


class UserReviewsListView(generics.ListAPIView):
    """
    List all reviews by the current user
    """
    serializer_class = ReviewSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = ReviewPagination
    
    def get_queryset(self):
        return Review.objects.filter(
            user=self.request.user
        ).select_related('product').order_by('-created_at')


class StoreReviewsListView(generics.ListAPIView):
    """
    List all reviews for products owned by the current user (store owner)
    """
    serializer_class = ReviewSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = ReviewPagination
    
    def get_queryset(self):
        # Get all reviews for products owned by the current user
        return Review.objects.filter(
            product__owner=self.request.user,
            is_approved=True
        ).select_related('product', 'user').order_by('-created_at')
        
    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            result = self.get_paginated_response(serializer.data)
            result.data['total_count'] = queryset.count()
            return result
        
        serializer = self.get_serializer(queryset, many=True)
        return Response({
            'results': serializer.data,
            'total_count': queryset.count()
        })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def store_reviews_count(request):
    """
    Get the total count of reviews for products owned by the current user
    """
    count = Review.objects.filter(
        product__owner=request.user,
        is_approved=True
    ).count()
    
    return Response({'count': count})


@api_view(['GET'])
def public_store_reviews_count(request, store_username):
    """
    Get the total count of reviews for products owned by any store (public endpoint)
    """
    try:
        # Get the store owner by store_username
        store_owner = get_object_or_404(User, store_username=store_username)
        
        # Count reviews for products owned by this store
        count = Review.objects.filter(
            product__owner=store_owner,
            is_approved=True
        ).count()
        
        return Response({'count': count})
    except User.DoesNotExist:
        return Response({'error': 'Store not found'}, status=status.HTTP_404_NOT_FOUND)


# Create your views here.
