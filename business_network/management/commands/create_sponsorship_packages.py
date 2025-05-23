from django.core.management.base import BaseCommand
from business_network.models import SponsorshipPackage

class Command(BaseCommand):
    help = 'Create initial sponsorship packages'

    def handle(self, *args, **options):
        packages = [
            {
                'name': '1 Month Gold Sponsor',
                'description': 'Premium visibility for 1 month with featured placement',
                'price': 2999.00,
                'duration_months': 1,
                'is_active': True
            },
            {
                'name': '3 Months Gold Sponsor',
                'description': 'Premium visibility for 3 months with 10% discount',
                'price': 8099.00,
                'duration_months': 3,
                'is_active': True
            },
            {
                'name': '6 Months Gold Sponsor',
                'description': 'Premium visibility for 6 months with 15% discount',
                'price': 15299.00,
                'duration_months': 6,
                'is_active': True
            },
            {
                'name': '12 Months Gold Sponsor',
                'description': 'Premium visibility for 1 year with 20% discount - Best Value!',
                'price': 28799.00,
                'duration_months': 12,
                'is_active': True
            }
        ]
        
        created_count = 0
        for package_data in packages:
            package, created = SponsorshipPackage.objects.get_or_create(
                name=package_data['name'],
                defaults=package_data
            )
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'Created package: {package.name}')
                )
            else:
                self.stdout.write(
                    self.style.WARNING(f'Package already exists: {package.name}')
                )
        
        self.stdout.write(
            self.style.SUCCESS(f'Created {created_count} new sponsorship packages')
        )
