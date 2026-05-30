from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("base", "0112_user_date_of_birth"),
    ]

    operations = [
        migrations.AlterField(
            model_name="fcmtoken",
            name="token",
            field=models.TextField(unique=True),
        ),
    ]
