
from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class Operator(models.Model):
    name = models.CharField(max_length=100)
    icon = models.ImageField(upload_to='operator_icons/')
    bg_color = models.CharField(max_length=50, help_text="CSS background color class")
    icon_color = models.CharField(max_length=50, help_text="CSS text color class")
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class PackageType(models.TextChoices):
    BALANCE = 'balance', 'Balance'
    DATA = 'data', 'Data'
    VOICE = 'voice', 'Voice'
    COMBO = 'combo', 'Combo'

class Package(models.Model):
    operator = models.ForeignKey(Operator, on_delete=models.CASCADE, related_name='packages')
    type = models.CharField(max_length=20, choices=PackageType.choices)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    data = models.CharField(max_length=50)
    validity = models.CharField(max_length=50)
    calls = models.CharField(max_length=100)
    popular = models.BooleanField(default=False)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.operator.name} - {self.type} - ${self.price}"

class Recharge(models.Model):
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='recharges')
    operator = models.ForeignKey(Operator, on_delete=models.SET_NULL, null=True, related_name='operator')
    package = models.ForeignKey(Package, on_delete=models.SET_NULL, null=True)
    phone_number = models.CharField(max_length=20)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    RECHARGE_STATUS = [
        ('pending', 'Pending'),        # awaiting processing (manual or provider)
        ('processing', 'Processing'),  # sent to provider, awaiting result
        ('completed', 'Completed'),    # delivered successfully
        ('failed', 'Failed'),          # could not deliver (balance refunded)
        ('refunded', 'Refunded'),      # cancelled + money returned
    ]
    status = models.CharField(max_length=20, choices=RECHARGE_STATUS, default='pending')
    transaction_id = models.CharField(max_length=100, blank=True)
    # Whether the user's Adsy Pay balance was charged for this recharge (so a
    # refund only happens once).
    balance_charged = models.BooleanField(default=False)
    # --- Third-party provider automation fields (filled when a provider runs) ---
    provider_reference = models.CharField(max_length=128, blank=True, default='')
    provider_response = models.JSONField(default=dict, blank=True)
    failure_reason = models.CharField(max_length=255, blank=True, default='')
    processed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Recharge {self.id}: {self.phone_number} - ৳{self.amount} ({self.status})"


class RechargeProviderConfig(models.Model):
    """Holds the third-party recharge API credentials. Leave is_enabled OFF until
    real API details are filled in — while disabled, recharges are created and
    held as 'pending' for manual processing. Turn it ON to auto-process.

    Only the most recently-updated enabled config is used.
    """
    name = models.CharField(max_length=100, default='Recharge Provider')
    is_enabled = models.BooleanField(
        default=False,
        help_text='Turn ON only after the API details below are filled in. '
                  'While OFF, recharges stay pending for manual processing.')
    base_url = models.URLField(blank=True, default='', help_text='Provider API base URL')
    api_key = models.CharField(max_length=255, blank=True, default='')
    api_secret = models.CharField(max_length=255, blank=True, default='')
    extra_config = models.JSONField(
        default=dict, blank=True,
        help_text='Any extra provider parameters (sender id, account, etc.) as JSON.')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Recharge provider (API)'
        verbose_name_plural = 'Recharge provider (API)'

    def __str__(self):
        return f"{self.name} ({'enabled' if self.is_enabled else 'disabled'})"