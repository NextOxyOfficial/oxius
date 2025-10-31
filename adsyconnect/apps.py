from django.apps import AppConfig


class AdsyconnectConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'adsyconnect'
    verbose_name = 'AdsyConnect Chat'
    
    def ready(self):
        import adsyconnect.signals
