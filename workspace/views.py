import logging

from rest_framework import generics, status, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.contrib.auth import get_user_model
from django.db.models import F, Q

# The single audited way to move money. Settlement must not grow a second one.
from base import wallet

User = get_user_model()
from django.utils import timezone

# These were `print()`. On a Windows console (cp1252) printing the emoji they
# carried raised UnicodeEncodeError, and because print() propagates, the
# exception escaped send_workspace_notification and turned order completion and
# cancellation into HTTP 500s — locally only; production stdout is UTF-8, so it
# never fired there. The class of bug is wider than the emoji: these lines also
# print user-supplied content and exception text, which on this platform can
# carry Bengali. logging cannot take an endpoint down that way — a handler that
# fails prints its own diagnostic and the caller continues.
logger = logging.getLogger(__name__)


def claim_escrow_hold(order, *, settle_as):
    """Consume an order's pending escrow record and return what it held.

    Every path that releases escrow — buyer refund, seller payout, admin
    dispute resolution — goes through here, so there is exactly one definition
    of "who is allowed to pay this out". Flipping the row out of 'pending' with
    a conditional UPDATE is the token: of any number of concurrent releasers,
    exactly one changes a row and exactly one may move money.

    `settle_as` records WHY it was consumed ('refunded' or 'completed'); it has
    no bearing on the claim itself.

    Returns the held Decimal, or None when there is nothing to release.
    """
    from .models import GigOrderTransaction

    hold = GigOrderTransaction.objects.filter(
        order=order, transaction_type='hold', status='pending',
    ).first()
    if hold is None:
        return None

    if not GigOrderTransaction.objects.filter(
        pk=hold.pk, status='pending',
    ).update(status=settle_as):
        # Lost the race; the winner owns the money.
        return None

    return hold.amount


def settle_dispute(dispute, *, outcome, resolved_by=None):
    """Resolve a dispute once, paying out the escrow it is about.

    `outcome` is one of 'resolved_buyer', 'resolved_seller', 'resolved_partial'.

    Returns None if somebody else already settled it, otherwise a dict of what
    THIS call actually moved: {'held', 'buyer', 'seller'}. Callers must use
    those figures rather than the form's, because a partial split is clamped to
    the escrow — telling a buyer they were refunded what they asked for, when
    they were refunded what was held, is its own kind of wrong.

    WHY THIS EXISTS

    Dispute resolution was six read-modify-write mutations spread over two
    entry points that duplicate each other — the bulk admin actions and
    `save_model` handling a directly edited status. None of them claimed
    anything, so re-running an action paid again: measured, a 600.00 escrow
    paid out 1200.00. The partial branch was worse — it refunded the
    admin-entered `refund_amount` and released `order.price` minus that figure,
    neither checked against the escrow, so entering 99999.00 against a 600.00
    hold paid out 99999.00.

    None of the six consumed the `hold` row either, leaving the escrow ledger
    claiming money was still held after it had been paid out.

    Two claims here, in one transaction: the dispute row (so one resolution
    wins) and the escrow hold (so one payout happens). The amount comes from
    the hold, never from the order or the form.
    """
    from decimal import Decimal

    from django.db import transaction as db_transaction

    from .models import GigOrder, GigOrderTransaction, OrderDispute

    if outcome not in ('resolved_buyer', 'resolved_seller', 'resolved_partial'):
        raise ValueError('Unknown dispute outcome: %r' % (outcome,))

    with db_transaction.atomic():
        # 1. Claim the dispute. Only an unresolved one can be resolved, and
        #    only one caller gets to do it.
        claimed = OrderDispute.objects.filter(
            pk=dispute.pk, status__in=['open', 'under_review'],
        ).update(
            status=outcome,
            resolved_by=resolved_by,
            resolved_at=timezone.now(),
        )
        if not claimed:
            return None

        order = dispute.order

        # 2. Claim the escrow. A resolution whose order was already settled by
        #    complete/cancel/decline finds nothing here and moves no money —
        #    the dispute still closes, which is the correct bookkeeping.
        settle_as = 'refunded' if outcome == 'resolved_buyer' else 'completed'
        held = claim_escrow_hold(order, settle_as=settle_as)
        held = Decimal('0') if held is None else held

        buyer_gets = Decimal('0')
        seller_gets = Decimal('0')

        if outcome == 'resolved_buyer':
            buyer_gets = held
            new_status = 'cancelled'
        elif outcome == 'resolved_seller':
            seller_gets = held
            new_status = 'completed'
        else:
            # The split is bounded by the escrow at both ends: a negative or
            # oversized refund_amount can only ever redistribute what is
            # actually held, never create or destroy any of it.
            requested = dispute.refund_amount or Decimal('0')
            buyer_gets = min(max(requested, Decimal('0')), held)
            seller_gets = held - buyer_gets
            new_status = 'completed'

        if buyer_gets > 0:
            wallet.credit(order.buyer_id, buyer_gets,
                          reason='dispute_%s_buyer:%s' % (outcome, dispute.pk))
            GigOrderTransaction.objects.create(
                order=order, user=order.buyer, amount=buyer_gets,
                transaction_type='refund', status='completed',
                description='Dispute resolution refund for order #%s'
                            % str(order.id)[:8])
        if seller_gets > 0:
            wallet.credit(order.seller_id, seller_gets,
                          reason='dispute_%s_seller:%s' % (outcome, dispute.pk))
            GigOrderTransaction.objects.create(
                order=order, user=order.seller, amount=seller_gets,
                transaction_type='release', status='completed',
                description='Dispute resolution payout for order #%s'
                            % str(order.id)[:8])

        fields = {'status': new_status, 'updated_at': timezone.now()}
        if new_status == 'completed':
            fields['completed_at'] = timezone.now()
        GigOrder.objects.filter(pk=order.pk).update(**fields)

    logger.info('Dispute %s settled as %s: buyer=%s seller=%s of %s held',
                dispute.pk, outcome, buyer_gets, seller_gets, held)
    dispute.refresh_from_db()
    return {'held': held, 'buyer': buyer_gets, 'seller': seller_gets}


