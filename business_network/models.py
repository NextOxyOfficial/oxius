from django.db import models
from base.models import *



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
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    slug = models.SlugField(max_length=300, unique=True, null=True, blank=True)
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='business_network_posts')
    title = models.CharField(max_length=255)
    content = models.TextField()
    media = models.ManyToManyField(BusinessNetworkMedia, blank=True, related_name='business_network_posts')
    tags = models.ManyToManyField(BusinessNetworkPostTag, blank=True, related_name='business_network_posts')
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
            self.slug = slugify(self.title)
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
        if BusinessNetworkPostComment.objects.filter(id=base_number).exists():
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
    title = models.CharField(max_length=255)
    description = models.TextField()
    category = models.ForeignKey(AbnAdsPanelCategory, on_delete=models.CASCADE, related_name='abn_ads_panel')
    media = models.ManyToManyField(AbnAdsPanelMedia, blank=True, related_name='abn_ads_panel')
    GENDER_CHOICES = (
        ('male' , 'Male'),
        ('female' , 'Female'),
        ('other' , 'Other'),
    )
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES, default='male')
    min_age = models.PositiveIntegerField(null=True, blank=True)
    max_age = models.PositiveIntegerField(null=True, blank=True)
    COUNTRY_CHOICES = (
        ('BD', 'Bangladesh'),
    )
    country = models.CharField(max_length=2, choices=COUNTRY_CHOICES, default='BD')
    AD_TyPES = (
        ('click_to_website', 'Click To Website'),
        ('call_on_whatsapp', 'Call On WhatsApp'),
        ('call_on_phone', 'Call On Phone'),
        ('email_us', 'Email Us'),
    )
    ad_type = models.CharField(max_length=20, choices=AD_TyPES, default='image')
    ad_budgert = models.DecimalField(max_digits=10, decimal_places=2)
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
        super().save(*args, **kwargs)
    
    def __str__(self):
        return self.title
