from django.db import models
from django.utils.text import slugify
from django.utils import timezone
from base.models import *
import re
import os
import uuid
import random
import string

# Add this helper function for generating unique slugs
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


class BusinessNetworkMedia(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    image = models.ImageField(upload_to='business_network/images/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if BusinessNetworkMedia.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)

class BusinessNetworkMediaLike(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    media = models.ForeignKey('BusinessNetworkMedia', on_delete=models.CASCADE, related_name='media_likes')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='business_network_media_likes')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['media', 'user']

    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if BusinessNetworkMediaLike.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)

class BusinessNetworkMediaComment(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    media = models.ForeignKey('BusinessNetworkMedia', on_delete=models.CASCADE, related_name='media_comments')
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='business_network_media_comments')
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
    
    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if BusinessNetworkMediaComment.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)

class BusinessNetworkPostTag(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    tag = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)

    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if BusinessNetworkPostTag.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)

class BusinessNetworkPost(models.Model):
    VISIBILITY_CHOICES = [
        ('public', 'Public'),
        ('private', 'Private'),
    ]
    
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    slug = models.SlugField(max_length=300, unique=True, null=True, blank=True)
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='business_network_posts')
    title = models.CharField(max_length=255,blank=True,null=True)
    content = models.TextField(blank=True,null=True)
    media = models.ManyToManyField(BusinessNetworkMedia, blank=True, related_name='business_network_posts')
    tags = models.ManyToManyField(BusinessNetworkPostTag, blank=True, related_name='business_network_posts')
    visibility = models.CharField(max_length=10, choices=VISIBILITY_CHOICES, default='public')
    is_banned = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if BusinessNetworkPost.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        if not self.slug and self.title:
            self.slug = generate_unique_slug(BusinessNetworkPost,self.title,self)
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Post {self.title} by {self.author.username}"



class BusinessNetworkPostLike(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    post = models.ForeignKey(BusinessNetworkPost, on_delete=models.CASCADE, related_name='post_likes')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='business_network_likes')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['post', 'user']

    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if BusinessNetworkPostLike.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)

class BusinessNetworkPostFollow(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    post = models.ForeignKey(BusinessNetworkPost, on_delete=models.CASCADE, related_name='post_followers')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='business_network_follows')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['post', 'user']

    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if BusinessNetworkPostFollow.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)

class BusinessNetworkPostComment(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    post = models.ForeignKey(BusinessNetworkPost, on_delete=models.CASCADE, related_name='post_comments')
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='business_network_comments')
    parent_comment = models.ForeignKey('self', null=True, blank=True, on_delete=models.CASCADE, related_name='replies')
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_gift_comment = models.BooleanField(default=False) 
    diamond_amount = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['-created_at']
    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if BusinessNetworkPostComment.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)


class UserSavedPosts(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='saved_posts')
    post = models.ForeignKey(BusinessNetworkPost, on_delete=models.CASCADE, related_name='saved_by')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['user', 'post']
    
    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if UserSavedPosts.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number

    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)


class BusinessNetworkWorkspace(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if BusinessNetworkWorkspace.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)
    
    def __str__(self):
        return self.name
    
class BusinessNetworkFollowerModel(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    follower = models.ForeignKey(User, on_delete=models.CASCADE, related_name='business_network_followers')
    following = models.ForeignKey(User, on_delete=models.CASCADE, related_name='business_network_following')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['follower', 'following']  # Prevent duplicate follows
    
    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if BusinessNetworkFollowerModel.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
        
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)


class AbnAdsPanelCategory(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    name = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if AbnAdsPanelCategory.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)
    
    def __str__(self):
        return self.name

