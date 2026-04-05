from django.core.management.base import BaseCommand
from django.utils import timezone
from subscription.utils import expire_due_subscriptions

class Command(BaseCommand):
    help = 'Deactivate Pro subscriptions that have expired'

    def handle(self, *args, **options):
        result = expire_due_subscriptions(now=timezone.now(), trigger='management-command')

        for item in result['expired_results']:
            self.stdout.write(
                self.style.SUCCESS(
                    f"Expired subscription {item['subscription_id']} for user {item['user_id']} ({item['plan']})"
                )
            )

        for item in result['legacy_results']:
            self.stdout.write(
                self.style.SUCCESS(
                    f"Deactivated legacy pro for user {item['username']} ({item['products_affected']} products affected)"
                )
            )

        self.stdout.write(
            self.style.SUCCESS(
                'Successfully deactivated '
                f"{result['total_processed']} expired Pro subscriptions "
                f"(New system: {result['subscriptions_expired']}, Legacy: {result['legacy_users_deactivated']})"
            )
        )