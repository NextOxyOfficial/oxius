from django.db import models
from django.contrib.auth import get_user_model
from django.utils.text import slugify
import uuid
from base.models import ForSaleCategory
import time
import random

User = get_user_model()
def generate_unique_id():
  return int(time.time() * 1) + random.randint(0, 999)

class SalePost(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending Review'),
        ('active', 'Active'),
        ('stop', 'Stop'),
        ('sold', 'Sold'),
        ('expired', 'Expired'),
        ('rejected', 'Rejected'),
    )
    
    CONDITION_CHOICES = (
        ('brand-new', 'Brand New'),
        ('like-new', 'Like New'),
        ('good', 'Good'),
        ('fair', 'Fair'),
        ('for-parts', 'For Parts'),
    )
    
    # Basic info
    title = models.CharField(max_length=255)
    slug = models.SlugField(max_length=300, unique=True, blank=True)
    description = models.TextField()
    condition = models.CharField(max_length=20, choices=CONDITION_CHOICES)
    category = models.ForeignKey(ForSaleCategory, on_delete=models.SET_NULL, null=True, blank=True)
    
    # Price info
    price = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    negotiable = models.BooleanField(default=False)
    
    # Location info
    division = models.CharField(max_length=100)
    district = models.CharField(max_length=100)
    area = models.CharField(max_length=100)
    detailed_address = models.TextField()
    
    # Contact info
    phone = models.CharField(max_length=15)
    email = models.EmailField(blank=True, null=True)
    
    # Property specific fields
    property_type = models.CharField(max_length=50, blank=True, null=True)
    size = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    unit = models.CharField(max_length=20, blank=True, null=True, default='sqft')
    bedrooms = models.CharField(max_length=10, blank=True, null=True)
    bathrooms = models.CharField(max_length=10, blank=True, null=True)
    amenities = models.JSONField(default=dict, blank=True, null=True)
    
    # Vehicle specific fields
    vehicle_type = models.CharField(max_length=50, blank=True, null=True)
    make = models.CharField(max_length=100, blank=True, null=True)
    model = models.CharField(max_length=100, blank=True, null=True)
    year = models.CharField(max_length=4, blank=True, null=True)
    mileage = models.CharField(max_length=20, blank=True, null=True)
    fuel_type = models.CharField(max_length=20, blank=True, null=True)
    transmission = models.CharField(max_length=20, blank=True, null=True)
    registration_year = models.CharField(max_length=4, blank=True, null=True)
    
    # Electronics specific fields
    electronics_type = models.CharField(max_length=50, blank=True, null=True)
    brand = models.CharField(max_length=100, blank=True, null=True)
    age_value = models.CharField(max_length=10, blank=True, null=True)
    age_unit = models.CharField(max_length=10, blank=True, null=True, default='months')
    warranty = models.CharField(max_length=30, blank=True, null=True)
    
    # Other categories fields
    item_type = models.CharField(max_length=100, blank=True, null=True)
    item_quality = models.CharField(max_length=100, blank=True, null=True)
    
    # Metadata
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sale_posts')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    featured = models.BooleanField(default=False)
    view_count = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Sale Post'
        verbose_name_plural = 'Sale Posts'
    
    def __str__(self):
        return self.title
    
    def save(self, *args, **kwargs):
        if not self.slug:
            # Generate a base slug from the title
            base_slug = slugify(self.title)
            
            # Add a unique identifier (first 8 chars of a UUID)
            unique_id = str(uuid.uuid4()).split('-')[0]
            
            # Combine base slug with unique identifier
            self.slug = f"{base_slug}-{unique_id}"
            
            # If the slug is too long, truncate the title part
            max_base_length = 280  # Allow space for the unique ID and hyphen
            if len(self.slug) > 300:
                truncated_base = base_slug[:max_base_length]
                self.slug = f"{truncated_base}-{unique_id}"
        
        super().save(*args, **kwargs)


class SalePostImage(models.Model):
    sale_post = models.ForeignKey(SalePost, on_delete=models.CASCADE, related_name='images')
    image = models.ImageField(upload_to='sale_posts/%Y/%m/%d/')
    is_main = models.BooleanField(default=False)
    order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['order']
    
    def __str__(self):
        return f"Image for {self.sale_post.title}"
