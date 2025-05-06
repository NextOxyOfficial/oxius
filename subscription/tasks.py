from celery import shared_task
from django.utils import timezone
from base.models import User

@shared_task
def deactivate_expired_subscriptions():
    """
    Deactivate Pro subscriptions that have expired.
    This task is scheduled to run daily via Celery Beat.
    """
    today = timezone.now().date()
    
    # Find users with Pro status whose validity date has passed
    expired_users = User.objects.filter(
        is_pro=True,
        pro_validity__lt=today
    )
    
    count = expired_users.count()
    
    # Update their Pro status to False
    expired_users.update(is_pro=False)
    
    return f'Successfully deactivated {count} expired Pro subscriptions'