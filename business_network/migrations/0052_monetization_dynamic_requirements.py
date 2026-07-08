from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ("business_network", "0051_contentmonetizationapplication"),
    ]

    operations = [
        migrations.CreateModel(
            name="ContentMonetizationSettings",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("required_followers", models.PositiveIntegerField(default=1000)),
                ("required_views", models.PositiveIntegerField(default=20000)),
                ("required_video_posts", models.PositiveIntegerField(default=10)),
                ("required_image_posts", models.PositiveIntegerField(default=10)),
                ("updated_at", models.DateTimeField(auto_now=True)),
            ],
            options={
                "verbose_name": "Content Monetization Settings",
                "verbose_name_plural": "Content Monetization Settings",
            },
        ),
        migrations.CreateModel(
            name="ContentMonetizationCustomRequirement",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("required_followers", models.PositiveIntegerField(blank=True, null=True)),
                ("required_views", models.PositiveIntegerField(blank=True, null=True)),
                ("required_video_posts", models.PositiveIntegerField(blank=True, null=True)),
                ("required_image_posts", models.PositiveIntegerField(blank=True, null=True)),
                ("note", models.CharField(blank=True, default="", max_length=255)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                ("user", models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name="monetization_custom_requirement", to=settings.AUTH_USER_MODEL)),
            ],
            options={
                "verbose_name": "Content Monetization Custom Requirement",
                "verbose_name_plural": "Content Monetization Custom Requirements",
            },
        ),
        migrations.AddField(
            model_name="contentmonetizationapplication",
            name="video_posts_at_apply",
            field=models.PositiveIntegerField(default=0),
        ),
        migrations.AddField(
            model_name="contentmonetizationapplication",
            name="image_posts_at_apply",
            field=models.PositiveIntegerField(default=0),
        ),
    ]
