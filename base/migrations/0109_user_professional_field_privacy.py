from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("base", "0108_user_professional_details_public"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="about_public",
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name="user",
            name="company_public",
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name="user",
            name="facebook_public",
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name="user",
            name="instagram_public",
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name="user",
            name="profession_public",
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name="user",
            name="website_public",
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name="user",
            name="whatsapp_public",
            field=models.BooleanField(default=True),
        ),
    ]