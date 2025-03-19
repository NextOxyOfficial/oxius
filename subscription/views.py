
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
