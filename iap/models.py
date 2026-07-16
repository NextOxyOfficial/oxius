import uuid

from django.conf import settings
from django.db import models


class IapProduct(models.Model):
    """Maps a Google Play product / base-plan id to an in-app entitlement.

    Admin-editable so product ids can be filled in once they're created in the
    Play Console — the app fetches this list from /api/iap/products/ instead of
    hardcoding ids. Diamonds are one-off (managed products); Pro and Gold
    Sponsor are auto-renewing subscriptions.
    """

    KIND_CHOICES = [
        ("diamonds", "Diamonds"),
        ("pro", "Pro subscription"),
        ("gold", "Gold Sponsor subscription"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    kind = models.CharField(max_length=20, choices=KIND_CHOICES)
    title = models.CharField(max_length=120, blank=True, default="")
    google_product_id = models.CharField(
        max_length=150, unique=True,
        help_text="Play Console product id (e.g. adsyclub_pro, diamonds_50).",
    )
    base_plan_id = models.CharField(
        max_length=120, blank=True, default="",
        help_text="Subscriptions only: the base plan id (e.g. monthly, yearly).",
    )
    is_subscription = models.BooleanField(
        default=False, help_text="True for Pro & Gold Sponsor (auto-renew)."
    )
    # ── entitlement config ──
    diamonds = models.PositiveIntegerField(
        default=0, help_text="Diamonds granted (diamonds kind)."
    )
    duration_days = models.PositiveIntegerField(
        default=0,
        help_text="Access days for Gold Sponsor; Pro uses Google's expiry.",
    )
    price_label = models.CharField(
        max_length=40, blank=True, default="",
        help_text="Display price, e.g. '৳100' or '$0.99'.",
    )
    is_active = models.BooleanField(default=True)
    sort_order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["kind", "sort_order", "google_product_id"]
        verbose_name = "IAP product"
        verbose_name_plural = "IAP products"

    def __str__(self):
        return f"{self.kind}: {self.google_product_id}"


class IapPurchase(models.Model):
    """One Google Play purchase, verified server-side. The unique
    purchase_token makes granting idempotent (a token is honored once)."""

    STATUS_CHOICES = [
        ("pending", "Pending"),
        ("granted", "Granted"),
        ("refunded", "Refunded"),
        ("expired", "Expired"),
        ("failed", "Failed"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="iap_purchases",
    )
    kind = models.CharField(max_length=20)
    google_product_id = models.CharField(max_length=150)
    purchase_token = models.TextField(unique=True)
    order_id = models.CharField(max_length=120, blank=True, default="")
    ref_id = models.CharField(
        max_length=80, blank=True, default="",
        help_text="Optional in-app object this purchase completes (e.g. a "
                  "pending Gold Sponsor id).",
    )
    status = models.CharField(
        max_length=20, choices=STATUS_CHOICES, default="pending"
    )
    is_subscription = models.BooleanField(default=False)
    expiry_at = models.DateTimeField(
        null=True, blank=True, help_text="Subscription expiry from Google."
    )
    raw = models.JSONField(default=dict, blank=True)
    error = models.TextField(blank=True, default="")
    # Hash of the AdsyClub user id sent to Google as obfuscatedAccountId, echoed
    # back on verification. Lets us prove which app account started a purchase
    # even though Play only knows the buyer's Google account.
    obfuscated_account_id = models.CharField(
        max_length=64, blank=True, default="", db_index=True
    )
    # Google Play only allows one active subscription per base plan per Google
    # account, so a user with two AdsyClub accounts must move the entitlement
    # rather than buy twice. These track that move.
    transferred_at = models.DateTimeField(null=True, blank=True)
    transfer_count = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user", "-created_at"], name="iap_user_recent_idx"),
            models.Index(fields=["status"], name="iap_status_idx"),
        ]
        verbose_name = "IAP purchase"
        verbose_name_plural = "IAP purchases"

    def __str__(self):
        return f"{self.user_id} {self.google_product_id} [{self.status}]"
