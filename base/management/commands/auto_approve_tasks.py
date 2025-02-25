from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from base.models import MicroGigPostTask

class Command(BaseCommand):
    help = 'Auto-approve tasks that are older than 48 hours'

    def handle(self, *args, **kwargs):
        # Get tasks older than 48 hours that aren't completed/approved/rejected
        cutoff_time = timezone.now() - timedelta(hours=48)
        pending_tasks = MicroGigPostTask.objects.filter(
            created_at__lte=cutoff_time,
            completed=False,
            approved=False,
            rejected=False
        )

        count = 0
        for task in pending_tasks:
            task.approved = True
            task.save()
            count += 1

        self.stdout.write(
            self.style.SUCCESS(f'Successfully auto-approved {count} tasks')
        )