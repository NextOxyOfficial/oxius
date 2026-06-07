from django.utils import timezone
from django.db.models import Q
from base.models import User, Product
from .models import Subscription, SubscriptionPlan, SubscriptionLog


STORE_SUBSCRIPTION_EXPIRED_CODE = 'STORE_SUBSCRIPTION_EXPIRED'
STORE_SUBSCRIPTION_EXPIRED_MESSAGE_BN = (
    'এই স্টোরের সাবস্ক্রিপশনের মেয়াদ শেষ হয়েছে। '
    'সাবস্ক্রিপশন নবায়ন করলে স্টোরটি আবার দেখা যাবে।'
)


def has_current_pro_access(user, now=None):
    """Return True only while a user's pro access is currently valid."""
    if not user or getattr(user, 'is_anonymous', False):
        return False

    now = now or timezone.now()
    if not getattr(user, 'is_pro', False):
        return False

    pro_validity = getattr(user, 'pro_validity', None)
    return pro_validity is None or pro_validity > now


def public_store_queryset(queryset=None, now=None):
    """Stores that are visible to visitors/customers."""
    now = now or timezone.now()
    if queryset is None:
        queryset = User.objects.all()
    return queryset.filter(is_pro=True).filter(
        Q(pro_validity__isnull=True) | Q(pro_validity__gt=now)
    )


def public_product_queryset(queryset=None, now=None):
    """Products that may appear in public eShop surfaces."""
    now = now or timezone.now()
    if queryset is None:
        queryset = Product.objects.all()
    return (
        queryset.filter(is_active=True, owner__isnull=False, owner__is_pro=True)
        .filter(Q(owner__pro_validity__isnull=True) | Q(owner__pro_validity__gt=now))
    )


def sync_user_subscription_state(user, now=None, trigger='request'):
    """Expire stale subscriptions and align user pro/product state immediately."""
    if not user or getattr(user, 'is_anonymous', False):
        return {'is_pro_active': False, 'products_affected': 0}

    now = now or timezone.now()
    expired_count = 0
    products_affected = 0

    expired_subscriptions = Subscription.objects.select_related('plan').filter(
        user=user,
        status='active',
        end_date__isnull=False,
        end_date__lte=now,
    )
    for subscription in expired_subscriptions:
        subscription.expire()
        SubscriptionLog.objects.create(
            subscription=subscription,
            action='expired',
            details=f'Subscription expired automatically by {trigger}',
        )
        expired_count += 1

    active_paid_subscription = Subscription.objects.filter(
        user=user,
        status='active',
        end_date__gt=now,
        plan__price__gt=0,
    ).order_by('-end_date').first()

    if active_paid_subscription:
        updates = []
        if not user.is_pro:
            user.is_pro = True
            updates.append('is_pro')
        if user.pro_validity != active_paid_subscription.end_date:
            user.pro_validity = active_paid_subscription.end_date
            updates.append('pro_validity')
        if updates:
            user.save(update_fields=updates)
        result = manage_user_products_activation(
            user,
            activate=True,
            reason=f'Active paid subscription sync via {trigger}',
        )
        products_affected += result.get('products_affected', 0)
        return {
            'is_pro_active': True,
            'expired_subscriptions': expired_count,
            'products_affected': products_affected,
        }

    if user.is_pro and user.pro_validity is None:
        result = manage_user_products_activation(
            user,
            activate=True,
            reason=f'Legacy pro access sync via {trigger}',
        )
        products_affected += result.get('products_affected', 0)
        return {
            'is_pro_active': True,
            'expired_subscriptions': expired_count,
            'products_affected': products_affected,
        }

    if user.is_pro or user.pro_validity is not None:
        user.is_pro = False
        user.pro_validity = None
        user.save(update_fields=['is_pro', 'pro_validity'])

    result = manage_user_products_activation(
        user,
        activate=False,
        reason=f'No active paid subscription via {trigger}',
    )
    products_affected += result.get('products_affected', 0)
    return {
        'is_pro_active': False,
        'expired_subscriptions': expired_count,
        'products_affected': products_affected,
    }


def expire_due_subscriptions(now=None, trigger='system'):
    """Expire due subscriptions and sync legacy pro flags.

    This is the single source of truth for automated subscription expiry.
    It is safe to call repeatedly from Celery, cron, or a systemd timer.
    """
    now = now or timezone.now()

    expired_count = 0
    expired_results = []

    expired_subscriptions = Subscription.objects.select_related('user', 'plan').filter(
        status='active',
        end_date__isnull=False,
        end_date__lte=now,
    )

    for subscription in expired_subscriptions:
        subscription.expire()
        SubscriptionLog.objects.create(
            subscription=subscription,
            action='expired',
            details=(
                f"Subscription expired automatically by {trigger} at "
                f"{now.strftime('%Y-%m-%d %H:%M:%S')}"
            ),
        )
        expired_count += 1
        expired_results.append(
            {
                'subscription_id': subscription.id,
                'user_id': subscription.user_id,
                'plan': subscription.plan.name,
            }
        )

    legacy_count = 0
    legacy_results = []

    legacy_expired_users = User.objects.filter(
        is_pro=True,
        pro_validity__isnull=False,
        pro_validity__lte=now,
    )

    for user in legacy_expired_users:
        active_paid_subscription = Subscription.objects.filter(
            user=user,
            status='active',
            end_date__gt=now,
            plan__price__gt=0,
        ).order_by('-end_date').first()

        if active_paid_subscription:
            latest_end = active_paid_subscription.end_date
            updates = []
            if not user.is_pro:
                user.is_pro = True
                updates.append('is_pro')
            if user.pro_validity != latest_end:
                user.pro_validity = latest_end
                updates.append('pro_validity')
            if updates:
                user.save(update_fields=updates)
            continue

        user.is_pro = False
        user.pro_validity = None
        user.save(update_fields=['is_pro', 'pro_validity'])
        product_result = manage_user_products_activation(
            user,
            activate=False,
            reason=f"Legacy pro validity expired via {trigger}",
        )
        legacy_count += 1
        legacy_results.append(
            {
                'user_id': user.id,
                'username': user.username,
                'products_affected': product_result.get('products_affected', 0),
            }
        )

    return {
        'timestamp': now,
        'trigger': trigger,
        'subscriptions_expired': expired_count,
        'legacy_users_deactivated': legacy_count,
        'expired_results': expired_results,
        'legacy_results': legacy_results,
        'total_processed': expired_count + legacy_count,
    }

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

