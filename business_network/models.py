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
    MEDIA_TYPE_CHOICES = [
        ('image', 'Image'),
        ('video', 'Video'),
    ]
    
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    type = models.CharField(max_length=10, choices=MEDIA_TYPE_CHOICES, default='image')
    image = models.ImageField(upload_to='business_network/images/', blank=True, null=True)
    video = models.FileField(upload_to='business_network/videos/', blank=True, null=True)
    thumbnail = models.ImageField(upload_to='business_network/thumbnails/', blank=True, null=True)
    views = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        filename = ""
        if self.type == "video" and self.video:
            filename = os.path.basename(self.video.name)
        elif self.image:
            filename = os.path.basename(self.image.name)
        elif self.thumbnail:
            filename = os.path.basename(self.thumbnail.name)
        return f"{self.type}:{self.id}{(' - ' + filename) if filename else ''}"

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

    def ensure_thumbnail(self):
        if self.type != "video":
            return
        if not self.video:
            return
        if self.thumbnail:
            return

        try:
            video_path = getattr(self.video, "path", None)
            if not video_path:
                return

            import os
            import tempfile
            from django.core.files.base import ContentFile

            try:
                import imageio.v3 as iio
                from PIL import Image

                frame = iio.imread(video_path, index=0)
                if frame is not None:
                    img = Image.fromarray(frame)
                    with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as tmp:
                        tmp_path = tmp.name
                    img.save(tmp_path, format="JPEG", quality=85)

                    with open(tmp_path, "rb") as f:
                        thumb_data = f.read()
                    os.unlink(tmp_path)

                    thumb_file = ContentFile(thumb_data)
                    thumb_file.name = f"thumb_{os.path.basename(video_path).rsplit('.', 1)[0]}.jpg"
                    self.thumbnail.save(thumb_file.name, thumb_file, save=True)
                    return
            except Exception as e:
                print(f"ensure_thumbnail imageio failed: {e}")

            try:
                from moviepy.editor import VideoFileClip

                clip = VideoFileClip(video_path)
                frame_time = 0
                try:
                    if getattr(clip, "duration", 0):
                        frame_time = min(0.5, clip.duration / 2)
                except Exception:
                    frame_time = 0

                with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as tmp:
                    tmp_path = tmp.name

                clip.save_frame(tmp_path, t=frame_time)
                clip.close()

                with open(tmp_path, "rb") as f:
                    thumb_data = f.read()
                os.unlink(tmp_path)

                thumb_file = ContentFile(thumb_data)
                thumb_file.name = f"thumb_{os.path.basename(video_path).rsplit('.', 1)[0]}.jpg"
                self.thumbnail.save(thumb_file.name, thumb_file, save=True)
                return
            except Exception as e:
                print(f"ensure_thumbnail moviepy failed: {e}")
                

            try:
                import cv2

                cap = cv2.VideoCapture(video_path)
                ret, frame = cap.read()
                cap.release()
                if not ret:
                    raise Exception("cv2 could not read frame")

                ok, buffer = cv2.imencode(".jpg", frame)
                if not ok:
                    raise Exception("cv2 could not encode frame")

                thumb_file = ContentFile(buffer.tobytes())
                thumb_file.name = f"thumb_{os.path.basename(video_path).rsplit('.', 1)[0]}.jpg"
                self.thumbnail.save(thumb_file.name, thumb_file, save=True)
                return
            except Exception as e:
                print(f"ensure_thumbnail opencv failed: {e}")

            try:
                import subprocess
                import shutil

                ffmpeg_bin = shutil.which("ffmpeg")
                if not ffmpeg_bin:
                    for p in ["/snap/bin/ffmpeg", "/usr/bin/ffmpeg", "/usr/local/bin/ffmpeg"]:
                        if os.path.isfile(p):
                            ffmpeg_bin = p
                            break
                if not ffmpeg_bin:
                    raise Exception("ffmpeg not found on PATH or known locations")

                with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as tmp:
                    tmp_path = tmp.name

                result = subprocess.run(
                    [
                        ffmpeg_bin,
                        "-i", video_path,
                        "-vf", "select=eq(n\\,0)",
                        "-vframes", "1",
                        "-f", "image2",
                        "-y",
                        tmp_path,
                    ],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    timeout=30,
                )

                if os.path.exists(tmp_path) and os.path.getsize(tmp_path) > 0:
                    with open(tmp_path, "rb") as f:
                        thumb_data = f.read()
                    os.unlink(tmp_path)

                    thumb_file = ContentFile(thumb_data)
                    thumb_file.name = f"thumb_{os.path.basename(video_path).rsplit('.', 1)[0]}.jpg"
                    self.thumbnail.save(thumb_file.name, thumb_file, save=True)
                    return

                if os.path.exists(tmp_path):
                    os.unlink(tmp_path)
                stderr_out = result.stderr.decode("utf-8", errors="replace")[-500:] if result.stderr else "no stderr"
                raise Exception(f"ffmpeg produced empty output. stderr: {stderr_out}")
            except Exception as e:
                print(f"ensure_thumbnail ffmpeg failed: {e}")
                return
        except Exception:
            return


