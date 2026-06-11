"""Seed an EPOCH baseline rate-change for every existing commission row so the
current rate covers all historical sales (preserves today's numbers). New rate
edits after this point are timestamped and apply only going forward."""
from datetime import datetime
from zoneinfo import ZoneInfo

from django.db import migrations

EPOCH = datetime(2000, 1, 1, tzinfo=ZoneInfo("Asia/Dhaka"))


def backfill(apps, schema_editor):
    ZoneFeatureCommission = apps.get_model("zonal", "ZoneFeatureCommission")
    ZoneRateChange = apps.get_model("zonal", "ZoneRateChange")
    AreaManagerCommission = apps.get_model("zonal", "AreaManagerCommission")
    AreaManagerRateChange = apps.get_model("zonal", "AreaManagerRateChange")

    for c in ZoneFeatureCommission.objects.all():
        if not ZoneRateChange.objects.filter(office_id=c.office_id, feature=c.feature).exists():
            ZoneRateChange.objects.create(
                office_id=c.office_id, feature=c.feature,
                commission_type=c.commission_type, value=c.value, effective_from=EPOCH,
            )
    for c in AreaManagerCommission.objects.all():
        if not AreaManagerRateChange.objects.filter(manager_id=c.manager_id, feature=c.feature).exists():
            AreaManagerRateChange.objects.create(
                manager_id=c.manager_id, feature=c.feature,
                commission_type=c.commission_type, value=c.value, effective_from=EPOCH,
            )


def noop(apps, schema_editor):
    pass


class Migration(migrations.Migration):
    dependencies = [
        ("zonal", "0006_areamanagerratechange_zoneratechange"),
    ]
    operations = [migrations.RunPython(backfill, noop)]
