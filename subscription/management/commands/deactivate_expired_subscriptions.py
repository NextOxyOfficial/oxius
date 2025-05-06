from django.core.management.base import BaseCommand
from django.utils import timezone
from base.models import User
from datetime import datetime

class Command(BaseCommand):
    help = 'Deactivate Pro subscriptions that have expired'

    def handle(self, *args, **options):
        today = timezone.now().date()
        
        # Find users with Pro status whose validity date has passed
        expired_users = User.objects.filter(
            is_pro=True,
            pro_validity__lt=today
        )
        
        count = expired_users.count()
        
        # Update their Pro status to False
        expired_users.update(is_pro=False)
        
        self.stdout.write(
            self.style.SUCCESS(f'Successfully deactivated {count} expired Pro subscriptions')
        )