class BusinessNetworkMediaView(models.Model):
    """One row per (media, user) — so the media.views counter (which feeds
    monetization eligibility) counts each viewer once and can't be pumped by
    repeated calls or self-views."""
    media = models.ForeignKey(
        'BusinessNetworkMedia', on_delete=models.CASCADE, related_name='view_records'
    )
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='business_network_media_views'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        # unique_together already provides the (media, user) index we look up on.
        unique_together = ['media', 'user']


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

    class Meta:
        indexes = [
            models.Index(fields=["tag"], name="bn_post_tag_tag_idx"),
        ]

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
        ('followers', 'Followers only'),
        ('private', 'Private'),
    ]
    
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    slug = models.SlugField(max_length=300, unique=True, null=True, blank=True)
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='business_network_posts')
    title = models.CharField(max_length=255,blank=True,null=True)
    content = models.TextField(blank=True,null=True)
    # A reshare/repost: this post shares another user's post. content holds the
    # optional caption; media/tags stay empty (the original is embedded).
    shared_from = models.ForeignKey(
        'self', null=True, blank=True, on_delete=models.SET_NULL,
        related_name='reshares',
    )
    # A reshare of an Adsy News story. shared_from can only point at another
    # BusinessNetworkPost, so news reshares need their own reference.
    shared_news = models.ForeignKey(
        'news.NewsPost', null=True, blank=True, on_delete=models.SET_NULL,
        related_name='bn_reshares',
    )
    media = models.ManyToManyField(BusinessNetworkMedia, blank=True, related_name='business_network_posts')
    tags = models.ManyToManyField(BusinessNetworkPostTag, blank=True, related_name='business_network_posts')
    # Shares that are NOT reposts (sent to a chat, external apps, etc.).
    # share_count in the serializer = reshares.count() + this.
    external_share_count = models.PositiveIntegerField(default=0)
    visibility = models.CharField(max_length=10, choices=VISIBILITY_CHOICES, default='public')
    is_banned = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Denormalized engagement counters, kept in sync by signals (see signals.py).
    # They let the feed rank by engagement without a COUNT(...) join per post on
    # every request, and power the time-decayed "hot" ranking.
    like_count = models.PositiveIntegerField(default=0)
    comment_count = models.PositiveIntegerField(default=0)
    save_count = models.PositiveIntegerField(default=0)
    # Last time anyone liked/commented/saved — used to surface freshly active posts.
    last_activity_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        indexes = [
            models.Index(
                fields=["visibility", "is_banned", "-created_at"],
                name="bn_post_feed_idx",
            ),
            models.Index(
                fields=["author", "-created_at"],
                name="bn_post_author_recent_idx",
            ),
            # Speeds up the engagement/time-decay ordering in the society feed.
            models.Index(
                fields=["visibility", "is_banned", "-last_activity_at"],
                name="bn_post_activity_idx",
            ),
        ]
    
    def generate_id(self):
        from datetime import datetime
        import random
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")
        if BusinessNetworkPost.objects.filter(id=base_number).exists():
            random_suffix = f"{random.randint(0, 999):03d}"
            return base_number[:7] + random_suffix
        return base_number
    
    def _generate_hash_slug(self):
        """A short random hash so every post has a unique, unguessable
        shareable link (title was removed, so slugs no longer derive from it)."""
        from django.utils.crypto import get_random_string
        alphabet = "abcdefghijklmnopqrstuvwxyz0123456789"
        for _ in range(12):
            candidate = get_random_string(10, alphabet)
            if not BusinessNetworkPost.objects.filter(slug=candidate).exists():
                return candidate
        return get_random_string(14, alphabet)

    def save(self, *args, **kwargs):
        if not self.pk:
            self.id = self.generate_id()
        if not self.slug:
            self.slug = self._generate_hash_slug()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Post {self.id} by {self.author.username}"



