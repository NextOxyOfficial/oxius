# Generated by Django 5.1.4 on 2024-12-23 07:34

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0028_user_image'),
    ]

    operations = [
        migrations.RenameField(
            model_name='balance',
            old_name='transaction_type',
            new_name='payment_method',
        ),
        migrations.RemoveField(
            model_name='balance',
            name='status',
        ),
        migrations.AddField(
            model_name='balance',
            name='bank_status',
            field=models.CharField(choices=[('pending', 'Pending'), ('completed', 'Completed')], default='pending'),
        ),
        migrations.AddField(
            model_name='balance',
            name='merchant_invoice_no',
            field=models.CharField(default='', null=True),
        ),
        migrations.AddField(
            model_name='balance',
            name='payable_amount',
            field=models.DecimalField(decimal_places=2, default=0.0, max_digits=8),
        ),
        migrations.AddField(
            model_name='balance',
            name='received_amount',
            field=models.DecimalField(decimal_places=2, default=0.0, max_digits=8),
        ),
        migrations.AddField(
            model_name='balance',
            name='shurjopay_order_id',
            field=models.CharField(default='', null=True),
        ),
    ]