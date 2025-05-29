from django.apps import AppConfig


class SubscriptionConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'subscription'
    
    def ready(self):
        # Import signals when the app is ready
        import subscription.signals
        
        # Note: Default plan creation moved to a management command
        # to avoid database access during app initialization

