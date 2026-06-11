import random
import re
import string
import time

# from django.contrib.auth.models import User
import uuid
from datetime import timedelta
from decimal import Decimal

from django.contrib.auth.models import AbstractUser
from django.core.exceptions import ValidationError
from django.db import models
from django.utils import timezone
from django.utils.text import slugify
from tinymce import models as tinymce_models


def generate_unique_id():
    return int(time.time() * 1) + random.randint(0, 999)


# Add this helper function for generating unique slugs


def generate_unique_slug(model_class, field_value, instance=None):
    # Handle Bangla/non-Latin slugification
    slug = slugify(field_value)
    if not slug or len(slug) < len(field_value) / 2:
        slug = re.sub(r'[\'.,:!?()&*+=|\\/\`~{}\[\]<>;"“”‘’"_।॥৳৥৲৶]', "", field_value)
        slug = re.sub(r"\s+", "-", slug)

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


def generate_unique_username(user):
    name_source = f"{user.first_name or ''} {user.last_name or ''}".strip()
    if not name_source:
        name_source = (user.name or "").strip()
    if not name_source and user.email:
        name_source = user.email.split("@", 1)[0]

    base = slugify(name_source).replace("-", "")
    if not base:
        base = re.sub(r"[^A-Za-z0-9]+", "", name_source).lower()
    base = (base or "adsyclub")[:32]

    while True:
        suffix_length = random.randint(2, 4)
        suffix = "".join(random.choices(string.digits, k=suffix_length))
        username = f"{base}{suffix}"
        queryset = User.objects.filter(username__iexact=username)
        if user.pk:
            queryset = queryset.exclude(pk=user.pk)
        if not queryset.exists():
            return username


# Create your models here.


class User(AbstractUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    image = models.ImageField(upload_to="images/", blank=True, null=True)
    otp = models.CharField(max_length=100, blank=True, default="000000")
    name = models.CharField(max_length=100, blank=True, default="")
    about = models.TextField(null=True, blank=True, default="")
    face_link = models.CharField(null=True, blank=True, default="")
    instagram_link = models.CharField(null=True, blank=True, default="")
    gmail_link = models.CharField(null=True, blank=True, default="")
    whatsapp_link = models.CharField(null=True, blank=True, default="")
    is_vendor = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    # null=True so users without a phone (e.g. social-login signups) store NULL
    # instead of "" — multiple NULLs are allowed under a UNIQUE index, but
    # multiple "" rows would collide. Without this, the 2nd phone-less user
    # (social login) fails to save. Existing "" rows are left as-is.
    phone = models.CharField(
        unique=True, max_length=100, default="", blank=True, null=True
    )
    email = models.EmailField(unique=True, default="", null=True)
    date_of_birth = models.DateField(blank=True, null=True)
    age = models.IntegerField(blank=True, null=True)
    gender = models.CharField(max_length=10, blank=True, null=True)
    kyc_pending = models.BooleanField(default=False)
    kyc = models.BooleanField(default=False)
    address = models.CharField(max_length=256, blank=True, default="")
    country = models.CharField(max_length=256, blank=True, default="")
    city = models.CharField(max_length=256, blank=True, default="")
    state = models.CharField(max_length=256, blank=True, default="")
    upazila = models.CharField(max_length=256, blank=True, default="")
    zip = models.CharField(max_length=256, blank=True, default="")
    # Last location the user browsed services/classifieds with. Used as a
    # fallback target for local engagement (area service counts) when the
    # profile address is empty. Updated on classified location-filtered search.
    last_search_state = models.CharField(max_length=256, blank=True, default="")
    last_search_city = models.CharField(max_length=256, blank=True, default="")
    last_search_upazila = models.CharField(max_length=256, blank=True, default="")
    last_search_at = models.DateTimeField(null=True, blank=True)
    balance = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    pending_balance = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    diamond_balance = models.IntegerField(default=0)
    USER_TYPES = [
        ("admin", "Admin"),
        ("user", "User"),
        ("vendor", "Vendor"),
    ]
    user_type = models.CharField(max_length=20, choices=USER_TYPES, default="user")
    refer = models.ForeignKey("self", on_delete=models.SET_NULL, null=True, blank=True)
    refer_count = models.IntegerField(default=0)
    commission_earned = models.DecimalField(
        max_digits=8, decimal_places=2, default=0.00
    )
    commission = models.DecimalField(max_digits=8, decimal_places=2, default=5.00)
    referral_code = models.CharField(max_length=10, unique=True, editable=False)
    nid_number = models.CharField(unique=True, null=True, blank=True, max_length=16)
    profession = models.CharField(max_length=256, blank=True, default="")
    company = models.CharField(max_length=256, blank=True, default="")
    website = models.CharField(max_length=256, blank=True, default="")
    email_public = models.BooleanField(default=False)
    phone_public = models.BooleanField(default=False)
    professional_details_public = models.BooleanField(default=True)
    profession_public = models.BooleanField(default=True)
    company_public = models.BooleanField(default=True)
    website_public = models.BooleanField(default=True)
    facebook_public = models.BooleanField(default=True)
    instagram_public = models.BooleanField(default=True)
    whatsapp_public = models.BooleanField(default=True)
    about_public = models.BooleanField(default=True)
    is_topcontributor = models.BooleanField(default=False)
    #   subscription
    is_pro = models.BooleanField(default=False)
    pro_validity = models.DateTimeField(null=True, blank=True)
    # Pro auto-renew preference (the app's Pro lives on User.is_pro/pro_validity,
    # so the renew preference is stored here too rather than on a Subscription row).
    auto_renew = models.BooleanField(default=False)
    store_name = models.CharField(max_length=40, blank=True, default="")
    store_username = models.CharField(max_length=40, blank=True, default="")
    store_description = models.TextField(null=True, blank=True, default="")
    store_address = models.CharField(max_length=256, blank=True, default="")
    store_logo = models.ImageField(upload_to="images/", blank=True, null=True)
    store_banner = models.ImageField(upload_to="images/", blank=True, null=True)
    product_limit = models.IntegerField(default=10)
    email_notifications = models.BooleanField(default=True)
    # Account suspension. Unlike is_active (which blocks auth entirely), a
    # suspended user can still authenticate so the app can show a "suspended"
    # lock screen — but middleware blocks every service endpoint.
    is_suspended = models.BooleanField(default=False)
    suspension_reason = models.TextField(blank=True, default="")
    suspended_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return self.email

    @staticmethod
    def _capitalize_words(value):
        """First letter of every word uppercased; the rest left untouched.

        Product rule: names always display with leading capitals even when
        the user typed lowercase. Only the first character of each word is
        changed, so spellings like "McDonald" or all-caps brand names are
        not mangled, and Bangla text (caseless) passes through unchanged.
        """
        if not value:
            return value
        return " ".join(
            w[:1].upper() + w[1:] if w else w for w in str(value).split(" ")
        )

    def save(self, *args, **kwargs):
        if not self.username or "@" in self.username:
            self.username = generate_unique_username(self)

        self.first_name = self._capitalize_words((self.first_name or "").strip())
        self.last_name = self._capitalize_words((self.last_name or "").strip())

        # The display `name` always follows the user's own first/last name. This
        # is the single source of truth, so a social-login (Google/Facebook)
        # provider name can never be stored separately or override what the user
        # entered. When first/last are both empty we leave `name` as-is.
        derived_name = (
            f"{(self.first_name or '').strip()} {(self.last_name or '').strip()}".strip()
        )
        if derived_name:
            self.name = derived_name
        elif self.name:
            self.name = self._capitalize_words(self.name.strip())

        if not self.referral_code:
            # Generate a unique referral code
            while True:
                code = "".join(
                    random.choices(string.ascii_uppercase + string.digits, k=10)
                )
                if not User.objects.filter(referral_code=code).exists():
                    self.referral_code = code
                    break
        if self.balance < 0:
            raise ValueError("Balance can't be negative")

        # Check if pro_validity has passed and update is_pro accordingly
        if self.pro_validity and self.is_pro:
            if timezone.now() > self.pro_validity:
                self.is_pro = False

        super(User, self).save(*args, **kwargs)


class Subscription(models.Model):
    user = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, related_name="subscription"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    months = models.IntegerField(default=1)
    total = models.DecimalField(max_digits=8, decimal_places=2, default=149.00)

    def save(self, *args, **kwargs):
        if not self.pk:
            self.user.is_pro = True
            self.user.pro_validity = timezone.now() + timedelta(
                days=30 * int(self.months)
            )
            self.user.balance -= Decimal(self.total)
            self.user.save()
        super(Subscription, self).save(*args, **kwargs)


class NID(models.Model):
    user = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, related_name="nid"
    )
    front = models.ImageField(upload_to="images/", blank=True, null=True)
    back = models.ImageField(upload_to="images/", blank=True, null=True)
    selfie = models.ImageField(upload_to="images/", blank=True, null=True)
    other_document = models.ImageField(upload_to="images/", blank=True, null=True)
    pending = models.BooleanField(default=True)
    completed = models.BooleanField(default=False)
    approved = models.BooleanField(default=False)
    rejected = models.BooleanField(default=False)

    def __str__(self):
        return str(self.id)

    @property
    def review_status(self):
        if self.approved:
            return "approved"
        if self.rejected:
            return "rejected"
        return "pending"

    def clean(self):
        if self.approved and self.rejected:
            raise ValidationError("NID verification cannot be both approved and rejected.")

    def save(self, *args, **kwargs):
        previous = None
        if self.pk:
            previous = type(self).objects.filter(pk=self.pk).values("approved", "rejected").first()

        self.clean()

        if self.approved:
            self.pending = False
            self.completed = True
        elif self.rejected:
            self.pending = False
            self.completed = True
        else:
            self.pending = True
            self.completed = False

        if self.user:
            if self.approved:
                self.user.kyc_pending = False
                self.user.kyc = True
            elif self.rejected:
                self.user.kyc_pending = False
                self.user.kyc = False
            else:
                self.user.kyc_pending = True
                self.user.kyc = False
            self.user.save(update_fields=["kyc_pending", "kyc"])

        super(NID, self).save(*args, **kwargs)

        if self.user and self.user.email:
            if self.approved and not (previous and previous["approved"]):
                try:
                    from .email_service import send_kyc_approved_email
                    send_kyc_approved_email(self.user)
                except Exception as e:
                    print(f"Error sending KYC approved email: {e}")
            elif self.rejected and not (previous and previous["rejected"]):
                try:
                    from .email_service import send_kyc_rejected_email
                    send_kyc_rejected_email(self.user)
                except Exception as e:
                    print(f"Error sending KYC rejected email: {e}")
            elif previous is None and not self.approved and not self.rejected:
                # First-time submission — confirm it's received & under review.
                try:
                    from .email_service import send_kyc_received_email
                    send_kyc_received_email(self.user)
                except Exception as e:
                    print(f"Error sending KYC received email: {e}")
                # Notify the admin that a new KYC needs review.
                try:
                    from .email_service import notify_admin_kyc_submission
                    notify_admin_kyc_submission(self.user)
                except Exception as e:
                    print(f"Error sending KYC admin notification: {e}")


