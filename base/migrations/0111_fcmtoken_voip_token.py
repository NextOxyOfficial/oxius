from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("base", "0110_add_email_notifications_to_user"),
    ]

    operations = [
        migrations.AddField(
            model_name="fcmtoken",
            name="voip_token",
            field=models.TextField(blank=True, default=""),
        ),
        migrations.AddField(
            model_name="fcmtoken",
            name="voip_environment",
            field=models.CharField(blank=True, default="", max_length=20),
        ),
    ]
