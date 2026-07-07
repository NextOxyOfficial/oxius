from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ("business_network", "0050_goldsponsor_auto_renew_goldsponsorreminderlog"),
    ]

    operations = [
        migrations.CreateModel(
            name="ContentMonetizationApplication",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("status", models.CharField(choices=[("pending", "Pending Review"), ("approved", "Approved"), ("rejected", "Rejected")], default="pending", max_length=10)),
                ("followers_at_apply", models.PositiveIntegerField(default=0)),
                ("views_at_apply", models.PositiveIntegerField(default=0)),
                ("terms_accepted", models.BooleanField(default=False)),
                ("admin_note", models.TextField(blank=True, default="")),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("reviewed_at", models.DateTimeField(blank=True, null=True)),
                ("user", models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name="monetization_application", to=settings.AUTH_USER_MODEL)),
            ],
            options={
                "verbose_name": "Content Monetization Application",
                "verbose_name_plural": "Content Monetization Applications",
                "ordering": ["-created_at"],
            },
        ),
    ]
