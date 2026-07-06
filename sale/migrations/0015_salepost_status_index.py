from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("sale", "0014_salepost_delivery_locations"),
    ]

    operations = [
        migrations.AlterField(
            model_name="salepost",
            name="status",
            field=models.CharField(
                choices=[
                    ("pending", "Pending Review"),
                    ("active", "Active"),
                    ("sold", "Sold"),
                    ("expired", "Expired"),
                ],
                db_index=True,
                default="pending",
                max_length=20,
            ),
        ),
    ]
