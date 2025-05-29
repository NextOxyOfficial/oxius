from django.core.management.base import BaseCommand
from subscription.models import SubscriptionPlan


class Command(BaseCommand):
    help = 'Create default subscription plans (Free and Pro)'

    def handle(self, *args, **options):
        self.stdout.write('Creating default subscription plans...')
        
        try:
            # Create Free plan if it doesn't exist
            free_plan, created = SubscriptionPlan.objects.get_or_create(
                name='Free',
                defaults={
                    'description': 'Basic plan with limited features',
                    'price': 0.00,
                    'duration_days': 36500,  # ~100 years
                    'max_listings': 2,
                    'featured_listings': 0,
                    'is_active': True
                }
            )
            
            if created:
                self.stdout.write(
                    self.style.SUCCESS('Successfully created Free plan')
                )
            else:
                self.stdout.write('Free plan already exists')

            # Create Pro plan if it doesn't exist
            pro_plan, created = SubscriptionPlan.objects.get_or_create(
                name='Pro',
                defaults={
                    'description': 'Premium access with advanced features',
                    'price': 499.00,
                    'duration_days': 30,
                    'max_listings': 10,
                    'featured_listings': 2,
                    'is_active': True
                }
            )
            
            if created:
                self.stdout.write(
                    self.style.SUCCESS('Successfully created Pro plan')
                )
            else:
                self.stdout.write('Pro plan already exists')
                
            self.stdout.write(
                self.style.SUCCESS('Default subscription plans setup completed!')
            )
            
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'Failed to create default subscription plans: {e}')
            )
            raise
