"""Zonal office system.

One zone = one city (e.g. "Dhaka"). The owner creates a ZonalOffice from the
main Django admin, links it to the officer's existing user account, and sets
per-feature commission percentages dynamically (inline). The officer then logs
in at adsyclub.com/zoneadmin and sees the sales/leads dashboard for their zone.
"""
from django.conf import settings
from django.db import models
from django.utils.timezone import now as timezone_now


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

    # --- Zone settings (edited by the officer at /zoneadmin) ---
    contact_phone = models.CharField(max_length=30, blank=True, default="")
    office_address = models.CharField(max_length=255, blank=True, default="")
    nid_number = models.CharField(max_length=40, blank=True, default="")
    payout_method = models.CharField(
        max_length=20, blank=True, default="",
        choices=[
            ("bkash", "bKash"),
            ("nagad", "Nagad"),
            ("rocket", "Rocket"),
            ("bank", "Bank"),
        ],
    )
    payout_account_name = models.CharField(max_length=120, blank=True, default="")
    payout_account_number = models.CharField(max_length=60, blank=True, default="")
    payout_bank_name = models.CharField(max_length=120, blank=True, default="")
    payout_bank_branch = models.CharField(max_length=120, blank=True, default="")
    payout_routing_number = models.CharField(max_length=40, blank=True, default="")

    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Zonal Office"
        verbose_name_plural = "Zonal Offices"
        ordering = ["city"]

    def __str__(self):
        return f"{self.name} ({self.city})"


class ZoneFeatureCommission(models.Model):
    """Commission a zone earns on a feature inside its city.

    Either a PERCENT of the feature's sales amount, or a FLAT taka amount per
    transaction/lead — picked per feature from the office admin page. Every
    office automatically gets one row per feature (value 0 = no commission).
    """

    FEATURES = [
        ("registration", "User Registration (leads)"),
        ("pro_subscription", "Pro Subscription"),
        ("microgig_post", "MicroGig Post"),
        ("eshop_order", "eShop Order"),
        ("mobile_recharge", "Mobile Recharge"),
        ("gold_sponsor", "Gold Sponsor"),
        ("rideshare_driver", "Rideshare Driver Commission"),
    ]

    COMMISSION_TYPES = [
        ("percent", "Percent (%)"),
        ("flat", "Flat amount (৳ per item)"),
    ]

    office = models.ForeignKey(
        ZonalOffice, on_delete=models.CASCADE, related_name="commissions"
    )
    feature = models.CharField(max_length=32, choices=FEATURES)
    commission_type = models.CharField(
        max_length=10, choices=COMMISSION_TYPES, default="percent"
    )
    value = models.DecimalField(
        max_digits=10, decimal_places=2, default=0,
        help_text="Percent (e.g. 10 = 10%) or flat ৳ per item, per the type.",
    )

    class Meta:
        unique_together = ("office", "feature")
        verbose_name = "Zone Feature Commission"
        verbose_name_plural = "Zone Feature Commissions"

    def __str__(self):
        unit = "%" if self.commission_type == "percent" else "৳/item"
        return f"{self.office.city}: {self.get_feature_display()} {self.value}{unit}"


