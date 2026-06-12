import uuid

from django.db import models


class OutreachDraft(models.Model):
    """One sponsor/partner/investor outreach email, prepared (by the assistant in
    chat) and reviewed/edited by the founder on /aiiliance before sending.

    The `body_html` holds ONLY the personalized message. The branded header +
    signature (ceo@adsyclub.com, WhatsApp), the Donate button, and the
    unsubscribe/address footer are added automatically at render time
    (alliance/emails.py), so the founder edits just the pitch."""

    STATUS_CHOICES = [
        ("draft", "Draft"),
        ("approved", "Approved"),
        ("scheduled", "Scheduled"),
        ("sending", "Sending"),
        ("sent", "Sent"),
        ("failed", "Failed"),
        ("skipped", "Skipped"),
    ]

    LANGUAGE_CHOICES = [
        ("en", "English"),
        ("bn", "বাংলা"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    language = models.CharField(max_length=5, choices=LANGUAGE_CHOICES, default="en",
                                help_text="Drives the email chrome + the recipient's donation page language")
    category = models.CharField(max_length=80, blank=True, default="",
                                help_text="e.g. telecom, fintech, investor, csr")
    company = models.CharField(max_length=200)
    to_name = models.CharField(max_length=200, blank=True, default="")
    to_email = models.EmailField()
    subject = models.CharField(max_length=300)
    body_html = models.TextField(
        help_text="Main message body (HTML). Signature/contact/donate/unsubscribe added automatically.")
    notes = models.CharField(max_length=400, blank=True, default="",
                             help_text="Internal: why relevant / source of the email")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="draft")
    scheduled_for = models.DateTimeField(null=True, blank=True)
    sent_at = models.DateTimeField(null=True, blank=True)
    error = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Outreach draft"
        verbose_name_plural = "Outreach drafts"

    def __str__(self):
        return f"{self.company} <{self.to_email}> [{self.status}]"


class AllianceDonation(models.Model):
    """A donation made through the Donate button in outreach emails / the
    /donate page, paid via SurjoPay. Kept fully separate from the wallet
    deposit flow — a donation never credits anyone's Adsy Pay balance."""

    STATUS_CHOICES = [
        ("pending", "Pending"),
        ("completed", "Completed"),
        ("failed", "Failed"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order_id = models.CharField(max_length=64, unique=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    language = models.CharField(max_length=5, default="en",
                                help_text="Language of the donation page this came from (en/bn)")
    recipient_name = models.CharField(max_length=200, blank=True, default="",
                                      help_text="Name shown on the personalized donate link (from the outreach draft)")
    donor_name = models.CharField(max_length=200, blank=True, default="")
    donor_email = models.EmailField(blank=True, default="")
    donor_phone = models.CharField(max_length=40, blank=True, default="")
    message = models.CharField(max_length=500, blank=True, default="")
    sp_order_id = models.CharField(max_length=120, blank=True, default="")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending")
    created_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Alliance donation"
        verbose_name_plural = "Alliance donations"

    def __str__(self):
        who = self.donor_name or self.donor_email or "Anonymous"
        return f"৳{self.amount} · {self.status} · {who}"
