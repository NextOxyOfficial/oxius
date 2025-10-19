from django.core.management.base import BaseCommand
from business_network.models import BusinessNetworkMindforceCategory


class Command(BaseCommand):
    help = 'Create dummy MindForce categories'

    def handle(self, *args, **kwargs):
        categories = [
            'Programming & Development',
            'Business & Marketing',
            'Design & Creative',
            'Technology & IT',
            'Finance & Accounting',
            'Education & Training',
            'Health & Wellness',
            'Legal & Compliance',
            'Engineering & Architecture',
            'Science & Research',
            'Writing & Content',
            'Data & Analytics',
            'Project Management',
            'Customer Service',
            'Sales & Growth',
            'Other',
        ]

        created_count = 0
        existing_count = 0

        for category_name in categories:
            # Check if category already exists
            if BusinessNetworkMindforceCategory.objects.filter(name=category_name).exists():
                existing_count += 1
                self.stdout.write(
                    self.style.WARNING(f'Category "{category_name}" already exists')
                )
            else:
                category = BusinessNetworkMindforceCategory(name=category_name)
                category.save()
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'Created category: {category_name} (ID: {category.id})')
                )

        self.stdout.write(
            self.style.SUCCESS(
                f'\nSummary: {created_count} categories created, {existing_count} already existed'
            )
        )
