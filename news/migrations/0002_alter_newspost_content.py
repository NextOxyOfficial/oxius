# Generated by Django 5.1.4 on 2025-04-22 09:54

import tinymce.models
from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('news', '0001_initial'),
    ]

    operations = [
        migrations.AlterField(
            model_name='newspost',
            name='content',
            field=tinymce.models.HTMLField(),
        ),
    ]
