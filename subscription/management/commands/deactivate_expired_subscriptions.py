from django.core.management.base import BaseCommand
from django.utils import timezone
from base.models import User
from subscription.models import Subscription, SubscriptionLog

class Command(BaseCommand):
    help = 'Deactivate Pro subscriptions that have expired'

    def handle(self, *args, **options):
        now = timezone.now()
        
        # Handle new subscription system - mark expired subscriptions
        expired_subscriptions = Subscription.objects.filter(
            status='active',
            end_date__lt=now
        )
        
        expired_count = 0
        for subscription in expired_subscriptions:
            subscription.expire()  # This will also update user pro status
            
            # Log the expiration
            SubscriptionLog.objects.create(
                subscription=subscription,
                action='expired',
                details="Subscription expired automatically by management command"
            )
            expired_count += 1
            
            self.stdout.write(
                self.style.SUCCESS(f'Expired subscription for user: {subscription.user.email}')
            )
        
        # Handle legacy system - users with pro_validity that has passed
        legacy_expired_users = User.objects.filter(
            is_pro=True,
            pro_validity__lt=now
        )
        
        legacy_count = legacy_expired_users.count()
        
        # Update their Pro status to False
        for user in legacy_expired_users:
            user.is_pro = False
            user.save(update_fields=['is_pro'])
            self.stdout.write(
                self.style.SUCCESS(f'Deactivated legacy pro status for user: {user.email}')
            )
        
        total_count = expired_count + legacy_count
        
        self.stdout.write(
            self.style.SUCCESS(f'Successfully deactivated {total_count} expired Pro subscriptions (New system: {expired_count}, Legacy: {legacy_count})')
        )