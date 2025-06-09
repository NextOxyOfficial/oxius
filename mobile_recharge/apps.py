from django.apps import AppConfig


class MobileRechargeConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'mobile_recharge'
    
    def ready(self):
        import mobile_recharge.signals
