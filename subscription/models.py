from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()

class SubscriptionPlan(models.Model):
    """Model to define different subscription plans available"""
    name = models.CharField(max_length=100)
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    duration_days = models.PositiveIntegerField(help_text="Duration in days")
    max_listings = models.PositiveIntegerField(default=5, help_text="Maximum number of listings allowed")
    featured_listings = models.PositiveIntegerField(default=0, help_text="Number of featured listings included")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.name} (৳{self.price} for {self.duration_days} days)"


class Subscription(models.Model):
    """Model to track user subscriptions"""
    STATUS_CHOICES = (
        ('active', 'Active'),
        ('expired', 'Expired'),
        ('cancelled', 'Cancelled'),
        ('pending', 'Pending Payment'),
    )

    PAYMENT_METHOD_CHOICES = (
        ('credit_card', 'Credit Card'),
        ('bkash', 'bKash'),
        ('nagad', 'Nagad'),
        ('bank_transfer', 'Bank Transfer'),
        ('sslcommerz', 'SSLCommerz'),
        ('account_balance', 'Account Balance'),
        ('other', 'Other'),
    )

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='subscriptions')
    plan = models.ForeignKey(SubscriptionPlan, on_delete=models.PROTECT)
    
    # Subscription details
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    start_date = models.DateTimeField(null=True, blank=True)
    end_date = models.DateTimeField(null=True, blank=True)
    auto_renew = models.BooleanField(default=False)
    
    # Payment details
    payment_method = models.CharField(max_length=20, choices=PAYMENT_METHOD_CHOICES, null=True, blank=True)
    payment_reference = models.CharField(max_length=100, null=True, blank=True, help_text="Transaction ID or reference")
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        
    def __str__(self):
        return f"{self.user.username} - {self.plan.name} ({self.status})"
    
    def is_active(self):
        """Check if subscription is currently active"""
        if self.status != 'active':
            return False
        if not self.end_date:
            return False
        return self.end_date > timezone.now()
    
    def days_remaining(self):
        """Return number of days remaining in subscription"""
        if not self.is_active():
            return 0
        delta = self.end_date - timezone.now()
        return max(0, delta.days)

    def activate(self):
        """Activate subscription and set start/end dates"""
        if not self.start_date:
            self.start_date = timezone.now()
        # Set end date based on plan duration
        self.end_date = self.start_date + timezone.timedelta(days=self.plan.duration_days)
        self.status = 'active'
        self.save()
        
        # Update user's pro status if this is a paid plan
        if self.plan.price > 0:
            self.user.is_pro = True
            self.user.pro_validity = self.end_date
            self.user.save(update_fields=['is_pro', 'pro_validity'])
        
    def cancel(self):
        """Cancel subscription"""
        self.status = 'cancelled'
        self.auto_renew = False
        self.save()
        
        # If this was a paid plan, remove pro status from user
        if self.plan.price > 0:
            # Check if user has any other active paid subscriptions
            other_active_paid = Subscription.objects.filter(
                user=self.user,
                status='active',
                end_date__gt=timezone.now(),
                plan__price__gt=0
            ).exclude(id=self.id).exists()
            
            if not other_active_paid:
                self.user.is_pro = False
                self.user.pro_validity = None
                self.user.save(update_fields=['is_pro', 'pro_validity'])

    def expire(self):
        """Mark subscription as expired and update user pro status"""
        self.status = 'expired'
        self.save()
        
        # If this was a paid plan, remove pro status from user
        if self.plan.price > 0:
            # Check if user has any other active paid subscriptions
            other_active_paid = Subscription.objects.filter(
                user=self.user,
                status='active',
                end_date__gt=timezone.now(),
                plan__price__gt=0
            ).exclude(id=self.id).exists()
            
            if not other_active_paid:
                self.user.is_pro = False
                self.user.pro_validity = None
                self.user.save(update_fields=['is_pro', 'pro_validity'])


class SubscriptionLog(models.Model):
    """Model to track subscription events and history"""
    ACTIONS = (
        ('created', 'Created'),
        ('activated', 'Activated'),
        ('renewed', 'Renewed'),
        ('cancelled', 'Cancelled'),
        ('expired', 'Expired'),
        ('payment_failed', 'Payment Failed'),
    )
    
    subscription = models.ForeignKey(Subscription, on_delete=models.CASCADE, related_name='logs')
    action = models.CharField(max_length=20, choices=ACTIONS)
    timestamp = models.DateTimeField(auto_now_add=True)
    details = models.TextField(blank=True, null=True)
    
    class Meta:
        ordering = ['-timestamp']
    
    def __str__(self):
        return f"{self.subscription.user.username} - {self.action} at {self.timestamp.strftime('%Y-%m-%d %H:%M')}"
