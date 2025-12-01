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
        ('pending', 'Pending Review'),
        ('active', 'Active'),
        ('paused', 'Paused'),
        ('rejected', 'Rejected'),
        ('deleted', 'Deleted'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='workspace_gigs')
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES, default='design')
    price = models.DecimalField(max_digits=10, decimal_places=2)
    image = models.ImageField(upload_to=gig_image_path, blank=True, null=True)
    gallery = models.JSONField(default=list, blank=True, help_text="List of additional image URLs")
    delivery_time = models.PositiveIntegerField(default=3, help_text="Delivery time in days")
    revisions = models.PositiveIntegerField(default=2, help_text="Number of revisions included")
    skills = models.JSONField(default=list, blank=True, help_text="List of skills/expertise tags")
    features = models.JSONField(default=list, blank=True, help_text="List of what buyers will get")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    rejection_reason = models.TextField(blank=True, null=True, help_text="Reason for rejection if status is rejected")
    reviewed_at = models.DateTimeField(blank=True, null=True, help_text="When the gig was reviewed by admin")
    reviewed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='reviewed_gigs')
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
    order = models.ForeignKey('GigOrder', on_delete=models.SET_NULL, null=True, blank=True, related_name='review')
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
        ('disputed', 'Disputed'),
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


class OrderDispute(models.Model):
    """Model for order disputes"""
    STATUS_CHOICES = [
        ('open', 'Open'),
        ('under_review', 'Under Review'),
        ('resolved_buyer', 'Resolved - Buyer Wins'),
        ('resolved_seller', 'Resolved - Seller Wins'),
        ('resolved_partial', 'Resolved - Partial Refund'),
        ('closed', 'Closed'),
    ]
    
    REASON_CHOICES = [
        ('unresponsive_seller', 'Seller is unresponsive'),
        ('unresponsive_buyer', 'Buyer is unresponsive'),
        ('work_not_delivered', 'Work not delivered'),
        ('work_not_as_described', 'Work not as described'),
        ('quality_issues', 'Quality issues'),
        ('late_delivery', 'Late delivery'),
        ('payment_issue', 'Payment issue'),
        ('communication_issue', 'Communication breakdown'),
        ('other', 'Other'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey(GigOrder, on_delete=models.CASCADE, related_name='disputes')
    raised_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='disputes_raised')
    reason = models.CharField(max_length=50, choices=REASON_CHOICES)
    description = models.TextField(help_text="Detailed description of the issue")
    evidence = models.JSONField(default=list, blank=True, help_text="List of evidence URLs/attachments")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')
    
    # Admin resolution fields
    admin_notes = models.TextField(blank=True, null=True, help_text="Internal notes for admin")
    resolution_notes = models.TextField(blank=True, null=True, help_text="Resolution explanation visible to both parties")
    refund_amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True, help_text="Amount to refund if partial refund")
    resolved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='disputes_resolved')
    resolved_at = models.DateTimeField(blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Order Dispute"
        verbose_name_plural = "Order Disputes"
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Dispute #{str(self.id)[:8]} - Order #{str(self.order.id)[:8]}"
    
    @property
    def is_resolved(self):
        return self.status in ['resolved_buyer', 'resolved_seller', 'resolved_partial', 'closed']


class GigOrderTransaction(models.Model):
    """Model for tracking order payment transactions"""
    TRANSACTION_TYPE_CHOICES = [
        ('payment', 'Payment'),           # Buyer pays for order
        ('refund', 'Refund'),             # Refund to buyer
        ('release', 'Release'),           # Release payment to seller
        ('hold', 'Hold'),                 # Hold payment in escrow
    ]
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('refunded', 'Refunded'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey(GigOrder, on_delete=models.CASCADE, related_name='transactions')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='workspace_transactions')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    transaction_type = models.CharField(max_length=20, choices=TRANSACTION_TYPE_CHOICES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    description = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = "Order Transaction"
        verbose_name_plural = "Order Transactions"
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.transaction_type} - ৳{self.amount} for Order #{str(self.order.id)[:8]}"


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
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='workspace_order_messages', null=True, blank=True)
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


def workspace_banner_path(instance, filename):
    """Generate path for workspace banner images"""
    ext = filename.split('.')[-1]
    filename = f"banner_{uuid.uuid4()}.{ext}"
    return os.path.join('workspace/banners', filename)


