# Generated by Django 5.1.4 on 2024-12-29 10:43

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0005_authenticationbanner'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='referral_code',
            field=models.CharField(blank=True, editable=False, max_length=10),
        ),
    ]
