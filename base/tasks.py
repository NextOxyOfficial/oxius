from celery import shared_task
from django.utils import timezone
from datetime import timedelta
from .models import MicroGigPostTask

@shared_task
def check_and_auto_approve_tasks():
    cutoff_time = timezone.now() - timedelta(hours=48)
    pending_tasks = MicroGigPostTask.objects.filter(
        created_at__lte=cutoff_time,
        completed=False,
        approved=False,
        rejected=False
    )

    for task in pending_tasks:
        task.approved = True
        task.save()