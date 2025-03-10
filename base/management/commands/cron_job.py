from django.core.management.base import BaseCommand, CommandError
from base.models import MicroGigPostTask
from django.utils import timezone
from datetime import timedelta

class Command(BaseCommand):
    help = "Auto approve"

    def handle(self, *args, **options):
        cutoff_time = timezone.now() - timedelta(hours=45)
        pending_tasks = MicroGigPostTask.objects.filter(completed=False, approved=False, created_at__lt=cutoff_time)
        print('Available for auto approve:',len(pending_tasks))
        for task in pending_tasks:
            task.approved = True
            task.completed = True
            task.save()
            
            self.stdout.write(
                self.style.SUCCESS('Successfully processed task "%s"' % task.id)
            )