class BusinessNetworkPostLike(models.Model):
    id = models.CharField(max_length=20, unique=True, editable=False, primary_key=True)
    post = models.ForeignKey(BusinessNetworkPost, on_delete=models.CASCADE, related_name='post_likes')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='business_network_likes')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['post', 'user']
        indexes = [
            models.Index(fields=["user", "-created_at"], name="bn_like_user_recent_idx"),
            models.Index(fields=["post", "user"], name="bn_like_post_user_idx"),
        ]

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
        indexes = [
            models.Index(fields=["author", "-created_at"], name="bn_comment_author_recent_idx"),
            models.Index(fields=["post", "author", "-created_at"], name="bn_comment_post_author_idx"),
        ]
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
        indexes = [
            models.Index(fields=["follower", "following"], name="bn_follow_follower_idx"),
            models.Index(fields=["following", "follower"], name="bn_follow_following_idx"),
        ]
    
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
    # Creative format: image card / 5s-skippable video (with companion
    # banner) / boosted BN post (plays inline in the shorts reel).
    FORMAT_CHOICES = (
        ('image', 'Image'),
        ('video', 'Video'),
        ('boost', 'Boosted Post'),
    )
    format = models.CharField(max_length=10, choices=FORMAT_CHOICES, default='image')
    # Companion banner shown UNDER the video creative (YouTube-style).
    companion_banner = models.ImageField(
        upload_to='business_network/abn/banners/', null=True, blank=True
    )
    # format='boost': the BN post being promoted into the shorts reel.
    boosted_post = models.ForeignKey(
        BusinessNetworkPost, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='boosts',
    )
    budget = models.DecimalField(max_digits=10, decimal_places=2)
    # Pacing/scheduling: spread spend across days, run only in a window.
    daily_budget = models.DecimalField(
        max_digits=10, decimal_places=2, null=True, blank=True
    )
    start_at = models.DateTimeField(null=True, blank=True)
    end_at = models.DateTimeField(null=True, blank=True)
    # Location targeting: list of city/upazila names (empty = all Bangladesh).
    target_locations = models.JSONField(default=list, blank=True)
    STATUS_CHOCES = (
        ('review', 'In Review'),
        ('active', 'Active'),
        ('pending', 'Pending'),
        ('rejected', 'Rejected'),
        ('stoped', 'Stoped'),
        ('completed', 'Completed'),
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOCES, default='active')
    # Where this ad may show. List of placement keys, e.g.
    # ["bn_feed", "shorts_banner", "gigs_list", "sale_list", "news_list",
    #  "food_list", "web_feed"]. Empty = all placements.
    placements = models.JSONField(default=list, blank=True)
    reject_reason = models.TextField(null=True, blank=True)
    views = models.PositiveIntegerField(default=0)
    clicks = models.PositiveIntegerField(default=0)
    # Money consumed so far (views * CPV) — never exceeds budget.
    spent = models.DecimalField(max_digits=10, decimal_places=2, default=0)
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
        # View cap reached → completed. Guard on estimated_views: a fresh
        # ad has views == estimated_views == 0 and must NOT be stopped.
        if self.estimated_views and self.views >= self.estimated_views:
            self.status = 'completed'
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
        ('share', 'Share'),
    )
    
    recipient = models.ForeignKey(User, on_delete=models.CASCADE, related_name='bn_notifications_received')
    actor = models.ForeignKey(User, on_delete=models.CASCADE, related_name='bn_notifications_created')
    type = models.CharField(max_length=20, choices=NOTIFICATION_TYPES)
    read = models.BooleanField(default=False)
    target_id = models.CharField(max_length=50, null=True, blank=True)  # ID of the target object (post, comment, etc.)
    parent_id = models.CharField(max_length=50, null=True, blank=True)  # ID of parent object (post for comments)
    content = models.TextField(null=True, blank=True)  # Optional content snippet
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = "Business Network Notification"
        verbose_name_plural = "Business Network Notifications"
    
    def __str__(self):
        return f"{self.actor.username} → {self.recipient.username}: {self.type}"

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


