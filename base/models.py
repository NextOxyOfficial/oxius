from django.db import models
# from django.contrib.auth.models import User
import uuid
from django.contrib.auth.models import AbstractUser
from django.utils.text import slugify
from django.dispatch import receiver
from django.utils.translation import gettext_lazy as _
from django.db.models.signals import post_save, pre_save
from decimal import Decimal

from tinymce import models as tinymce_models

import string
from django.utils import timezone
from datetime import timedelta
from django.core.exceptions import ValidationError
from decimal import Decimal
import re

import time
import random


def generate_unique_id():
  return int(time.time() * 1) + random.randint(0, 999)
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

# Create your models here.


class User(AbstractUser): 
  id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
  image = models.ImageField(upload_to='images/', blank=True, null=True)
  otp = models.CharField(max_length=100,blank=True, default="000000")
  name = models.CharField(max_length=100,blank=True, default="")
  about = models.TextField(null=True, blank=True, default="")
  face_link=models.CharField(null=True, blank=True, default="")
  instagram_link=models.CharField(null=True, blank=True, default="")
  gmail_link=models.CharField(null=True, blank=True, default="")
  whatsapp_link=models.CharField(null=True, blank=True, default="")
  is_vendor = models.BooleanField(default=False)
  is_active = models.BooleanField(default=True)
  phone = models.CharField(unique=True,max_length=100, default='', blank=True)
  email = models.EmailField(unique=True,default='', null=True)
  age = models.IntegerField(blank=True, null=True)
  gender = models.CharField(max_length=10, blank=True, null=True)
  kyc_pending = models.BooleanField(default=False)
  kyc = models.BooleanField(default=False)
  address = models.CharField(max_length=256,blank=True, default="")
  country = models.CharField(max_length=256,blank=True, default="")
  city=models.CharField(max_length=256,blank=True, default="")
  state=models.CharField(max_length=256,blank=True, default="")
  upazila=models.CharField(max_length=256,blank=True, default="")
  zip=models.CharField(max_length=256,blank=True, default="")
  balance =  models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
  pending_balance =  models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
  diamond_balance = models.IntegerField(default=0)
  USER_TYPES = [
      ('admin', 'Admin'),
      ('user', 'User'),
      ('vendor', 'Vendor'), 
  ]
  user_type = models.CharField(max_length=20, choices=USER_TYPES, default='user')
  refer  = models.ForeignKey('self',on_delete=models.SET_NULL,null=True, blank=True) 
  refer_count = models.IntegerField(default=0)
  commission_earned = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
  commission = models.DecimalField(max_digits=8, decimal_places=2, default=5.00)
  referral_code = models.CharField(max_length=10, unique=True, editable=False)
  nid_number = models.CharField(unique=True,null=True, blank=True,max_length=16)
  profession = models.CharField(max_length=256,blank=True, default="")
  company = models.CharField(max_length=256,blank=True, default="")
  website = models.CharField(max_length=256,blank=True, default="")
  is_topcontributor = models.BooleanField(default=False)
    #   subscription
  is_pro = models.BooleanField(default=False)
  pro_validity = models.DateTimeField(null=True, blank=True)
  store_name = models.CharField(max_length=40,blank=True, default="")
  store_username = models.CharField(max_length=40,blank=True, default="")
  store_description = models.TextField(null=True, blank=True, default="")
  store_address = models.CharField(max_length=256,blank=True, default="")
  store_logo = models.ImageField(upload_to='images/', blank=True, null=True)
  store_banner = models.ImageField(upload_to='images/', blank=True, null=True)
  product_limit = models.IntegerField(default=10)

  def __str__(self):
      return self.email
  def save(self, *args, **kwargs):
      if not self.referral_code:
            # Generate a unique referral code
            while True:
                code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=10))
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
    user = models.ForeignKey(User,on_delete=models.SET_NULL, null=True, related_name='subscription')
    created_at = models.DateTimeField(auto_now_add=True)
    months = models.IntegerField(default=1)
    total = models.DecimalField(max_digits=8, decimal_places=2, default=149.00)
    def save(self, *args, **kwargs):
        if not self.pk:
            self.user.is_pro = True
            self.user.pro_validity = timezone.now() + timedelta(days=30 * int( self.months))
            self.user.balance -=  Decimal(self.total)
            self.user.save()
        super(Subscription, self).save(*args, **kwargs)
    
