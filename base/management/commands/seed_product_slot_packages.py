from django.core.management.base import BaseCommand
from base.models import ProductSlotPackage

class Command(BaseCommand):
    help = 'Seeds the database with default product slot packages'

    def handle(self, *args, **kwargs):
        # Delete existing packages if requested
        if ProductSlotPackage.objects.exists():
            self.stdout.write('Product slot packages already exist. Use --flush to delete existing packages.')
            return

        # Create packages
        packages = [
            {
                'slots': 5,
                'price': 500,
                'is_featured': False
            },
            {
                'slots': 10,
                'price': 900,
                'original_price': 1000,
                'is_featured': False
            },
            {
                'slots': 20,
                'price': 1600,
                'original_price': 2000,
                'is_featured': True
            }
        ]

        for package_data in packages:
            ProductSlotPackage.objects.create(**package_data)
            self.stdout.write(f'Created package: {package_data["slots"]} slots for ৳{package_data["price"]}')
            
        self.stdout.write(self.style.SUCCESS('Successfully seeded product slot packages'))
