from django.db import models
from django.utils import timezone
from base.models import User
import uuid
import os


def gig_image_path(instance, filename):
    """Generate a unique path for uploading gig images"""
    ext = filename.split('.')[-1]
    filename = f"{uuid.uuid4()}.{ext}"
    return os.path.join('workspace/gigs', filename)


class GigCategory(models.Model):
    """Model for gig categories managed from admin"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    slug = models.SlugField(max_length=100, unique=True)
    icon = models.CharField(max_length=50, blank=True, help_text="Icon class name (e.g., i-heroicons-paint-brush)")
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = "Gig Category"
        verbose_name_plural = "Gig Categories"
        ordering = ['order', 'name']
    
    def __str__(self):
        return self.name


class GigSkill(models.Model):
    """Model for skills/expertise tags managed from admin"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    slug = models.SlugField(max_length=100, unique=True)
    category = models.ForeignKey(GigCategory, on_delete=models.SET_NULL, null=True, blank=True, related_name='skills')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = "Gig Skill"
        verbose_name_plural = "Gig Skills"
        ordering = ['name']
    
    def __str__(self):
        return self.name


class GigDeliveryTime(models.Model):
    """Model for delivery time options managed from admin"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    label = models.CharField(max_length=50, help_text="Display label (e.g., '1 Day', '3 Days')")
    days = models.PositiveIntegerField(help_text="Number of days")
    is_active = models.BooleanField(default=True)
    order = models.PositiveIntegerField(default=0)
    
    class Meta:
        verbose_name = "Delivery Time Option"
        verbose_name_plural = "Delivery Time Options"
        ordering = ['order', 'days']
    
    def __str__(self):
        return self.label


class GigRevisionOption(models.Model):
    """Model for revision options managed from admin"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    label = models.CharField(max_length=50, help_text="Display label (e.g., '1 Revision', 'Unlimited')")
    count = models.PositiveIntegerField(help_text="Number of revisions (use 999 for unlimited)")
    is_active = models.BooleanField(default=True)
    order = models.PositiveIntegerField(default=0)
    
    class Meta:
        verbose_name = "Revision Option"
        verbose_name_plural = "Revision Options"
        ordering = ['order', 'count']
    
    def __str__(self):
        return self.label


class Gig(models.Model):
    """Model for workspace gigs/services"""
    
    CATEGORY_CHOICES = [
        ('design', 'Design & Creative'),
        ('development', 'Programming & Tech'),
        ('writing', 'Writing & Translation'),
        ('marketing', 'Digital Marketing'),
        ('business', 'Business & Consulting'),
    ]
    
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('paused', 'Paused'),
        ('deleted', 'Deleted'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='workspace_gigs')
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES, default='design')
    price = models.DecimalField(max_digits=10, decimal_places=2)
    image = models.ImageField(upload_to=gig_image_path, blank=True, null=True)
    delivery_time = models.PositiveIntegerField(default=3, help_text="Delivery time in days")
    revisions = models.PositiveIntegerField(default=2, help_text="Number of revisions included")
    skills = models.JSONField(default=list, blank=True, help_text="List of skills/expertise tags")
    features = models.JSONField(default=list, blank=True, help_text="List of what buyers will get")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    is_featured = models.BooleanField(default=False)
    views_count = models.PositiveIntegerField(default=0)
    orders_count = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Gig"
        verbose_name_plural = "Gigs"
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.title} by {self.user.first_name}"
    
    @property
    def average_rating(self):
        """Calculate average rating from reviews"""
        reviews = self.reviews.all()
        if reviews.exists():
            return round(sum(r.rating for r in reviews) / reviews.count(), 1)
        return 0
    
    @property
    def reviews_count(self):
        """Get total number of reviews"""
        return self.reviews.count()


class GigReview(models.Model):
    """Model for gig reviews"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    gig = models.ForeignKey(Gig, on_delete=models.CASCADE, related_name='reviews')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='workspace_gig_reviews')
    rating = models.PositiveIntegerField(default=5)  # 1-5 stars
    comment = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = "Gig Review"
        verbose_name_plural = "Gig Reviews"
        ordering = ['-created_at']
        unique_together = ['gig', 'user']  # One review per user per gig
    
    def __str__(self):
        return f"Review by {self.user.first_name} for {self.gig.title}"


class GigFavorite(models.Model):
    """Model for favorited gigs"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    gig = models.ForeignKey(Gig, on_delete=models.CASCADE, related_name='favorites')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='workspace_favorite_gigs')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = "Gig Favorite"
        verbose_name_plural = "Gig Favorites"
        unique_together = ['gig', 'user']
    
    def __str__(self):
        return f"{self.user.first_name} favorited {self.gig.title}"


class GigOrder(models.Model):
    """Model for gig orders"""
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('in_progress', 'In Progress'),
        ('delivered', 'Delivered'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
        ('revision', 'Revision Requested'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    gig = models.ForeignKey(Gig, on_delete=models.CASCADE, related_name='orders')
    buyer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='workspace_orders_placed')
    seller = models.ForeignKey(User, on_delete=models.CASCADE, related_name='workspace_orders_received')
    price = models.DecimalField(max_digits=10, decimal_places=2)
    requirements = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    delivery_date = models.DateTimeField(blank=True, null=True)
    completed_at = models.DateTimeField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Gig Order"
        verbose_name_plural = "Gig Orders"
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Order #{str(self.id)[:8]} - {self.gig.title}"


class OrderMessage(models.Model):
    """Model for order chat messages"""
    MESSAGE_TYPE_CHOICES = [
        ('text', 'Text'),
        ('image', 'Image'),
        ('video', 'Video'),
        ('document', 'Document'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey(GigOrder, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='workspace_order_messages')
    content = models.TextField(blank=True, default='')
    message_type = models.CharField(max_length=20, choices=MESSAGE_TYPE_CHOICES, default='text')
    media = models.FileField(upload_to='order_messages/', blank=True, null=True)
    file_name = models.CharField(max_length=255, blank=True, null=True)
    file_size = models.PositiveIntegerField(blank=True, null=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = "Order Message"
        verbose_name_plural = "Order Messages"
        ordering = ['created_at']
    
    def __str__(self):
        return f"Message from {self.sender.first_name} on Order #{str(self.order.id)[:8]}"
    
    @property
    def media_url(self):
        if self.media:
            return self.media.url
        return None
