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
