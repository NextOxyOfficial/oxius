"""
Data migration: create FareConfig + FareDistanceTier for bike, car, cng.

Tiered pricing keeps local city rides cheap and scales long-distance rides
to match real-world intercity fares (e.g. Kushtia→Dhaka 190 km ≈ ৳10k car).
"""

from decimal import Decimal
from django.db import migrations


CONFIGS = {
    "bike": {
        "base_fare": Decimal("25.00"),
        "per_km_rate": Decimal("12.00"),
        "per_minute_rate": Decimal("1.50"),
        "minimum_fare": Decimal("40.00"),
        "booking_fee": Decimal("5.00"),
        "cancellation_fee": Decimal("15.00"),
        "surge_multiplier": Decimal("1.00"),
    },
    "car": {
        "base_fare": Decimal("50.00"),
        "per_km_rate": Decimal("18.00"),
        "per_minute_rate": Decimal("2.50"),
        "minimum_fare": Decimal("75.00"),
        "booking_fee": Decimal("10.00"),
        "cancellation_fee": Decimal("25.00"),
        "surge_multiplier": Decimal("1.00"),
    },
    "cng": {
        "base_fare": Decimal("35.00"),
        "per_km_rate": Decimal("14.00"),
        "per_minute_rate": Decimal("2.00"),
        "minimum_fare": Decimal("55.00"),
        "booking_fee": Decimal("8.00"),
        "cancellation_fee": Decimal("20.00"),
        "surge_multiplier": Decimal("1.00"),
    },
}

TIERS = {
    "bike": [
        (0, 5, Decimal("8.00")),
        (5, 15, Decimal("10.00")),
        (15, 50, Decimal("14.00")),
        (50, 100, Decimal("18.00")),
        (100, 300, Decimal("22.00")),
    ],
    "car": [
        (0, 5, Decimal("15.00")),
        (5, 15, Decimal("20.00")),
        (15, 50, Decimal("35.00")),
        (50, 100, Decimal("50.00")),
        (100, 300, Decimal("60.00")),
    ],
    "cng": [
        (0, 5, Decimal("10.00")),
        (5, 15, Decimal("14.00")),
        (15, 50, Decimal("20.00")),
        (50, 100, Decimal("30.00")),
        (100, 300, Decimal("35.00")),
    ],
}


def populate(apps, schema_editor):
    FareConfig = apps.get_model("rideshare", "FareConfig")
    FareDistanceTier = apps.get_model("rideshare", "FareDistanceTier")

    for vehicle_type, cfg in CONFIGS.items():
        fare_config, _ = FareConfig.objects.get_or_create(
            vehicle_type=vehicle_type,
            defaults={**cfg, "is_active": True},
        )
        # Update existing config to match new defaults
        if not _:
            for field, value in cfg.items():
                setattr(fare_config, field, value)
            fare_config.is_active = True
            fare_config.save()

        # Clear old tiers and recreate
        FareDistanceTier.objects.filter(fare_config=fare_config).delete()
        for min_km, max_km, rate in TIERS[vehicle_type]:
            FareDistanceTier.objects.create(
                fare_config=fare_config,
                min_km=Decimal(str(min_km)),
                max_km=Decimal(str(max_km)),
                per_km_rate=rate,
            )


def rollback(apps, schema_editor):
    FareDistanceTier = apps.get_model("rideshare", "FareDistanceTier")
    FareDistanceTier.objects.all().delete()


class Migration(migrations.Migration):
    dependencies = [
        ("rideshare", "0004_driverprofile_max_ride_distance_km_and_more"),
    ]

    operations = [
        migrations.RunPython(populate, rollback),
    ]
