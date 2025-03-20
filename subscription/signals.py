from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from django.utils import timezone
from .models import Subscription, SubscriptionPlan, SubscriptionLog

User = get_user_model()

@receiver(post_save, sender=User)
def create_free_subscription(sender, instance, created, **kwargs):
    """Create a free subscription for new users"""
    if created:
        try:
            # Get the free plan
            free_plan = SubscriptionPlan.objects.get(name='Free')
            
            # Create subscription
            subscription = Subscription.objects.create(
                user=instance,
                plan=free_plan,
                status='active',
                start_date=timezone.now(),
                end_date=timezone.now() + timezone.timedelta(days=free_plan.duration_days),
                auto_renew=True
            )
            
            # Log the subscription creation
            SubscriptionLog.objects.create(
                subscription=subscription,
                action='created',
                details="Free subscription automatically created for new user"
            )
        except SubscriptionPlan.DoesNotExist:
            # Log this somewhere, the Free plan doesn't exist
            print("Error: Free subscription plan not found")