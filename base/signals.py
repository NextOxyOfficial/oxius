from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from .models import AdminNotice, ClassifiedCategoryPost, FCMToken, MicroGigPost


@receiver(pre_save, sender=MicroGigPost)
def store_previous_gig_status(sender, instance, **kwargs):
    """Store the previous gig status before saving"""
    if instance.pk:
        try:
            previous = MicroGigPost.objects.get(pk=instance.pk)
            instance._previous_gig_status = previous.gig_status
        except MicroGigPost.DoesNotExist:
            instance._previous_gig_status = None
    else:
        instance._previous_gig_status = None


@receiver(post_save, sender=MicroGigPost)
def handle_gig_status_change(sender, instance, created, **kwargs):
    """
    Signal to handle gig status changes
    Create notification when gig is approved (status changed from 'pending' to 'approved')
    """
    print(f"=== GIG STATUS SIGNAL TRIGGERED ===")
    print(f"Created: {created}")
    print(f"Instance ID: {instance.id}")
    print(f"Current gig_status: {instance.gig_status}")
    print(f"Previous gig_status: {getattr(instance, '_previous_gig_status', 'Unknown')}")
    print(f"User: {instance.user}")
    
    # Only process if this is an update (not a new creation)
    if not created and hasattr(instance, '_previous_gig_status'):
        previous_status = instance._previous_gig_status
        current_status = instance.gig_status
        
        print(f"Processing gig status change: {previous_status} -> {current_status}")
          # Check if status changed from pending to approved
        if previous_status == 'pending' and current_status == 'approved':
            print(f"✅ Gig status changed to approved! Creating notification...")
            try:
                # Check if notification already exists for this gig to prevent duplicates
                from .models import AdminNotice
                existing_notification = AdminNotice.objects.filter(
                    user=instance.user,
                    notification_type='gig_approved',
                    reference_id=str(instance.id)
                ).first()
                
                if existing_notification:
                    print(f"⚠️ Notification already exists for gig {instance.id}, skipping creation")
                    return
                
                from .views import create_gig_approved_notification
                notification = create_gig_approved_notification(
                    user=instance.user,
                    gig_id=instance.id,
                    gig_title=instance.title,
                    reference_id=str(instance.id)  # Pass gig ID as reference
                )
                print(f"✅ Successfully created approval notification: {notification.title}")
                print(f"Notification ID: {notification.id}")
            except Exception as e:
                print(f"❌ Error creating gig approval notification: {e}")
                import traceback
                traceback.print_exc()
        
        # Check if status changed from pending to rejected
        elif previous_status == 'pending' and current_status == 'rejected':
            print(f"❌ Gig status changed to rejected! Creating notification...")
            try:
                # Check if notification already exists for this gig to prevent duplicates
                from .models import AdminNotice
                existing_notification = AdminNotice.objects.filter(
                    user=instance.user,
                    notification_type='gig_rejected',
                    reference_id=str(instance.id)
                ).first()
                
                if existing_notification:
                    print(f"⚠️ Rejection notification already exists for gig {instance.id}, skipping creation")
                    return
                
                from .views import create_gig_rejected_notification
                notification = create_gig_rejected_notification(
                    user=instance.user,
                    gig_id=instance.id,
                    gig_title=instance.title,
                    reference_id=str(instance.id)  # Pass gig ID as reference
                )
                print(f"✅ Successfully created rejection notification: {notification.title}")
                print(f"Notification ID: {notification.id}")
            except Exception as e:
                print(f"❌ Error creating gig rejection notification: {e}")
                import traceback
                traceback.print_exc()
        else:
            print(f"ℹ️ No notification needed for gig status change: {previous_status} -> {current_status}")
    else:
        if created:
            print(f"ℹ️ New gig created with status: {instance.gig_status}")
        else:
            print(f"ℹ️ Update without previous status tracking")
    
    print(f"=== END GIG STATUS SIGNAL ===\n")


SITE = "https://adsyclub.com"

# Notice types that should fire a push, with the in-app deep link to open on tap.
PUSHABLE_NOTICE_TYPES = {
    # financial
    "withdraw_successful": f"{SITE}/deposit-withdraw",
    "mobile_recharge_successful": f"{SITE}/mobile-recharge",
    "transfer_sent": f"{SITE}/deposit-withdraw",
    "transfer_received": f"{SITE}/deposit-withdraw",
    "deposit_successful": f"{SITE}/deposit-withdraw",
    # approvals — let the user know the moment their thing goes live
    "kyc_approved": f"{SITE}/my-account",
    "kyc_rejected": f"{SITE}/my-account",
    "gig_approved": f"{SITE}/micro-gigs",
    "gig_rejected": f"{SITE}/micro-gigs",
    "service_approved": f"{SITE}/classified",
    "sale_approved": f"{SITE}/sale",
    "sponsor_approved": f"{SITE}/business-network",
}


@receiver(post_save, sender=AdminNotice)
def send_financial_notice_push(sender, instance, created, **kwargs):
    if not created or instance.user_id is None:
        return

    deep_link = PUSHABLE_NOTICE_TYPES.get(instance.notification_type)
    if not deep_link:
        return

    tokens = list(
        FCMToken.objects.filter(user=instance.user, is_active=True).values_list(
            "token", flat=True
        )
    )
    if not tokens:
        return

    from .fcm_service import send_fcm_notification

    payload = {
        "type": instance.notification_type,
        "notification_type": instance.notification_type,
        "reference_id": instance.reference_id or "",
        "amount": str(instance.amount) if instance.amount is not None else "",
        "deep_link": deep_link,
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
    }

    for token in tokens:
        send_fcm_notification(
            fcm_token=token,
            title=instance.title,
            body=instance.message,
            data=payload,
        )


@receiver(pre_save, sender=ClassifiedCategoryPost)
def _store_prev_service_status(sender, instance, **kwargs):
    if instance.pk:
        prev = sender.objects.filter(pk=instance.pk).values_list(
            "service_status", flat=True
        ).first()
        instance._prev_service_status = prev
    else:
        instance._prev_service_status = None


@receiver(post_save, sender=ClassifiedCategoryPost)
def _notify_service_approved(sender, instance, created, **kwargs):
    """Push (+ in-app) when an 'আমার সেবা' post goes pending -> approved."""
    if created or not instance.user_id:
        return
    prev = getattr(instance, "_prev_service_status", None)
    if prev != "approved" and instance.service_status == "approved":
        try:
            AdminNotice.objects.create(
                user_id=instance.user_id,
                notification_type="service_approved",
                title="আপনার সেবা লাইভ হয়েছে ✅",
                message=f"“{instance.title}” এখন ‘আমার সেবা’-তে সবাই দেখতে পাচ্ছেন। "
                        "নতুন কাস্টমার আসা শুরু হবে।",
                reference_id=str(instance.id),
            )
        except Exception as e:
            print(f"Error creating service approved notice: {e}")
