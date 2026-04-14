from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("rideshare", "0010_ridesharesettings_google_maps_api_key"),
    ]

    operations = [
        migrations.CreateModel(
            name="SearchableLocation",
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
                ("name", models.CharField(max_length=255)),
                (
                    "subtitle",
                    models.CharField(
                        blank=True,
                        default="",
                        help_text="Optional area or locality text shown below the location name.",
                        max_length=255,
                    ),
                ),
                (
                    "search_keywords",
                    models.TextField(
                        blank=True,
                        default="",
                        help_text="Comma or line-separated keywords and aliases for search matching.",
                    ),
                ),
                ("latitude", models.DecimalField(decimal_places=6, max_digits=9)),
                ("longitude", models.DecimalField(decimal_places=6, max_digits=9)),
                (
                    "priority",
                    models.PositiveIntegerField(
                        default=0,
                        help_text="Higher priority locations appear earlier when multiple matches are found.",
                    ),
                ),
                ("is_active", models.BooleanField(default=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
            ],
            options={
                "verbose_name": "Searchable Location",
                "verbose_name_plural": "Searchable Locations",
                "ordering": ["-priority", "name"],
            },
        ),
        migrations.AddIndex(
            model_name="searchablelocation",
            index=models.Index(fields=["is_active", "name"], name="rideshare_s_is_acti_2b736c_idx"),
        ),
    ]