class ZonalNotice(models.Model):
    """Notice posted from the main django admin, shown on officers' dashboards.

    Leave `office` empty to broadcast to ALL zones, or pick one office to
    target just that zone. Image is optional (stored on the default media
    storage — R2/CDN in production).
    """
    title = models.CharField(max_length=200)
    body = models.TextField(blank=True, default="")
    image = models.ImageField(upload_to="zonal/notices/", blank=True, null=True)
    office = models.ForeignKey(
        ZonalOffice, on_delete=models.CASCADE, related_name="notices",
        blank=True, null=True,
        help_text="Empty = every zone sees it; set = only that zone.",
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Zonal Notice"
        verbose_name_plural = "Zonal Notices"

    def __str__(self):
        target = self.office.city if self.office_id else "All zones"
        return f"{self.title} ({target})"


class ZonalNote(models.Model):
    """Officer's own notebook ("Primary Note") — created from /zoneadmin,
    fully visible in the main django admin."""
    office = models.ForeignKey(
        ZonalOffice, on_delete=models.CASCADE, related_name="notes"
    )
    title = models.CharField(max_length=200)
    body = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-updated_at"]
        verbose_name = "Zonal Note"
        verbose_name_plural = "Zonal Notes"

    def __str__(self):
        return f"{self.office.city}: {self.title}"


class AreaManager(models.Model):
    """An agent the zonal OFFICER appoints for one area (upazila) of their
    city, with their own commission structure. Managed entirely from
    /zoneadmin (no separate login/panel); visible in django admin."""
    office = models.ForeignKey(
        ZonalOffice, on_delete=models.CASCADE, related_name="area_managers"
    )
    name = models.CharField(max_length=120)
    phone = models.CharField(max_length=30, blank=True, default="")
    area = models.CharField(
        max_length=120,
        help_text="Upazila/area name — must match users' Upazila value.",
    )
    payout_method = models.CharField(
        max_length=20, blank=True, default="",
        choices=[("bkash", "bKash"), ("nagad", "Nagad"),
                 ("rocket", "Rocket"), ("bank", "Bank")],
    )
    payout_account_name = models.CharField(max_length=120, blank=True, default="")
    payout_account_number = models.CharField(max_length=60, blank=True, default="")
    payout_bank_name = models.CharField(max_length=120, blank=True, default="")
    payout_bank_branch = models.CharField(max_length=120, blank=True, default="")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["area"]
        unique_together = ("office", "area", "name")
        verbose_name = "Area Manager"
        verbose_name_plural = "Area Managers"

    def __str__(self):
        return f"{self.name} — {self.area} ({self.office.city})"


class AreaManagerCommission(models.Model):
    """Per-feature commission for an area manager (same scheme as the zone:
    percent of sales or flat ৳ per item)."""
    manager = models.ForeignKey(
        AreaManager, on_delete=models.CASCADE, related_name="commissions"
    )
    feature = models.CharField(max_length=32, choices=ZoneFeatureCommission.FEATURES)
    commission_type = models.CharField(
        max_length=10, choices=ZoneFeatureCommission.COMMISSION_TYPES,
        default="percent",
    )
    value = models.DecimalField(max_digits=10, decimal_places=2, default=0)

    class Meta:
        unique_together = ("manager", "feature")
        verbose_name = "Area Manager Commission"
        verbose_name_plural = "Area Manager Commissions"

    def __str__(self):
        unit = "%" if self.commission_type == "percent" else "TK/item"
        return f"{self.manager.name}: {self.feature} {self.value}{unit}"


class ZonalPayment(models.Model):
    """A commission payout made to a zonal office — recorded by the owner in
    django admin; the officer sees the history (read-only) in /zoneadmin."""

    STATUS = [("paid", "Paid"), ("pending", "Pending")]

    office = models.ForeignKey(
        ZonalOffice, on_delete=models.CASCADE, related_name="payments"
    )
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    method = models.CharField(max_length=30, blank=True, default="")
    trx_id = models.CharField("Transaction ID", max_length=80, blank=True, default="")
    period_from = models.DateField(null=True, blank=True)
    period_to = models.DateField(null=True, blank=True)
    note = models.CharField(max_length=255, blank=True, default="")
    status = models.CharField(max_length=10, choices=STATUS, default="paid")
    paid_at = models.DateTimeField(default=timezone_now)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-paid_at"]
        verbose_name = "Zonal Payment"
        verbose_name_plural = "Zonal Payments"

    def __str__(self):
        return f"{self.office.city}: ৳{self.amount} ({self.status})"


class _InvoiceBase(models.Model):
    """Monthly commission statement. `amount` is the commission earned that
    calendar month, SNAPSHOTTED at generation time (so later rate changes don't
    rewrite history). `breakdown` keeps the per-feature rows. The owner marks it
    paid in django admin (status + payment fields) — that is the payout."""

    STATUS = [("unpaid", "Unpaid"), ("paid", "Paid")]

    period_year = models.PositiveIntegerField()
    period_month = models.PositiveSmallIntegerField()  # 1-12
    amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    breakdown = models.JSONField(default=list, blank=True)
    status = models.CharField(max_length=10, choices=STATUS, default="unpaid")
    # Payment details (filled by the owner when paying)
    pay_method = models.CharField(max_length=30, blank=True, default="")
    pay_trx_id = models.CharField("Transaction ID", max_length=80, blank=True, default="")
    pay_note = models.CharField(max_length=255, blank=True, default="")
    paid_at = models.DateTimeField(null=True, blank=True)
    generated_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True
        ordering = ["-period_year", "-period_month"]

    @property
    def period_label(self):
        return "%04d-%02d" % (self.period_year, self.period_month)

    def mark_paid(self):
        if self.status != "paid":
            self.status = "paid"
            if not self.paid_at:
                self.paid_at = timezone_now()
            self.save(update_fields=["status", "paid_at", "updated_at"])


class ZonalInvoice(_InvoiceBase):
    office = models.ForeignKey(
        ZonalOffice, on_delete=models.CASCADE, related_name="invoices"
    )

    class Meta(_InvoiceBase.Meta):
        unique_together = ("office", "period_year", "period_month")
        verbose_name = "Zonal Invoice"
        verbose_name_plural = "Zonal Invoices"

    def __str__(self):
        return f"{self.office.city} {self.period_label}: ৳{self.amount} ({self.status})"


class AreaManagerInvoice(_InvoiceBase):
    manager = models.ForeignKey(
        AreaManager, on_delete=models.CASCADE, related_name="invoices"
    )

    class Meta(_InvoiceBase.Meta):
        unique_together = ("manager", "period_year", "period_month")
        verbose_name = "Area Manager Invoice"
        verbose_name_plural = "Area Manager Invoices"

    def __str__(self):
        return f"{self.manager.name} {self.period_label}: ৳{self.amount} ({self.status})"
