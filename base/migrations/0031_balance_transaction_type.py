# Generated by Django 5.1.4 on 2024-12-23 09:57

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0030_balance_payment_confirmed_at'),
    ]

    operations = [
        migrations.AddField(
            model_name='balance',
            name='transaction_type',
            field=models.CharField(blank=True, default='', max_length=20, null=True),
        ),
    ]
