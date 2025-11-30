from rest_framework import generics, status, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.db.models import Q
from django.utils import timezone

from .models import Gig, GigReview, GigFavorite, GigOrder
from .serializers import (
    GigSerializer, GigCreateSerializer, GigReviewSerializer,
    GigOrderSerializer, GigFavoriteSerializer
)


class GigPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100


class GigListView(generics.ListAPIView):
    """List all active gigs with filtering and search"""
    serializer_class = GigSerializer
    pagination_class = GigPagination
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'description', 'user__first_name', 'user__last_name']
    ordering_fields = ['created_at', 'price', 'views_count', 'orders_count']
    ordering = ['-created_at']
    
    def get_queryset(self):
        queryset = Gig.objects.filter(status='active').select_related('user')
        
        # Filter by category
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category=category)
        
        # Filter by price range
        min_price = self.request.query_params.get('min_price')
        max_price = self.request.query_params.get('max_price')
        if min_price:
            queryset = queryset.filter(price__gte=min_price)
        if max_price:
            queryset = queryset.filter(price__lte=max_price)
        
        # Filter by featured
        featured = self.request.query_params.get('featured')
        if featured and featured.lower() == 'true':
            queryset = queryset.filter(is_featured=True)
        
        return queryset


class GigDetailView(generics.RetrieveAPIView):
    """Get gig details"""
    serializer_class = GigSerializer
    permission_classes = [AllowAny]
    lookup_field = 'id'
    
    def get_queryset(self):
        return Gig.objects.filter(status='active').select_related('user')
    
    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        # Increment view count
        instance.views_count += 1
        instance.save(update_fields=['views_count'])
        serializer = self.get_serializer(instance)
        return Response(serializer.data)


class GigCreateView(generics.CreateAPIView):
    """Create a new gig"""
    serializer_class = GigCreateSerializer
    permission_classes = [IsAuthenticated]
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        gig = serializer.save()
        
        # Return full gig data
        response_serializer = GigSerializer(gig, context={'request': request})
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


class GigUpdateView(generics.UpdateAPIView):
    """Update a gig"""
    serializer_class = GigCreateSerializer
    permission_classes = [IsAuthenticated]
    lookup_field = 'id'
    
    def get_queryset(self):
        return Gig.objects.filter(user=self.request.user)


class GigDeleteView(generics.DestroyAPIView):
    """Delete a gig (soft delete)"""
    permission_classes = [IsAuthenticated]
    lookup_field = 'id'
    
    def get_queryset(self):
        return Gig.objects.filter(user=self.request.user)
    
    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.status = 'deleted'
        instance.save(update_fields=['status'])
        return Response(status=status.HTTP_204_NO_CONTENT)


class MyGigsView(generics.ListAPIView):
    """List current user's gigs with filtering and search"""
    serializer_class = GigSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = GigPagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'description']
    ordering_fields = ['created_at', 'price', 'views_count', 'orders_count']
    ordering = ['-created_at']
    
    def get_queryset(self):
        queryset = Gig.objects.filter(
            user=self.request.user
        ).exclude(status='deleted').select_related('user')
        
        # Filter by category
        category = self.request.query_params.get('category')
        if category:
            queryset = queryset.filter(category=category)
        
        # Filter by status
        status_filter = self.request.query_params.get('status')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        
        # Filter by price range
        min_price = self.request.query_params.get('min_price')
        max_price = self.request.query_params.get('max_price')
        if min_price:
            queryset = queryset.filter(price__gte=min_price)
        if max_price:
            queryset = queryset.filter(price__lte=max_price)
        
        return queryset


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def toggle_favorite(request, gig_id):
    """Toggle gig favorite status"""
    try:
        gig = Gig.objects.get(id=gig_id, status='active')
    except Gig.DoesNotExist:
        return Response({'error': 'Gig not found'}, status=status.HTTP_404_NOT_FOUND)
    
    favorite, created = GigFavorite.objects.get_or_create(
        gig=gig,
        user=request.user
    )
    
    if not created:
        favorite.delete()
        return Response({'is_favorited': False, 'message': 'Removed from favorites'})
    
    return Response({'is_favorited': True, 'message': 'Added to favorites'})


