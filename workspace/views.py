from rest_framework import generics, status, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.db.models import Q
from django.utils import timezone

from .models import (
    Gig, GigReview, GigFavorite, GigOrder, OrderMessage,
    GigCategory, GigSkill, GigDeliveryTime, GigRevisionOption
)
from .serializers import (
    GigSerializer, GigCreateSerializer, GigReviewSerializer,
    GigOrderSerializer, GigFavoriteSerializer, OrderMessageSerializer,
    GigCategorySerializer, GigSkillSerializer, GigDeliveryTimeSerializer, GigRevisionOptionSerializer
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


class OrderMessageListView(generics.ListAPIView):
    """List messages for an order"""
    serializer_class = OrderMessageSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        order_id = self.kwargs.get('order_id')
        user = self.request.user
        
        # Only allow buyer or seller to view messages
        try:
            order = GigOrder.objects.get(id=order_id)
            if order.buyer != user and order.seller != user:
                return OrderMessage.objects.none()
            
            # Mark messages as read
            OrderMessage.objects.filter(
                order=order
            ).exclude(sender=user).update(is_read=True)
            
            return OrderMessage.objects.filter(order_id=order_id).select_related('sender')
        except GigOrder.DoesNotExist:
            return OrderMessage.objects.none()


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_order_message(request, order_id):
    """Create a message for an order"""
    try:
        order = GigOrder.objects.get(id=order_id)
    except GigOrder.DoesNotExist:
        return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)
    
    # Only buyer or seller can send messages
    if order.buyer != request.user and order.seller != request.user:
        return Response({'error': 'Not authorized'}, status=status.HTTP_403_FORBIDDEN)
    
    content = request.data.get('content', '').strip()
    media = request.FILES.get('media')
    message_type = request.data.get('message_type', 'text')
    
    # Require either content or media
    if not content and not media:
        return Response({'error': 'Message content or media is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    message = OrderMessage.objects.create(
        order=order,
        sender=request.user,
        content=content,
        message_type=message_type if media else 'text',
        media=media,
        file_name=media.name if media else None,
        file_size=media.size if media else None
    )
    
    serializer = OrderMessageSerializer(message, context={'request': request})
    return Response(serializer.data, status=status.HTTP_201_CREATED)


# ============================================
# Gig Options API
# ============================================

@api_view(['GET'])
@permission_classes([AllowAny])
def get_gig_options(request):
    """Get all gig options (categories, skills, delivery times, revisions)"""
    categories = GigCategory.objects.filter(is_active=True)
    skills = GigSkill.objects.filter(is_active=True)
    delivery_times = GigDeliveryTime.objects.filter(is_active=True)
    revision_options = GigRevisionOption.objects.filter(is_active=True)
    
    # Optional: Filter skills by category
    category_id = request.query_params.get('category')
    if category_id:
        skills = skills.filter(category_id=category_id)
    
    return Response({
        'categories': GigCategorySerializer(categories, many=True).data,
        'skills': GigSkillSerializer(skills, many=True).data,
        'delivery_times': GigDeliveryTimeSerializer(delivery_times, many=True).data,
        'revision_options': GigRevisionOptionSerializer(revision_options, many=True).data
    })


@api_view(['GET'])
@permission_classes([AllowAny])
def get_skills_by_category(request, category_id):
    """Get skills filtered by category"""
    skills = GigSkill.objects.filter(is_active=True, category_id=category_id)
    return Response(GigSkillSerializer(skills, many=True).data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_unread_message_counts(request):
    """Get unread message counts for all user's orders"""
    user = request.user
    
    # Get orders where user is buyer or seller
    from django.db.models import Count, Q
    
    # Get unread counts for orders as buyer
    buyer_orders = GigOrder.objects.filter(buyer=user).annotate(
        unread_count=Count(
            'messages',
            filter=Q(messages__is_read=False) & ~Q(messages__sender=user)
        )
    ).values('id', 'unread_count')
    
    # Get unread counts for orders as seller
    seller_orders = GigOrder.objects.filter(seller=user).annotate(
        unread_count=Count(
            'messages',
            filter=Q(messages__is_read=False) & ~Q(messages__sender=user)
        )
    ).values('id', 'unread_count')
    
    # Combine into a dict
    unread_counts = {}
    total_unread = 0
    
    for order in buyer_orders:
        unread_counts[str(order['id'])] = order['unread_count']
        total_unread += order['unread_count']
    
    for order in seller_orders:
        unread_counts[str(order['id'])] = order['unread_count']
        total_unread += order['unread_count']
    
    return Response({
        'counts': unread_counts,
        'total': total_unread
    })


# ============================================
# Order Status Management API
# ============================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_order_status(request, order_id, action):
    """Update order status (accept, decline, deliver, complete, cancel)"""
    try:
        order = GigOrder.objects.get(id=order_id)
    except GigOrder.DoesNotExist:
        return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)
    
    user = request.user
    note = request.data.get('note', '')
    
    # Define valid transitions and who can perform them
    valid_actions = {
        'accept': {
            'allowed_by': 'seller',
            'from_status': ['pending'],
            'to_status': 'in_progress'
        },
        'decline': {
            'allowed_by': 'seller',
            'from_status': ['pending'],
            'to_status': 'cancelled'
        },
        'deliver': {
            'allowed_by': 'seller',
            'from_status': ['in_progress'],
            'to_status': 'delivered'
        },
        'complete': {
            'allowed_by': 'buyer',
            'from_status': ['delivered'],
            'to_status': 'completed'
        },
        'cancel': {
            'allowed_by': 'buyer',
            'from_status': ['pending'],
            'to_status': 'cancelled'
        }
    }
    
    if action not in valid_actions:
        return Response({'error': 'Invalid action'}, status=status.HTTP_400_BAD_REQUEST)
    
    action_config = valid_actions[action]
    
    # Check authorization
    if action_config['allowed_by'] == 'seller' and order.seller != user:
        return Response({'error': 'Only the seller can perform this action'}, status=status.HTTP_403_FORBIDDEN)
    if action_config['allowed_by'] == 'buyer' and order.buyer != user:
        return Response({'error': 'Only the buyer can perform this action'}, status=status.HTTP_403_FORBIDDEN)
    
    # Check current status
    if order.status not in action_config['from_status']:
        return Response({
            'error': f'Cannot {action} order with status "{order.status}"'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Update status
    order.status = action_config['to_status']
    order.save(update_fields=['status', 'updated_at'])
    
    # Create a system message in the order chat
    action_messages = {
        'accept': f'Order accepted by seller.',
        'decline': f'Order declined by seller. Reason: {note}' if note else 'Order declined by seller.',
        'deliver': f'Order marked as delivered.',
        'complete': f'Order completed by buyer.',
        'cancel': f'Order cancelled by buyer.'
    }
    
    if note and action == 'accept':
        action_messages['accept'] = f'Order accepted! Message from seller: {note}'
    
    # Optionally create a message for the action
    OrderMessage.objects.create(
        order=order,
        sender=user,
        content=action_messages[action],
        message_type='text'
    )
    
    serializer = GigOrderSerializer(order, context={'request': request})
    return Response({
        'message': f'Order {action}ed successfully',
        'order': serializer.data
    })
