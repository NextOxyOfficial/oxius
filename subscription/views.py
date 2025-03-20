from .models import *
from .serializers import *
from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.utils import timezone
from django.shortcuts import get_object_or_404
from django.db.models import Q

from .models import *
from .serializers import *


# Subscription Plan Views
class SubscriptionPlanListView(generics.ListAPIView):
    """
    List all active subscription plans
    """
    queryset = SubscriptionPlan.objects.filter(is_active=True)
    serializer_class = SubscriptionPlanSerializer
    permission_classes = [permissions.AllowAny]


class SubscriptionPlanDetailView(generics.RetrieveAPIView):
    """
    Retrieve a specific subscription plan
    """
    queryset = SubscriptionPlan.objects.filter(is_active=True)
    serializer_class = SubscriptionPlanSerializer
    permission_classes = [permissions.AllowAny]


# User Subscription Views
class UserSubscriptionListCreateView(generics.ListCreateAPIView):
    """
    List all user subscriptions or create a new subscription
    """
    serializer_class = SubscriptionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Return only the current user's subscriptions"""
        return Subscription.objects.filter(user=self.request.user)
    
    def get_serializer_class(self):
        """Use different serializer for creation"""
        if self.request.method == 'POST':
            return SubscriptionCreateSerializer
        return SubscriptionSerializer
    
    def perform_create(self, serializer):
        """Set the user automatically to the current user"""
        serializer.save(user=self.request.user)
        
        # Create a log entry for creation
        subscription = serializer.instance
        SubscriptionLog.objects.create(
            subscription=subscription,
            action='created',
            details="Subscription created"
        )


class UserSubscriptionDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Retrieve, update or delete a user subscription
    """
    serializer_class = SubscriptionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Return only the current user's subscriptions"""
        return Subscription.objects.filter(user=self.request.user)


