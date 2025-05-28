from django.db import models
from django.contrib.auth import get_user_model
from django.utils.translation import gettext_lazy as _
from django.utils import timezone
from datetime import timedelta
import uuid

User = get_user_model()




class Batch(models.Model):
    """Model representing an educational batch like SSC, HSC, etc."""
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    name = models.CharField(_("Name"), max_length=100)
    code = models.SlugField(_("Code"), max_length=20, unique=True)
    description = models.TextField(_("Description"), blank=True)
    icon = models.CharField(_("Icon SVG"), max_length=500, blank=True, help_text="SVG code for the batch icon")
    display_order = models.PositiveIntegerField(_("Display Order"), default=0)
    is_active = models.BooleanField(_("Active"), default=True)
    created_at = models.DateTimeField(_("Created At"), auto_now_add=True)
    updated_at = models.DateTimeField(_("Updated At"), auto_now=True)
    
    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if Batch.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)

    class Meta:
        verbose_name = _("Batch")
        verbose_name_plural = _("Batches")
        ordering = ["display_order", "name"]

    def __str__(self):
        return self.name


class Division(models.Model):
    """Model representing an educational division like Science, Arts, Commerce, etc."""
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    name = models.CharField(_("Name"), max_length=100)
    code = models.SlugField(_("Code"), max_length=20, unique=True)
    description = models.TextField(_("Description"), blank=True)
    icon = models.CharField(_("Icon SVG"), max_length=500, blank=True, help_text="SVG code for the division icon")
    batches = models.ManyToManyField(Batch, related_name="divisions")
    display_order = models.PositiveIntegerField(_("Display Order"), default=0)
    is_active = models.BooleanField(_("Active"), default=True)
    created_at = models.DateTimeField(_("Created At"), auto_now_add=True)
    updated_at = models.DateTimeField(_("Updated At"), auto_now=True)
    
    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if Division.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)

    class Meta:
        verbose_name = _("Division")
        verbose_name_plural = _("Divisions")
        ordering = ["display_order", "name"]

    def __str__(self):
        return self.name


class Subject(models.Model):
    """Model representing an educational subject like Physics, Chemistry, etc."""
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    name = models.CharField(_("Name"), max_length=100)
    code = models.SlugField(_("Code"), max_length=30, unique=True)
    description = models.TextField(_("Description"), blank=True)
    icon = models.CharField(_("Icon SVG"), max_length=500, blank=True, help_text="SVG code for the subject icon")
    color = models.CharField(_("Color"), max_length=20, default="#3B82F6", 
                            help_text="Color code for the subject card")
    divisions = models.ManyToManyField(Division, related_name="subjects")
    display_order = models.PositiveIntegerField(_("Display Order"), default=0)
    is_active = models.BooleanField(_("Active"), default=True)
    created_at = models.DateTimeField(_("Created At"), auto_now_add=True)
    updated_at = models.DateTimeField(_("Updated At"), auto_now=True)
    
    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if Subject.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)

    class Meta:
        verbose_name = _("Subject")
        verbose_name_plural = _("Subjects")
        ordering = ["display_order", "name"]

    def __str__(self):
        return self.name


class VideoLesson(models.Model):
    """Model representing a video lesson in a subject."""
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    title = models.CharField(_("Title"), max_length=200)
    title_bn = models.CharField(_("Bengali Title"), max_length=200, blank=True)
    description = models.TextField(_("Description"))
    description_bn = models.TextField(_("Bengali Description"), blank=True)
    youtube_url = models.URLField(_("YouTube URL"))
    lesson_name = models.CharField(_("Lesson Name"), max_length=100)
    lesson_name_bn = models.CharField(_("Bengali Lesson Name"), max_length=100, blank=True)
    duration = models.CharField(_("Duration"), max_length=10)
    thumbnail_url = models.URLField(_("Thumbnail URL"), blank=True)
    views_count = models.PositiveIntegerField(_("Views Count"), default=0)
    subject = models.ForeignKey(Subject, on_delete=models.CASCADE, related_name="videos")
    display_order = models.PositiveIntegerField(_("Display Order"), default=0)
    is_active = models.BooleanField(_("Active"), default=True)
    is_featured = models.BooleanField(_("Featured"), default=False)
    created_at = models.DateTimeField(_("Created At"), auto_now_add=True)
    updated_at = models.DateTimeField(_("Updated At"), auto_now=True)
    
    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if VideoLesson.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        super().save(*args, **kwargs)

    class Meta:
        verbose_name = _("Video Lesson")
        verbose_name_plural = _("Video Lessons")
        ordering = ["display_order", "created_at"]

    def __str__(self):
        return self.title
    
    def get_youtube_id(self):
        """Extract YouTube video ID from URL."""
        import re
        pattern = r'(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})'
        match = re.search(pattern, self.youtube_url)
        if match:
            return match.group(1)
        return None

