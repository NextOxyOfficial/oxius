# Generated manually for production version-gate support.

from django.db import migrations, models


class Migration(migrations.Migration):
    initial = True

    dependencies = []

    operations = [
        migrations.CreateModel(
            name="AppVersionConfig",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("platform", models.CharField(choices=[("android", "Android"), ("ios", "iOS")], max_length=20)),
                ("latest_version", models.CharField(help_text="Example: 8.0.32", max_length=50)),
                ("latest_build", models.PositiveIntegerField(default=0, help_text="Example: 72")),
                ("minimum_supported_version", models.CharField(blank=True, default="", help_text="Versions below this can be forced to update. Example: 8.0.20", max_length=50)),
                ("minimum_supported_build", models.PositiveIntegerField(default=0, help_text="Builds below this can be forced to update. Example: 60")),
                ("force_update", models.BooleanField(default=False, help_text="When enabled, every outdated app must update before continuing.")),
                ("store_url", models.URLField(max_length=500)),
                ("title", models.CharField(default="Update available", max_length=120)),
                ("message", models.TextField(default="A new version of AdsyClub is available. Please update to continue.")),
                ("snooze_hours", models.PositiveIntegerField(default=24, help_text="Optional update popup delay after the user taps Later.")),
                ("is_active", models.BooleanField(default=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
            ],
            options={
                "verbose_name": "App Version Config",
                "verbose_name_plural": "App Version Configs",
                "ordering": ("platform", "-latest_build", "-updated_at"),
            },
        ),
        migrations.AddIndex(
            model_name="appversionconfig",
            index=models.Index(fields=["platform", "is_active"], name="appver_platform_active_idx"),
        ),
    ]
