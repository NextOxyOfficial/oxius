from django.core.management.base import BaseCommand
from django.utils import timezone
from subscription.utils import sync_products_with_subscription_status
import json


class Command(BaseCommand):
    help = 'Sync product activation status with user subscription status'

    def add_arguments(self, parser):
        parser.add_argument(
            '--username',
            type=str,
            help='Username of specific user to sync (optional)',
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be changed without making actual changes',
        )
        parser.add_argument(
            '--verbose',
            action='store_true',
            help='Show detailed output',
        )

    def handle(self, *args, **options):
        username = options.get('username')
        dry_run = options.get('dry_run')
        verbose = options.get('verbose')

        if dry_run:
            self.stdout.write(
                self.style.WARNING('DRY RUN MODE - No changes will be made')
            )

        try:
            if username:
                from base.models import User
                try:
                    user = User.objects.get(username=username)
                    self.stdout.write(f'Syncing products for user: {username}')
                    
                    if not dry_run:
                        result = sync_products_with_subscription_status(user=user)
                    else:
                        # For dry run, we'll simulate the result
                        from base.models import Product
                        user_products = Product.objects.filter(owner=user)
                        should_be_active = user.is_pro and (
                            user.pro_validity is None or user.pro_validity > timezone.now()
                        )
                        
                        if should_be_active:
                            inactive_count = user_products.filter(is_active=False).count()
                            result = {
                                'sync_type': f'dry_run_single_user_{username}',
                                'users_processed': 1,
                                'products_activated': inactive_count,
                                'products_deactivated': 0,
                                'message': f'Would activate {inactive_count} products'
                            }
                        else:
                            active_count = user_products.filter(is_active=True).count()
                            result = {
                                'sync_type': f'dry_run_single_user_{username}',
                                'users_processed': 1,
                                'products_activated': 0,
                                'products_deactivated': active_count,
                                'message': f'Would deactivate {active_count} products'
                            }
                    
                except User.DoesNotExist:
                    self.stdout.write(
                        self.style.ERROR(f'User "{username}" not found')
                    )
                    return
            else:
                self.stdout.write('Syncing products for all users...')
                
                if not dry_run:
                    result = sync_products_with_subscription_status()
                else:
                    # For dry run, provide summary without making changes
                    from base.models import User, Product
                    users_with_products = User.objects.filter(products__isnull=False).distinct()
                    total_changes = 0
                    
                    for user in users_with_products:
                        should_be_active = user.is_pro and (
                            user.pro_validity is None or user.pro_validity > timezone.now()
                        )
                        user_products = Product.objects.filter(owner=user)
                        
                        if should_be_active:
                            total_changes += user_products.filter(is_active=False).count()
                        else:
                            total_changes += user_products.filter(is_active=True).count()
                    
                    result = {
                        'sync_type': 'dry_run_all_users',
                        'users_processed': users_with_products.count(),
                        'total_potential_changes': total_changes,
                        'message': f'Would make {total_changes} product status changes'
                    }

            # Display results
            self.stdout.write(
                self.style.SUCCESS(f'\n=== Sync Results ===')
            )
            
            if username:
                self.stdout.write(f'User: {username}')
            else:
                self.stdout.write(f'Users processed: {result.get("users_processed", 0)}')
            
            if not dry_run:
                self.stdout.write(f'Products activated: {result.get("products_activated", 0)}')
                self.stdout.write(f'Products deactivated: {result.get("products_deactivated", 0)}')
            else:
                self.stdout.write(f'Potential changes: {result.get("total_potential_changes", 0)}')
            
            if verbose:
                self.stdout.write(f'\nDetailed results:')
                self.stdout.write(json.dumps(result, indent=2, default=str))

            self.stdout.write(
                self.style.SUCCESS('\nSync completed successfully!')
            )

        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'Error during sync: {str(e)}')
            )
            if verbose:
                import traceback
                self.stdout.write(traceback.format_exc())