def manage_user_products_activation(user, activate=True, reason=""):
    """
    Activate or deactivate all products owned by a user based on subscription status.
    
    Args:
        user: User instance
        activate: Boolean - True to activate products, False to deactivate
        reason: String describing the reason for the change (for logging)
    
    Returns:
        dict: Summary of changes made
    """
    if not user:
        return {"error": "User not provided"}
    
    # Get all products owned by the user
    user_products = Product.objects.filter(owner=user)
    
    if not user_products.exists():
        return {
            "user": user.username,
            "action": "activate" if activate else "deactivate",
            "products_affected": 0,
            "message": "No products found for user"
        }
    
    # Count products that will be affected (only those that need status change)
    products_to_update = user_products.filter(is_active=not activate)
    affected_count = products_to_update.count()
    
    # Update product activation status
    if affected_count > 0:
        products_to_update.update(is_active=activate)
    
    action_word = "activated" if activate else "deactivated"
    
    return {
        "user": user.username,
        "action": "activate" if activate else "deactivate",
        "products_affected": affected_count,
        "total_products": user_products.count(),
        "reason": reason,
        "message": f"{affected_count} products {action_word} for user {user.username}"
    }


def deactivate_products_for_expired_subscriptions():
    """
    Deactivate products for users whose pro subscriptions have expired.
    This function should be called when subscriptions expire.
    
    Returns:
        dict: Summary of all changes made
    """
    now = timezone.now()
    
    # Find users whose pro status has expired but is_pro is still True
    expired_pro_users = User.objects.filter(
        is_pro=True,
        pro_validity__lt=now
    )
    
    results = []
    total_affected = 0
    
    for user in expired_pro_users:
        result = manage_user_products_activation(
            user, 
            activate=False, 
            reason=f"Pro subscription expired on {user.pro_validity}"
        )
        results.append(result)
        total_affected += result.get("products_affected", 0)
    
    return {
        "timestamp": now,
        "total_users_processed": len(results),
        "total_products_deactivated": total_affected,
        "user_results": results
    }


def reactivate_products_for_renewed_subscriptions():
    """
    Reactivate products for users whose pro subscriptions are active.
    This function should be called when subscriptions are renewed or activated.
    
    Returns:
        dict: Summary of all changes made
    """
    now = timezone.now()
    
    # Find users who have active pro status but might have deactivated products
    active_pro_users = User.objects.filter(
        is_pro=True,
        pro_validity__gt=now
    )
    
    results = []
    total_affected = 0
    
    for user in active_pro_users:
        # Only reactivate if user has inactive products (to avoid unnecessary updates)
        if Product.objects.filter(owner=user, is_active=False).exists():
            result = manage_user_products_activation(
                user, 
                activate=True, 
                reason=f"Pro subscription active until {user.pro_validity}"
            )
            results.append(result)
            total_affected += result.get("products_affected", 0)
    
    return {
        "timestamp": now,
        "total_users_processed": len(results),
        "total_products_reactivated": total_affected,
        "user_results": results
    }


def sync_products_with_subscription_status(user=None):
    """
    Sync product activation status with user's subscription status.
    Can be used for a specific user or all users.
    
    Args:
        user: User instance (optional) - if provided, only sync this user's products
        
    Returns:
        dict: Summary of changes made
    """
    now = timezone.now()
    
    if user:
        users_to_check = [user]
    else:
        # Get all users who have products
        users_to_check = User.objects.filter(products__isnull=False).distinct()
    
    activated_results = []
    deactivated_results = []
    
    for user_obj in users_to_check:
        # Check if user should have active products based on subscription status
        should_be_active = user_obj.is_pro and (
            user_obj.pro_validity is None or user_obj.pro_validity > now
        )
        
        # Get current product status
        user_products = Product.objects.filter(owner=user_obj)
        if not user_products.exists():
            continue
            
        # Check if products need status update
        if should_be_active:
            # User should have active products - activate any inactive ones
            inactive_products = user_products.filter(is_active=False)
            if inactive_products.exists():
                result = manage_user_products_activation(
                    user_obj,
                    activate=True,
                    reason="Subscription sync - user has active pro status"
                )
                activated_results.append(result)
        else:
            # User should have inactive products - deactivate any active ones
            active_products = user_products.filter(is_active=True)
            if active_products.exists():
                result = manage_user_products_activation(
                    user_obj,
                    activate=False,
                    reason="Subscription sync - user has expired/no pro status"
                )
                deactivated_results.append(result)
    
    total_activated = sum(r.get("products_affected", 0) for r in activated_results)
    total_deactivated = sum(r.get("products_affected", 0) for r in deactivated_results)
    
    return {
        "timestamp": now,
        "sync_type": f"single_user_{user.username}" if user else "all_users",
        "users_processed": len(users_to_check),
        "products_activated": total_activated,
        "products_deactivated": total_deactivated,
        "activation_results": activated_results,
        "deactivation_results": deactivated_results
    }
