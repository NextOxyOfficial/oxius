import decimal
import django.db.models.deletion
import uuid

from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ("rideshare", "0002_add_targeted_driver_fields"),
    ]

    operations = [
        migrations.CreateModel(
            name="RideshareSettings",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("platform_fee_percent", models.DecimalField(decimal_places=2, default=decimal.Decimal("5.00"), max_digits=5)),
                ("driver_response_timeout_seconds", models.PositiveIntegerField(default=60)),
                ("max_search_window_minutes", models.PositiveIntegerField(default=15)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
            ],
            options={
                "verbose_name": "Rideshare Settings",
                "verbose_name_plural": "Rideshare Settings",
            },
        ),
        migrations.AddField(
            model_name="ride",
            name="driver_payout_amount",
            field=models.DecimalField(decimal_places=2, default=decimal.Decimal("0.00"), max_digits=10),
        ),
        migrations.AddField(
            model_name="ride",
            name="early_completion_distance_km",
            field=models.DecimalField(blank=True, decimal_places=2, max_digits=8, null=True),
        ),
        migrations.AddField(
            model_name="ride",
            name="early_completion_duration_seconds",
            field=models.PositiveIntegerField(default=0),
        ),
        migrations.AddField(
            model_name="ride",
            name="early_completion_fare",
            field=models.DecimalField(blank=True, decimal_places=2, max_digits=10, null=True),
        ),
        migrations.AddField(
            model_name="ride",
            name="early_completion_requested_at",
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="ride",
            name="platform_fee_amount",
            field=models.DecimalField(decimal_places=2, default=decimal.Decimal("0.00"), max_digits=10),
        ),
        migrations.AddField(
            model_name="ride",
            name="platform_fee_percent",
            field=models.DecimalField(decimal_places=2, default=decimal.Decimal("0.00"), max_digits=5),
        ),
        migrations.AddField(
            model_name="ride",
            name="search_expires_at",
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AlterField(
            model_name="ride",
            name="status",
            field=models.CharField(
                choices=[
                    ("requested", "Requested"),
                    ("searching_driver", "Searching Driver"),
                    ("accepted", "Accepted"),
                    ("driver_arriving", "Driver Arriving"),
                    ("in_progress", "In Progress"),
                    ("awaiting_passenger_confirmation", "Awaiting Passenger Confirmation"),
                    ("completed", "Completed"),
                    ("cancelled", "Cancelled"),
                ],
                default="requested",
                max_length=40,
            ),
        ),
        migrations.AlterField(
            model_name="ridestatushistory",
            name="status",
            field=models.CharField(
                choices=[
                    ("requested", "Requested"),
                    ("searching_driver", "Searching Driver"),
                    ("accepted", "Accepted"),
                    ("driver_arriving", "Driver Arriving"),
                    ("in_progress", "In Progress"),
                    ("awaiting_passenger_confirmation", "Awaiting Passenger Confirmation"),
                    ("completed", "Completed"),
                    ("cancelled", "Cancelled"),
                ],
                max_length=40,
            ),
        ),
        migrations.CreateModel(
            name="RideCancellationReport",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("details", models.TextField(blank=True, default="")),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("reported_driver", models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name="cancellation_reports", to="rideshare.driverprofile")),
                ("reporter", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="ride_cancellation_reports", to=settings.AUTH_USER_MODEL)),
                ("ride", models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name="cancellation_reports", to="rideshare.ride")),
            ],
            options={
                "ordering": ["-created_at"],
                "unique_together": {("ride", "reporter")},
            },
        ),
    ]