class AbnAdsPanelMedia(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    image = models.ImageField(upload_to='business_network/abn/', blank=True, null=True)
    video = models.FileField(upload_to='business_network/abn/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if AbnAdsPanelMedia.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)
    def __str__(self):
        return f"AbnAdsPanelMedia {self.id}"

class AbnAdsPanel(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    user= models.ForeignKey(User, on_delete=models.CASCADE, related_name='abn_ads_panel', null=True, blank=True)
    title = models.CharField(max_length=255)
    description = models.TextField()
    category = models.ForeignKey(AbnAdsPanelCategory, on_delete=models.CASCADE, related_name='abn_ads_panel')
    media = models.ManyToManyField(AbnAdsPanelMedia, blank=True, related_name='abn_ads_panel')
    male = models.BooleanField(default=False)
    female = models.BooleanField(default=False)
    other = models.BooleanField(default=False)
    min_age = models.PositiveIntegerField(null=True, blank=True)
    max_age = models.PositiveIntegerField(null=True, blank=True)
    COUNTRY_CHOICES = (
        ('bangladesh', 'Bangladesh'),
    )
    country = models.CharField(max_length=15, choices=COUNTRY_CHOICES, default='bangladesh')
    AD_TyPES = (
        ('click_to_website', 'Click To Website'),
        ('call_on_whatsapp', 'Call On WhatsApp'),
        ('call_on_phone', 'Call On Phone'),
        ('email_us', 'Email Us'),
    )
    ad_type = models.CharField(max_length=20, choices=AD_TyPES, default='image')
    ad_type_details= models.TextField(null=True, blank=True)
    budget = models.DecimalField(max_digits=10, decimal_places=2)
    STATUS_CHOCES = (('active', 'Active'), ('pending', 'Pending'),('stoped','Stoped'))
    status = models.CharField(max_length=20, choices=STATUS_CHOCES, default='active')
    views = models.PositiveIntegerField(default=0)
    estimated_views = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if AbnAdsPanel.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        if self.estimated_views == self.views:
            self.status = 'stoped'
        super().save(*args, **kwargs)
    
    def __str__(self):
        return self.title

class BusinessNetworkMindforceCategory(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    name = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if BusinessNetworkMindforceCategory.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
        
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)
        
    def __str__(self):
        return self.name

class BusinessNetworkMindforceMedia(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    image = models.ImageField(upload_to='business_network/mindforce/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if BusinessNetworkMindforceMedia.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
        
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)
        
    
class BusinessNetworkMindforce(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='business_network_mindforce',default=1)
    title = models.CharField(max_length=255)
    payment_option = models.CharField(max_length=255, blank=True, null=True)
    payment_amount = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    description = models.TextField()
    status = models.CharField(max_length=255,choices=(('active','Active'),('solved','Solved')), blank=True, null=True, default='active')
    category = models.ForeignKey(BusinessNetworkMindforceCategory, on_delete=models.CASCADE, related_name='business_network_mindforce', blank=True, null=True)
    media = models.ManyToManyField(BusinessNetworkMindforceMedia, blank=True, related_name='business_network_mindforce')
    views = models.PositiveIntegerField(default=0, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if BusinessNetworkMindforce.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
        
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)
        
    def __str__(self):
        return self.title

class BusinessNetworkMindforceCommentMedia(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    image = models.ImageField(upload_to='business_network/mindforce/comment/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if BusinessNetworkMindforceCommentMedia.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number

    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)
    

class BusinessNetworkMindforceComment(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    mindforce_problem = models.ForeignKey(BusinessNetworkMindforce, on_delete=models.CASCADE, related_name='mindforce_comments')
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='mindforce_comments')
    content = models.TextField()
    media = models.ManyToManyField(BusinessNetworkMindforceCommentMedia, blank=True, related_name='mindforce_comments')
    is_solved = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if BusinessNetworkMindforceComment.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
        
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)


class BusinessNetworkNotification(models.Model):
    """Model for business network notifications"""
    NOTIFICATION_TYPES = (
        ('follow', 'Follow'),
        ('like_post', 'Like Post'),
        ('like_comment', 'Like Comment'),
        ('comment', 'Comment'),
        ('reply', 'Reply'),
        ('mention', 'Mention'),
        ('solution', 'Solution'),
    )
    
    recipient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='bn_notifications_received')
    actor = models.ForeignKey(User, on_delete=models.CASCADE, related_name='bn_notifications_created')
    type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    read = models.BooleanField(default=False)
    target_id = models.CharField(max_length=50, null=True, blank=True)  # ID of the target object (post, comment, etc.)
    parent_id = models.CharField(max_length=50, null=True, blank=True)  # ID of parent object (post for comments)
    content = models.TextField(null=True, blank=True)  # Optional content snippet
    created_at = models.DateTimeField(auto_now_add=True)
    def __str__(self):
        return f"{self.sponsor.business_name} - {self.title or 'Banner'}"


class HiddenPost(models.Model):
    """Model to track posts hidden by users"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='hidden_posts')
    post = models.ForeignKey('BusinessNetworkPost', on_delete=models.CASCADE, related_name='hidden_by_users')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['user', 'post']
        ordering = ['-created_at']
        verbose_name = "Hidden Post"
        verbose_name_plural = "Hidden Posts"
    
    def __str__(self):
        return f"{self.user.username} hid post {self.post.id}"


class PostReport(models.Model):
    """Model to track post reports"""
    REPORT_REASONS = [
        ('spam', 'Spam or misleading'),
        ('harassment', 'Harassment or hate speech'),
        ('violence', 'Violence or dangerous content'),
        ('inappropriate', 'Inappropriate content'),
        ('other', 'Other'),
    ]
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('reviewed', 'Reviewed'),
        ('resolved', 'Resolved'),
        ('dismissed', 'Dismissed'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='post_reports')
    post = models.ForeignKey('BusinessNetworkPost', on_delete=models.CASCADE, related_name='reports')
    reason = models.CharField(max_length=20, choices=REPORT_REASONS)
    description = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['user', 'post', 'reason']
        ordering = ['-created_at']
        verbose_name = "Post Report"
        verbose_name_plural = "Post Reports"
    
    def __str__(self):
        return f"{self.user.username} reported post {self.post.id} for {self.get_reason_display()}"


# Gold Sponsor Models

def sponsor_logo_path(instance, filename):
    """Generate a unique path for uploading sponsor logos"""
    ext = filename.split('.')[-1]
    filename = f"{uuid.uuid4()}.{ext}"
    return os.path.join('business_network/gold_sponsors', filename)


class SponsorshipPackage(models.Model):
    """Model for different gold sponsorship packages"""
    name = models.CharField(max_length=100)
    description = models.TextField(max_length=255)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    duration_months = models.IntegerField(default=1)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Sponsorship Package"
        verbose_name_plural = "Sponsorship Packages"
    
    def __str__(self):
        return f"{self.name} - ৳{self.price}"


class GoldSponsor(models.Model):
    """Model for gold sponsors"""
    STATUS_CHOICES = (
        ('pending', 'Pending Approval'),
        ('active', 'Active'),
        ('expired', 'Expired'),
        ('rejected', 'Rejected'),
    )
    
    # Ownership field
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='gold_sponsors')
    
    business_name = models.CharField(max_length=255)
    business_description = models.TextField(max_length=500)
    slug = models.SlugField(max_length=255, unique=True, blank=True)
    contact_email = models.EmailField()
    phone_number = models.CharField(max_length=20)
    website = models.URLField(blank=True, null=True)
    profile_url = models.URLField(blank=True, null=True)
    logo = models.ImageField(upload_to=sponsor_logo_path, blank=True, null=True)
    
    # Package information
    package = models.ForeignKey(SponsorshipPackage, on_delete=models.PROTECT, related_name='sponsors')
    start_date = models.DateTimeField(default=timezone.now)
    end_date = models.DateTimeField(blank=True, null=True)
    
    # Views tracking
    views = models.PositiveIntegerField(default=0)
    
    # Status and timestamps
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    is_featured = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Gold Sponsor"
        verbose_name_plural = "Gold Sponsors"
        ordering = ['-created_at']
    
    def save(self, *args, **kwargs):
        # Generate a slug if not provided
        if not self.slug:
            self.slug = slugify(self.business_name)
            # Ensure unique slug
            original_slug = self.slug
            counter = 1
            while GoldSponsor.objects.filter(slug=self.slug).exclude(pk=self.pk).exists():
                self.slug = f"{original_slug}-{counter}"
                counter += 1
        
        # Calculate end date based on package duration
        if not self.end_date and self.package:
            from datetime import timedelta
            self.end_date = self.start_date + timedelta(days=30 * self.package.duration_months)
        
        # Handle payment deduction for new sponsorships
        if not self.pk and self.user and self.package:  # Only for new instances
            if self.user.balance < self.package.price:
                from django.core.exceptions import ValidationError
                raise ValidationError(f"Insufficient balance. You need ৳{self.package.price} but have ৳{self.user.balance}")
            
            # Deduct money from user's balance
            self.user.balance -= self.package.price
            self.user.save()
            
        super().save(*args, **kwargs)
    
    def increment_views(self):
        """Increment views count"""
        self.views += 1
        self.save(update_fields=['views'])
    
    def is_active(self):
        """Check if sponsorship is currently active"""
        return self.status == 'active' and self.end_date > timezone.now()
    
    def days_remaining(self):
        """Get days remaining for the sponsorship"""
        if self.end_date:
            remaining = self.end_date - timezone.now()
            return max(0, remaining.days)
        return 0
    
    def __str__(self):
        return self.business_name


def sponsor_banner_path(instance, filename):
    """Generate a unique path for uploading sponsor banners"""
    ext = filename.split('.')[-1]
    filename = f"{uuid.uuid4()}.{ext}"
    return os.path.join('business_network/gold_sponsors/banners', filename)


class GoldSponsorBanner(models.Model):
    """Model for gold sponsor banners"""
    sponsor = models.ForeignKey(GoldSponsor, on_delete=models.CASCADE, related_name='banners')
    title = models.CharField(max_length=255, blank=True, null=True)
    image = models.ImageField(upload_to=sponsor_banner_path)
    link_url = models.URLField(blank=True, null=True)
    order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Gold Sponsor Banner"
        verbose_name_plural = "Gold Sponsor Banners"
        ordering = ['order', '-created_at']
    
    def __str__(self):
        return f"Banner for {self.sponsor.business_name}"