# Generated by Django 5.1.4 on 2024-12-29 10:51

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0006_user_referral_code'),
    ]

    operations = [
        migrations.AlterField(
            model_name='user',
            name='referral_code',
            field=models.CharField(blank=True, default='', editable=False, max_length=10),
        ),
    ]