class Logo(models.Model):
    image = models.ImageField(upload_to="images/", blank=True, null=True)

    def __str__(self):
        return "Site Logo"


class EshopLogo(models.Model):
    image = models.ImageField(upload_to="images/", blank=True, null=True)

    def __str__(self):
        return "Eshop Logo"


class AuthenticationBanner(models.Model):
    image = models.ImageField(upload_to="images/", blank=True, null=True)

    def __str__(self):
        return "Site Authentication Banner"


class AdminNotice(models.Model):
    NOTIFICATION_TYPES = (
        ("system", "System Notice"),
        ("order_received", "New Order Received"),
        ("withdraw_successful", "Withdraw Successful"),
        ("mobile_recharge_successful", "Mobile Recharge Successful"),
        ("transfer_sent", "Money Transfer Sent"),
        ("transfer_received", "Money Transfer Received"),
        ("deposit_successful", "Deposit Successful"),
        ("pro_subscribed", "Pro Subscription Activated"),
        ("pro_expiring", "Pro Subscription Expiring"),
        ("gig_posted", "Gig Posted Successfully"),
        ("gig_approved", "Gig Approved by Admin"),
        ("gig_rejected", "Gig Rejected by Admin"),
        ("general", "General Update"),
    )

    title = models.CharField(max_length=256)
    message = models.TextField()
    notification_type = models.CharField(
        max_length=30, choices=NOTIFICATION_TYPES, default="general"
    )
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        help_text="Leave blank for global notices, specify user for personalized notifications",
    )
    amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Amount for financial notifications",
    )
    reference_id = models.CharField(
        max_length=100,
        null=True,
        blank=True,
        help_text="Reference ID (order ID, transaction ID, etc.)",
    )
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        if self.user:
            return f"{self.title} - {self.user.name or self.user.email}"
        return f"{self.title} (Global)"