class ProfileReport(models.Model):
    """A report against a user's profile (e.g. fake/impersonating accounts)."""
    REPORT_REASONS = [
        ('fake', 'Fake or impersonating account'),
        ('spam', 'Spam or scam'),
        ('harassment', 'Harassment or hate speech'),
        ('inappropriate', 'Inappropriate content'),
        ('other', 'Other'),
    ]
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('reviewed', 'Reviewed'),
        ('resolved', 'Resolved'),
        ('dismissed', 'Dismissed'),
    ]

    reporter = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='profile_reports_made'
    )
    reported_user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='profile_reports_received'
    )
    reason = models.CharField(max_length=20, choices=REPORT_REASONS)
    description = models.TextField(blank=True, null=True)
    status = models.CharField(
        max_length=20, choices=STATUS_CHOICES, default='pending'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['reporter', 'reported_user', 'reason']
        ordering = ['-created_at']
        verbose_name = "Profile Report"
        verbose_name_plural = "Profile Reports"

    def __str__(self):
        return f"{self.reporter_id} reported {self.reported_user_id} ({self.reason})"


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
    website = models.CharField(max_length=255, blank=True, null=True)  # Allow any text
    profile_url = models.CharField(max_length=255, blank=True, null=True)  # Allow any text
    logo = models.ImageField(upload_to=sponsor_logo_path, blank=True, null=True)
    
    # Package information
    package = models.ForeignKey(SponsorshipPackage, on_delete=models.PROTECT, related_name='sponsors')
    start_date = models.DateTimeField(default=timezone.now)
    end_date = models.DateTimeField(blank=True, null=True)
    
    # Views tracking
    views = models.PositiveIntegerField(default=0)

    # Amount actually charged (after any location-targeting discount)
    amount_paid = models.DecimalField(max_digits=10, decimal_places=2, default=0)

    # Status and timestamps
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    is_featured = models.BooleanField(default=False)
    # When True, the lifecycle task charges the owner's wallet shortly before
    # expiry and extends the sponsorship automatically (with email + push
    # follow-ups). When False, the owner gets multi-step renewal reminders.
    auto_renew = models.BooleanField(default=False)
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
            price = self.package.price
            # Discount applies only to tightly-targeted ads (a few divisions);
            # whole-Bangladesh or broadly-targeted ads pay full price. The
            # serializer sets _discount_eligible based on distinct divisions.
            if getattr(self, '_discount_eligible', False):
                price = GoldSponsorSettings.current().discounted(price)

            if self.user.balance < price:
                from django.core.exceptions import ValidationError
                raise ValidationError(f"Insufficient balance. You need ৳{price} but have ৳{self.user.balance}")

            # Deduct money from user's balance
            self.user.balance -= price
            self.user.save()
            self.amount_paid = price

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

    def extend(self, *, charge=True, reason='manual'):
        """Extend the sponsorship by one package period and re-activate it.

        Used by both the manual "Renew now" endpoint/admin action and the
        auto-renew lifecycle task. When ``charge`` is True the package price is
        deducted from the owner's wallet (a comp/admin extension can pass
        ``charge=False``).

        Returns a dict describing the outcome:
          {'ok': True,  'price': D, 'end_date': dt}
          {'ok': False, 'reason': 'insufficient_balance', 'price': D, 'balance': D}
        Never raises for the insufficient-balance case so callers can decide how
        to surface it (push/email follow-up vs. admin message).
        """
        from datetime import timedelta

        if not self.package:
            return {'ok': False, 'reason': 'no_package'}

        price = self.package.price or 0
        if charge and price:
            balance = self.user.balance or 0
            if balance < price:
                return {
                    'ok': False,
                    'reason': 'insufficient_balance',
                    'price': price,
                    'balance': balance,
                }
            self.user.balance = balance - price
            self.user.save(update_fields=['balance'])
            self.amount_paid = (self.amount_paid or 0) + price
            # Best-effort wallet ledger entry (non-fatal if the model rejects it).
            try:
                from base.models import Balance
                Balance.objects.create(
                    user=self.user,
                    transaction_type='gold_sponsor',
                    amount=price,
                    payable_amount=price,
                    completed=True,
                    approved=True,
                )
            except Exception:
                pass

        now = timezone.now()
        base = self.end_date if (self.end_date and self.end_date > now) else now
        self.end_date = base + timedelta(days=30 * self.package.duration_months)
        self.status = 'active'
        self.save(update_fields=['end_date', 'status', 'amount_paid', 'updated_at'])

        # New cycle -> let the multi-step reminders fire again next period.
        try:
            self.reminder_logs.all().delete()
        except Exception:
            pass

        return {'ok': True, 'price': price, 'end_date': self.end_date, 'reason': reason}

    def __str__(self):
        return self.business_name


class GoldSponsorReminderLog(models.Model):
    """One row per follow-up step sent for a sponsor, so the lifecycle task
    never sends the same step twice. Cleared when a sponsor renews so the next
    period starts a fresh reminder sequence."""
    STAGE_CHOICES = (
        ('expiry_7d', 'Expires in 7 days'),
        ('expiry_3d', 'Expires in 3 days'),
        ('expiry_1d', 'Expires tomorrow'),
        ('autorenew_success', 'Auto-renewed'),
        ('autorenew_low', 'Auto-renew needs balance'),
        ('expired_notice', 'Expired notice'),
        ('winback', 'Win-back'),
    )
    sponsor = models.ForeignKey(
        GoldSponsor, on_delete=models.CASCADE, related_name='reminder_logs')
    stage = models.CharField(max_length=40, choices=STAGE_CHOICES)
    channel = models.CharField(max_length=20, default='push')
    sent_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('sponsor', 'stage')
        ordering = ['-sent_at']

    def __str__(self):
        return f"{self.sponsor_id} · {self.stage}"


class GoldSponsorLocation(models.Model):
    """One geographic target for a Gold Sponsor ad.

    A sponsor with NO location rows is shown all over Bangladesh (default). With
    one or more rows it's shown only to users whose division/city/area matches at
    least one row. Within a row, leave a field blank to match any value for it —
    e.g. division="Dhaka" with blank city/area targets the whole Dhaka division.
    """
    sponsor = models.ForeignKey(
        GoldSponsor, on_delete=models.CASCADE, related_name='locations')
    division = models.CharField(
        max_length=128, blank=True, default='',
        help_text='Division / State (e.g. Dhaka). Blank = any division.')
    city = models.CharField(
        max_length=128, blank=True, default='',
        help_text='City / District. Blank = any city.')
    area = models.CharField(
        max_length=128, blank=True, default='',
        help_text='Area / Upazila. Blank = any area.')

    class Meta:
        verbose_name = 'Target location'
        verbose_name_plural = 'Target locations'

    def __str__(self):
        bits = [b for b in (self.division, self.city, self.area) if b]
        return ' › '.join(bits) or 'All Bangladesh'


class GoldSponsorSettings(models.Model):
    """Admin-managed pricing/limits for Gold Sponsor ads (singleton).

    Whole-Bangladesh ads pay the full package price; location-targeted ads get
    `specific_location_discount_percent` off. Edit these without touching the
    frontend — both web and app read them from the pricing-config endpoint.
    """
    specific_location_discount_percent = models.PositiveIntegerField(
        default=70,
        help_text='Discount % applied when a sponsor targets specific locations '
                  '(vs all over Bangladesh).')
    max_custom_locations = models.PositiveIntegerField(
        default=10,
        help_text='Maximum number of custom target locations a sponsor can add.')
    max_discount_divisions = models.PositiveIntegerField(
        default=2,
        help_text='The discount applies only when the targeting covers at most '
                  'this many distinct divisions. More divisions = full price.')
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Gold Sponsor settings'
        verbose_name_plural = 'Gold Sponsor settings'

    def __str__(self):
        return (f'{self.specific_location_discount_percent}% off targeted · '
                f'max {self.max_custom_locations} locations')

    @classmethod
    def current(cls):
        obj = cls.objects.first()
        if obj is None:
            obj = cls.objects.create()
        return obj

    def discounted(self, price):
        from decimal import Decimal, ROUND_HALF_UP
        price = Decimal(str(price))
        pct = Decimal(str(self.specific_location_discount_percent))
        result = price * (Decimal('100') - pct) / Decimal('100')
        return result.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)


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
    link_url = models.CharField(max_length=255, blank=True, null=True)  # Allow any text
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


