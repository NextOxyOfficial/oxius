from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
import time
import random

User = get_user_model()

# Create your models here.


def generate_unique_id():
    return int(time.time() * 1) + random.randint(0, 999)


class PopupDesktop(models.Model):
    VIEWING_CONDITIONS = [
        ('once', 'Once per user'),
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('always', 'Always show'),
    ]
    id = models.BigIntegerField(
        primary_key=True, default=generate_unique_id, editable=False)
    link = models.CharField(
        max_length=255, blank=True, null=True,

    )
    open_external = models.BooleanField(default=False)
    image = models.ImageField(
        upload_to='popup_desktop_images/', blank=True, null=True)
    is_active = models.BooleanField(default=True)
    show_for_logged_in_users = models.BooleanField(default=True)
    show_for_anonymous_users = models.BooleanField(default=True)
    viewing_condition = models.CharField(
        max_length=20, choices=VIEWING_CONDITIONS, default='once')
    total_views = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Desktop Popup - ID: {self.id}"


class PopupMobile(models.Model):
    VIEWING_CONDITIONS = [
        ('once', 'Once per user'),
        ('daily', 'Daily'),
        ('weekly', 'Weekly'),
        ('monthly', 'Monthly'),
        ('always', 'Always show'),
    ]
    id = models.BigIntegerField(
        primary_key=True, default=generate_unique_id, editable=False)
    image = models.ImageField(
        upload_to='popup_mobile_images/', blank=True, null=True)
    link = models.CharField(
        max_length=255, blank=True, null=True,

    )
    open_external = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    show_for_logged_in_users = models.BooleanField(default=True)
    show_for_anonymous_users = models.BooleanField(default=True)
    viewing_condition = models.CharField(
        max_length=20, choices=VIEWING_CONDITIONS, default='once')
    total_views = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Mobile Popup - ID: {self.id}"


class PopupView(models.Model):
    """Track popup views per user/session"""
    popup_desktop = models.ForeignKey(
        PopupDesktop, on_delete=models.CASCADE, null=True, blank=True,
        related_name='views')
    popup_mobile = models.ForeignKey(
        PopupMobile, on_delete=models.CASCADE, null=True, blank=True,
        related_name='views')
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, null=True, blank=True)
    session_key = models.CharField(
        max_length=40, null=True, blank=True)  # For anonymous users
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True, default="")
    viewed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [
            ['popup_desktop', 'user'],
            ['popup_mobile', 'user'],
            ['popup_desktop', 'session_key'],
            ['popup_mobile', 'session_key'],
        ]

    def __str__(self):
        popup_type = "Desktop" if self.popup_desktop else "Mobile"
        user_identifier = self.user.email if self.user else f"Session: {self.session_key}"
        return f"{popup_type} Popup View - {user_identifier}"
