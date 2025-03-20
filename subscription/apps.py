from django.apps import AppConfig


class SubscriptionConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'subscription'
    
    def ready(self):
        import subscription.signals  # This imports your signals
        
        # Create default plans
        from .models import SubscriptionPlan
        
        if not SubscriptionPlan.objects.filter(name='Free').exists():
            SubscriptionPlan.objects.get_or_create(
                name='Free',
                defaults={
                    'description': 'Basic plan with limited features',
                    'price': 0.00,
                    'duration_days': 36500,
                    'max_listings': 2,
                    'featured_listings': 0,
                    'is_active': True
                }
            )
        
        if not SubscriptionPlan.objects.filter(name='Pro').exists():
            SubscriptionPlan.objects.get_or_create(
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

