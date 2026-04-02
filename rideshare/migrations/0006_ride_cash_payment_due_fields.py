from decimal import Decimal

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("rideshare", "0005_populate_fare_tiers"),
    ]

    operations = [
        migrations.AddField(
            model_name="ride",
            name="driver_due_amount",
            field=models.DecimalField(decimal_places=2, default=Decimal("0.00"), max_digits=10),
        ),
        migrations.AddField(
            model_name="ride",
            name="driver_due_settled_at",
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="ride",
            name="payment_method",
            field=models.CharField(
                choices=[("wallet", "Wallet"), ("cash", "Cash")],
                default="wallet",
                max_length=20,
            ),
        ),
    ]
