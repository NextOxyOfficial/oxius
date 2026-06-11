"""Server-controlled ad configuration.

The app integrates the AppLovin MAX SDK once; everything else — which screen
shows ads, how often, which ad-unit IDs, the master on/off, brand-safety
rating — is driven from here so it can change WITHOUT an app update.
"""
from django.db import models


class AdSettings(models.Model):
    """Single global row (id=1). Master switch + SDK key + brand safety."""

    CONTENT_RATINGS = [
        ("G", "G — General (no gambling / alcohol / sexual)"),
        ("PG", "PG — Parental guidance"),
        ("T", "T — Teen"),
        ("MA", "MA — Mature"),
    ]

    enabled = models.BooleanField(
        default=False, help_text="Master switch — turn ALL ads off instantly."
    )
    applovin_sdk_key = models.TextField(
        blank=True, default="",
        help_text="AppLovin MAX SDK key (from the MAX dashboard).",
    )
    test_mode = models.BooleanField(
        default=True,
        help_text="Show MAX test ads (use while integrating; turn off for real ads).",
    )
    # Brand safety: G removes gambling, alcohol and sexual/nudity ad categories.
    max_ad_content_rating = models.CharField(
        max_length=2, choices=CONTENT_RATINGS, default="G",
        help_text="Max ad content rating. Keep G to block gambling & nudity.",
    )
    blocked_keywords = models.TextField(
        blank=True, default="",
        help_text="Comma-separated keywords to also discourage (advisory; main "
                  "blocking is the rating + network block-lists).",
    )

    class Meta:
        verbose_name = "Ad Settings"
        verbose_name_plural = "Ad Settings"

    def __str__(self):
        return f"Ad Settings (enabled={self.enabled}, test={self.test_mode})"

    @classmethod
    def get(cls):
        obj, _ = cls.objects.get_or_create(id=1)
        return obj


class AdPlacement(models.Model):
    """One ad slot in the app (e.g. BN feed native every 4 posts)."""

    FORMATS = [
        ("native", "Native"),
        ("mrec", "MREC (300x250)"),
        ("banner", "Adaptive Banner"),
        ("interstitial", "Interstitial"),
        ("rewarded", "Rewarded"),
        ("app_open", "App Open"),
    ]
    NETWORKS = [("applovin_max", "AppLovin MAX (mediation)")]

    key = models.SlugField(
        max_length=60, unique=True,
        help_text="Stable id the app references, e.g. bn_feed_native.",
    )
    label = models.CharField(max_length=120)
    network = models.CharField(max_length=30, choices=NETWORKS, default="applovin_max")
    ad_format = models.CharField(max_length=20, choices=FORMATS, default="native")
    enabled = models.BooleanField(default=False)
    ad_unit_id_android = models.CharField(max_length=120, blank=True, default="")
    ad_unit_id_ios = models.CharField(max_length=120, blank=True, default="")
    # For list/feed placements: insert one ad after every N items.
    frequency = models.PositiveIntegerField(
        default=4, help_text="Feed/list: show an ad after every N items.",
    )
    min_app_version = models.CharField(
        max_length=20, blank=True, default="",
        help_text="Optional — only serve on app builds >= this (e.g. 8.0.51).",
    )
    sort_order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["sort_order", "key"]
        verbose_name = "Ad Placement"
        verbose_name_plural = "Ad Placements"

    def __str__(self):
        return f"{self.label} ({self.key}) {'ON' if self.enabled else 'off'}"
