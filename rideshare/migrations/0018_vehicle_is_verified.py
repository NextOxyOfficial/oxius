from django.db import migrations, models


def grandfather_existing(apps, schema_editor):
    """Every vehicle that existed before this gate is treated as verified —
    the admin approved these drivers with these vehicles in view, and gating
    them retroactively would silently stop live drivers from being dispatched.
    """
    Vehicle = apps.get_model("rideshare", "Vehicle")
    Vehicle.objects.all().update(is_verified=True)


class Migration(migrations.Migration):

    dependencies = [
        ("rideshare", "0017_riderating"),
    ]

    operations = [
        migrations.AddField(
            model_name="vehicle",
            name="is_verified",
            field=models.BooleanField(
                default=False,
                help_text="Admin has verified this vehicle's papers. Unverified vehicles are never dispatched.",
            ),
        ),
        migrations.RunPython(grandfather_existing, migrations.RunPython.noop),
    ]
