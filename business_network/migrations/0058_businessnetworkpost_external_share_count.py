from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('business_network', '0057_profilereport'),
    ]

    operations = [
        migrations.AddField(
            model_name='businessnetworkpost',
            name='external_share_count',
            field=models.PositiveIntegerField(default=0),
        ),
    ]
