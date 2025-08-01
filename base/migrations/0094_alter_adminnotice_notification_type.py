# Generated by Django 5.1.4 on 2025-06-17 04:03

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('base', '0093_alter_user_phone'),
    ]

    operations = [
        migrations.AlterField(
            model_name='adminnotice',
            name='notification_type',
            field=models.CharField(choices=[('system', 'System Notice'), ('order_received', 'New Order Received'), ('withdraw_successful', 'Withdraw Successful'), ('mobile_recharge_successful', 'Mobile Recharge Successful'), ('transfer_sent', 'Money Transfer Sent'), ('transfer_received', 'Money Transfer Received'), ('deposit_successful', 'Deposit Successful'), ('pro_subscribed', 'Pro Subscription Activated'), ('pro_expiring', 'Pro Subscription Expiring'), ('gig_posted', 'Gig Posted Successfully'), ('gig_approved', 'Gig Approved by Admin'), ('gig_rejected', 'Gig Rejected by Admin'), ('general', 'General Update')], default='general', max_length=30),
        ),
    ]
