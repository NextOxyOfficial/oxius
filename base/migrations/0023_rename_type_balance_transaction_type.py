# Generated by Django 5.1.4 on 2024-12-18 13:43

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0022_rename_method_balance_type'),
    ]

    operations = [
        migrations.RenameField(
            model_name='balance',
            old_name='type',
            new_name='transaction_type',
        ),
    ]
