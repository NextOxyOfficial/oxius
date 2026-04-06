from decimal import Decimal

from django.db import migrations, models


def ensure_rideshare_settings(apps, schema_editor):
    RideshareSettings = apps.get_model("rideshare", "RideshareSettings")
    if RideshareSettings.objects.exists():
        return

    RideshareSettings.objects.create(
        platform_fee_percent=Decimal("5.00"),
        driver_response_timeout_seconds=60,
        max_search_window_minutes=15,
        max_passenger_search_radius_km=Decimal("15.00"),
    )


class Migration(migrations.Migration):

    dependencies = [
        ("rideshare", "0009_driverprofile_driver_details_and_additional_documents"),
    ]

    operations = [
        migrations.AddField(
            model_name="ridesharesettings",
            name="google_maps_api_key",
            field=models.CharField(
                blank=True,
                default="",
                help_text="Optional override for Google Places and Geocoding. Leave blank to use the server environment variable.",
                max_length=255,
            ),
        ),
        migrations.RunPython(ensure_rideshare_settings, migrations.RunPython.noop),
    ]