class WorkspaceBanner(models.Model):
    """Model for workspace promotional banners"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=100, help_text="Banner title (for admin reference)")
    image = models.ImageField(upload_to=workspace_banner_path)
    link = models.URLField(blank=True, null=True, help_text="URL to navigate when banner is clicked")
    link_type = models.CharField(
        max_length=20,
        choices=[
            ('external', 'External URL'),
            ('internal', 'Internal Page'),
            ('gig', 'Gig Detail'),
            ('category', 'Category Filter'),
        ],
        default='external'
    )
    internal_path = models.CharField(max_length=255, blank=True, help_text="Internal path (e.g., /business-network/workspaces?category=design)")
    is_active = models.BooleanField(default=True)
    order = models.PositiveIntegerField(default=0, help_text="Display order (lower = first)")
    starts_at = models.DateTimeField(null=True, blank=True, help_text="When to start showing the banner")
    ends_at = models.DateTimeField(null=True, blank=True, help_text="When to stop showing the banner")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Workspace Banner"
        verbose_name_plural = "Workspace Banners"
        ordering = ['order', '-created_at']
    
    def __str__(self):
        return self.title
    
    @property
    def is_currently_active(self):
        """Check if banner should be displayed based on dates"""
        now = timezone.now()
        if not self.is_active:
            return False
        if self.starts_at and now < self.starts_at:
            return False
        if self.ends_at and now > self.ends_at:
            return False
        return True


class GigFeeSettings(models.Model):
    """
    Singleton model for managing gig order fees from Django Admin.
    Only one instance should exist - use get_settings() class method.
    """
    
    # Buyer fees (charged when placing order)
    buyer_service_fee_percent = models.DecimalField(
        max_digits=5, decimal_places=2, default=0,
        help_text="Percentage fee charged to buyer on order amount (e.g., 5 for 5%)"
    )
    buyer_service_fee_min = models.DecimalField(
        max_digits=10, decimal_places=2, default=0,
        help_text="Minimum service fee in BDT"
    )
    buyer_service_fee_max = models.DecimalField(
        max_digits=10, decimal_places=2, default=500,
        help_text="Maximum service fee cap in BDT"
    )
    buyer_processing_fee = models.DecimalField(
        max_digits=10, decimal_places=2, default=0,
        help_text="Fixed processing fee in BDT"
    )
    buyer_fee_waived = models.BooleanField(
        default=True,
        help_text="If checked, buyer service fees are waived (promotional period)"
    )
    
    # Seller fees (deducted from earnings on completion)
    seller_commission_percent = models.DecimalField(
        max_digits=5, decimal_places=2, default=10,
        help_text="Platform commission percentage deducted from seller earnings (e.g., 10 for 10%)"
    )
    seller_commission_min = models.DecimalField(
        max_digits=10, decimal_places=2, default=5,
        help_text="Minimum commission in BDT"
    )
    seller_commission_max = models.DecimalField(
        max_digits=10, decimal_places=2, default=5000,
        help_text="Maximum commission cap in BDT"
    )
    seller_withdrawal_fee = models.DecimalField(
        max_digits=10, decimal_places=2, default=0,
        help_text="Fee for withdrawing earnings in BDT"
    )
    seller_fee_discount_percent = models.DecimalField(
        max_digits=5, decimal_places=2, default=0,
        help_text="Promotional discount on seller commission (e.g., 20 for 20% off)"
    )
    
    # Metadata
    updated_at = models.DateTimeField(auto_now=True)
    updated_by = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='fee_settings_updates'
    )
    
    class Meta:
        verbose_name = "Gig Fee Settings"
        verbose_name_plural = "Gig Fee Settings"
    
    def __str__(self):
        return f"Gig Fee Settings (Buyer: {self.buyer_service_fee_percent}%, Seller: {self.seller_commission_percent}%)"
    
    def save(self, *args, **kwargs):
        """Ensure only one instance exists"""
        self.pk = 1
        super().save(*args, **kwargs)
    
    def delete(self, *args, **kwargs):
        """Prevent deletion"""
        pass
    
    @classmethod
    def get_settings(cls):
        """Get or create the singleton settings instance"""
        obj, created = cls.objects.get_or_create(pk=1)
        return obj
    
    def calculate_buyer_fees(self, order_amount):
        """Calculate buyer fees for an order"""
        order_amount = float(order_amount)
        
        if self.buyer_fee_waived:
            return {
                'order_amount': order_amount,
                'service_fee': 0,
                'processing_fee': 0,
                'total_fee': 0,
                'total_to_pay': order_amount,
                'is_fee_waived': True,
            }
        
        # Calculate service fee
        service_fee = (order_amount * float(self.buyer_service_fee_percent)) / 100
        service_fee = max(service_fee, float(self.buyer_service_fee_min))
        service_fee = min(service_fee, float(self.buyer_service_fee_max))
        service_fee = round(service_fee, 2)
        
        processing_fee = float(self.buyer_processing_fee)
        total_fee = service_fee + processing_fee
        total_to_pay = order_amount + total_fee
        
        return {
            'order_amount': order_amount,
            'service_fee': service_fee,
            'processing_fee': processing_fee,
            'total_fee': total_fee,
            'total_to_pay': total_to_pay,
            'is_fee_waived': False,
        }
    
    def calculate_seller_fees(self, order_amount):
        """Calculate seller fees/earnings for an order"""
        order_amount = float(order_amount)
        
        # Calculate platform commission
        commission = (order_amount * float(self.seller_commission_percent)) / 100
        commission = max(commission, float(self.seller_commission_min))
        commission = min(commission, float(self.seller_commission_max))
        
        # Apply promotional discount if any
        discount_applied = 0
        if self.seller_fee_discount_percent > 0:
            discount_applied = (commission * float(self.seller_fee_discount_percent)) / 100
            commission = commission - discount_applied
        
        commission = round(commission, 2)
        discount_applied = round(discount_applied, 2)
        net_earnings = order_amount - commission
        
        return {
            'order_amount': order_amount,
            'platform_commission': commission,
            'commission_percent': float(self.seller_commission_percent),
            'net_earnings': net_earnings,
            'discount_applied': discount_applied,
        }