class MyFavoritesView(generics.ListAPIView):
    """List user's favorite gigs"""
    serializer_class = GigFavoriteSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = GigPagination
    
    def get_queryset(self):
        return GigFavorite.objects.filter(
            user=self.request.user,
            gig__status='active'
        ).select_related('gig', 'gig__user')


class ReviewPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 50


class GigReviewListView(generics.ListAPIView):
    """List reviews for a gig with pagination"""
    serializer_class = GigReviewSerializer
    permission_classes = [AllowAny]
    pagination_class = ReviewPagination
    
    def get_queryset(self):
        gig_id = self.kwargs.get('gig_id')
        return GigReview.objects.filter(gig_id=gig_id).select_related('user').order_by('-created_at')


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_review(request, gig_id):
    """Create a review for a gig"""
    try:
        gig = Gig.objects.get(id=gig_id, status='active')
    except Gig.DoesNotExist:
        return Response({'error': 'Gig not found'}, status=status.HTTP_404_NOT_FOUND)
    
    # Check if user already reviewed
    if GigReview.objects.filter(gig=gig, user=request.user).exists():
        return Response({'error': 'You have already reviewed this gig'}, status=status.HTTP_400_BAD_REQUEST)
    
    rating = request.data.get('rating', 5)
    comment = request.data.get('comment', '')
    
    review = GigReview.objects.create(
        gig=gig,
        user=request.user,
        rating=min(max(int(rating), 1), 5),  # Ensure rating is 1-5
        comment=comment
    )
    
    serializer = GigReviewSerializer(review, context={'request': request})
    return Response(serializer.data, status=status.HTTP_201_CREATED)


class MyOrdersView(generics.ListAPIView):
    """List user's orders (as buyer)"""
    serializer_class = GigOrderSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = GigPagination
    
    def get_queryset(self):
        return GigOrder.objects.filter(
            buyer=self.request.user
        ).select_related('gig', 'gig__user', 'buyer', 'seller')


class MySellerOrdersView(generics.ListAPIView):
    """List orders received (as seller)"""
    serializer_class = GigOrderSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = GigPagination
    
    def get_queryset(self):
        return GigOrder.objects.filter(
            seller=self.request.user
        ).select_related('gig', 'gig__user', 'buyer', 'seller')


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_order(request, gig_id):
    """Create an order for a gig"""
    try:
        gig = Gig.objects.get(id=gig_id, status='active')
    except Gig.DoesNotExist:
        return Response({'error': 'Gig not found'}, status=status.HTTP_404_NOT_FOUND)
    
    # Can't order own gig
    if gig.user == request.user:
        return Response({'error': 'You cannot order your own gig'}, status=status.HTTP_400_BAD_REQUEST)
    
    requirements = request.data.get('requirements', '')
    
    # Calculate delivery date
    delivery_date = timezone.now() + timezone.timedelta(days=gig.delivery_time)
    
    order = GigOrder.objects.create(
        gig=gig,
        buyer=request.user,
        seller=gig.user,
        price=gig.price,
        requirements=requirements,
        delivery_date=delivery_date
    )
    
    # Increment gig orders count
    gig.orders_count += 1
    gig.save(update_fields=['orders_count'])
    
    serializer = GigOrderSerializer(order, context={'request': request})
    return Response(serializer.data, status=status.HTTP_201_CREATED)


@api_view(['GET'])
@permission_classes([AllowAny])
def gig_categories(request):
    """Get list of gig categories"""
    categories = [
        {'value': 'design', 'label': 'Design & Creative'},
        {'value': 'development', 'label': 'Programming & Tech'},
        {'value': 'writing', 'label': 'Writing & Translation'},
        {'value': 'marketing', 'label': 'Digital Marketing'},
        {'value': 'business', 'label': 'Business & Consulting'},
    ]
    return Response(categories)
