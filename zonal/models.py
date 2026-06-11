"""Zonal office system.

One zone = one city (e.g. "Dhaka"). The owner creates a ZonalOffice from the
main Django admin, links it to the officer's existing user account, and sets
per-feature commission percentages dynamically (inline). The officer then logs
in at adsyclub.com/zoneadmin and sees the sales/leads dashboard for their zone.
"""
from django.conf import settings
from django.db import models


class ZonalOffice(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="zonal_office",
        help_text="The officer's AdsyClub account — they log in at /zoneadmin with it.",
    )
    name = models.CharField(
        max_length=120,
        help_text='Office display name, e.g. "Dhaka Zonal Office".',
    )
    city = models.CharField(
        max_length=120,
        help_text="Zone city — must match users' City value (e.g. Dhaka).",
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Zonal Office"
        verbose_name_plural = "Zonal Offices"
        ordering = ["city"]

    def __str__(self):
        return f"{self.name} ({self.city})"


class ZoneFeatureCommission(models.Model):
    """Commission % a zone earns on a feature's revenue inside its city."""

    FEATURES = [
        ("registration", "User Registration (leads)"),
        ("pro_subscription", "Pro Subscription"),
        ("microgig_post", "MicroGig Post"),
        ("eshop_order", "eShop Order"),
        ("mobile_recharge", "Mobile Recharge"),
    ]

    office = models.ForeignKey(
        ZonalOffice, on_delete=models.CASCADE, related_name="commissions"
    )
    feature = models.CharField(max_length=32, choices=FEATURES)
    percent = models.DecimalField(
        max_digits=5, decimal_places=2, default=0,
        help_text="Commission % on this feature's revenue in the zone.",
    )

    class Meta:
        unique_together = ("office", "feature")
        verbose_name = "Zone Feature Commission"
        verbose_name_plural = "Zone Feature Commissions"

    def __str__(self):
        return f"{self.office.city}: {self.get_feature_display()} {self.percent}%"
