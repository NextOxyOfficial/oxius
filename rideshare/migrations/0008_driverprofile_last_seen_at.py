# Generated manually

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('rideshare', '0007_fix_driverlocation_decimal_precision'),
    ]

    operations = [
        migrations.AddField(
            model_name='driverprofile',
            name='last_seen_at',
            field=models.DateTimeField(
                blank=True,
                null=True,
                help_text=(
                    'Last time the driver was confirmed active (online toggle, '
                    'GPS ping, or heartbeat). Used to detect stale/offline devices.'
                ),
            ),
        ),
    ]
