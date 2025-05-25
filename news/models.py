from django.db import models
from django.utils.text import slugify
from base.models import *
from tinymce import models as tinymce_models
import re
import string
import random


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
            self.slug = generate_unique_slug(NewsCategory,self.title,self)
        super().save(*args, **kwargs)
        
    def __str__(self):
        return self.title


class NewsPost(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='news_posts')
    category = models.ManyToManyField(NewsCategory, related_name='news_posts')
    title = models.CharField(max_length=255)
    content = tinymce_models.HTMLField()
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
            self.slug = generate_unique_slug(NewsPost,self.title,self)
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
            self.slug = generate_unique_slug(TipsAndSuggestion,self.title,self)
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"Tip: {self.title} by {self.author.username}"

    class Meta:
        ordering = ['-created_at']

class BreakingNews(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    title = models.CharField(max_length=255)
    news = models.ForeignKey(NewsPost, on_delete=models.CASCADE, related_name='breaking_news', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if BreakingNews.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        # if not self.slug and self.title:
        #     self.slug = slugify_bangla(self.title)
        super().save(*args, **kwargs)
    
    def __str__(self):
        return self.title
    

