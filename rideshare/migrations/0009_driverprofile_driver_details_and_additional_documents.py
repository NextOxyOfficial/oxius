from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("rideshare", "0008_driverprofile_last_seen_at"),
    ]

    operations = [
        migrations.AddField(
            model_name="driverprofile",
            name="driver_details",
            field=models.TextField(
                blank=True,
                default="",
                help_text="Additional driver details provided during verification.",
            ),
        ),
        migrations.AddField(
            model_name="driverprofile",
            name="additional_documents",
            field=models.JSONField(
                blank=True,
                default=list,
                help_text="Additional verification documents (base64/image URLs).",
            ),
        ),
    ]
