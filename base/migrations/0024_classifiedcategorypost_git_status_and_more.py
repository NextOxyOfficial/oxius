# Generated by Django 5.1.4 on 2024-12-21 11:21

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0023_rename_type_balance_transaction_type'),
    ]

    operations = [
        migrations.AddField(
            model_name='classifiedcategorypost',
            name='git_status',
            field=models.CharField(choices=[('pending', 'Pending'), ('approved', 'Approved'), ('rejected', 'Rejected')], default='pending', max_length=20),
        ),
        migrations.AddField(
            model_name='microgigpost',
            name='git_status',
            field=models.CharField(choices=[('pending', 'Pending'), ('approved', 'Approved'), ('rejected', 'Rejected')], default='pending', max_length=20),
        ),
    ]