class ContentMonetizationSettings(models.Model):
    """Admin-tunable global requirements for content monetization (singleton).

    Changing these only affects users who have NOT applied yet — existing
    applications keep the snapshot they were reviewed against.
    """

    required_followers = models.PositiveIntegerField(default=1000)
    required_views = models.PositiveIntegerField(default=20000)
    required_video_posts = models.PositiveIntegerField(default=10)
    required_image_posts = models.PositiveIntegerField(default=10)

    # ── Earnings (revenue-pool model) ──────────────────────────────────────
    # A fixed monthly pool is split among approved creators by their share of
    # engagement points. Fraudulent volume can only dilute the pool, never
    # inflate the total payout. 0 = earnings accrual paused.
    monthly_pool_amount = models.DecimalField(
        max_digits=12, decimal_places=2, default=0,
        help_text="Total BDT distributed among creators each month. 0 pauses earnings.",
    )
    point_view = models.PositiveIntegerField(
        default=1, help_text="Points per valid content view.")
    point_like = models.PositiveIntegerField(
        default=3, help_text="Points per like received.")
    point_comment = models.PositiveIntegerField(
        default=5, help_text="Points per comment received.")
    point_follower = models.PositiveIntegerField(
        default=10, help_text="Points per new follower gained.")
    min_payout = models.DecimalField(
        max_digits=10, decimal_places=2, default=100,
        help_text="Amounts below this roll over to the next month.",
    )
    holdback_days = models.PositiveIntegerField(
        default=7,
        help_text="Review window after month close before earnings clear.",
    )
    viewer_min_account_age_days = models.PositiveIntegerField(
        default=7,
        help_text="Views from accounts younger than this carry no points.",
    )
    viewer_daily_view_cap = models.PositiveIntegerField(
        default=30,
        help_text="Max valid views one viewer can contribute to a creator per day.",
    )

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Content Monetization Settings"
        verbose_name_plural = "Content Monetization Settings"

    def __str__(self):
        return (
            f"{self.required_followers} followers / {self.required_views} views / "
            f"{self.required_video_posts} videos / {self.required_image_posts} photos"
        )

    @classmethod
    def current(cls):
        obj = cls.objects.first()
        return obj if obj is not None else cls.objects.create()