class ClassifiedCategory(models.Model):
    user = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, related_name="classified_categories"
    )
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=256)
    slug = models.SlugField(max_length=300, unique=True, null=True, blank=True)
    business_type = models.CharField(max_length=256, default="shop")
    image = models.ImageField(upload_to="images/", blank=True, null=True)
    is_featured = models.BooleanField(default=False)
    is_food_zone = models.BooleanField(
        default=False,
        help_text="Check this to include posts from this category in Food Zone section",
    )
    search_keywords = models.TextField(
        blank=True,
        null=True,
        help_text="Comma-separated keywords to help with search functionality",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = generate_unique_slug(ClassifiedCategory, self.title, self)
        super(ClassifiedCategory, self).save(*args, **kwargs)

    def __str__(self):
        return self.title


class ClassifiedCategoryPostMedia(models.Model):
    image = models.ImageField(upload_to="images/", blank=True, null=True)
    video = models.FileField(upload_to="videos/", blank=True, null=True)

    def __str__(self):
        return str(self.id)


class ClassifiedCategoryPost(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name="classified_categories_post",
    )
    category = models.ForeignKey(
        ClassifiedCategory,
        on_delete=models.SET_NULL,
        null=True,
        related_name="classified_categories_post",
    )
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=256)
    slug = models.SlugField(max_length=300, unique=True, null=True, blank=True)
    location = models.TextField(max_length=512)
    price = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    negotiable = models.BooleanField(default=False)
    country = models.CharField(null=True, blank=True, default="")
    state = models.CharField(null=True, blank=True, default="")
    city = models.CharField(null=True, blank=True, default="")
    upazila = models.CharField(null=True, blank=True, default="")
    medias = models.ManyToManyField(ClassifiedCategoryPostMedia, blank=True)
    instructions = models.TextField(blank=True, null=True, default="")
    accepted_terms = models.BooleanField(default=True)
    accepted_privacy = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    active_service = models.BooleanField(default=True)
    views_count = models.PositiveIntegerField(default=0)
    GIG_STATUS = [
        ("pending", "Pending"),
        ("approved", "Approved"),
        ("rejected", "Rejected"),
        ("completed", "Completed"),
    ]
    service_status = models.CharField(
        max_length=20, choices=GIG_STATUS, default="pending"
    )

    def save(self, *args, **kwargs):
        is_new = self._state.adding
        if not self.slug:
            self.slug = generate_unique_slug(ClassifiedCategoryPost, self.title, self)
        super(ClassifiedCategoryPost, self).save(*args, **kwargs)
        # New Amar Sheba post awaiting review -> notify admin with quick actions.
        if is_new and self.service_status == "pending":
            try:
                from base.moderation import notify_admin_pending
                notify_admin_pending(self)
            except Exception:
                pass

    def __str__(self):
        return self.title


class ClassifiedCategoryPostReport(models.Model):
    REASON_CHOICES = [
        ("spam", "Spam or misleading"),
        ("inappropriate", "Inappropriate content"),
        ("harassment", "Harassment or hate speech"),
        ("violence", "Violence or dangerous content"),
        ("fraud", "Fraudulent or scam"),
        ("other", "Other"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    post = models.ForeignKey(
        ClassifiedCategoryPost, on_delete=models.CASCADE, related_name="reports"
    )
    reported_by = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="classified_post_reports"
    )
    reason = models.CharField(max_length=20, choices=REASON_CHOICES)
    details = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    reviewed = models.BooleanField(default=False)
    reviewed_at = models.DateTimeField(null=True, blank=True)
    reviewed_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="reviewed_classified_post_reports",
    )

    class Meta:
        ordering = ["-created_at"]
        unique_together = ["post", "reported_by"]

    def __str__(self):
        return f"Report by {self.reported_by} on {self.post}"


class MicroGigCategory(models.Model):
    user = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, related_name="micro_gigs"
    )
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=256)
    slug = models.SlugField(max_length=300, unique=True, null=True, blank=True)
    image = models.ImageField(upload_to="images/", blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = generate_unique_slug(MicroGigCategory, self.title, self)
        super(MicroGigCategory, self).save(*args, **kwargs)

    def __str__(self):
        return self.title


class TargetCountry(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=256)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title


class TargetDevice(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=256)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title


class TargetNetwork(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=256)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title


class MicroGigPostMedia(models.Model):
    image = models.ImageField(upload_to="images/", blank=True, null=True)
    video = models.FileField(upload_to="videos/", blank=True, null=True)

    def __str__(self):
        return str(self.id)


class MicroGigPost(models.Model):
    user = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, related_name="micro_gig_posts"
    )
    category = models.ForeignKey(
        MicroGigCategory,
        on_delete=models.SET_NULL,
        null=True,
        related_name="micro_gig_posts",
    )
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=256)
    slug = models.SlugField(max_length=300, unique=True, null=True, blank=True)
    price = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    required_quantity = models.IntegerField()
    filled_quantity = models.IntegerField(default=0)
    medias = models.ManyToManyField(
        MicroGigPostMedia, blank=True, related_name="micro_gig_posts"
    )
    instructions = models.TextField(blank=True, null=True, default="")
    target_network = models.ManyToManyField(TargetNetwork, blank=True)
    target_country = models.CharField(blank=True, null=True)
    target_device = models.ManyToManyField(TargetDevice, blank=True)
    total_cost = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    balance = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    accepted_terms = models.BooleanField(default=True)
    accepted_privacy = models.BooleanField(default=True)
    active_gig = models.BooleanField(default=True)
    stop_gig = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    action_link = models.URLField(blank=True, null=True)
    GIG_STATUS = [
        ("pending", "Pending"),
        ("approved", "Approved"),
        ("rejected", "Rejected"),
        ("completed", "Completed"),
    ]
    gig_status = models.CharField(max_length=20, choices=GIG_STATUS, default="pending")
    rejection_reason = models.TextField(blank=True, null=True, help_text="Reason for rejection")
    appeal_count = models.IntegerField(default=0, help_text="Number of times this gig has been appealed")

    def save(self, *args, **kwargs):
        # True only on the very first insert. Each completed task calls
        # gig.save() too, so we use this (not "status is pending") to make sure
        # the admin gets the review email ONCE, when the gig post is created.
        is_new = self._state.adding
        # Remember prior gig_status so we can email on an approve/reject transition.
        previous_gig_status = None
        if self.pk:
            previous_gig_status = (
                type(self).objects.filter(pk=self.pk)
                .values_list("gig_status", flat=True).first()
            )

        if not self.slug:
            self.slug = generate_unique_slug(MicroGigPost, self.title, self)

        # Existing save logic
        if self.stop_gig and not self.gig_status == "completed":
            pending_tasks_exist = MicroGigPostTask.objects.filter(
                gig=self, completed=False, approved=False, rejected=False
            ).exists()

            if pending_tasks_exist:
                raise ValidationError(
                    "Cannot stop this gig because there are pending tasks that need to be reviewed."
                )
            else:
                if self.required_quantity > 0:
                    self.user.balance += self.balance
                    self.user.save()
                    self.balance = 0
                    self.gig_status = "completed"

        if self.filled_quantity >= self.required_quantity:
            self.active_gig = False
            self.gig_status = "completed"

        super(MicroGigPost, self).save(*args, **kwargs)

        # Email the gig owner when their gig is approved or rejected.
        if (
            previous_gig_status
            and previous_gig_status != self.gig_status
            and self.user
            and getattr(self.user, "email", "")
        ):
            try:
                from .email_service import (
                    send_post_approved_email,
                    send_post_rejected_email,
                    SITE_URL,
                )
                link = f"{SITE_URL}/micro-gigs/{self.slug}"
                if self.gig_status == "approved":
                    send_post_approved_email(self.user, self.title, "gig", link)
                elif self.gig_status == "rejected":
                    send_post_rejected_email(self.user, self.title, "gig", "", link)
            except Exception as e:
                print(f"Error sending gig status email: {e}")

        # New gig POST created -> notify admin once (never on per-task saves).
        if is_new and self.gig_status == "pending":
            try:
                from base.moderation import notify_admin_pending
                notify_admin_pending(self)
            except Exception:
                pass

    def __str__(self):
        return self.title

    @property
    def task_submissions(self):
        """Returns all tasks with user information"""
        return (
            self.microgigposttask_set.all()
            .select_related("user")
            .order_by("-created_at")
        )


