from django.utils import timezone
from .models import *

def get_user_subscription(user):
    """Get the user's active subscription"""
    if not user or user.is_anonymous:
        return None
    
    return Subscription.objects.filter(
        user=user,
        status='active',
        end_date__gt=timezone.now()
    ).select_related('plan').first()

def is_pro_subscriber(user):
    """Check if user has a pro subscription"""
    if not user or user.is_anonymous:
        return False
    
    subscription = get_user_subscription(user)
    if not subscription:
        return False
    
    # Pro subscribers have paid plans
    return subscription.plan.price > 0

def get_subscription_limits(user):
    """Get the limits for the user's current subscription"""
    subscription = get_user_subscription(user)
    if not subscription:
        # Default free limits
        return {
            'max_listings': 2,
            'featured_listings': 0
        }
    
    return {
        'max_listings': subscription.plan.max_listings,
        'featured_listings': subscription.plan.featured_listings
    }