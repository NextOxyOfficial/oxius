from celery import shared_task
from django.utils import timezone
from .utils import expire_due_subscriptions

@shared_task
def deactivate_expired_subscriptions():
    """
    Deactivate Pro subscriptions that have expired.
    This task handles both the new subscription system and legacy user fields.
    This task is scheduled to run daily via Celery Beat.
    """
    result = expire_due_subscriptions(now=timezone.now(), trigger='celery')
    result_message = (
        'Successfully deactivated '
        f"{result['total_processed']} expired Pro subscriptions "
        f"(New system: {result['subscriptions_expired']}, "
        f"Legacy: {result['legacy_users_deactivated']})"
    )
    print(f"📊 {result_message}")
    return result_message