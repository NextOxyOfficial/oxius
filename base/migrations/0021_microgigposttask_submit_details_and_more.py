# Generated by Django 5.1.1 on 2024-12-17 07:44

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0020_nid_remove_user_nid_user_nid'),
    ]

    operations = [
        migrations.AddField(
            model_name='microgigposttask',
            name='submit_details',
            field=models.TextField(blank=True, default='', null=True),
        ),
        migrations.AlterField(
            model_name='microgigposttask',
            name='reason',
            field=models.TextField(blank=True, default='', null=True),
        ),
    ]
