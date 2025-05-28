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


# =============================================================================
# SESSION TRACKING MODELS FOR ACCESS CONTROL
# =============================================================================

class ELearningSession(models.Model):
    """Track active e-learning sessions to prevent abuse"""
    SESSION_STATUS_CHOICES = [
        ('active', 'Active'),
        ('expired', 'Expired'),
        ('terminated', 'Terminated'),
        ('inactive', 'Inactive'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='elearning_sessions')
    session_key = models.CharField(max_length=40, help_text="Browser session key")
    device_fingerprint = models.CharField(max_length=128, help_text="Device identifier")
    ip_address = models.GenericIPAddressField()
    user_agent = models.TextField()
    
    # Session tracking
    status = models.CharField(max_length=20, choices=SESSION_STATUS_CHOICES, default='active')
    started_at = models.DateTimeField(auto_now_add=True)
    last_activity = models.DateTimeField(auto_now=True)
    ended_at = models.DateTimeField(null=True, blank=True)
    
    # Access tracking
    page_url = models.URLField(help_text="E-learning page URL")
    subject_id = models.CharField(max_length=20, null=True, blank=True)
    current_video_id = models.CharField(max_length=20, null=True, blank=True)
    
    # Time tracking for non-pro users
    total_viewing_time = models.PositiveIntegerField(default=0, help_text="Total seconds viewed")
    session_viewing_time = models.PositiveIntegerField(default=0, help_text="Seconds viewed in this session")
    
    # Subscription status snapshot (for performance)
    is_pro_user = models.BooleanField(default=False)
    subscription_valid_until = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        verbose_name = _("E-Learning Session")
        verbose_name_plural = _("E-Learning Sessions")
        ordering = ['-started_at']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['device_fingerprint', 'status']),
            models.Index(fields=['ip_address', 'status']),
            models.Index(fields=['started_at']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.status} - {self.started_at}"
    
    def is_active(self):
        """Check if session is currently active"""
        if self.status != 'active':
            return False
        
        # Check if session has timed out (30 minutes of inactivity)
        timeout_threshold = timezone.now() - timedelta(minutes=30)
        if self.last_activity < timeout_threshold:
            self.expire_session('inactive')
            return False
            
        return True
    
    def expire_session(self, reason='expired'):
        """Mark session as expired"""
        self.status = reason
        self.ended_at = timezone.now()
        self.save(update_fields=['status', 'ended_at'])
    
    def add_viewing_time(self, seconds):
        """Add viewing time and check limits for non-pro users"""
        self.session_viewing_time += seconds
        self.total_viewing_time += seconds
        self.last_activity = timezone.now()
        
        # For non-pro users, check 1-minute limit
        if not self.is_pro_user and self.session_viewing_time >= 60:
            self.expire_session('time_limit_reached')
            return False
            
        self.save(update_fields=['session_viewing_time', 'total_viewing_time', 'last_activity'])
        return True
    
    def get_remaining_time(self):
        """Get remaining viewing time for non-pro users"""
        if self.is_pro_user:
            return None  # Unlimited for pro users
        
        return max(0, 60 - self.session_viewing_time)


class SessionActivityLog(models.Model):
    """Log all session activities for monitoring and abuse detection"""
    ACTION_CHOICES = [
        ('session_start', 'Session Started'),
        ('page_access', 'Page Accessed'),
        ('video_start', 'Video Started'),
        ('video_pause', 'Video Paused'),
        ('video_resume', 'Video Resumed'),
        ('video_end', 'Video Ended'),
        ('session_end', 'Session Ended'),
        ('concurrent_access_blocked', 'Concurrent Access Blocked'),
        ('time_limit_reached', 'Time Limit Reached'),
        ('suspicious_activity', 'Suspicious Activity'),
    ]
    
    session = models.ForeignKey(ELearningSession, on_delete=models.CASCADE, related_name='activity_logs')
    action = models.CharField(max_length=30, choices=ACTION_CHOICES)
    timestamp = models.DateTimeField(auto_now_add=True)
    details = models.JSONField(default=dict, blank=True)
    ip_address = models.GenericIPAddressField()
    
    class Meta:
        verbose_name = _("Session Activity Log")
        verbose_name_plural = _("Session Activity Logs")
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['session', 'timestamp']),
            models.Index(fields=['action', 'timestamp']),
        ]
    
    def __str__(self):
        return f"{self.session.user.username} - {self.action} - {self.timestamp}"


class DeviceSession(models.Model):
    """Track devices to prevent sharing"""
    device_fingerprint = models.CharField(max_length=128, unique=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='devices')
    device_name = models.CharField(max_length=100, blank=True)
    browser_info = models.TextField()
    first_seen = models.DateTimeField(auto_now_add=True)
    last_seen = models.DateTimeField(auto_now=True)
    is_trusted = models.BooleanField(default=False)
    
    # Concurrent session tracking
    active_sessions_count = models.PositiveIntegerField(default=0)
    max_allowed_sessions = models.PositiveIntegerField(default=1)
    
    class Meta:
        verbose_name = _("Device Session")
        verbose_name_plural = _("Device Sessions")
        ordering = ['-last_seen']
        indexes = [
            models.Index(fields=['device_fingerprint']),
            models.Index(fields=['user', 'is_trusted']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.device_name or 'Unknown Device'}"
    
    def can_start_new_session(self):
        """Check if device can start a new session"""
        return self.active_sessions_count < self.max_allowed_sessions
    
    def increment_sessions(self):
        """Increment active session count"""
        self.active_sessions_count += 1
        self.last_seen = timezone.now()
        self.save(update_fields=['active_sessions_count', 'last_seen'])
    
    def decrement_sessions(self):
        """Decrement active session count"""
        if self.active_sessions_count > 0:
            self.active_sessions_count -= 1
            self.save(update_fields=['active_sessions_count'])


class SuspiciousActivity(models.Model):
    """Track suspicious activities for abuse detection"""
    ACTIVITY_TYPES = [
        ('multiple_devices', 'Multiple Devices'),
        ('rapid_switching', 'Rapid Account Switching'),
        ('unusual_access_pattern', 'Unusual Access Pattern'),
        ('concurrent_sessions', 'Concurrent Sessions'),
        ('account_sharing', 'Potential Account Sharing'),
        ('automation_detected', 'Automation Detected'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='suspicious_activities')
    activity_type = models.CharField(max_length=30, choices=ACTIVITY_TYPES)
    description = models.TextField()
    evidence = models.JSONField(default=dict)
    severity = models.PositiveIntegerField(default=1, help_text="1-10 severity scale")
    
    # Context
    ip_addresses = models.JSONField(default=list)
    device_fingerprints = models.JSONField(default=list)
    session_ids = models.JSONField(default=list)
    
    # Status
    is_resolved = models.BooleanField(default=False)
    action_taken = models.TextField(blank=True)
    detected_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        verbose_name = _("Suspicious Activity")
        verbose_name_plural = _("Suspicious Activities")
        ordering = ['-detected_at']
        indexes = [
            models.Index(fields=['user', 'is_resolved']),
            models.Index(fields=['activity_type', 'detected_at']),
            models.Index(fields=['severity', 'is_resolved']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.activity_type} - Severity {self.severity}"