class NID(models.Model):
    user = models.ForeignKey(User,on_delete=models.SET_NULL, null=True, related_name='nid')
    front = models.ImageField(upload_to='images/', blank=True, null=True)
    back = models.ImageField(upload_to='images/', blank=True, null=True)
    selfie = models.ImageField(upload_to='images/', blank=True, null=True)
    other_document = models.ImageField(upload_to='images/', blank=True, null=True)
    pending = models.BooleanField(default=True)
    completed = models.BooleanField(default=False)
    approved = models.BooleanField(default=False)
    rejected = models.BooleanField(default=False)
    def __str__(self):
      return str(self.id)
    def save(self, *args, **kwargs):
        if not self.completed and not self.approved and not self.rejected:
            self.user.kyc_pending = True
            self.user.save()
        if self.approved and not self.completed:
            self.pending = False
            self.completed = True
            self.user.kyc_pending = False
            self.user.kyc = True
            self.user.save()

        if self.rejected and not self.completed:
            self.pending = False
            self.completed = True
            self.user.kyc_pending = False
            self.user.kyc = False
            self.user.save()

        super(NID, self).save(*args, **kwargs)


class Logo(models.Model):
    image = models.ImageField(upload_to='images/', blank=True, null=True)
    def __str__(self):
        return f"Site Logo"
    
class AuthenticationBanner(models.Model):
    image = models.ImageField(upload_to='images/', blank=True, null=True)
    def __str__(self):
        return f"Site Authentication Banner"
    
class AdminNotice(models.Model):
    title = models.CharField(max_length=256)
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']  
    def __str__(self):
        return self.title

class ClassifiedCategory(models.Model):
  user = models.ForeignKey(User,on_delete=models.SET_NULL, null=True, related_name='classified_categories')
  id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
  title = models.CharField(max_length=256)
  slug = models.SlugField(max_length=300, unique=True, null=True, blank=True) 
  business_type = models.CharField(max_length=256, default="shop")
  image = models.ImageField(upload_to='images/', blank=True, null=True)
  is_featured = models.BooleanField(default=False)
  created_at = models.DateTimeField(auto_now_add=True)
  updated_at = models.DateTimeField(auto_now=True)

  def save(self, *args, **kwargs):
      if not self.slug:
          self.slug = generate_unique_slug(ClassifiedCategory, self.title, self)
      super(ClassifiedCategory, self).save(*args, **kwargs)

  def __str__(self):
        return self.title
  
class ClassifiedCategoryPostMedia(models.Model):
    image = models.ImageField(upload_to='images/', blank=True, null=True)
    video = models.FileField(upload_to='videos/', blank=True, null=True)
    def __str__(self):
      return str(self.id)

class ClassifiedCategoryPost(models.Model):
    user = models.ForeignKey(User,on_delete=models.SET_NULL, null=True,related_name='classified_categories_post')
    category = models.ForeignKey(ClassifiedCategory,on_delete=models.SET_NULL, null=True,related_name='classified_categories_post')
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=256)
    slug = models.SlugField(max_length=300, unique=True, null=True, blank=True)
    location = models.TextField(max_length=512)
    price = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    negotiable = models.BooleanField(default=False)
    country = models.CharField(null=True, blank=True,default='')
    state = models.CharField(null=True, blank=True,default='')
    city = models.CharField(null=True, blank=True,default='')
    upazila = models.CharField(null=True, blank=True,default='')
    medias = models.ManyToManyField(ClassifiedCategoryPostMedia,  blank=True)
    instructions = models.TextField(blank=True, null=True,default="")
    accepted_terms = models.BooleanField(default=True)
    accepted_privacy = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    active_service = models.BooleanField(default=True)
    GIG_STATUS = [
      ('pending', 'Pending'),
      ('approved', 'Approved'),
      ('rejected', 'Rejected'),
      ('completed', 'Completed'),
    ]
    service_status = models.CharField(
      max_length=20, choices=GIG_STATUS, default='pending')
    
    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = generate_unique_slug(ClassifiedCategoryPost, self.title, self)
        super(ClassifiedCategoryPost, self).save(*args, **kwargs)
    
    def __str__(self):
        return self.title