class ReferBonus(models.Model):
    COMMISSION_TYPE_CHOICES = [
        ("gig_completion", "Gig Completion"),
        ("pro_subscription", "Pro Subscription"),
        ("gold_sponsor", "Gold Sponsor"),
    ]

    user = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, related_name="commission_bonus"
    )
    referred_user = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name="generated_commissions",
        blank=True,
    )
    commission_type = models.CharField(
        max_length=20, choices=COMMISSION_TYPE_CHOICES, default="gig_completion"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    amount = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    commission_rate = models.DecimalField(
        max_digits=5, decimal_places=2, default=5.00
    )  # Percentage rate
    base_amount = models.DecimalField(
        max_digits=8, decimal_places=2, default=0.00
    )  # Original transaction amount
    completed = models.BooleanField(default=False)
    description = models.TextField(blank=True, null=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Referral Commission"
        verbose_name_plural = "Referral Commissions"

    def __str__(self):
        return f"{self.get_commission_type_display()} - ৳{self.amount} ({self.created_at.strftime('%Y-%m-%d')})"

    @classmethod
    def get_commission_rate_for_type(cls, commission_type):
        """Get the commission rate for a specific type"""
        rates = {
            "gig_completion": 5.00,
            "pro_subscription": 20.00,
            "gold_sponsor": 20.00,
        }
        return rates.get(commission_type, 5.00)

    def save(self, *args, **kwargs):
        if not self.pk and not self.completed:
            self.completed = True
            self.user.balance += self.amount
            self.user.commission_earned += self.amount
            self.user.save()

            # Create balance transaction record
            Balance.objects.create(
                user=self.user,
                to_user=self.referred_user,
                amount=self.amount,
                transaction_type="referral_commission",
                completed=True,
                bank_status="completed",
                description=f"{self.get_commission_type_display()} referral commission",
            )
        super(ReferBonus, self).save(*args, **kwargs)


class MicroGigPostTask(models.Model):
    user = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, related_name="micro_gig_worker"
    )
    gig = models.ForeignKey(MicroGigPost, on_delete=models.SET_NULL, null=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)
    completed = models.BooleanField(default=False)
    approved = models.BooleanField(default=False)
    rejected = models.BooleanField(default=False)
    medias = models.ManyToManyField(MicroGigPostMedia, blank=True)
    submit_details = models.TextField(blank=True, null=True, default="")
    reason = models.TextField(blank=True, null=True, default="")
    task_completion_link = models.URLField(blank=True, null=True, default="")
    accepted_terms = models.BooleanField(default=True)
    accepted_condition = models.BooleanField(default=True)

    def __str__(self):
        return str(self.created_at)

    @property
    def is_48_hours_passed(self):
        if not self.created_at:
            return False
        return timezone.now() >= (self.created_at + timedelta(hours=48))

    def auto_approve(self):
        if (
            self.is_48_hours_passed
            and not self.completed
            and not self.approved
            and not self.rejected
        ):
            self.approved = True
            self.save()

    def save(self, *args, **kwargs):
        if (
            self.is_48_hours_passed
            and not self.completed
            and not self.approved
            and not self.rejected
        ):
            self.approved = True
        # Check if task is neither completed, approved, nor rejected
        if not self.completed and not self.approved and not self.rejected:
            self.gig.filled_quantity += 1
            self.gig.balance -= self.gig.price
            self.gig.save()
            self.user.pending_balance += self.gig.price
            self.user.save()
        # Mark as completed if approved
        if self.approved and not self.completed:
            self.completed = True
            self.user.balance += self.gig.price
            self.user.pending_balance -= self.gig.price
            self.user.save()
            if self.user.refer:
                ReferBonus.objects.create(
                    user=self.user.refer,
                    amount=(self.gig.price * self.user.refer.commission) / 100,
                )
            # add balance

        # Reduce filled quantity and mark as completed if rejected
        if self.rejected and not self.completed:
            self.gig.filled_quantity -= 1
            self.gig.balance += self.gig.price
            self.gig.save()
            self.completed = True
            self.user.pending_balance -= self.gig.price
            self.user.save()

        # Call the original save method
        super(MicroGigPostTask, self).save(*args, **kwargs)


class Balance(models.Model):
    user = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, related_name="user_balance"
    )
    to_user = models.ForeignKey(
        User, on_delete=models.SET_NULL, blank=True, null=True, related_name="to_user"
    )
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    transaction_number = models.CharField(max_length=20, unique=True, blank=True, null=True, db_index=True)
    PAYMENT_STATUS = [  # delete this, use completed, approved, rejected booleans
        ("pending", "Pending"),
        ("rejected", "Rejected"),
        ("completed", "Completed"),
    ]
    transaction_type = models.CharField(
        max_length=20, default="", blank=True, null=True
    )
    bank_status = models.CharField(choices=PAYMENT_STATUS, default="pending")
    payment_method = models.CharField(default="", blank=True, null=True)
    payment_confirmed_at = models.CharField(default="", blank=True, null=True)
    amount = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    payable_amount = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    received_amount = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    merchant_invoice_no = models.CharField(default="", blank=True, null=True)
    shurjopay_order_id = models.CharField(default="", blank=True, null=True)
    card_number = models.CharField(default="", blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    completed = models.BooleanField(default=False)
    approved = models.BooleanField(default=False)
    rejected = models.BooleanField(default=False)
    description = models.TextField(blank=True, null=True, default="")

    class Meta:
        ordering = ["-updated_at"]

    def __str__(self):
        return f"{self.user}'s Service: {self.payable_amount}"

    def save(self, *args, **kwargs):
        # Generate transaction number if not exists
        if not self.transaction_number:
            import random
            import string
            from datetime import datetime
            
            # Format: TXN + YYYYMMDD + 6 random digits
            # Example: TXN20251029123456
            date_str = datetime.now().strftime('%Y%m%d')
            random_digits = ''.join(random.choices(string.digits, k=6))
            self.transaction_number = f"TXN{date_str}{random_digits}"
            
            # Ensure uniqueness
            while Balance.objects.filter(transaction_number=self.transaction_number).exists():
                random_digits = ''.join(random.choices(string.digits, k=6))
                self.transaction_number = f"TXN{date_str}{random_digits}"
        
        # Normalize transaction_type to lowercase for consistency
        self.transaction_type = (self.transaction_type or "").lower()
        # Handle transfer
        if self.transaction_type == "transfer" and self.to_user and not self.completed:
            self.user.balance -= Decimal(self.payable_amount)
            self.to_user.balance += Decimal(self.payable_amount)
            self.user.save()
            self.to_user.save()
            self.completed = True
            self.approved = True
            self.bank_status = "completed"  # Mark as completed for instant transfer

            # Create notifications for both sender and receiver
            try:
                from .views import (
                    create_transfer_received_notification,
                    create_transfer_sent_notification,
                )

                # Notification for sender
                create_transfer_sent_notification(
                    user=self.user,
                    amount=self.payable_amount,
                    recipient_name=f"{self.to_user.first_name} {self.to_user.last_name}".strip()
                    or self.to_user.name,
                    transaction_id=str(self.id),
                )

                # Notification for receiver
                create_transfer_received_notification(
                    user=self.to_user,
                    amount=self.payable_amount,
                    sender_name=f"{self.user.first_name} {self.user.last_name}".strip()
                    or self.user.name,
                    transaction_id=str(self.id),
                )
            except Exception as e:
                print(f"Error creating transfer notifications: {str(e)}")

            # Send email notifications for transfer
            try:
                from .email_service import send_transfer_sent_email, send_transfer_received_email
                if self.user.email:
                    send_transfer_sent_email(self.user, self.to_user, self.payable_amount, str(self.id))
                if self.to_user.email:
                    send_transfer_received_email(self.to_user, self.user, self.payable_amount, str(self.id))
            except Exception as e:
                print(f"Error sending transfer emails: {str(e)}")

        if (
            self.transaction_type == "withdraw"
            and not self.completed
            and not self.approved
        ):
            self.user.balance -= self.payable_amount
            self.user.save()

            # Send withdrawal request email to user + admin
            try:
                from .email_service import send_withdraw_email, notify_admin_withdrawal_request
                if self.user.email:
                    send_withdraw_email(self.user, self.payable_amount, str(self.id), getattr(self, 'payment_method', ''), getattr(self, 'card_number', ''))
                notify_admin_withdrawal_request(self.user, self.payable_amount, getattr(self, 'payment_method', ''), getattr(self, 'card_number', ''))
            except Exception as e:
                print(f"Error sending withdraw emails: {str(e)}")
        if self.transaction_type == "withdraw" and self.approved:
            self.completed = True
            self.approved = True
            self.user.save()

            # Create notification for successful withdrawal approval
            try:
                from .views import create_withdraw_notification

                create_withdraw_notification(
                    user=self.user,
                    amount=self.payable_amount,
                    transaction_id=str(self.id),
                )
            except Exception as e:
                print(f"Error creating withdraw notification: {str(e)}")

            # Send withdrawal approved email
            try:
                from .email_service import send_withdraw_approved_email
                if self.user.email:
                    send_withdraw_approved_email(self.user, self.payable_amount, str(self.id))
            except Exception as e:
                print(f"Error sending withdraw approved email: {str(e)}")
        if self.transaction_type == "withdraw" and self.rejected and not self.completed:
            self.completed = True
            self.user.balance += self.amount
            self.user.save()

            # Notify the user their withdrawal was declined + refunded
            try:
                from .email_service import send_withdraw_rejected_email
                if self.user and self.user.email:
                    send_withdraw_rejected_email(
                        self.user, self.payable_amount, str(self.id),
                        getattr(self, "rejection_reason", "") or "",
                    )
            except Exception as e:
                print(f"Error sending withdraw rejected email: {e}")
        if self.transaction_type == "deposit":
            self.user.balance += self.payable_amount
            self.completed = True
            self.approved = True
            self.bank_status = "completed"  # Mark as completed for instant deposit
            self.user.save()

            # Create notification for successful deposit
            try:
                from .views import create_deposit_notification

                create_deposit_notification(
                    user=self.user,
                    amount=self.payable_amount,
                    transaction_id=str(self.id),
                )
            except Exception as e:
                print(f"Error creating deposit notification: {str(e)}")

            # Send deposit email
            try:
                from .email_service import send_deposit_email
                if self.user.email:
                    send_deposit_email(self.user, self.payable_amount, str(self.id), getattr(self, 'payment_method', ''))
            except Exception as e:
                print(f"Error sending deposit email: {str(e)}")

        if self.approved and not self.completed:
            self.completed = True

        # Call the original save method
        super(Balance, self).save(*args, **kwargs)


class PendingTask(models.Model):
    user = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, related_name="pending_tasks"
    )
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=256)
    price = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title


