from celery import shared_task
from django.utils import timezone
from base.models import User
from .models import Subscription, SubscriptionLog
from .utils import manage_user_products_activation, deactivate_products_for_expired_subscriptions

@shared_task
def deactivate_expired_subscriptions():
    """
    Deactivate Pro subscriptions that have expired.
    This task handles both the new subscription system and legacy user fields.
    This task is scheduled to run daily via Celery Beat.
    """
    now = timezone.now()
    
    # Handle new subscription system - mark expired subscriptions
    expired_subscriptions = Subscription.objects.select_related('user', 'plan').filter(
        status='active',
        end_date__lt=now
    )
    
    expired_count = 0
    for subscription in expired_subscriptions:
        try:
            subscription.expire()  # This will also update user pro status
            
            # Deactivate user's products
            product_result = manage_user_products_activation(
                subscription.user, 
                activate=False, 
                reason=f"Subscription expired: {subscription.plan.name}"
            )
            
            # Log the expiration
            SubscriptionLog.objects.create(
                subscription=subscription,
                action='expired',
                details=f"Subscription expired automatically by system at {now.strftime('%Y-%m-%d %H:%M:%S')}. Products affected: {product_result.get('products_affected', 0)}"
            )
            expired_count += 1
            
            print(f"✓ Expired subscription for user: {subscription.user.email} (Plan: {subscription.plan.name}) - {product_result.get('products_affected', 0)} products deactivated")
            
        except Exception as e:
            print(f"✗ Error expiring subscription {subscription.id}: {str(e)}")
    
    # Handle legacy system - users with pro_validity that has passed
    legacy_expired_users = User.objects.filter(
        is_pro=True,
        pro_validity__lt=now
    )
    
    legacy_count = 0
    for user in legacy_expired_users:
        try:
            user.is_pro = False
            user.save(update_fields=['is_pro'])
            legacy_count += 1
            
            print(f"✓ Deactivated legacy pro status for user: {user.email}")
            
        except Exception as e:
            print(f"✗ Error deactivating legacy pro for user {user.id}: {str(e)}")
    
    total_count = expired_count + legacy_count
    
    result_message = f'Successfully deactivated {total_count} expired Pro subscriptions (New system: {expired_count}, Legacy: {legacy_count})'
    print(f"📊 {result_message}")
    
    return result_message