from django.apps import AppConfig


class ZonalConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'zonal'

    def ready(self):
        from . import signals  # noqa: F401  (register rate-change loggers)
