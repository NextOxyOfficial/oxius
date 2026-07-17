import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('business_network', '0058_businessnetworkpost_external_share_count'),
    ]

    operations = [
        migrations.CreateModel(
            name='BusinessNetworkMediaView',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('media', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='view_records', to='business_network.businessnetworkmedia')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='business_network_media_views', to=settings.AUTH_USER_MODEL)),
            ],
        ),
        migrations.AlterUniqueTogether(
            name='businessnetworkmediaview',
            unique_together={('media', 'user')},
        ),
    ]