class MicroGigCategory(models.Model):
    user = models.ForeignKey(User,on_delete=models.SET_NULL, null=True,related_name='micro_gigs')
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=256)
    slug = models.SlugField(max_length=300, unique=True, null=True, blank=True)
    image = models.ImageField(upload_to='images/', blank=True, null=True)
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
    image = models.ImageField(upload_to='images/', blank=True, null=True)
    video = models.FileField(upload_to='videos/', blank=True, null=True)
    def __str__(self):
      return str(self.id)
     
class MicroGigPost(models.Model):
    user = models.ForeignKey(User,on_delete=models.SET_NULL, null=True,related_name='micro_gig_posts')
    category = models.ForeignKey(MicroGigCategory,on_delete=models.SET_NULL, null=True,related_name='micro_gig_posts')
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=256)
    slug = models.SlugField(max_length=300, unique=True, null=True, blank=True)
    price = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    required_quantity = models.IntegerField()
    filled_quantity = models.IntegerField(default=0)
    medias = models.ManyToManyField(MicroGigPostMedia,  blank=True, related_name='micro_gig_posts')
    instructions = models.TextField(blank=True, null=True,default="")
    target_network = models.ManyToManyField(TargetNetwork,blank=True)
    target_country = models.CharField(blank=True, null=True)
    target_device = models.ManyToManyField(TargetDevice,blank=True)
    total_cost = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    balance = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    accepted_terms = models.BooleanField(default=True)
    accepted_privacy = models.BooleanField(default=True)
    active_gig = models.BooleanField(default=True)
    stop_gig = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    action_link = models.URLField(blank=True, null=True,default='')
    GIG_STATUS = [
      ('pending', 'Pending'),
      ('approved', 'Approved'),
      ('rejected', 'Rejected'),
      ('completed', 'Completed'),
    ]
    gig_status = models.CharField(
      max_length=20, choices=GIG_STATUS, default='pending')
    
    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = generate_unique_slug(MicroGigPost, self.title, self)
            
        # Existing save logic
        if self.stop_gig and not self.gig_status == 'completed':
            pending_tasks_exist = MicroGigPostTask.objects.filter(
                gig=self,
                completed=False,
                approved=False,
                rejected=False
            ).exists()
            
            if pending_tasks_exist:
                raise ValidationError("Cannot stop this gig because there are pending tasks that need to be reviewed.")
            else:
                if self.required_quantity > 0:
                    self.user.balance += self.balance
                    self.user.save()
                    self.balance = 0
                    self.gig_status = 'completed'

        if self.filled_quantity >= self.required_quantity:
            self.active_gig = False
            self.gig_status = 'completed'
            
        super(MicroGigPost, self).save(*args, **kwargs)
    
    def __str__(self):
        return self.title

    @property
    def task_submissions(self):
        """Returns all tasks with user information"""
        return self.microgigposttask_set.all().select_related('user').order_by('-created_at')
    
