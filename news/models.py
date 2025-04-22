from django.db import models
from django.utils.text import slugify
from base.models import *

def slugify_bangla(text):
    slug = slugify(text)
    if not slug or len(slug) < len(text) / 2:
        return f"{text.replace(' ', '-')}"
    else:
        return slug
    
class NewsCategory(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    title = models.CharField(max_length=255)
    slug = models.SlugField(max_length=300, unique=True, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if NewsCategory.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        if not self.slug and self.title:
            self.slug = slugify_bangla(self.title)
        super().save(*args, **kwargs)
        
    def __str__(self):
        return self.title


class NewsPost(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='news_posts')
    category = models.ManyToManyField(NewsCategory, related_name='news_posts')
    title = models.CharField(max_length=255)
    content = models.TextField()
    image = models.ImageField(upload_to='news/images/', blank=True, null=True)
    slug = models.SlugField(max_length=300, unique=True, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if NewsPost.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        if not self.slug and self.title:
            self.slug = slugify_bangla(self.title)
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Post {self.title} by {self.author.username}"


class NewsPostComment(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    post = models.ForeignKey(NewsPost, on_delete=models.CASCADE, related_name='post_comments')
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='news_comments')
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
        if NewsPostComment.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)

class TipsAndSuggestion(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    title = models.CharField(max_length=255)
    slug = models.SlugField(max_length=300, unique=True, null=True, blank=True)
    description = models.TextField()
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='tips_suggestions')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if TipsAndSuggestion.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        if not self.slug and self.title:
            self.slug = slugify_bangla(self.title)
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"Tip: {self.title} by {self.author.username}"

    class Meta:
        ordering = ['-created_at']

