from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("base", "0105_add_is_food_zone_to_classifiedcategory"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="email_public",
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name="user",
            name="phone_public",
            field=models.BooleanField(default=False),
        ),
    ]