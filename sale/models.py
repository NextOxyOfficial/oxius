from django.db import models
from django.contrib.auth import get_user_model
from django.utils.text import slugify
import uuid
import time
import random
import re
import string

User = get_user_model()

def generate_unique_id():
    return int(time.time() * 1) + random.randint(0, 999)

def generate_unique_slug(model_class, field_value, instance=None):
# Handle Bangla/non-Latin slugification
    slug = slugify(field_value)
    if not slug or len(slug) < len(field_value) / 2:
        slug = re.sub(r'[\'.,:!?()&*+=|\\/\`~{}\[\]<>;"“”‘’"_।॥৳৥৲৶]', '', field_value)
        slug = re.sub(r'\s+', '-', slug)
        
    unique_slug = slug
    queryset = model_class.objects.filter(slug=unique_slug)

    # Exclude the current instance if it's an update
    if instance and instance.pk:
        queryset = queryset.exclude(pk=instance.pk)

    # Keep generating slugs until a unique one is found
    while queryset.exists():
        suffix = f"-{random.choice(string.ascii_lowercase)}{random.randint(1, 999)}"
        unique_slug = f"{slug}{suffix}"
        queryset = model_class.objects.filter(slug=unique_slug)
        if instance and instance.pk:
            queryset = queryset.exclude(pk=instance.pk)

    return unique_slug

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

class SaleBanner(models.Model):
    """Banner images for sale section"""
    id = models.BigIntegerField(primary_key=True, default=generate_unique_id, editable=False)
    title = models.CharField(max_length=255, blank=True, null=True)
    category = models.ForeignKey(SaleCategory, on_delete=models.SET_NULL, null=True, blank=True, related_name='banners')
    image = models.ImageField(upload_to='sale_banners/')
    link = models.URLField(max_length=500, blank=True, null=True)
    order = models.PositiveSmallIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['order']
        verbose_name = 'Sale Banner'
        verbose_name_plural = 'Sale Banners'
        
    def __str__(self):
        return self.title or f"Banner {self.id}"

class SaleCondition(models.Model):
    """Condition options for sale items that can be managed from the admin panel"""
    id = models.BigIntegerField(primary_key=True, default=generate_unique_id, editable=False)
    name = models.CharField(max_length=100, help_text="Display name (e.g., 'Brand New')")
    value = models.CharField(max_length=100, unique=True, help_text="Value for database (e.g., 'brand-new')")
    description = models.TextField(blank=True, null=True, help_text="Optional description of this condition")
    order = models.PositiveIntegerField(default=0, help_text="Display order in the dropdown")
    is_active = models.BooleanField(default=True, help_text="Whether this condition is currently available for selection")
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['order', 'name']
        verbose_name = 'Sale Condition'
        verbose_name_plural = 'Sale Conditions'
        
    def __str__(self):
        return self.name

class SalePost(models.Model):
    """Sale post model with simplified structure"""
    # Keeping CONDITION_CHOICES for backward compatibility and as fallback
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
    
    # Changed to allow any value to support dynamic conditions from SaleCondition model
    condition = models.CharField(max_length=100)
    condition_object = models.ForeignKey(
        SaleCondition, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name='posts',
        verbose_name="Condition"
    )
    
    # Price information
    price = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    negotiable = models.BooleanField(default=False)
    
    # Location information
    division = models.CharField(max_length=100,blank=True, null=True)
    district = models.CharField(max_length=100,blank=True, null=True)
    area = models.CharField(max_length=100,blank=True, null=True)
    detailed_address = models.TextField(blank=True, null=True)
    
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
            self.slug = generate_unique_slug(SalePost, self.title, self)
        
        # Link to condition object if available
        if self.condition and not self.condition_object:
            try:
                condition_obj = SaleCondition.objects.filter(value=self.condition).first()
                if condition_obj:
                    self.condition_object = condition_obj
            except:
                pass
                
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





