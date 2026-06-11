"""Seed the first placement (BN feed native, every 4 posts) + the settings row,
both DISABLED, so nothing shows until the owner pastes the SDK key / ad-unit
ids and flips the switches in admin."""
from django.db import migrations


def seed(apps, schema_editor):
    AdSettings = apps.get_model("ads", "AdSettings")
    AdPlacement = apps.get_model("ads", "AdPlacement")
    AdSettings.objects.get_or_create(
        id=1, defaults={"enabled": False, "test_mode": True, "max_ad_content_rating": "G"}
    )
    AdPlacement.objects.get_or_create(
        key="bn_feed_native",
        defaults={
            "label": "Business Network feed — native",
            "network": "applovin_max",
            "ad_format": "native",
            "enabled": False,
            "frequency": 4,
            "sort_order": 10,
        },
    )


def unseed(apps, schema_editor):
    apps.get_model("ads", "AdPlacement").objects.filter(key="bn_feed_native").delete()


class Migration(migrations.Migration):
    dependencies = [("ads", "0001_initial")]
    operations = [migrations.RunPython(seed, unseed)]
