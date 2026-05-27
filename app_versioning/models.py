from django.db import models


class AppVersionConfig(models.Model):
    PLATFORM_ANDROID = "android"
    PLATFORM_IOS = "ios"
    PLATFORM_CHOICES = (
        (PLATFORM_ANDROID, "Android"),
        (PLATFORM_IOS, "iOS"),
    )

    platform = models.CharField(max_length=20, choices=PLATFORM_CHOICES)
    latest_version = models.CharField(max_length=50, help_text="Example: 8.0.32")
    latest_build = models.PositiveIntegerField(default=0, help_text="Example: 72")
    minimum_supported_version = models.CharField(
        max_length=50,
        blank=True,
        default="",
        help_text="Versions below this can be forced to update. Example: 8.0.20",
    )
    minimum_supported_build = models.PositiveIntegerField(
        default=0,
        help_text="Builds below this can be forced to update. Example: 60",
    )
    force_update = models.BooleanField(
        default=False,
        help_text="When enabled, every outdated app must update before continuing.",
    )
    store_url = models.URLField(max_length=500)
    title = models.CharField(max_length=120, default="Update available")
    message = models.TextField(
        default="A new version of AdsyClub is available. Please update to continue."
    )
    snooze_hours = models.PositiveIntegerField(
        default=24,
        help_text="Optional update popup delay after the user taps Later.",
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("platform", "-latest_build", "-updated_at")
        verbose_name = "App Version Config"
        verbose_name_plural = "App Version Configs"
        indexes = [
            models.Index(fields=["platform", "is_active"], name="appver_platform_active_idx"),
        ]

    def __str__(self):
        return f"{self.get_platform_display()} {self.latest_version}+{self.latest_build}"

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if self.is_active:
            AppVersionConfig.objects.filter(
                platform=self.platform,
                is_active=True,
            ).exclude(pk=self.pk).update(is_active=False)
