from django.apps import AppConfig


class BusinessNetworkConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'business_network'
    
    def ready(self):
        """Import signals when the app is ready"""
        import business_network.signals
