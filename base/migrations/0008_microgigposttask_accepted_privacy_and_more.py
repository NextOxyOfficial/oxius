# Generated by Django 5.1.4 on 2024-12-11 06:21

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0007_rename_active_gigs_microgigpost_active_gig'),
    ]

    operations = [
        migrations.AddField(
            model_name='microgigposttask',
            name='accepted_privacy',
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name='microgigposttask',
            name='accepted_terms',
            field=models.BooleanField(default=True),
        ),
    ]
