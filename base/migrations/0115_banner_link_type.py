from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("base", "0114_classifiedcategorypost_views_count_and_more"),
    ]

    operations = [
        migrations.AddField(
            model_name="bannerimage",
            name="link_type",
            field=models.CharField(
                choices=[
                    ("internal", "Internal app/web page"),
                    ("external", "External browser link"),
                ],
                default="internal",
                help_text="Internal opens supported AdsyClub URLs inside the app. External opens in browser.",
                max_length=10,
            ),
        ),
        migrations.AlterField(
            model_name="bannerimage",
            name="link",
            field=models.CharField(
                blank=True,
                help_text="Use a full URL or app path. Internal links open inside the app.",
                max_length=500,
                null=True,
            ),
        ),
        migrations.AddField(
            model_name="shopbannerimage",
            name="link_type",
            field=models.CharField(
                choices=[
                    ("internal", "Internal app/web page"),
                    ("external", "External browser link"),
                ],
                default="internal",
                help_text="Internal opens supported AdsyClub URLs inside the app. External opens in browser.",
                max_length=10,
            ),
        ),
        migrations.AlterField(
            model_name="shopbannerimage",
            name="link",
            field=models.CharField(
                blank=True,
                help_text="Use a full URL or app path. Internal links open inside the app.",
                max_length=500,
                null=True,
            ),
        ),
        migrations.AddField(
            model_name="eshopbanner",
            name="link_type",
            field=models.CharField(
                choices=[
                    ("internal", "Internal app/web page"),
                    ("external", "External browser link"),
                ],
                default="internal",
                help_text="Internal opens supported AdsyClub URLs inside the app. External opens in browser.",
                max_length=10,
            ),
        ),
        migrations.AlterField(
            model_name="eshopbanner",
            name="link",
            field=models.CharField(
                blank=True,
                help_text="Use a full URL or app path. Internal links open inside the app.",
                max_length=500,
                null=True,
            ),
        ),
    ]