class SubscriptionActivateView(APIView):
    """
    Activate a pending subscription
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request, pk):
        subscription = get_object_or_404(Subscription, id=pk, user=request.user)
        
        if subscription.status != 'pending':
            return Response(
                {"error": f"Cannot activate subscription with status: {subscription.status}"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        subscription.activate()
        
        # Create log entry
        SubscriptionLog.objects.create(
            subscription=subscription,
            action='activated',
            details="Subscription activated manually"
        )
        
        serializer = SubscriptionSerializer(subscription)
        return Response(serializer.data)


class SubscriptionCancelView(APIView):
    """
    Cancel an active subscription
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request, pk):
        subscription = get_object_or_404(Subscription, id=pk, user=request.user)
        
        if subscription.status != 'active':
            return Response(
                {"error": f"Cannot cancel subscription with status: {subscription.status}"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        subscription.cancel()
        
        # Create log entry
        SubscriptionLog.objects.create(
            subscription=subscription,
            action='cancelled',
            details=request.data.get('reason', "Subscription cancelled by user")
        )
        
        serializer = SubscriptionSerializer(subscription)
        return Response(serializer.data)


class ActiveSubscriptionView(generics.RetrieveAPIView):
    """
    Get user's currently active subscription
    """
    serializer_class = SubscriptionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        active_subscription = Subscription.objects.filter(
            user=self.request.user,
            status='active',
            end_date__gt=timezone.now()
        ).first()
        
        if not active_subscription:
            self.permission_denied(
                self.request, 
                message="No active subscription found"
            )
            
        return active_subscription


# Admin Views
class AdminSubscriptionListView(generics.ListAPIView):
    """
    Admin view to list all subscriptions
    """
    queryset = Subscription.objects.all()
    serializer_class = SubscriptionSerializer
    permission_classes = [permissions.IsAdminUser]


class AdminSubscriptionDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Admin view to retrieve, update or delete any subscription
    """
    queryset = Subscription.objects.all()
    serializer_class = SubscriptionSerializer
    permission_classes = [permissions.IsAdminUser]


class ExpiringSoonSubscriptionsView(generics.ListAPIView):
    """
    Admin view to list subscriptions expiring in the next 7 days
    """
    serializer_class = SubscriptionSerializer
    permission_classes = [permissions.IsAdminUser]
    
    def get_queryset(self):
        next_week = timezone.now() + timezone.timedelta(days=7)
        return Subscription.objects.filter(
            status='active',
            end_date__gt=timezone.now(),
            end_date__lte=next_week
        )


class RecentlyExpiredSubscriptionsView(generics.ListAPIView):
    """
    Admin view to list subscriptions that expired in the last 30 days
    """
    serializer_class = SubscriptionSerializer
    permission_classes = [permissions.IsAdminUser]
    
    def get_queryset(self):
        thirty_days_ago = timezone.now() - timezone.timedelta(days=30)
        return Subscription.objects.filter(
            Q(status='active') | Q(status='expired'),
            end_date__lt=timezone.now(),
            end_date__gt=thirty_days_ago
        )


class SubscriptionUpgradeView(APIView):
    """
    Upgrade user subscription to a different plan
    """
    permission_classes = [permissions.IsAuthenticated]
    
    def post(self, request):
        plan_id = request.data.get('plan_id')
        if not plan_id:
            return Response(
                {"error": "Plan ID is required"},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            # Get the selected plan
            new_plan = get_object_or_404(SubscriptionPlan, id=plan_id)
            
            # Check if plan is active
            if not new_plan.is_active:
                return Response(
                    {"error": "The selected plan is not currently available"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Get user's active subscription if any
            current_subscription = Subscription.objects.filter(
                user=request.user,
                status='active',
                end_date__gt=timezone.now()
            ).first()
            
            # If upgrading to paid plan, check if it's the same plan
            if current_subscription and current_subscription.plan.id == new_plan.id:
                return Response(
                    {"error": "You are already subscribed to this plan"},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Process payment if it's a paid plan
            if new_plan.price > 0:
                payment_method = request.data.get('payment_method', 'account_balance')
                payment_success, error_message = self.process_payment(
                    request.user, new_plan, payment_method)
                    
                if not payment_success:
                    return Response(
                        {"error": f"Payment failed: {error_message}"},
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            # If current subscription exists, end it
            if current_subscription:
                # If downgrading from paid to free, handle accordingly
                if current_subscription.plan.price > 0 and new_plan.price == 0:
                    # Optional: Prorate refund logic here
                    pass
                
                # Mark current subscription as cancelled
                current_subscription.status = 'cancelled'
                current_subscription.auto_renew = False
                current_subscription.save()
                
                # Log cancellation
                SubscriptionLog.objects.create(
                    subscription=current_subscription,
                    action='cancelled',
                    details=f"Cancelled due to upgrade to {new_plan.name} plan"
                )
            
            # Create new subscription
            new_subscription = Subscription.objects.create(
                user=request.user,
                plan=new_plan,
                status='active',  # Change to active since payment was successful
                start_date=timezone.now(),
                end_date=timezone.now() + timezone.timedelta(days=new_plan.duration_days),
                auto_renew=True,
                payment_method=request.data.get('payment_method', 'account_balance') if new_plan.price > 0 else None
            )
            
            # Log activation
            SubscriptionLog.objects.create(
                subscription=new_subscription,
                action='activated',
                details=f"{new_plan.name} plan activated"
            )
            
            # Return the new subscription
            serializer = SubscriptionSerializer(new_subscription)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            return Response(
                {"error": f"Failed to upgrade subscription: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def process_payment(self, user, plan, payment_method):
        """Process payment for a subscription"""
        if plan.price <= 0:
            return True, None  # Free plans don't need payment
            
        if payment_method == 'account_balance':
            # Check if user has sufficient balance
            if user.balance < plan.price:
                return False, "Insufficient balance"
                
            # Deduct from user balance
            user.balance -= plan.price
            user.save()
            
            # Create balance record
            from base.models import Balance
            Balance.objects.create(
                user=user,
                transaction_type='subscription',
                amount=plan.price,
                payable_amount=plan.price,
                completed=True,
                approved=True
            )
            
            return True, None
            
        # Add other payment methods as needed
        return False, "Payment method not supported"
