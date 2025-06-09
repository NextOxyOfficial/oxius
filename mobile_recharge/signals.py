from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from .models import Recharge


@receiver(pre_save, sender=Recharge)
def store_previous_status(sender, instance, **kwargs):
    """Store the previous status before saving"""
    if instance.pk:
        try:
            previous = Recharge.objects.get(pk=instance.pk)
            instance._previous_status = previous.status
        except Recharge.DoesNotExist:
            instance._previous_status = None
    else:
        instance._previous_status = None


@receiver(post_save, sender=Recharge)
def handle_recharge_status_change(sender, instance, created, **kwargs):
    """
    Signal to handle mobile recharge status changes
    Create notification when recharge is approved (status changed to 'completed')
    """
    print(f"=== RECHARGE SIGNAL TRIGGERED ===")
    print(f"Created: {created}")
    print(f"Instance ID: {instance.id}")
    print(f"Current status: {instance.status}")
    print(f"Previous status: {getattr(instance, '_previous_status', 'Unknown')}")
    print(f"User: {instance.user}")
    
    # Only process if this is an update (not a new creation)
    if not created and hasattr(instance, '_previous_status'):
        previous_status = instance._previous_status
        current_status = instance.status
        
        print(f"Processing status change: {previous_status} -> {current_status}")
        
        # Check if status changed from pending to completed
        if previous_status == 'pending' and current_status == 'completed':
            print(f"✅ Status changed to completed! Creating notification...")
            try:
                from base.views import create_mobile_recharge_notification
                notification = create_mobile_recharge_notification(
                    user=instance.user,
                    amount=instance.amount,
                    phone_number=instance.phone_number
                )
                print(f"✅ Successfully created notification: {notification.title}")
                print(f"Notification ID: {notification.id}")
            except Exception as e:
                print(f"❌ Error creating mobile recharge notification: {e}")
                import traceback
                traceback.print_exc()
        else:
            print(f"ℹ️ No notification needed for status change: {previous_status} -> {current_status}")
    else:
        if created:
            print(f"ℹ️ New recharge created with status: {instance.status}")
        else:
            print(f"ℹ️ Update without previous status tracking")
    
    print(f"=== END RECHARGE SIGNAL ===\n")
