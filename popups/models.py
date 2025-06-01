from django.db import models
from django.conf import settings
from django.utils import timezone
from PIL import Image


class Popup(models.Model):
    POPUP_TYPES = [
        ('image', 'Image Popup'),
        ('text', 'Text Popup'),
        ('mixed', 'Mixed Content'),
    ]
    
    DISPLAY_FREQUENCY = [
        ('once', 'Show Once Per Session'),
        ('always', 'Show Every Visit'),
        ('daily', 'Show Once Per Day'),
    ]
    
    LINK_NAVIGATION_CHOICES = [
        ('internal', 'Open in same window/app'),
        ('external', 'Open in external browser'),
        ('new_tab', 'Open in new tab'),
    ]
    
    title = models.CharField(max_length=200, help_text="Title for the popup")
    popup_type = models.CharField(max_length=10, choices=POPUP_TYPES, default='image')
    image = models.ImageField(upload_to='popups/', blank=True, null=True, help_text="Upload popup image")
    text_content = models.TextField(blank=True, null=True, help_text="Text content for the popup")
    link_url = models.URLField(blank=True, null=True, help_text="Optional link URL")
    link_text = models.CharField(max_length=100, blank=True, null=True, help_text="Link button text")
    link_navigation = models.CharField(
        max_length=10, 
        choices=LINK_NAVIGATION_CHOICES, 
        default='internal',
        help_text="How the link should open"
    )
    
    # Display settings
    is_active = models.BooleanField(default=True, help_text="Show this popup to users")
    start_date = models.DateTimeField(default=timezone.now, help_text="When to start showing this popup")
    end_date = models.DateTimeField(blank=True, null=True, help_text="When to stop showing this popup (optional)")
    display_frequency = models.CharField(max_length=10, choices=DISPLAY_FREQUENCY, default='once')
      # Display conditions
    show_to_authenticated_users = models.BooleanField(default=True, help_text="Show to logged-in users")
    show_to_anonymous_users = models.BooleanField(default=True, help_text="Show to visitors")
    show_to_pro_users_only = models.BooleanField(default=False, help_text="Show only to pro/premium users")
    delay_seconds = models.IntegerField(default=2, help_text="Delay before showing popup (in seconds)")
    
    # Close settings
    auto_close_enabled = models.BooleanField(default=True, help_text="Automatically close popup after specified time")
    auto_close_delay = models.IntegerField(default=10, help_text="Auto-close delay in seconds (0 = no auto-close)")
    show_close_button = models.BooleanField(default=True, help_text="Show manual close button")
    close_on_overlay_click = models.BooleanField(default=True, help_text="Allow closing by clicking outside popup")
    
    # Styling options
    width = models.IntegerField(default=500, help_text="Popup width in pixels")
    height = models.IntegerField(default=400, help_text="Popup height in pixels")
    background_color = models.CharField(max_length=7, default='#ffffff', help_text="Background color (hex code)")
    text_color = models.CharField(max_length=7, default='#000000', help_text="Text color (hex code)")
    
    # Tracking
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    view_count = models.IntegerField(default=0, help_text="Number of times this popup was shown")
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = "Popup"
        verbose_name_plural = "Popups"
    
    def __str__(self):
        return self.title
    
    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        
        # Resize image if it's too large
        if self.image:
            img = Image.open(self.image.path)
            if img.height > 800 or img.width > 800:
                output_size = (800, 800)
                img.thumbnail(output_size)
                img.save(self.image.path)
    
    def is_currently_active(self):
        """Check if popup should be shown based on date range"""
        now = timezone.now()
        if not self.is_active:
            return False
        if self.start_date > now:
            return False
        if self.end_date and self.end_date < now:
            return False
        return True
    
    def increment_view_count(self):
        """Increment the view count"""
        self.view_count += 1
        self.save(update_fields=['view_count'])


class PopupView(models.Model):
    """Track popup views per user/session"""
    popup = models.ForeignKey(Popup, on_delete=models.CASCADE, related_name='popup_views')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, blank=True, null=True)
    session_key = models.CharField(max_length=40, blank=True, null=True)
    ip_address = models.GenericIPAddressField()
    viewed_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['popup', 'user', 'session_key']
        ordering = ['-viewed_at']
    
    def __str__(self):
        return f"{self.popup.title} - {self.viewed_at}"
