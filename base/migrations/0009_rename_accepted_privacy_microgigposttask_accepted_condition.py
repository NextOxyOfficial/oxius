# Generated by Django 5.1.4 on 2024-12-11 06:45

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0008_microgigposttask_accepted_privacy_and_more'),
    ]

    operations = [
        migrations.RenameField(
            model_name='microgigposttask',
            old_name='accepted_privacy',
            new_name='accepted_condition',
        ),
    ]
