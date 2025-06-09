from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from decimal import Decimal
import uuid

User = get_user_model()

class Review(models.Model):
    """Model for product reviews"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    product = models.ForeignKey('base.Product', on_delete=models.CASCADE, related_name='product_reviews')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='user_reviews')
    rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        help_text="Rating from 1 to 5 stars"
    )
    title = models.CharField(max_length=200, blank=True, null=True)
    comment = models.TextField(help_text="Review comment")
    is_verified_purchase = models.BooleanField(default=False, help_text="Whether this review is from a verified purchase")
    is_approved = models.BooleanField(default=True, help_text="Whether this review is approved by admin")
    helpful_count = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ('product', 'user')  # One review per user per product
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['product', '-created_at']),
            models.Index(fields=['rating']),
            models.Index(fields=['is_approved']),
        ]
    
    def __str__(self):
        return f"{self.user.name or self.user.username} - {self.product.name} ({self.rating}★)"
    
    @property
    def reviewer_name(self):
        """Get the display name for the reviewer"""
        return self.user.name or self.user.first_name or self.user.username


class ReviewHelpful(models.Model):
    """Model to track which users found reviews helpful"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    review = models.ForeignKey(Review, on_delete=models.CASCADE, related_name='helpful_votes')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='review_helpful_votes')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('review', 'user')  # One vote per user per review
    
    def __str__(self):
        return f"{self.user.username} found {self.review.id} helpful"


class ProductRatingStats(models.Model):
    """Model to store aggregated rating statistics for products"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    product = models.OneToOneField('base.Product', on_delete=models.CASCADE, related_name='rating_stats')
    total_reviews = models.PositiveIntegerField(default=0)
    average_rating = models.DecimalField(max_digits=3, decimal_places=2, default=Decimal('0.00'))
    
    # Rating distribution
    rating_5_count = models.PositiveIntegerField(default=0)
    rating_4_count = models.PositiveIntegerField(default=0)
    rating_3_count = models.PositiveIntegerField(default=0)
    rating_2_count = models.PositiveIntegerField(default=0)
    rating_1_count = models.PositiveIntegerField(default=0)
    
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        indexes = [
            models.Index(fields=['average_rating']),
            models.Index(fields=['total_reviews']),
        ]
    
    def __str__(self):
        return f"{self.product.name} - {self.average_rating}★ ({self.total_reviews} reviews)"
    
    def get_rating_percentage(self, rating):
        """Get percentage for a specific rating"""
        if self.total_reviews == 0:
            return 0
        
        count_field = f'rating_{rating}_count'
        count = getattr(self, count_field, 0)
        return round((count / self.total_reviews) * 100, 1)
    
    def update_stats(self):
        """Update rating statistics from review data"""
        from django.db.models import Avg, Count
        
        reviews = Review.objects.filter(product=self.product, is_approved=True)
        
        # Update total reviews and average rating
        self.total_reviews = reviews.count()
        
        if self.total_reviews > 0:
            avg_rating = reviews.aggregate(avg=Avg('rating'))['avg']
            self.average_rating = round(Decimal(str(avg_rating)), 2)
            
            # Update rating distribution
            rating_counts = reviews.values('rating').annotate(count=Count('rating'))
            
            # Reset all counts
            self.rating_1_count = 0
            self.rating_2_count = 0
            self.rating_3_count = 0
            self.rating_4_count = 0
            self.rating_5_count = 0
            
            # Update counts based on actual data
            for item in rating_counts:
                count_field = f'rating_{item["rating"]}_count'
                setattr(self, count_field, item['count'])
        else:
            self.average_rating = Decimal('0.00')
            self.rating_1_count = 0
            self.rating_2_count = 0
            self.rating_3_count = 0
            self.rating_4_count = 0
            self.rating_5_count = 0
        
        self.save()

# Create your models here.
