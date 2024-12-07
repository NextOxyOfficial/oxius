# Generated by Django 5.1.4 on 2024-12-08 11:18

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0002_microgigpostmedia_microgigpost_medias'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='balance',
            field=models.DecimalField(decimal_places=2, default=0.0, max_digits=8),
        ),
        migrations.AddField(
            model_name='user',
            name='pending_balance',
            field=models.DecimalField(decimal_places=2, default=0.0, max_digits=8),
        ),
        migrations.AlterField(
            model_name='microgigpost',
            name='filled_quantity',
            field=models.IntegerField(default=0),
        ),
        migrations.CreateModel(
            name='MicroGigPostTask',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('completed', models.BooleanField(default=False)),
                ('approved', models.BooleanField(default=False)),
                ('rejected', models.BooleanField(default=False)),
                ('gig', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='base.microgigpost')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='micro_gig_worker', to=settings.AUTH_USER_MODEL)),
            ],
        ),
    ]