class ReferBonus(models.Model):
    COMMISSION_TYPE_CHOICES = [
        ('gig_completion', 'Gig Completion'),
        ('pro_subscription', 'Pro Subscription'),
        ('gold_sponsor', 'Gold Sponsor'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='commission_bonus')
    referred_user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='generated_commissions', blank=True)
    commission_type = models.CharField(max_length=20, choices=COMMISSION_TYPE_CHOICES, default='gig_completion')
    created_at = models.DateTimeField(auto_now_add=True)
    amount = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    commission_rate = models.DecimalField(max_digits=5, decimal_places=2, default=5.00)  # Percentage rate
    base_amount = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)  # Original transaction amount
    completed = models.BooleanField(default=False)
    description = models.TextField(blank=True, null=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = "Referral Commission"
        verbose_name_plural = "Referral Commissions"
    
    def __str__(self):
        return f"{self.get_commission_type_display()} - ৳{self.amount} ({self.created_at.strftime('%Y-%m-%d')})"
    
    @classmethod
    def get_commission_rate_for_type(cls, commission_type):
        """Get the commission rate for a specific type"""
        rates = {
            'gig_completion': 5.00,
            'pro_subscription': 20.00,
            'gold_sponsor': 20.00,
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
                transaction_type='referral_commission',
                completed=True,
                bank_status='completed',
                description=f"{self.get_commission_type_display()} referral commission"
            )
        super(ReferBonus, self).save(*args, **kwargs)

class MicroGigPostTask(models.Model):
    user = models.ForeignKey(User,on_delete=models.SET_NULL, null=True, related_name='micro_gig_worker')
    gig = models.ForeignKey(MicroGigPost, on_delete=models.SET_NULL, null=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)
    completed = models.BooleanField(default=False)
    approved = models.BooleanField(default=False)
    rejected = models.BooleanField(default=False)
    medias = models.ManyToManyField(MicroGigPostMedia, blank=True)
    submit_details = models.TextField(blank=True, null=True,default='')
    reason = models.TextField( blank=True, null=True,default='')
    task_completion_link = models.URLField(blank=True, null=True,default='')
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
       
        if self.is_48_hours_passed and not self.completed and not self.approved and not self.rejected:
            self.approved = True
            self.save()

    def save(self, *args, **kwargs):
        if self.is_48_hours_passed and not self.completed and not self.approved and not self.rejected:
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
                ReferBonus.objects.create(user=self.user.refer,amount=(self.gig.price * self.user.refer.commission) / 100 )
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
    user = models.ForeignKey(User,on_delete=models.SET_NULL, null=True,related_name='user_balance')
    to_user = models.ForeignKey(User,on_delete=models.SET_NULL, blank=True, null=True,related_name='to_user')
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    PAYMENT_STATUS = [ # delete this, use completed, approved, rejected booleans
      ('pending', 'Pending'),
      ('rejected', 'Rejected'),
      ('completed', 'Completed'),
    ]
    transaction_type = models.CharField(max_length=20,default='',blank=True,null=True)
    bank_status = models.CharField(choices=PAYMENT_STATUS,default='pending')
    payment_method = models.CharField(default='',blank=True,null=True)
    payment_confirmed_at = models.CharField(default='',blank=True,null=True)
    amount =  models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    payable_amount =  models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    received_amount =  models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    merchant_invoice_no = models.CharField(default='',blank=True,null=True)
    shurjopay_order_id = models.CharField(default='',blank=True,null=True)
    card_number = models.CharField(default='',blank=True,null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    completed = models.BooleanField(default=False)
    approved = models.BooleanField(default=False)
    rejected = models.BooleanField(default=False)
    description = models.TextField(blank=True, null=True,default='')
    class Meta:
        ordering = ['-updated_at']

    def __str__(self):
        return f"{self.user}'s Service: {self.payable_amount}"
    def save(self, *args, **kwargs):
        # Normalize transaction_type to lowercase for consistency
        self.transaction_type = (self.transaction_type or '').lower()
        # Handle withdrawal
        if self.transaction_type == 'transfer' and  self.to_user and not self.completed:
            self.user.balance -= Decimal(self.payable_amount)
            self.to_user.balance += Decimal(self.payable_amount)
            self.user.save()
            self.to_user.save()
            self.completed = True
            self.approved = True
        if self.transaction_type == 'withdraw' and not self.completed and not self.approved:
            self.user.balance -= self.payable_amount
            self.user.save()
        if self.transaction_type == 'withdraw' and self.approved:
            self.completed = True
            self.approved = True
            self.user.save()
        if self.transaction_type == 'withdraw' and self.rejected and not self.completed:
            self.completed = True
            self.user.balance += self.amount
            self.user.save()
        if self.transaction_type == 'deposit':
            self.user.balance += self.payable_amount
            self.completed = True
            self.approved = True
            self.user.save()

        if self.approved and not self.completed:
            self.completed = True

        # Call the original save method
        super(Balance, self).save(*args, **kwargs)


class PendingTask(models.Model):
    user = models.ForeignKey(User,on_delete=models.SET_NULL, null=True,related_name='pending_tasks')
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
    image = models.ImageField(upload_to='images/', blank=True, null=True)
    badge = models.CharField(max_length=255, blank = True, null = True)
    badge_color= models.CharField(max_length=255, blank = True, null = True)
    special_offer= models.BooleanField(default=False)
    hot_arrival= models.BooleanField(default=False)
    slug = models.SlugField(max_length=300, unique=True, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add = True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = generate_unique_slug(ProductCategory, self.name, self)
        super(ProductCategory, self).save(*args, **kwargs)
    
    def __str__(self):
        return self.name

class ProductMedia(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    image = models.ImageField(upload_to='images/', blank=True, null=True)
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
    owner = models.ForeignKey(User,on_delete=models.SET_NULL, null=True, related_name='products')
    name = models.CharField(max_length=256)
    slug = models.SlugField(max_length=300, unique=True, null=True, blank=True)
    image = models.ManyToManyField(ProductMedia, blank=True)
    description = models.TextField( blank=True, null=True)
    short_description = models.TextField(blank=True, null=True)
    delivery_information = models.TextField(blank=True, null=True)
    is_free_delivery = models.BooleanField(default=False)
    delivery_fee_free = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    delivery_fee_inside_dhaka = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    delivery_fee_outside_dhaka = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    category= models.ManyToManyField(ProductCategory, blank=True, related_name='products')
    regular_price = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    sale_price = models.DecimalField(max_digits=8, decimal_places=2, default=0.00, blank=True, null=True)
    quantity = models.IntegerField(default=0)
    is_featured = models.BooleanField(default=False)
    weight = models.DecimalField(max_digits=8, decimal_places=2, default=0.00, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_advanced = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    is_science = models.BooleanField(default=False)
    is_commerce = models.BooleanField(default=False)
    is_humanities = models.BooleanField(default=False)
    # New marketing fields
    benefits = models.ManyToManyField(ProductBenefit, blank=True, related_name='products')
    faqs = models.ManyToManyField(ProductFAQ, blank=True, related_name='products')
    trust_badges = models.ManyToManyField(ProductTrustBadge, blank=True, related_name='products')
    
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
        if not self.slug:
            self.slug = generate_unique_slug(Product, self.name, self)
        super(Product, self).save(*args, **kwargs)
    
    def __str__(self):
        return self.name
        
    @property
    def order_count(self):
        """Returns the number of times this product has been ordered"""
        from django.db.models import Sum
        # Count all order items for this product
        order_items = OrderItem.objects.filter(product=self)
        return order_items.count()
        
    @property
    def total_items_ordered(self):
        """Returns the total quantity of this product that has been ordered"""
        from django.db.models import Sum
        # Sum all quantities for this product in order items
        result = OrderItem.objects.filter(product=self).aggregate(Sum('quantity'))
        return result['quantity__sum'] or 0

class OrderItem(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey('Order', on_delete=models.CASCADE, related_name='items')  # Added this field
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
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='orders')
    name = models.CharField(max_length=256, blank=True, default="")
    email = models.EmailField(default='',blank=True, null=True)
    address = models.CharField(max_length=256, blank=True, default="")
    phone = models.CharField(max_length=256, blank=True, default="")
    total = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    delivery_fee = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    ORDER_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('shipped', 'Shipped'),
        ('delivered', 'Delivered'),
        ('cancelled', 'Cancelled'),
    ]
    order_status = models.CharField(max_length=256, choices=ORDER_STATUS_CHOICES, default='pending')
    PAYMENT_METHOD_CHOICES = [
        ('balance', 'Account Balance'),
        ('cash_on_delivery', 'Cash on Delivery'),
    ]
    payment_method = models.CharField(max_length=256, blank=True, choices=PAYMENT_METHOD_CHOICES, default="cash_on_delivery")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def generate_order_number(self):
        """Generate a unique 10-digit order number based on current time"""
        from datetime import datetime
        import random
        
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
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    image = models.ImageField(upload_to='banner_images/')
    title = models.CharField(max_length=255, blank=True, null=True)
    link = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    
class ShopBannerImage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    image = models.ImageField(upload_to='shop_banner_images/')
    title = models.CharField(max_length=255, blank=True, null=True)
    link = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class EshopBanner(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    image = models.ImageField(upload_to='eshop_banner/')
    title = models.CharField(max_length=255, blank=True, null=True)
    link = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    


class BNLogo(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    image = models.ImageField(upload_to='bn_logo/')
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

class DiamondTransaction(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='diamond_transactions')
    to_user = models.ForeignKey(User, on_delete=models.SET_NULL, blank=True, null=True, related_name='received_diamonds')
    
    TRANSACTION_TYPE_CHOICES = [
        ('purchase', 'Purchase'),
        ('gift', 'Gift'),
        ('bonus', 'Bonus'),
        ('refund', 'Refund'),
        ('admin', 'Admin Adjustment')
    ]
    transaction_type = models.CharField(max_length=20, choices=TRANSACTION_TYPE_CHOICES)
    
    amount = models.IntegerField()  # Number of diamonds
    cost = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)  # Cost in BDT
    
    completed = models.BooleanField(default=False)
    approved = models.BooleanField(default=False)
    rejected = models.BooleanField(default=False)
    
    post_id = models.CharField(max_length=100, blank=True, null=True)  # For gifts to specific posts
    payment_method = models.CharField(max_length=50, blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user}'s Diamond {self.transaction_type}: {self.amount}"
    
    def save(self, *args, **kwargs):
        # Diamond purchase from balance
        if self.transaction_type == 'purchase' and not self.completed:
            if self.user.balance >= self.cost:
                self.user.balance -= self.cost
                self.user.diamond_balance += self.amount
                self.completed = True
                self.approved = True
                self.user.save()
            else:
                raise ValidationError("Insufficient balance for diamond purchase")
        
        # Gift diamonds to another user
        if self.transaction_type == 'gift' and self.to_user and not self.completed:
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
        if self.transaction_type == 'admin' and not self.completed:
            self.user.diamond_balance += self.amount  # Can be positive or negative
            self.completed = True
            self.approved = True
            self.user.save()
            
        # Bonus diamonds
        if self.transaction_type == 'bonus' and not self.completed:
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
    image = models.ImageField(upload_to='news-logo/')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    def __str__(self):
        return f"BN Logo {self.id}"
        
class AndroidAppVersion(models.Model):
    version_name = models.CharField(max_length=50, help_text="Version name (e.g., 1.0.0)")
    version_code = models.PositiveIntegerField(help_text="Version code (integer, e.g., 100)")
    download_url = models.URLField(max_length=500, help_text="URL to download the APK")
    release_notes = models.TextField(blank=True, help_text="What's new in this version")
    is_active = models.BooleanField(default=True, help_text="Is this the currently active version")
    min_android_version = models.CharField(max_length=20, default="5.0", help_text="Minimum Android version required")
    file_size_mb = models.DecimalField(max_digits=6, decimal_places=2, help_text="APK file size in MB", null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Android App Version"
        verbose_name_plural = "Android App Versions"
        ordering = ['-version_code']
        
    def __str__(self):
        return f"v{self.version_name} (code: {self.version_code})"
        
    def save(self, *args, **kwargs):
        # If this version is being set as active, deactivate all other versions
        if self.is_active:
            AndroidAppVersion.objects.exclude(pk=self.pk).update(is_active=False)
        super().save(*args, **kwargs)

