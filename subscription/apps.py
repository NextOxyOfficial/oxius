from django.apps import AppConfig
import os
import sys

class SubscriptionConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'subscription'
    
    def ready(self):
        # Only run when not in a management command or only in certain commands
        if 'runserver' in sys.argv or 'uwsgi' in sys.argv or 'gunicorn' in sys.argv:
            # Import signals (moved from top-level to avoid import issues)
            import subscription.signals
            
            # Create default plans - safely
            self.create_default_plans()
    
    def create_default_plans(self):
        # Import models here to avoid circular imports
        from .models import SubscriptionPlan
        
        # Skip during migrations or when testing
        if 'makemigrations' in sys.argv or 'migrate' in sys.argv or 'test' in sys.argv:
            return
            
        try:
            # Create Free plan if it doesn't exist
            if not SubscriptionPlan.objects.filter(name='Free').exists():
                SubscriptionPlan.objects.get_or_create(
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
            
            # Create Pro plan if it doesn't exist
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
                
        except Exception as e:
            # Log the error but don't crash the application
            # This prevents issues during migrations or tests
            print(f"Warning: Failed to create default subscription plans: {e}")