class ContentMonetizationCustomRequirement(models.Model):
    """Per-user override of the monetization bar. Any blank field falls back
    to the global ContentMonetizationSettings value."""

    user = models.OneToOneField(
        User, on_delete=models.CASCADE, related_name="monetization_custom_requirement"
    )
    required_followers = models.PositiveIntegerField(null=True, blank=True)
    required_views = models.PositiveIntegerField(null=True, blank=True)
    required_video_posts = models.PositiveIntegerField(null=True, blank=True)
    required_image_posts = models.PositiveIntegerField(null=True, blank=True)
    note = models.CharField(max_length=255, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Content Monetization Custom Requirement"
        verbose_name_plural = "Content Monetization Custom Requirements"

    def __str__(self):
        return f"Custom bar for {self.user.email or self.user.username}"


class ContentMonetizationApplication(models.Model):
    """A creator's application for content monetization.

    Requirements (followers, views, video posts, photo posts) come from
    ContentMonetizationSettings, optionally overridden per user by
    ContentMonetizationCustomRequirement. Applying requires accepting the
    Terms & Community Guidelines in the app; admins review applications
    from the Django admin.
    """

    STATUS_CHOICES = [
        ("pending", "Pending Review"),
        ("approved", "Approved"),
        ("rejected", "Rejected"),
    ]

    user = models.OneToOneField(
        User, on_delete=models.CASCADE, related_name="monetization_application"
    )
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default="pending")
    # Snapshot of the numbers at the moment of application, for the reviewer.
    followers_at_apply = models.PositiveIntegerField(default=0)
    views_at_apply = models.PositiveIntegerField(default=0)
    video_posts_at_apply = models.PositiveIntegerField(default=0)
    image_posts_at_apply = models.PositiveIntegerField(default=0)
    terms_accepted = models.BooleanField(default=False)
    admin_note = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = "Content Monetization Application"
        verbose_name_plural = "Content Monetization Applications"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user.email or self.user.username} — {self.status}"


