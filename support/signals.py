from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from .models import SupportTicket, TicketReadStatus


@receiver(post_save, sender=SupportTicket)
def create_ticket_read_status(sender, instance, created, **kwargs):
    """
    When a new ticket is created, initialize the read status for the ticket owner.
    This ensures that admin-created tickets appear properly in user inboxes.
    """
    if created:
        # Create a TicketReadStatus for the ticket owner with timestamp set to ticket creation
        # This ensures the ticket appears as "unread" since any new activity will be after this timestamp
        TicketReadStatus.objects.get_or_create(
            ticket=instance,
            user=instance.user,
            defaults={
                'last_read_at': instance.created_at - timezone.timedelta(seconds=1)
            }
        )
