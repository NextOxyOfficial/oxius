"""Rideshare signals — driver application status emails."""

from django.db.models.signals import pre_save, post_save
from django.dispatch import receiver

from .models import DriverProfile


@receiver(pre_save, sender=DriverProfile)
def _capture_driver_approval_status(sender, instance, **kwargs):
    """Remember the prior approval_status so post_save can detect a transition."""
    if instance.pk:
        instance._old_approval_status = (
            sender.objects.filter(pk=instance.pk)
            .values_list("approval_status", flat=True)
            .first()
        )
    else:
        instance._old_approval_status = None


@receiver(post_save, sender=DriverProfile)
def _email_on_driver_approval_change(sender, instance, created, **kwargs):
    old = getattr(instance, "_old_approval_status", None)
    if created or old == instance.approval_status:
        return
    user = instance.user
    if not user or not getattr(user, "email", ""):
        return
    try:
        if instance.approval_status == "approved":
            from base.email_service import send_driver_approved_email
            send_driver_approved_email(user)
        elif instance.approval_status == "suspended":
            from base.email_service import send_driver_rejected_email
            send_driver_rejected_email(user)
    except Exception as e:
        print(f"Error sending driver approval email: {e}")
