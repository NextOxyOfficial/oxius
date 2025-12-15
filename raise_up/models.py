from django.db import models
from django.contrib.auth import get_user_model
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone

User = get_user_model()

class RaiseUpPost(models.Model):
    STAGE_CHOICES = [
        ('seed', 'Seed'),
        ('early', 'Early'),
        ('growth', 'Growth'),
    ]
    
    STAGE_COLOR_CHOICES = [
        ('purple', 'Purple'),
        ('blue', 'Blue'),
        ('emerald', 'Emerald'),
        ('amber', 'Amber'),
    ]
    
    FUNDING_TYPE_CHOICES = [
        ('investment', 'Investment'),
        ('donation', 'Donation'),
        ('investment_donation', 'Investment + Donation'),
        ('revenue_share', 'Revenue Share'),
    ]
    
    RISK_LEVEL_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
    ]
    
    # Basic Info
    title = models.CharField(max_length=200)
    summary = models.TextField()
    sector = models.CharField(max_length=100)
    location = models.CharField(max_length=100)
    city = models.CharField(max_length=100)
    area = models.CharField(max_length=100, blank=True)
    
    # Funding Details
    stage = models.CharField(max_length=20, choices=STAGE_CHOICES)
    stage_color = models.CharField(max_length=20, choices=STAGE_COLOR_CHOICES)
    funding_type = models.CharField(max_length=50, choices=FUNDING_TYPE_CHOICES)
    min_investment = models.DecimalField(max_digits=12, decimal_places=2)
    expected_return = models.CharField(max_length=100)
    risk_level = models.CharField(max_length=20, choices=RISK_LEVEL_CHOICES)
    traction = models.CharField(max_length=200)
    
    # Financial
    raised = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    goal = models.DecimalField(max_digits=12, decimal_places=2)
    
    # Media
    thumbnail = models.URLField()
    video_embed_url = models.URLField(blank=True)
    
    # Poster (User)
    poster = models.ForeignKey(User, on_delete=models.CASCADE, related_name='raise_up_posts')
    
    # Timestamps
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Status
    is_active = models.BooleanField(default=True)
    is_featured = models.BooleanField(default=False)
    
    class Meta:
        ordering = ['-created_at']
        
    def __str__(self):
        return self.title
    
    @property
    def progress_percent(self):
        if self.goal > 0:
            return min(100, max(0, round((float(self.raised) / float(self.goal)) * 100)))
        return 0

class RaiseUpPostDetail(models.Model):
    post = models.OneToOneField(RaiseUpPost, on_delete=models.CASCADE, related_name='details')
    overview = models.TextField()
    use_of_funds = models.JSONField(default=list)  # List of strings
    milestones = models.JSONField(default=list)    # List of strings
    
    def __str__(self):
        return f"Details for {self.post.title}"

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='raise_up_profile')
    profession = models.CharField(max_length=200, blank=True)
    avatar = models.URLField(blank=True)
    is_pro = models.BooleanField(default=False)
    kyc_verified = models.BooleanField(default=False)
    
    def __str__(self):
        return f"{self.user.username} Profile"
