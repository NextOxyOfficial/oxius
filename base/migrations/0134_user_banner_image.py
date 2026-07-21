from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("base", "0133_user_who_can_message"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="banner_image",
            field=models.ImageField(
                blank=True, null=True, upload_to="profile_banners/"
            ),
        ),
    ]