class CreatorMonthlyEarning(models.Model):
    """One approved creator's earnings for one calendar month (pool model).

    Points are recomputed by `compute_monetization_earnings` (daily cron +
    once after month close); `amount` is that creator's share of the monthly
    pool. Lifecycle: accruing (current month) → held (fraud review) or
    cleared → paid (credited to AdsyPay by admin) / forfeited (fraud).
    """

    STATUS_CHOICES = [
        ("accruing", "Accruing"),
        ("held", "Held for review"),
        ("cleared", "Cleared"),
        ("paid", "Paid"),
        ("forfeited", "Forfeited"),
    ]

    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="monetization_earnings"
    )
    period = models.CharField(max_length=7)  # "YYYY-MM"
    valid_views = models.PositiveIntegerField(default=0)
    likes = models.PositiveIntegerField(default=0)
    comments = models.PositiveIntegerField(default=0)
    followers_gained = models.PositiveIntegerField(default=0)
    total_points = models.PositiveIntegerField(default=0)
    amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    status = models.CharField(
        max_length=10, choices=STATUS_CHOICES, default="accruing"
    )
    # Phase 2 fraud job writes this; admins review high scores first.
    fraud_score = models.PositiveIntegerField(default=0)
    note = models.CharField(max_length=255, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ["user", "period"]
        ordering = ["-period"]
        verbose_name = "Creator Monthly Earning"
        verbose_name_plural = "Creator Monthly Earnings"

    def __str__(self):
        return (
            f"{self.user.email or self.user.username} {self.period}: "
            f"{self.total_points} pts / {self.amount} ({self.status})"
        )


class PostSeen(models.Model):
    """Persistent per-user post impressions (which feed posts were served).

    Powers the feed's seen-demotion durably: the old cache-only list vanished
    on every cache restart/TTL, letting the same posts pin the top again.
    Written server-side when the feed page is served — no app change needed.
    """

    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="seen_posts"
    )
    post = models.ForeignKey(
        BusinessNetworkPost, on_delete=models.CASCADE, related_name="seen_by"
    )
    times_seen = models.PositiveIntegerField(default=1)
    last_seen_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ["user", "post"]
        indexes = [
            models.Index(
                fields=["user", "-last_seen_at"], name="bn_seen_user_recent_idx"
            ),
        ]

    def __str__(self):
        return f"{self.user_id} saw {self.post_id} x{self.times_seen}"


# ============================================================
# ADS SYSTEM — serving, tracking, viewer rewards, creator share
# ============================================================

class AdsSystemConfig(models.Model):
    """Singleton admin knobs for the whole ads system (panel + AdMob hybrid).

    Rates are per VIEW: panel ads burn `cpv_rate` from the advertiser budget;
    creators earn `creator_share_percent` of what their content generated.
    AdMob impressions have no direct BDT amount, so `admob_view_value`
    approximates their worth for creator attribution.
    """

    # Advertiser side: ৳ per view (200 → ~500 views at 0.40)
    cpv_rate = models.DecimalField(max_digits=6, decimal_places=2, default=0.40)
    # Creator share of ad revenue generated ON their content (percent) —
    # Facebook-style 50/50 split with the platform.
    creator_share_percent = models.PositiveIntegerField(default=50)
    # Approximate BDT value of ONE AdMob impression for creator attribution
    admob_view_value = models.DecimalField(max_digits=6, decimal_places=3, default=0.05)
    # Viewer daily diamond reward: every `views_per_diamond` tracked ad views
    # earn 1 diamond, capped at `max_daily_diamonds` per day.
    viewer_reward_enabled = models.BooleanField(default=True)
    views_per_diamond = models.PositiveIntegerField(default=20)
    max_daily_diamonds = models.PositiveIntegerField(default=5)
    # Same ad shown to the same user at most this many times per day
    daily_frequency_cap = models.PositiveIntegerField(default=4)
    # Interest profile: how many days a category interest stays boosted
    interest_decay_days = models.PositiveIntegerField(default=7)
    # CPV tiering: per-placement ৳/view overrides, e.g.
    # {"shorts_reel": 0.60, "bn_feed": 0.40, "news_list": 0.25}. A placement
    # missing here falls back to the built-in tier, then to cpv_rate.
    cpv_overrides = models.JSONField(default=dict, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    # Built-in tiers: premium full-attention surfaces cost more, list rows
    # less. Admin can override any of these via cpv_overrides.
    _CPV_TIERS = {
        "shorts_reel": "0.60",
        "shorts_fullscreen": "0.60",
        "bn_feed": "0.40",
        "shorts_banner": "0.40",
        "web_feed": "0.40",
        "gigs_list": "0.25",
        "sale_list": "0.25",
        "news_list": "0.25",
        "food_list": "0.25",
        "classified_list": "0.25",
        "web_banner": "0.25",
    }

    def cpv_for(self, placement):
        """৳ per billable view for this placement (Decimal)."""
        from decimal import Decimal
        override = (self.cpv_overrides or {}).get(placement)
        if override is not None:
            try:
                return Decimal(str(override))
            except Exception:
                pass
        tier = self._CPV_TIERS.get(placement)
        if tier is not None:
            return Decimal(tier)
        return Decimal(str(self.cpv_rate))

    class Meta:
        verbose_name = "Ads System Config"

    def __str__(self):
        return "Ads System Config"

    @classmethod
    def get(cls):
        obj = cls.objects.first()
        if obj is None:
            obj = cls.objects.create()
        return obj


class AdEvent(models.Model):
    """One row per ad interaction — the raw data every other ads feature
    (rewards, creator earnings, interest classification, dashboards) is
    computed from. `ad` is null for AdMob events (only source/placement)."""

    SOURCES = (("panel", "Ads Panel"), ("admob", "AdMob"))
    EVENT_TYPES = (
        ("impression", "Impression"),
        ("click", "Click"),
        ("cta_click", "CTA Click"),
    )

    ad = models.ForeignKey(
        AbnAdsPanel, on_delete=models.SET_NULL, null=True, blank=True,
        related_name="events",
    )
    source = models.CharField(max_length=10, choices=SOURCES, default="panel")
    event_type = models.CharField(max_length=15, choices=EVENT_TYPES)
    placement = models.CharField(max_length=30, blank=True, default="")
    platform = models.CharField(max_length=10, blank=True, default="app")
    # Viewer (null when logged out)
    user = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True,
        related_name="ad_events",
    )
    # Owner of the content the ad appeared ON/AFTER (BN post author for feed
    # native + shorts banner + post-swipe shorts ads) — earns the share.
    creator = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True,
        related_name="content_ad_events",
    )
    category = models.ForeignKey(
        AbnAdsPanelCategory, on_delete=models.SET_NULL, null=True, blank=True,
        related_name="ad_events",
    )
    # The specific CONTENT (BN post id) the ad appeared on — powers the
    # Facebook-style "এই কনটেন্টে এত earning" breakdown for creators.
    content_id = models.CharField(max_length=20, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=["user", "-created_at"], name="adevent_user_idx"),
            models.Index(fields=["creator", "-created_at"], name="adevent_creator_idx"),
            models.Index(fields=["ad", "-created_at"], name="adevent_ad_idx"),
            models.Index(fields=["created_at"], name="adevent_created_idx"),
            models.Index(
                fields=["creator", "content_id"], name="adevent_content_idx"
            ),
        ]

    def __str__(self):
        return f"{self.source}:{self.event_type} @{self.placement}"


