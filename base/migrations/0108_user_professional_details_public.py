from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("base", "0107_merge_20260409_1400"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="professional_details_public",
            field=models.BooleanField(default=True),
        ),
    ]