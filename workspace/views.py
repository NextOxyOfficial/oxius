from rest_framework import generics, status, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.db.models import Q
from django.utils import timezone


def send_workspace_notification(recipient_user, title, body, data=None):
    """
    Send push notification for workspace events
    """
    try:
        from base.fcm_service import send_fcm_notification
        from base.models import FCMToken
        
        # Get recipient's FCM tokens
        tokens = FCMToken.objects.filter(user=recipient_user, is_active=True).values_list('token', flat=True)
        
        notification_data = {
            'type': 'workspace',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            **(data or {})
        }
        
        success_count = 0
        for token in tokens:
            if send_fcm_notification(
                fcm_token=token,
                title=title,
                body=body,
                data=notification_data
            ):
                success_count += 1
        
        if tokens:
            print(f'📤 Workspace notification sent to {recipient_user.email} ({success_count}/{len(list(tokens))} devices)')
        else:
            print(f'⚠️ No FCM tokens found for user: {recipient_user.email}')
            
        return success_count > 0
    except Exception as e:
        print(f'❌ Error sending workspace notification: {e}')
        import traceback
        traceback.print_exc()
        return False

from .models import (
    Gig, GigReview, GigFavorite, GigOrder, OrderMessage,
    GigCategory, GigSkill, GigDeliveryTime, GigRevisionOption,
    WorkspaceBanner, GigFeeSettings, OrderDispute
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
    """Create a new gig - starts as pending for admin review"""
    serializer_class = GigCreateSerializer
    permission_classes = [IsAuthenticated]
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        # Gig is created with status='pending' by default (set in model)
        gig = serializer.save()
        
        # Send notification to user confirming submission
        send_workspace_notification(
            recipient_user=request.user,
            title='📝 Gig Submitted for Review',
            body=f'Your gig "{gig.title[:30]}" has been submitted and is pending admin approval.',
            data={
                'gig_id': str(gig.id),
                'notification_type': 'gig_submitted'
            }
        )
        
        # Return full gig data with pending status message
        response_serializer = GigSerializer(gig, context={'request': request})
        response_data = response_serializer.data
        response_data['message'] = 'Your gig has been submitted for review. You will be notified once it is approved.'
        return Response(response_data, status=status.HTTP_201_CREATED)


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
    order_id = request.data.get('order_id')
    
    # Get the order if provided
    order = None
    if order_id:
        try:
            order = GigOrder.objects.get(id=order_id, buyer=request.user, gig=gig)
            # Verify order is completed
            if order.status != 'completed':
                return Response({'error': 'You can only review completed orders'}, status=status.HTTP_400_BAD_REQUEST)
        except GigOrder.DoesNotExist:
            return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)
    
    review = GigReview.objects.create(
        gig=gig,
        order=order,
        user=request.user,
        rating=min(max(int(rating), 1), 5),  # Ensure rating is 1-5
        comment=comment
    )
    
    # Send push notification to gig owner
    reviewer_name = request.user.first_name or request.user.email
    stars = '⭐' * min(max(int(rating), 1), 5)
    
    send_workspace_notification(
        recipient_user=gig.user,
        title=f'{stars} New Review!',
        body=f'{reviewer_name} left a {rating}-star review on "{gig.title[:30]}"',
        data={
            'gig_id': str(gig.id),
            'notification_type': 'new_review'
        }
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
    
    # Send push notification to seller
    send_workspace_notification(
        recipient_user=gig.user,
        title='🎉 New Order Received!',
        body=f'{buyer.first_name or buyer.email} ordered your gig: {gig.title[:50]}',
        data={
            'order_id': str(order.id),
            'gig_id': str(gig.id),
            'notification_type': 'new_order'
        }
    )
    
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
    
    # Send push notification to seller about payment release
    buyer_name = request.user.first_name or request.user.email
    send_workspace_notification(
        recipient_user=seller,
        title='💰 Payment Received!',
        body=f'{buyer_name} completed the order. ৳{order.price} has been added to your balance!',
        data={
            'order_id': str(order.id),
            'notification_type': 'payment_released'
        }
    )
    
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
    
    # Send push notification to the other party
    recipient = order.seller if request.user == order.buyer else order.buyer
    canceller_name = request.user.first_name or request.user.email
    
    if request.user == order.buyer:
        # Buyer cancelled - notify seller
        send_workspace_notification(
            recipient_user=recipient,
            title='❌ Order Cancelled',
            body=f'{canceller_name} cancelled the order for "{order.gig.title[:30]}"',
            data={
                'order_id': str(order.id),
                'notification_type': 'order_cancelled'
            }
        )
    else:
        # Seller cancelled - notify buyer about refund
        send_workspace_notification(
            recipient_user=recipient,
            title='💸 Order Cancelled & Refunded',
            body=f'{canceller_name} cancelled your order. ৳{order.price} has been refunded to your balance.',
            data={
                'order_id': str(order.id),
                'notification_type': 'order_refunded'
            }
        )
    
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
    
    # Send push notification to the other party
    recipient = order.seller if request.user == order.buyer else order.buyer
    sender_name = request.user.first_name or request.user.email
    
    # Determine message preview
    if media:
        preview = f'📎 Sent an attachment'
    else:
        preview = content[:50] + '...' if len(content) > 50 else content
    
    send_workspace_notification(
        recipient_user=recipient,
        title=f'💬 New message from {sender_name}',
        body=preview,
        data={
            'order_id': str(order.id),
            'notification_type': 'order_message'
        }
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


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_messages_as_read(request, order_id):
    """Mark all messages in an order as read for the current user"""
    user = request.user
    
    try:
        order = GigOrder.objects.get(id=order_id)
    except GigOrder.DoesNotExist:
        return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)
    
    # Check if user is part of this order
    if order.buyer != user and order.seller != user:
        return Response({'error': 'Not authorized'}, status=status.HTTP_403_FORBIDDEN)
    
    # Mark all messages from the other party as read
    updated_count = OrderMessage.objects.filter(
        order=order,
        is_read=False
    ).exclude(sender=user).update(is_read=True)
    
    return Response({
        'message': 'Messages marked as read',
        'count': updated_count
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
            'from_status': ['in_progress', 'revision'],
            'to_status': 'delivered'
        },
        'complete': {
            'allowed_by': 'buyer',
            'from_status': ['delivered'],
            'to_status': 'completed'
        },
        'reopen': {
            'allowed_by': 'buyer',
            'from_status': ['delivered'],
            'to_status': 'revision'
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
        'reopen': f'Revision requested by buyer. Reason: {note}' if note else 'Revision requested by buyer.',
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
    
    # Send push notification to the other party
    recipient = order.buyer if user == order.seller else order.seller
    actor_name = user.first_name or user.email
    
    notification_titles = {
        'accept': '✅ Order Accepted!',
        'decline': '❌ Order Declined',
        'deliver': '📦 Order Delivered!',
        'complete': '🎉 Order Completed!',
        'reopen': '🔄 Revision Requested',
        'cancel': '❌ Order Cancelled'
    }
    
    notification_bodies = {
        'accept': f'{actor_name} accepted your order for "{order.gig.title[:30]}"',
        'decline': f'{actor_name} declined your order for "{order.gig.title[:30]}"',
        'deliver': f'{actor_name} has delivered your order "{order.gig.title[:30]}"',
        'complete': f'{actor_name} marked the order as complete. Payment released!',
        'reopen': f'{actor_name} requested a revision for "{order.gig.title[:30]}"',
        'cancel': f'{actor_name} cancelled the order for "{order.gig.title[:30]}"'
    }
    
    send_workspace_notification(
        recipient_user=recipient,
        title=notification_titles.get(action, 'Order Update'),
        body=notification_bodies.get(action, f'Order status updated to {action}'),
        data={
            'order_id': str(order.id),
            'notification_type': f'order_{action}'
        }
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


@api_view(['GET'])
@permission_classes([AllowAny])
def get_gig_fee_settings(request):
    """
    Get current gig fee settings for frontend fee calculations.
    Returns simplified buyer and seller fee configuration.
    """
    settings = GigFeeSettings.get_settings()
    
    return Response({
        'buyer_fee_percent': float(settings.buyer_fee_percent),
        'seller_fee_percent': float(settings.seller_fee_percent),
        'fees_enabled': settings.fees_enabled,
    })


@api_view(['POST'])
@permission_classes([AllowAny])
def calculate_order_fees(request):
    """
    Calculate fees for a specific order amount.
    Returns breakdown for both buyer and seller.
    
    Request body:
    {
        "amount": 1000
    }
    """
    amount = request.data.get('amount', 0)
    
    try:
        amount = float(amount)
        if amount <= 0:
            return Response(
                {'error': 'Amount must be greater than 0'},
                status=status.HTTP_400_BAD_REQUEST
            )
    except (ValueError, TypeError):
        return Response(
            {'error': 'Invalid amount'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    settings = GigFeeSettings.get_settings()
    
    return Response({
        'buyer': settings.calculate_buyer_fees(amount),
        'seller': settings.calculate_seller_fees(amount),
    })


# ============================================
# Order Dispute API
# ============================================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_dispute(request, order_id):
    """
    Create a dispute for an order.
    Both buyer and seller can raise disputes.
    
    Request body:
    {
        "reason": "unresponsive_seller",
        "description": "Detailed description of the issue"
    }
    """
    try:
        order = GigOrder.objects.get(id=order_id)
    except GigOrder.DoesNotExist:
        return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)
    
    user = request.user
    
    # Check if user is buyer or seller
    if user != order.buyer and user != order.seller:
        return Response({'error': 'You are not authorized to dispute this order'}, status=status.HTTP_403_FORBIDDEN)
    
    # Check if order can be disputed (not already completed, cancelled, or disputed)
    if order.status in ['completed', 'cancelled']:
        return Response({'error': 'Cannot dispute a completed or cancelled order'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Check if there's already an open dispute
    existing_dispute = OrderDispute.objects.filter(order=order, status__in=['open', 'under_review']).first()
    if existing_dispute:
        return Response({
            'error': 'There is already an open dispute for this order',
            'dispute_id': str(existing_dispute.id)
        }, status=status.HTTP_400_BAD_REQUEST)
    
    reason = request.data.get('reason')
    description = request.data.get('description', '')
    
    # Validate reason
    valid_reasons = [choice[0] for choice in OrderDispute.REASON_CHOICES]
    if not reason or reason not in valid_reasons:
        return Response({
            'error': 'Invalid reason',
            'valid_reasons': valid_reasons
        }, status=status.HTTP_400_BAD_REQUEST)
    
    if not description or len(description.strip()) < 20:
        return Response({'error': 'Please provide a detailed description (at least 20 characters)'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Create the dispute
    dispute = OrderDispute.objects.create(
        order=order,
        raised_by=user,
        reason=reason,
        description=description.strip()
    )
    
    # Update order status to disputed
    order.status = 'disputed'
    order.save(update_fields=['status'])
    
    # Create system message in order chat
    OrderMessage.objects.create(
        order=order,
        sender=None,
        content=f'⚠️ A dispute has been raised for this order. Reason: {dispute.get_reason_display()}. Our team will review and resolve this shortly.',
        message_type='text'
    )
    
    # Notify the other party
    other_party = order.seller if user == order.buyer else order.buyer
    raiser_name = user.first_name or user.email
    
    send_workspace_notification(
        recipient_user=other_party,
        title='⚠️ Dispute Raised',
        body=f'{raiser_name} has raised a dispute for order #{str(order.id)[:8].upper()}',
        data={
            'order_id': str(order.id),
            'dispute_id': str(dispute.id),
            'notification_type': 'dispute_raised'
        }
    )
    
    return Response({
        'message': 'Dispute raised successfully. Our team will review and contact you shortly.',
        'dispute': {
            'id': str(dispute.id),
            'reason': dispute.reason,
            'reason_display': dispute.get_reason_display(),
            'status': dispute.status,
            'created_at': dispute.created_at.isoformat()
        }
    }, status=status.HTTP_201_CREATED)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_order_dispute(request, order_id):
    """Get dispute details for an order"""
    try:
        order = GigOrder.objects.get(id=order_id)
    except GigOrder.DoesNotExist:
        return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)
    
    user = request.user
    
    # Check if user is buyer or seller
    if user != order.buyer and user != order.seller:
        return Response({'error': 'You are not authorized to view this dispute'}, status=status.HTTP_403_FORBIDDEN)
    
    dispute = OrderDispute.objects.filter(order=order).order_by('-created_at').first()
    
    if not dispute:
        return Response({'dispute': None})
    
    return Response({
        'dispute': {
            'id': str(dispute.id),
            'reason': dispute.reason,
            'reason_display': dispute.get_reason_display(),
            'description': dispute.description,
            'status': dispute.status,
            'status_display': dispute.get_status_display(),
            'resolution_notes': dispute.resolution_notes if dispute.is_resolved else None,
            'raised_by': {
                'id': str(dispute.raised_by.id),
                'name': f"{dispute.raised_by.first_name} {dispute.raised_by.last_name}",
                'is_buyer': dispute.raised_by == order.buyer
            },
            'created_at': dispute.created_at.isoformat(),
            'resolved_at': dispute.resolved_at.isoformat() if dispute.resolved_at else None,
            'is_resolved': dispute.is_resolved
        }
    })
