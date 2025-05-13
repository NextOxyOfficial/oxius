from django.db import models
from django.contrib.auth import get_user_model
from django.utils.text import slugify
import uuid
import time
import random

User = get_user_model()

def generate_unique_id():
    return int(time.time() * 1) + random.randint(0, 999)

class SaleCategory(models.Model):
    """Parent category model for sale items"""
    id = models.BigIntegerField(primary_key=True, default=generate_unique_id, editable=False)
    name = models.CharField(max_length=255)
    icon = models.ImageField(upload_to='sale_categories/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'Sale Category'
        verbose_name_plural = 'Sale Categories'
        ordering = ['name']
        
    def __str__(self):
        return self.name
        
class SaleChildCategory(models.Model):
    """Child category model for more specific categorization"""
    id = models.BigIntegerField(primary_key=True, default=generate_unique_id, editable=False)
    parent = models.ForeignKey(SaleCategory, on_delete=models.CASCADE, related_name='child_categories')
    name = models.CharField(max_length=255)
    icon = models.ImageField(upload_to='sale_child_categories/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'Sale Child Category'
        verbose_name_plural = 'Sale Child Categories'
        ordering = ['name']
        
    def __str__(self):
        return f"{self.name} ({self.parent.name})"

class SalePost(models.Model):
    """Sale post model with simplified structure"""
    CONDITION_CHOICES = (
        ('brand-new', 'Brand New'),
        ('like-new', 'Like New'),
        ('good', 'Good'),
        ('fair', 'Fair'),
        ('for-parts', 'For Parts'),
    )
    
    STATUS_CHOICES = (
        ('pending', 'Pending Review'),
        ('active', 'Active'),
        ('sold', 'Sold'),
        ('expired', 'Expired'),
    )
    
    # Basic information
    id = models.BigIntegerField(primary_key=True, default=generate_unique_id, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sale_posts')
    category = models.ForeignKey(SaleCategory, on_delete=models.SET_NULL, null=True, related_name='posts')
    child_category = models.ForeignKey(SaleChildCategory, on_delete=models.SET_NULL, null=True, blank=True, related_name='posts')
    title = models.CharField(max_length=255)
    slug = models.SlugField(max_length=300, unique=True, blank=True)
    description = models.TextField()
    condition = models.CharField(max_length=20, choices=CONDITION_CHOICES)
    
    # Price information
    price = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    negotiable = models.BooleanField(default=False)
    
    # Location information
    division = models.CharField(max_length=100)
    district = models.CharField(max_length=100)
    area = models.CharField(max_length=100)
    detailed_address = models.TextField()
    
    # Contact information
    phone = models.CharField(max_length=15)
    email = models.EmailField(blank=True, null=True)
    
    # Status and metadata
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    view_count = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
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

class SaleImage(models.Model):
    """Images for sale posts"""
    id = models.BigIntegerField(primary_key=True, default=generate_unique_id, editable=False)
    post = models.ForeignKey(SalePost, on_delete=models.CASCADE, related_name='images')
    image = models.ImageField(upload_to='sale_posts_images/')
    is_main = models.BooleanField(default=False)
    order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['order']
        verbose_name = 'Sale Image'
        verbose_name_plural = 'Sale Images'
        
    def __str__(self):
        return f"Image for {self.post.title} ({'Main' if self.is_main else 'Regular'})"