class Faq(models.Model):
    label = models.CharField(max_length=256)
    content = tinymce_models.HTMLField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.label


class ProductCategory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=256)
    image = models.ImageField(upload_to="images/", blank=True, null=True)
    badge = models.CharField(max_length=255, blank=True, null=True)
    badge_color = models.CharField(max_length=255, blank=True, null=True)
    special_offer = models.BooleanField(default=False)
    hot_arrival = models.BooleanField(default=False)
    slug = models.SlugField(max_length=300, unique=True, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = generate_unique_slug(ProductCategory, self.name, self)
        super(ProductCategory, self).save(*args, **kwargs)

    def __str__(self):
        return self.name


class ProductMedia(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    image = models.ImageField(upload_to="images/", blank=True, null=True)

    def __str__(self):
        return str(self.id)


class ProductBenefit(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=100)
    slug = models.SlugField(max_length=150, unique=True, null=True, blank=True)
    description = models.TextField()
    icon = models.CharField(max_length=50)

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = generate_unique_slug(ProductBenefit, self.title, self)
        super(ProductBenefit, self).save(*args, **kwargs)

    def __str__(self):
        return self.title


class ProductFAQ(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    label = models.CharField(max_length=255)
    slug = models.SlugField(max_length=300, unique=True, null=True, blank=True)
    content = models.TextField()
    icon = models.CharField(max_length=50, blank=True, null=True)

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = generate_unique_slug(ProductFAQ, self.label, self)
        super(ProductFAQ, self).save(*args, **kwargs)

    def __str__(self):
        return self.label


class ProductTrustBadge(models.Model):
    id = models.CharField(max_length=50, primary_key=True)
    text = models.CharField(max_length=100)
    slug = models.SlugField(max_length=150, unique=True, null=True, blank=True)
    icon = models.CharField(max_length=50)
    enabled = models.BooleanField(default=True)
    description = models.TextField(blank=True, null=True)

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = generate_unique_slug(ProductTrustBadge, self.text, self)
        super(ProductTrustBadge, self).save(*args, **kwargs)

    def __str__(self):
        return self.text


class Product(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, related_name="products"
    )
    name = models.CharField(max_length=256)
    slug = models.SlugField(max_length=300, unique=True, null=True, blank=True)
    keywords = models.TextField(
        blank=True,
        null=True,
        help_text="Comma-separated keywords to help customers find your product",
    )
    image = models.ManyToManyField(ProductMedia, blank=True)
    description = models.TextField(blank=True, null=True)
    short_description = models.TextField(blank=True, null=True)
    delivery_information = models.TextField(blank=True, null=True)
    is_free_delivery = models.BooleanField(default=False)
    delivery_fee_free = models.DecimalField(
        max_digits=8, decimal_places=2, default=0.00
    )
    delivery_fee_inside_dhaka = models.DecimalField(
        max_digits=8, decimal_places=2, default=0.00
    )
    delivery_fee_outside_dhaka = models.DecimalField(
        max_digits=8, decimal_places=2, default=0.00
    )
    category = models.ManyToManyField(
        ProductCategory, blank=True, related_name="products"
    )
    regular_price = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    sale_price = models.DecimalField(
        max_digits=8, decimal_places=2, default=0.00, blank=True, null=True
    )
    quantity = models.IntegerField(default=0)
    is_featured = models.BooleanField(default=False)
    weight = models.DecimalField(
        max_digits=8, decimal_places=2, default=0.00, blank=True, null=True
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_advanced = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    is_science = models.BooleanField(default=False)
    is_commerce = models.BooleanField(default=False)
    is_humanities = models.BooleanField(default=False)  # New marketing fields
    benefits = models.ManyToManyField(
        ProductBenefit, blank=True, related_name="products"
    )
    faqs = models.ManyToManyField(ProductFAQ, blank=True, related_name="products")
    trust_badges = models.ManyToManyField(
        ProductTrustBadge, blank=True, related_name="products"
    )
    # Educational batch relationship
    batches = models.ManyToManyField(
        "elearning.Batch",
        blank=True,
        related_name="products",
        help_text="Select batches where this product should be displayed",
    )

    # Educational division relationship
    divisions = models.ManyToManyField(
        "elearning.Division",
        blank=True,
        related_name="products",
        help_text="Select divisions where this product should be displayed",
    )

    # Marketing section titles
    benefits_title = models.CharField(max_length=200, blank=True, null=True)
    benefits_cta = models.CharField(max_length=200, blank=True, null=True)
    faqs_title = models.CharField(max_length=200, blank=True, null=True)
    faqs_subtitle = models.CharField(max_length=200, blank=True, null=True)

    # Call to action section
    cta_title = models.CharField(max_length=200, blank=True, null=True)
    cta_subtitle = models.CharField(max_length=200, blank=True, null=True)
    cta_button_text = models.CharField(max_length=50, blank=True, null=True)
    cta_button_subtext = models.CharField(max_length=100, blank=True, null=True)

    # Badge highlights
    cta_badge1 = models.CharField(max_length=50, blank=True, null=True)
    cta_badge2 = models.CharField(max_length=50, blank=True, null=True)
    cta_badge3 = models.CharField(max_length=50, blank=True, null=True)
    views = models.IntegerField(default=0)

    def save(self, *args, **kwargs):
        is_new = self._state.adding
        if not self.slug:
            self.slug = generate_unique_slug(Product, self.name, self)
        super(Product, self).save(*args, **kwargs)
        # New eShop product added -> notify admin (informational).
        if is_new:
            try:
                from django.utils import timezone
                from base.moderation import notify_admin_info
                owner = self.owner
                oname = "—"
                if owner is not None:
                    oname = (getattr(owner, "name", "") or getattr(owner, "first_name", "")
                             or getattr(owner, "email", "") or "—")
                notify_admin_info(
                    subject="নতুন eShop প্রোডাক্ট যোগ হয়েছে 🛍️",
                    label="eShop product",
                    intro="একটি নতুন প্রোডাক্ট eShop-এ যোগ করা হয়েছে।",
                    rows=[
                        ("Owner", oname),
                        ("Product", self.name),
                        ("Price", f"৳{self.sale_price or self.regular_price}"),
                        ("Added", timezone.now().strftime("%b %d, %Y %I:%M %p")),
                    ],
                    admin_path=f"/admin/base/product/{self.pk}/change/",
                    text_summary=f"New eShop product: {self.name}",
                )
            except Exception:
                pass

    def __str__(self):
        return self.name

    @property
    def order_count(self):
        """Returns the number of times this product has been ordered"""
        # Count all order items for this product
        order_items = OrderItem.objects.filter(product=self)
        return order_items.count()

    @property
    def total_items_ordered(self):
        """Returns the total quantity of this product that has been ordered"""
        from django.db.models import Sum

        # Sum all quantities for this product in order items
        result = OrderItem.objects.filter(product=self).aggregate(Sum("quantity"))
        return result["quantity__sum"] or 0


class OrderItem(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey(
        "Order", on_delete=models.CASCADE, related_name="items"
    )  # Added this field
    product = models.ForeignKey(Product, on_delete=models.SET_NULL, null=True)
    quantity = models.IntegerField(default=0)
    price = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.order.user}'s Order: {self.product.name if self.product else 'Unknown Product'}"


class Order(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order_number = models.CharField(max_length=10, unique=True, editable=False)
    user = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, related_name="orders"
    )
    name = models.CharField(max_length=256, blank=True, default="")
    email = models.EmailField(default="", blank=True, null=True)
    address = models.CharField(max_length=256, blank=True, default="")
    phone = models.CharField(max_length=256, blank=True, default="")
    total = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    delivery_fee = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    ORDER_STATUS_CHOICES = [
        ("pending", "Pending"),
        ("processing", "Processing"),
        ("shipped", "Shipped"),
        ("delivered", "Delivered"),
        ("cancelled", "Cancelled"),
    ]
    order_status = models.CharField(
        max_length=256, choices=ORDER_STATUS_CHOICES, default="pending"
    )
    PAYMENT_METHOD_CHOICES = [
        ("balance", "Account Balance"),
        ("cash_on_delivery", "Cash on Delivery"),
    ]
    payment_method = models.CharField(
        max_length=256,
        blank=True,
        choices=PAYMENT_METHOD_CHOICES,
        default="cash_on_delivery",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def generate_order_number(self):
        """Generate a unique 10-digit order number based on current time"""
        import random
        from datetime import datetime

        # Format: YYMMDDHHmm (Year, Month, Day, Hour, Minute)
        now = datetime.now()
        base_number = now.strftime("%y%m%d%H%M")

        # Check if this number already exists and add random digits if needed
        if Order.objects.filter(order_number=base_number).exists():
            # Add a random number (0-999) to make it unique
            random_suffix = f"{random.randint(0, 999):03d}"
            # Take first 7 digits of base_number and add the 3 random digits
            return base_number[:7] + random_suffix

        return base_number

    def save(self, *args, **kwargs):
        # Generate order_number for new orders
        if not self.pk or not self.order_number:
            self.order_number = self.generate_order_number()
        super(Order, self).save(*args, **kwargs)

    def __str__(self):
        return f"#{self.order_number} - {self.user}'s Order: {self.total}"


class BannerImage(models.Model):
    LINK_TYPE_CHOICES = [
        ("internal", "Internal app/web page"),
        ("external", "External browser link"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    image = models.ImageField(upload_to="banner_images/")
    title = models.CharField(max_length=255, blank=True, null=True)
    link = models.CharField(
        max_length=500,
        blank=True,
        null=True,
        help_text="Use a full URL or app path. Internal links open inside the app.",
    )
    link_type = models.CharField(
        max_length=10,
        choices=LINK_TYPE_CHOICES,
        default="internal",
        help_text="Internal opens supported AdsyClub URLs inside the app. External opens in browser.",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title or f"Banner {self.id}"


class ShopBannerImage(models.Model):
    LINK_TYPE_CHOICES = BannerImage.LINK_TYPE_CHOICES

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    image = models.ImageField(upload_to="shop_banner_images/")
    title = models.CharField(max_length=255, blank=True, null=True)
    link = models.CharField(
        max_length=500,
        blank=True,
        null=True,
        help_text="Use a full URL or app path. Internal links open inside the app.",
    )
    link_type = models.CharField(
        max_length=10,
        choices=LINK_TYPE_CHOICES,
        default="internal",
        help_text="Internal opens supported AdsyClub URLs inside the app. External opens in browser.",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title or f"Shop Banner {self.id}"


class EshopBanner(models.Model):
    DEVICE_CHOICES = [
        ("all", "All Devices"),
        ("mobile", "Mobile Only"),
        ("desktop", "Desktop Only"),
    ]
    LINK_TYPE_CHOICES = BannerImage.LINK_TYPE_CHOICES

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    image = models.ImageField(upload_to="eshop_banner/")
    mobile_image = models.ImageField(
        upload_to="eshop_banner/mobile/",
        blank=True,
        null=True,
        help_text="Optimized image for mobile devices",
    )
    title = models.CharField(max_length=255, blank=True, null=True)
    link = models.CharField(
        max_length=500,
        blank=True,
        null=True,
        help_text="Use a full URL or app path. Internal links open inside the app.",
    )
    link_type = models.CharField(
        max_length=10,
        choices=LINK_TYPE_CHOICES,
        default="internal",
        help_text="Internal opens supported AdsyClub URLs inside the app. External opens in browser.",
    )
    device_type = models.CharField(
        max_length=10,
        choices=DEVICE_CHOICES,
        default="all",
        help_text="Target device type for this banner",
    )
    is_active = models.BooleanField(
        default=True, help_text="Whether this banner should be displayed"
    )
    order = models.PositiveIntegerField(
        default=0, help_text="Order of display (lower numbers appear first)"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["order", "-created_at"]

    def __str__(self):
        return f"{self.title or 'Banner'} - {self.get_device_type_display()}"

    def get_image_for_device(self, is_mobile=False):
        """Get the appropriate image based on device type"""
        if is_mobile and self.mobile_image:
            return self.mobile_image
        return self.image


class BNLogo(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    image = models.ImageField(upload_to="bn_logo/")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"BN Logo {self.id}"


class DiamondPackages(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    price = models.DecimalField(max_digits=8, decimal_places=2)
    diamonds = models.IntegerField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Diamonds: {self.diamonds} - Price: {self.price}"


class ProductSlotPackage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    slots = models.IntegerField(help_text="Number of product slots in this package")
    price = models.DecimalField(max_digits=8, decimal_places=2)
    original_price = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Original price before discount",
    )
    is_featured = models.BooleanField(
        default=False, help_text="Highlight this package as best value"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["slots"]

    def __str__(self):
        return f"{self.slots} Slots - ৳{self.price}"

    @property
    def discount_percentage(self):
        """Calculate discount percentage if original price is set"""
        if self.original_price and self.original_price > self.price:
            return int(((self.original_price - self.price) / self.original_price) * 100)
        return 0


class DiamondTransaction(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="diamond_transactions"
    )
    to_user = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        blank=True,
        null=True,
        related_name="received_diamonds",
    )

    TRANSACTION_TYPE_CHOICES = [
        ("purchase", "Purchase"),
        ("gift", "Gift"),
        ("bonus", "Bonus"),
        ("refund", "Refund"),
        ("admin", "Admin Adjustment"),
    ]
    transaction_type = models.CharField(max_length=20, choices=TRANSACTION_TYPE_CHOICES)

    amount = models.IntegerField()  # Number of diamonds
    cost = models.DecimalField(
        max_digits=8, decimal_places=2, default=0.00
    )  # Cost in BDT

    completed = models.BooleanField(default=False)
    approved = models.BooleanField(default=False)
    rejected = models.BooleanField(default=False)

    # For gifts to specific posts
    post_id = models.CharField(max_length=100, blank=True, null=True)
    payment_method = models.CharField(max_length=50, blank=True, null=True)
    description = models.TextField(blank=True, null=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user}'s Diamond {self.transaction_type}: {self.amount}"

    def save(self, *args, **kwargs):
        # Diamond purchase from balance
        if self.transaction_type == "purchase" and not self.completed:
            if self.user.balance >= self.cost:
                self.user.balance -= self.cost
                self.user.diamond_balance += self.amount
                self.completed = True
                self.approved = True
                self.user.save()
            else:
                raise ValidationError("Insufficient balance for diamond purchase")

        # Gift diamonds to another user
        if self.transaction_type == "gift" and self.to_user and not self.completed:
            if self.user.diamond_balance >= self.amount:
                self.user.diamond_balance -= self.amount
                self.to_user.diamond_balance += self.amount
                self.completed = True
                self.approved = True
                self.user.save()
                self.to_user.save()
            else:
                raise ValidationError("Insufficient diamond balance for gifting")

        # Admin adjustment
        if self.transaction_type == "admin" and not self.completed:
            self.user.diamond_balance += self.amount  # Can be positive or negative
            self.completed = True
            self.approved = True
            self.user.save()

        # Bonus diamonds
        if self.transaction_type == "bonus" and not self.completed:
            self.user.diamond_balance += self.amount
            self.completed = True
            self.approved = True
            self.user.save()

        # Mark as completed if approved
        if self.approved and not self.completed:
            self.completed = True

        super(DiamondTransaction, self).save(*args, **kwargs)


class NewsLogo(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    image = models.ImageField(upload_to="news-logo/")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"BN Logo {self.id}"


class AndroidAppVersion(models.Model):
    version_name = models.CharField(
        max_length=50, help_text="Version name (e.g., 1.0.0)"
    )
    version_code = models.PositiveIntegerField(
        help_text="Version code (integer, e.g., 100)"
    )
    download_url = models.URLField(max_length=500, help_text="URL to download the APK")
    release_notes = models.TextField(blank=True, help_text="What's new in this version")
    is_active = models.BooleanField(
        default=True, help_text="Is this the currently active version"
    )
    min_android_version = models.CharField(
        max_length=20, default="5.0", help_text="Minimum Android version required"
    )
    file_size_mb = models.DecimalField(
        max_digits=6,
        decimal_places=2,
        help_text="APK file size in MB",
        null=True,
        blank=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Android App Version"
        verbose_name_plural = "Android App Versions"
        ordering = ["-version_code"]

    def __str__(self):
        return f"v{self.version_name} (code: {self.version_code})"

    def save(self, *args, **kwargs):
        # If this version is being set as active, deactivate all other versions
        if self.is_active:
            AndroidAppVersion.objects.exclude(pk=self.pk).update(is_active=False)
        super().save(*args, **kwargs)


class AILink(models.Model):
    """
    Model to store AI configuration for AdsyAI Bot.
    Supports OpenAI API integration for business finder functionality.
    """
    AI_PROVIDER_CHOICES = [
        ('openai', 'OpenAI'),
        ('cloudflare', 'Cloudflare Worker'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, default='AdsyAI', help_text='Name for this AI configuration')
    provider = models.CharField(max_length=20, choices=AI_PROVIDER_CHOICES, default='openai', help_text='AI provider to use')
    api_key = models.CharField(max_length=255, blank=True, null=True, help_text='OpenAI API key (starts with sk-)')
    link = models.URLField(blank=True, null=True, help_text='Cloudflare worker URL (only for cloudflare provider)')
    model = models.CharField(max_length=50, default='gpt-3.5-turbo', help_text='OpenAI model to use (e.g., gpt-3.5-turbo, gpt-4)')
    is_active = models.BooleanField(default=True, help_text='Whether this AI configuration is active')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'AI Link'
        verbose_name_plural = 'AI Links'
    
    def __str__(self):
        return f"{self.name} ({self.provider})"


class CountryVersion(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    code = models.CharField(max_length=50, unique=True)
    flag = models.CharField(max_length=50, blank=True, null=True)
    currency = models.CharField(max_length=10, blank=True, null=True)
    timezone = models.CharField(max_length=50, blank=True, null=True)

    def __str__(self):
        return self.name


class SearchHistory(models.Model):
    """Model to store user search history for products"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='search_history', null=True, blank=True)
    query = models.CharField(max_length=255)
    search_type = models.CharField(max_length=50, default='product')  # product, classified, gig, etc.
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Search History'
        verbose_name_plural = 'Search Histories'
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['query']),
        ]

    def __str__(self):
        user_info = self.user.username if self.user else 'Anonymous'
        return f"{user_info} searched: {self.query}"


class FCMToken(models.Model):
    """Model to store FCM tokens for push notifications.

    `user` is nullable: a device that installed the app but hasn't registered
    yet stores a GUEST token (user=None) so we can send registration-conversion
    pushes. When that device logs in, the token is claimed for the user.
    """
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='fcm_tokens',
        null=True, blank=True,
    )
    token = models.TextField(unique=True)
    device_type = models.CharField(max_length=20, default='android')
    voip_token = models.TextField(blank=True, default='')
    voip_environment = models.CharField(max_length=20, blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)
    # Guest-conversion campaign bookkeeping (only used while user is None).
    last_promo_at = models.DateTimeField(null=True, blank=True)
    promo_count = models.PositiveIntegerField(default=0)

    class Meta:
        db_table = 'fcm_tokens'
        ordering = ['-updated_at']
        indexes = [
            models.Index(fields=['user', 'is_active']),
            models.Index(fields=['token']),
            models.Index(fields=['user', 'is_active', 'last_promo_at'],
                         name='fcm_guest_promo_idx'),
        ]

    def __str__(self):
        who = self.user.email if self.user else 'guest'
        return f'{who} - {self.device_type}'


class AdminEmailRecipient(models.Model):
    """Extra admin-notification recipients (managers, assistants, ...).

    Every admin notification email (new user, recharge, moderation/approval
    requests, etc.) goes to the primary EmailSettings.admin_email PLUS all
    active rows here. Add/remove rows from Django admin at any time.
    """
    email = models.EmailField(unique=True)
    label = models.CharField(
        max_length=100, blank=True, default='',
        help_text='Who this is, e.g. "Manager", "Assistant Manager"',
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['email']
        verbose_name = 'Admin Email Recipient'
        verbose_name_plural = 'Admin Email Recipients'

    def __str__(self):
        return f"{self.email} ({self.label})" if self.label else self.email


class EmailSettings(models.Model):
    """Store email configuration settings"""
    email_host = models.CharField(max_length=255, default='smtp.gmail.com')
    email_port = models.IntegerField(default=587)
    email_use_tls = models.BooleanField(default=True)
    email_host_user = models.EmailField(blank=True, default='')
    email_host_password = models.CharField(max_length=255, blank=True, default='')
    from_email = models.EmailField(blank=True, default='')
    admin_email = models.EmailField(blank=True, default='')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = 'Email Settings'
        verbose_name_plural = 'Email Settings'
        ordering = ['-updated_at']

    def __str__(self):
        return f'Email Settings - {self.email_host}'


class UserNotification(models.Model):
    """A saved push notification, shown in the app's AdsyConnect "Updates" tab.

    Created whenever a push notification is sent so users can find it later.
    `deep_link` (e.g. "/business-network/posts/123" or "/eshop") drives the
    in-app "Visit" button — only notifications that have a deep_link show the
    button; plain announcements don't.
    """
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="app_notifications",
        null=True,
        blank=True,
        help_text="Recipient. Null = broadcast/announcement.",
    )
    title = models.CharField(max_length=255)
    body = models.TextField(blank=True, default="")
    image = models.URLField(max_length=500, blank=True, default="")
    deep_link = models.CharField(
        max_length=500,
        blank=True,
        default="",
        help_text='In-app path to open, e.g. "/business-network/posts/123" or '
        '"/eshop". Leave blank for no "Visit" button.',
    )
    notification_type = models.CharField(
        max_length=50, blank=True, default="general"
    )
    data = models.JSONField(default=dict, blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "user_notifications"
        verbose_name = "User Notification"
        verbose_name_plural = "User Notifications"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user", "is_read"]),
            models.Index(fields=["-created_at"]),
        ]

    def __str__(self):
        who = self.user.email if self.user else "broadcast"
        return f"{who}: {self.title}"


class NotificationRead(models.Model):
    """Per-user read receipt for a UserNotification.

    Broadcast notifications (UserNotification.user is null) are a single row
    shared by everyone, so their row-level `is_read` flag can't track who has
    read them. This table records, per user, which notifications they've read —
    so a broadcast stays "seen" after a reload.
    """
    notification = models.ForeignKey(
        UserNotification, on_delete=models.CASCADE, related_name="read_receipts"
    )
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="notification_reads"
    )
    read_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("notification", "user")
        indexes = [models.Index(fields=["user", "notification"])]


class EmailTemplatePreview(models.Model):
    """Placeholder model that gives the email-template preview tool an entry in
    the admin sidebar. It stores no data — the admin page renders the real email
    HTML live (see base/email_preview.py)."""

    class Meta:
        verbose_name = "Email template"
        verbose_name_plural = "Email templates (preview)"


class ProPricing(models.Model):
    """Single source of truth for Pro subscription pricing (admin-managed).

    `regular_price` is the normal monthly price; while `discount_active` is on,
    customers are shown/charged `discount_price`. Edit these from the admin to
    change pricing without an app update."""
    regular_price = models.DecimalField(
        max_digits=8, decimal_places=2, default=Decimal('299'),
        help_text='Normal monthly price (shown struck-through during a discount).')
    discount_price = models.DecimalField(
        max_digits=8, decimal_places=2, default=Decimal('149'),
        help_text='Discounted monthly price charged while the discount is active.')
    discount_active = models.BooleanField(default=True)
    discount_label = models.CharField(
        max_length=120, blank=True, default='Limited-time offer')
    yearly_discount = models.DecimalField(
        max_digits=8, decimal_places=2, default=Decimal('289'),
        help_text='Flat amount saved when buying 12 months at once.')
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Pro pricing'
        verbose_name_plural = 'Pro pricing'

    @property
    def effective_monthly_price(self):
        return self.discount_price if self.discount_active else self.regular_price

    @classmethod
    def current(cls):
        obj = cls.objects.first()
        if obj is None:
            obj = cls.objects.create()
        return obj

    def __str__(self):
        return f"Pro: regular {self.regular_price}, now {self.effective_monthly_price}"
