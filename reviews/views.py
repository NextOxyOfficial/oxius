from rest_framework import generics, status, permissions
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
from base.models import Product


class ReviewPagination(PageNumberPagination):
    page_size = 6  # Show 6 reviews per page (2 rows of 3 in the frontend)
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


# Create your views here.
