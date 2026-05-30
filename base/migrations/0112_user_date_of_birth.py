from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("base", "0111_fcmtoken_voip_token"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="date_of_birth",
            field=models.DateField(blank=True, null=True),
        ),
    ]
