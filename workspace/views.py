from rest_framework import generics, status, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.db.models import Q
from django.utils import timezone

from .models import (
    Gig, GigReview, GigFavorite, GigOrder, OrderMessage,
    GigCategory, GigSkill, GigDeliveryTime, GigRevisionOption,
    WorkspaceBanner
)
from .serializers import (
    GigSerializer, GigCreateSerializer, GigReviewSerializer,
    GigOrderSerializer, GigFavoriteSerializer, OrderMessageSerializer,
    GigCategorySerializer, GigSkillSerializer, GigDeliveryTimeSerializer, GigRevisionOptionSerializer,
    WorkspaceBannerSerializer
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
        print(f"GigCreateView: Received data: {request.data}")
        print(f"GigCreateView: User: {request.user}")
        
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            print(f"GigCreateView: Validation errors: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
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
    """Create an order for a gig with payment from balance"""
    from django.db import transaction as db_transaction
    from .models import GigOrderTransaction
    
    try:
        gig = Gig.objects.get(id=gig_id, status='active')
    except Gig.DoesNotExist:
        return Response({'error': 'Gig not found'}, status=status.HTTP_404_NOT_FOUND)
    
    # Can't order own gig
    if gig.user == request.user:
        return Response({'error': 'You cannot order your own gig'}, status=status.HTTP_400_BAD_REQUEST)
    
    buyer = request.user
    price = gig.price
    
    # Check if buyer has sufficient balance
    if buyer.balance < price:
        return Response({
            'error': 'Insufficient balance',
            'message': f'Your balance is ৳{buyer.balance}. You need ৳{price} to place this order.',
            'required': float(price),
            'available': float(buyer.balance),
            'shortfall': float(price - buyer.balance)
        }, status=status.HTTP_400_BAD_REQUEST)
    
    requirements = request.data.get('requirements', '')
    
    # Calculate delivery date
    delivery_date = timezone.now() + timezone.timedelta(days=gig.delivery_time)
    
    try:
        with db_transaction.atomic():
            # Deduct from buyer's balance
            buyer.balance -= price
            buyer.save(update_fields=['balance'])
            
            # Create the order
            order = GigOrder.objects.create(
                gig=gig,
                buyer=buyer,
                seller=gig.user,
                price=price,
                requirements=requirements,
                delivery_date=delivery_date,
                status='pending'
            )
            
            # Create payment transaction record
            GigOrderTransaction.objects.create(
                order=order,
                user=buyer,
                amount=price,
                transaction_type='payment',
                status='completed',
                description=f'Payment for order #{str(order.id)[:8]} - {gig.title}'
            )
            
            # Create hold transaction (money in escrow)
            GigOrderTransaction.objects.create(
                order=order,
                user=gig.user,  # Seller
                amount=price,
                transaction_type='hold',
                status='pending',
                description=f'Payment held in escrow for order #{str(order.id)[:8]}'
            )
            
            # Create system message for order placement
            OrderMessage.objects.create(
                order=order,
                sender=None,  # System message
                content=f'🎉 Order placed successfully! Payment of ৳{price} has been received and held in escrow. The seller has been notified.',
                message_type='text'
            )
            
            # Increment gig orders count
            gig.orders_count += 1
            gig.save(update_fields=['orders_count'])
            
    except Exception as e:
        return Response({
            'error': 'Payment failed',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    serializer = GigOrderSerializer(order, context={'request': request})
    return Response({
        'order': serializer.data,
        'message': 'Order placed successfully!',
        'payment': {
            'amount': float(price),
            'new_balance': float(buyer.balance),
            'status': 'completed'
        }
    }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def complete_order_payment(request, order_id):
    """Release payment to seller when order is completed"""
    from django.db import transaction as db_transaction
    from .models import GigOrderTransaction
    
    try:
        order = GigOrder.objects.get(id=order_id)
    except GigOrder.DoesNotExist:
        return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)
    
    # Only buyer can complete the order
    if order.buyer != request.user:
        return Response({'error': 'Only the buyer can complete this order'}, status=status.HTTP_403_FORBIDDEN)
    
    # Order must be delivered
    if order.status != 'delivered':
        return Response({'error': 'Order must be delivered before completion'}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        with db_transaction.atomic():
            # Update order status
            order.status = 'completed'
            order.completed_at = timezone.now()
            order.save(update_fields=['status', 'completed_at'])
            
            # Release payment to seller
            seller = order.seller
            seller.balance += order.price
            seller.save(update_fields=['balance'])
            
            # Update hold transaction to completed
            GigOrderTransaction.objects.filter(
                order=order,
                transaction_type='hold',
                status='pending'
            ).update(status='completed')
            
            # Create release transaction
            GigOrderTransaction.objects.create(
                order=order,
                user=seller,
                amount=order.price,
                transaction_type='release',
                status='completed',
                description=f'Payment released for completed order #{str(order.id)[:8]}'
            )
            
            # Create system message
            OrderMessage.objects.create(
                order=order,
                sender=None,
                content=f'✅ Order completed! Payment of ৳{order.price} has been released to the seller.',
                message_type='text'
            )
            
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    serializer = GigOrderSerializer(order, context={'request': request})
    return Response({
        'order': serializer.data,
        'message': 'Order completed and payment released!'
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def cancel_order(request, order_id):
    """Cancel order and refund buyer"""
    from django.db import transaction as db_transaction
    from .models import GigOrderTransaction
    
    try:
        order = GigOrder.objects.get(id=order_id)
    except GigOrder.DoesNotExist:
        return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)
    
    # Only buyer or seller can cancel
    if order.buyer != request.user and order.seller != request.user:
        return Response({'error': 'Not authorized'}, status=status.HTTP_403_FORBIDDEN)
    
    # Can only cancel pending or in_progress orders
    if order.status not in ['pending', 'in_progress']:
        return Response({'error': 'Cannot cancel order in current status'}, status=status.HTTP_400_BAD_REQUEST)
    
    canceller = 'buyer' if request.user == order.buyer else 'seller'
    
    try:
        with db_transaction.atomic():
            # Refund buyer
            buyer = order.buyer
            buyer.balance += order.price
            buyer.save(update_fields=['balance'])
            
            # Update order status
            order.status = 'cancelled'
            order.save(update_fields=['status'])
            
            # Update hold transaction
            GigOrderTransaction.objects.filter(
                order=order,
                transaction_type='hold',
                status='pending'
            ).update(status='refunded')
            
            # Create refund transaction
            GigOrderTransaction.objects.create(
                order=order,
                user=buyer,
                amount=order.price,
                transaction_type='refund',
                status='completed',
                description=f'Refund for cancelled order #{str(order.id)[:8]} (cancelled by {canceller})'
            )
            
            # Create system message
            OrderMessage.objects.create(
                order=order,
                sender=None,
                content=f'❌ Order cancelled by {canceller}. ৳{order.price} has been refunded to the buyer.',
                message_type='text'
            )
            
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    serializer = GigOrderSerializer(order, context={'request': request})
    return Response({
        'order': serializer.data,
        'message': 'Order cancelled and refunded!',
        'refund': {
            'amount': float(order.price),
            'new_balance': float(buyer.balance)
        }
    })


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


@api_view(['GET'])
@permission_classes([AllowAny])
def get_workspace_banners(request):
    """Get active workspace banners"""
    now = timezone.now()
    
    banners = WorkspaceBanner.objects.filter(
        is_active=True
    ).filter(
        Q(starts_at__isnull=True) | Q(starts_at__lte=now)
    ).filter(
        Q(ends_at__isnull=True) | Q(ends_at__gte=now)
    ).order_by('order', '-created_at')
    
    serializer = WorkspaceBannerSerializer(banners, many=True, context={'request': request})
    return Response(serializer.data)
