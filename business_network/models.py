from django.db import models
from base.models import *

class BusinessNetworkMedia(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    image = models.ImageField(upload_to='images/', blank=True, null=True)
    def __str__(self):
      return str(self.id)

class BusinessNetworkPost(models.Model):
    id = models.CharField(max_length=10, unique=True, editable=False, primary_key=True)
    slug = models.SlugField(max_length=300, unique=True, null=True, blank=True)
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='business_network_posts')
    title = models.CharField(max_length=255)
    content = models.TextField()
    liked_by = models.ManyToManyField(User, related_name='liked_posts', blank=True)
    followed_by = models.ManyToManyField(User, related_name='followed_posts', blank=True)
    comments = models.ManyToManyField('BusinessNetworkPostComment', related_name='comments', blank=True)
    reports = models.ManyToManyField('BusinessNetworkPostReport', related_name='reports', blank=True)
    tags = models.ManyToManyField('BusinessNetworkPostTag', related_name='posts', blank=True)
    medias = models.ManyToManyField(BusinessNetworkMedia, blank=True)
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
        if not self.pk or not self.order_number:
            self.order_number = self.generate_id()
        super(BusinessNetworkPost, self).save(*args, **kwargs)
    def __str__(self):
        return f"Post {self.title} by {self.author.username}"
    
    
class BusinessNetworkPostComment(models.Model):
    post = models.ForeignKey(BusinessNetworkPost, on_delete=models.CASCADE,related_name='comments')
    author = models.ForeignKey(User,on_delete=models.CASCADE,related_name='business_network_comments')
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Comment by {self.author.username} on {self.post.title}"

class BusinessNetworkPostReport(models.Model):
    post = models.ForeignKey(BusinessNetworkPost, on_delete=models.CASCADE,related_name='reports')
    author = models.ForeignKey(User,on_delete=models.CASCADE,related_name='business_network_reports')
    reason = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Report by {self.author.username} on {self.post.title}"

class BusinessNetworkPostTag(models.Model):
    post = models.ForeignKey(BusinessNetworkPost, on_delete=models.CASCADE,related_name='tags')
    tag = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Tag {self.tag} for {self.post.title}"