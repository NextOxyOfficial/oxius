# Generated by Django 5.1.4 on 2025-05-24 04:35

import business_network.models
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('business_network', '0034_add_user_and_views_to_goldsponsor'),
    ]

    operations = [
        migrations.AlterField(
            model_name='goldsponsorbanner',
            name='image',
            field=models.ImageField(upload_to=business_network.models.sponsor_banner_path),
        ),
    ]