class UserAdProfile(models.Model):
    """Per-user ad interest weights — {category_id: weight}. Impressions add
    a little, clicks add a lot; weights decay so a burst of interest only
    biases serving for `interest_decay_days`."""

    user = models.OneToOneField(
        User, on_delete=models.CASCADE, related_name="ad_profile"
    )
    category_weights = models.JSONField(default=dict, blank=True)
    # ── Interest Brain (built nightly from real activity, see
    # interest_brain.py) ──
    # {segment: 0-100} — e.g. {"food": 100, "tech": 42.5}
    interest_scores = models.JSONField(default=dict, blank=True)
    # top segments + activity tags — e.g. ["food", "tech", "high_activity"]
    segments = models.JSONField(default=list, blank=True)
    # engagement share on male vs female creators — {"male": 70, "female": 30}
    gender_affinity = models.JSONField(default=dict, blank=True)
    brain_built_at = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"AdProfile {self.user_id}"


class AdViewerDaily(models.Model):
    """Per-user per-day ad view counter → nightly diamond reward."""

    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="ad_viewer_days"
    )
    date = models.DateField()
    views = models.PositiveIntegerField(default=0)
    diamonds_awarded = models.PositiveIntegerField(default=0)
    rewarded = models.BooleanField(default=False)

    class Meta:
        unique_together = ["user", "date"]
        indexes = [
            models.Index(fields=["date", "rewarded"], name="adviewer_date_idx"),
        ]

    def __str__(self):
        return f"{self.user_id} {self.date}: {self.views} views"


class CreatorAdEarning(models.Model):
    """Nightly ledger: what each creator earned from ads on their content.
    Credited to the user's balance by the settlement task (auditable rows)."""

    creator = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="creator_ad_earnings"
    )
    date = models.DateField()
    panel_views = models.PositiveIntegerField(default=0)
    admob_views = models.PositiveIntegerField(default=0)
    amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    credited = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ["creator", "date"]
        ordering = ["-date"]

    def __str__(self):
        return f"{self.creator_id} {self.date}: ৳{self.amount}"
