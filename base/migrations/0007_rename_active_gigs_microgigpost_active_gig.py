# Generated by Django 5.1.4 on 2024-12-10 11:29

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0006_microgigpost_active_gigs'),
    ]

    operations = [
        migrations.RenameField(
            model_name='microgigpost',
            old_name='active_gigs',
            new_name='active_gig',
        ),
    ]