def release_escrow_to_buyer(order, *, reason):
    """Return a cancelled order's escrow to its buyer, at most once.

    THE AMOUNT IS NOT GUESSED AND NEVER COMES FROM THE CLIENT. When an order is
    placed the buyer's balance is debited and a `hold` GigOrderTransaction is
    written with the amount that actually left their wallet. That row is the
    only record of what is owed back, so it is what the refund is derived from
    — not the request, and not `order.price`, which is a live figure that can
    drift from what was really taken.

    Flipping that row from 'pending' to 'refunded' is also the idempotency
    token. It is a conditional UPDATE, so of any number of concurrent declines
    exactly one changes a row and exactly one pays. Its absence is equally
    meaningful: no pending hold means nothing is being held — the order was
    free, or the escrow was already released — and nothing may be paid out.

    Returns the refunded amount, or None when there was nothing to refund.
    """
    from .models import GigOrderTransaction

    amount = claim_escrow_hold(order, settle_as='refunded')
    if amount is None:
        # No escrow outstanding. A free gig, or somebody already released it.
        return None
    if not amount or amount <= 0:
        # The hold is settled, but a zero hold must not mint anything, and
        # wallet.credit refuses non-positive amounts by design.
        return None

    wallet.credit(order.buyer_id, amount, reason='%s:%s' % (reason, order.id))

    GigOrderTransaction.objects.create(
        order=order,
        user=order.buyer,
        amount=amount,
        transaction_type='refund',
        status='completed',
        description='Refund for order #%s' % str(order.id)[:8],
    )
    return amount


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
            logger.info('Workspace notification sent to %s (%s/%s devices)',
                        recipient_user.email, success_count, len(list(tokens)))
        else:
            logger.warning('No FCM tokens found for user: %s', recipient_user.email)
            
        return success_count > 0
    except Exception as e:
        # logger.exception already records the full traceback, so print_exc()
        # only duplicated it — while remaining the last statement in this
        # function that could raise into the caller and 500 a settlement.
        logger.exception('Error sending workspace notification: %s', e)
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
        
        # Filter by user ID
        user_id = self.request.query_params.get('user')
        if user_id:
            queryset = queryset.filter(user_id=user_id)
        
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
        # debug, not info: this is a whole request body and can carry personal
        # data. It stays available when someone turns the level up deliberately.
        logger.debug("GigCreateView: received data: %s", request.data)
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            logger.warning("GigCreateView: validation errors: %s", serializer.errors)
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
            # Conditional update, not read-modify-write. atomic() alone does not
            # stop two concurrent orders from both reading the same balance,
            # both passing the check above and the second write erasing the
            # first deduction — one balance buying two gigs.
            if not User.objects.filter(
                pk=buyer.pk, balance__gte=price
            ).update(balance=F('balance') - price):
                return Response({
                    'error': 'Insufficient balance',
                    'message': 'ব্যালেন্সে পর্যাপ্ত টাকা নেই।',
                }, status=status.HTTP_400_BAD_REQUEST)
            buyer.refresh_from_db(fields=['balance'])
            
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

    # Send email notifications for gig order placed
    try:
        from base.email_service import send_gig_order_placed_email
        send_gig_order_placed_email(buyer, gig.user, gig.title, price, order.id)
    except Exception as e:
        logger.exception("Error sending gig order email: %s", e)
    
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
            # CLAIM THE ORDER FIRST, AND LET THE DATABASE DECIDE.
            #
            # The status check above is a courtesy that produces a friendly
            # error; it cannot be the gate. It ran against an unlocked read, so
            # six concurrent clicks all saw 'delivered', all passed it, and all
            # paid — 2000.00 released from a single 500.00 escrow hold, four of
            # them answering 200. `transaction.atomic()` did not help: those are
            # six separate transactions, each individually valid. Nor did the
            # F(): it stops a payout being *overwritten*, which is precisely why
            # the duplicates added up cleanly instead of colliding.
            #
            # This UPDATE is the gate. `status='delivered'` in the WHERE clause
            # means whichever request flips delivered -> completed is the only
            # one that matches a row; the rest update nothing and pay nothing.
            # The claim and the payout share one transaction, so if the credit
            # raises, the order goes back to 'delivered' and can be retried
            # rather than being marked paid while the seller got nothing.
            claimed = GigOrder.objects.filter(
                pk=order.pk, status='delivered',
            ).update(status='completed', completed_at=timezone.now())

            if not claimed:
                return Response(
                    {'error': 'Order must be delivered before completion'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            # The in-memory object still says 'delivered'; the response
            # serialises it further down.
            order.refresh_from_db(fields=['status', 'completed_at'])

            # Release payment to seller
            seller = order.seller
            if order.price > 0:
                wallet.credit(
                    seller.pk, order.price,
                    reason='gig_release:%s' % order.id,
                )
            seller.refresh_from_db(fields=['balance'])
            
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

    # Send email notifications for gig order completed
    try:
        from base.email_service import send_gig_order_completed_email
        send_gig_order_completed_email(order.buyer, seller, order.gig.title, order.price, order.id)
    except Exception as e:
        logger.exception("Error sending gig completion email: %s", e)
    
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
            # CLAIM BEFORE REFUNDING — note the original order of these two
            # steps. The refund ran FIRST and the status was written after, so
            # concurrent cancels did not even need to interleave narrowly: five
            # clicks refunded 2000.00 against a single 500.00 hold, straight
            # into the buyer's own wallet. Both parties may cancel, so a buyer
            # and a seller pressing it together hit the same window.
            #
            # Only a request that moves the row out of a cancellable status is
            # allowed to pay, and it takes that right atomically.
            claimed = GigOrder.objects.filter(
                pk=order.pk, status__in=['pending', 'in_progress'],
            ).update(status='cancelled')

            if not claimed:
                return Response(
                    {'error': 'Cannot cancel order in current status'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            order.refresh_from_db(fields=['status'])

            # Refund buyer
            buyer = order.buyer
            if order.price > 0:
                wallet.credit(
                    buyer.pk, order.price,
                    reason='gig_refund:%s' % order.id,
                )
            buyer.refresh_from_db(fields=['balance'])
            
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
        # 'complete' deliberately absent. It used to move an order to
        # 'completed' from here WITHOUT paying the seller — unreachable only
        # because urls.py declares the explicit `complete/` route (which does
        # pay, via complete_order_payment) before this catch-all. Reordering
        # that file would have silently started settling orders and keeping the
        # seller's money. Removing the action means the worst a reordering can
        # do is answer "Invalid action".
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
    
    # CLAIM THE TRANSITION, THEN RELEASE THE ESCROW.
    #
    # This route is `orders/<uuid>/<str:action>/`, the catch-all beneath
    # `complete/` and `cancel/`. Those two carry their own paying handlers, so
    # `decline` was the one live action here that ends a PAID order: the seller
    # declined, the status became 'cancelled', HTTP 200 came back — and the
    # money the buyer had already paid was never returned. Measured on this
    # code: buyer balance 0.00 after a 500.00 order was declined. That is a
    # legitimate buyer permanently losing what they paid.
    #
    # The status write was also a plain read-modify-write over an unlocked
    # read, the same shape that let concurrent completions pay a seller four
    # times. Both problems close together: the conditional UPDATE decides who
    # owns the transition, and only that request releases the escrow. The two
    # share one transaction, so a failed refund rolls the status back rather
    # than leaving the order cancelled with the money still gone.
    from django.db import transaction as db_transaction

    refunded = None
    with db_transaction.atomic():
        claimed = GigOrder.objects.filter(
            pk=order.pk, status__in=action_config['from_status'],
        ).update(
            status=action_config['to_status'],
            # .update() bypasses auto_now, so it is set by hand here.
            updated_at=timezone.now(),
        )

        if not claimed:
            # Someone else moved the order between the read above and here.
            order.refresh_from_db(fields=['status'])
            return Response({
                'error': f'Cannot {action} order with status "{order.status}"'
            }, status=status.HTTP_400_BAD_REQUEST)

        order.refresh_from_db(fields=['status', 'updated_at'])

        # Any transition that ends the order as 'cancelled' leaves the buyer's
        # money in escrow. Keyed on the destination rather than on the action
        # name so a new cancelling action cannot quietly reintroduce this.
        if action_config['to_status'] == 'cancelled':
            refunded = release_escrow_to_buyer(
                order, reason='gig_%s_refund' % action)
            if refunded is not None:
                logger.info('Order %s %s: refunded %s to buyer %s',
                            order.id, action, refunded, order.buyer_id)
    
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

    # Send email notification for order status change
    try:
        from base.email_service import send_gig_order_status_email
        if recipient.email:
            send_gig_order_status_email(recipient, order.gig.title, order.id, action_config['to_status'], actor_name)
    except Exception as e:
        logger.exception("Error sending gig order status email: %s", e)
    
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
