from decimal import Decimal

import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ("business_network", "0059_businessnetworkmediaview"),
    ]

    operations = [
        migrations.AddField(
            model_name="contentmonetizationsettings",
            name="monthly_pool_amount",
            field=models.DecimalField(
                decimal_places=2,
                default=0,
                help_text="Total BDT distributed among creators each month. 0 pauses earnings.",
                max_digits=12,
            ),
        ),
        migrations.AddField(
            model_name="contentmonetizationsettings",
            name="point_view",
            field=models.PositiveIntegerField(
                default=1, help_text="Points per valid content view."
            ),
        ),
        migrations.AddField(
            model_name="contentmonetizationsettings",
            name="point_like",
            field=models.PositiveIntegerField(
                default=3, help_text="Points per like received."
            ),
        ),
        migrations.AddField(
            model_name="contentmonetizationsettings",
            name="point_comment",
            field=models.PositiveIntegerField(
                default=5, help_text="Points per comment received."
            ),
        ),
        migrations.AddField(
            model_name="contentmonetizationsettings",
            name="point_follower",
            field=models.PositiveIntegerField(
                default=10, help_text="Points per new follower gained."
            ),
        ),
        migrations.AddField(
            model_name="contentmonetizationsettings",
            name="min_payout",
            field=models.DecimalField(
                decimal_places=2,
                default=Decimal("100"),
                help_text="Amounts below this roll over to the next month.",
                max_digits=10,
            ),
        ),
        migrations.AddField(
            model_name="contentmonetizationsettings",
            name="holdback_days",
            field=models.PositiveIntegerField(
                default=7,
                help_text="Review window after month close before earnings clear.",
            ),
        ),
        migrations.AddField(
            model_name="contentmonetizationsettings",
            name="viewer_min_account_age_days",
            field=models.PositiveIntegerField(
                default=7,
                help_text="Views from accounts younger than this carry no points.",
            ),
        ),
        migrations.AddField(
            model_name="contentmonetizationsettings",
            name="viewer_daily_view_cap",
            field=models.PositiveIntegerField(
                default=30,
                help_text="Max valid views one viewer can contribute to a creator per day.",
            ),
        ),
        migrations.CreateModel(
            name="CreatorMonthlyEarning",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("period", models.CharField(max_length=7)),
                ("valid_views", models.PositiveIntegerField(default=0)),
                ("likes", models.PositiveIntegerField(default=0)),
                ("comments", models.PositiveIntegerField(default=0)),
                ("followers_gained", models.PositiveIntegerField(default=0)),
                ("total_points", models.PositiveIntegerField(default=0)),
                (
                    "amount",
                    models.DecimalField(decimal_places=2, default=0, max_digits=12),
                ),
                (
                    "status",
                    models.CharField(
                        choices=[
                            ("accruing", "Accruing"),
                            ("held", "Held for review"),
                            ("cleared", "Cleared"),
                            ("paid", "Paid"),
                            ("forfeited", "Forfeited"),
                        ],
                        default="accruing",
                        max_length=10,
                    ),
                ),
                ("fraud_score", models.PositiveIntegerField(default=0)),
                ("note", models.CharField(blank=True, default="", max_length=255)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "user",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="monetization_earnings",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={
                "verbose_name": "Creator Monthly Earning",
                "verbose_name_plural": "Creator Monthly Earnings",
                "ordering": ["-period"],
                "unique_together": {("user", "period")},
            },
        ),
    ]
