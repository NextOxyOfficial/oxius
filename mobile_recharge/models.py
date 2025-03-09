
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
    package = models.ForeignKey(Package, on_delete=models.SET_NULL, null=True)
    phone_number = models.CharField(max_length=20)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, default='completed')
    transaction_id = models.CharField(max_length=100, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Recharge {self.id}: {self.phone_number} - ${self.amount}"