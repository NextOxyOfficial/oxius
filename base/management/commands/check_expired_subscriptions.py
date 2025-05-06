from django.core.management.base import BaseCommand
from django.utils import timezone
from base.models import User

class Command(BaseCommand):
    help = 'Check and deactivate expired pro subscriptions'

    def handle(self, *args, **kwargs):
        # Get all pro users whose validity has expired
        expired_users = User.objects.filter(
            is_pro=True,
            pro_validity__lt=timezone.now()
        )
        
        count = expired_users.count()
        
        # Deactivate pro status for expired users
        for user in expired_users:
            user.is_pro = False
            user.save(update_fields=['is_pro'])
            self.stdout.write(self.style.SUCCESS(f'Deactivated pro status for user: {user.email}'))
            
        self.stdout.write(self.style.SUCCESS(f'Successfully deactivated {count} expired pro subscriptions'))