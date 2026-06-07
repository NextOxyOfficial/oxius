from django.apps import AppConfig


class EngagementConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "engagement"
    verbose_name = "Engagement & Assistant"

    def ready(self):
        # Wire the lightweight event hooks (kept separate so importing models
        # never pulls in signal side effects).
        import engagement.signals  # noqa: F401
