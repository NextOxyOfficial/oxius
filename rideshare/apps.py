from django.apps import AppConfig


class RideshareConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "rideshare"
    verbose_name = "Ride Share"

    def ready(self):
        from . import signals  # noqa: F401
