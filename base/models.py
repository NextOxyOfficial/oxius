from django.db import models
# from django.contrib.auth.models import User
import uuid
from django.contrib.auth.models import AbstractUser
from django.utils.text import slugify
from django.dispatch import receiver
from django.utils.translation import gettext_lazy as _
from django.db.models.signals import post_save, pre_save
from decimal import Decimal
import random
import string
from django.utils import timezone
from datetime import timedelta

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
  kyc_pending = models.BooleanField(default=False)
  kyc = models.BooleanField(default=False)
  address = models.CharField(max_length=256,blank=True, default="")
  city=models.CharField(max_length=256,blank=True, default="")
  state=models.CharField(max_length=256,blank=True, default="")
  zip=models.CharField(max_length=256,blank=True, default="")
  balance =  models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
  pending_balance =  models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
  USER_TYPES = [
      ('admin', 'Admin'),
      ('user', 'User'),
      ('vendor', 'Vendor'), 
  ]
  user_type = models.CharField(
      max_length=20, choices=USER_TYPES, default='user')
  refer  = models.ForeignKey('self',on_delete=models.SET_NULL,null=True, blank=True) 
  refer_count = models.IntegerField(default=0)
  commission_earned = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
  commission = models.DecimalField(max_digits=8, decimal_places=2, default=5.00)
  referral_code = models.CharField(max_length=10, unique=True, editable=False)
  nid_number = models.CharField(unique=True,null=True, blank=True,max_length=16)

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
      super(User, self).save(*args, **kwargs)

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
  image = models.ImageField(upload_to='images/', blank=True, null=True)
  created_at = models.DateTimeField(auto_now_add=True)
  updated_at = models.DateTimeField(auto_now=True)

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
    location = models.TextField(max_length=512)
    price = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    negotiable = models.BooleanField(default=False)
    country = models.CharField(null=True, blank=True,default='')
    state = models.CharField(null=True, blank=True,default='')
    city = models.CharField(null=True, blank=True,default='')
    upazila = models.CharField(null=True, blank=True,default='')
    medias = models.ManyToManyField(ClassifiedCategoryPostMedia, null=True, blank=True)
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
    def __str__(self):
        return self.title

class MicroGigCategory(models.Model):
    user = models.ForeignKey(User,on_delete=models.SET_NULL, null=True,related_name='micro_gigs')
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=256)
    image = models.ImageField(upload_to='images/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
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
    price = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    required_quantity = models.IntegerField()
    filled_quantity = models.IntegerField(default=0)
    medias = models.ManyToManyField(MicroGigPostMedia, null=True, blank=True)
    instructions = models.TextField(blank=True, null=True,default="")
    target_network = models.ManyToManyField(TargetNetwork,blank=True, null=True)
    target_country = models.CharField(blank=True, null=True)
    target_device = models.ManyToManyField(TargetDevice,blank=True, null=True)
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
    def __str__(self):
        return self.title
    @property
    def task_submissions(self):
        """Returns all tasks with user information"""
        return self.microgigposttask_set.all().select_related('user').order_by('-created_at')
    
    def save(self, *args, **kwargs):
        # Check if the gig is being stopped
        if self.stop_gig and not self.gig_status == 'completed':
            if self.required_quantity > 0:
                # Refund the unfulfilled portion
                self.user.balance += self.balance
                self.user.save()
                self.balance = 0
                self.gig_status = 'completed'

        # Check if the gig is complete
        if self.filled_quantity >= self.required_quantity:
            self.active_gig = False
            self.gig_status = 'completed'

        super(MicroGigPost, self).save(*args, **kwargs)

class ReferBonus(models.Model):
    user = models.ForeignKey(User,on_delete=models.SET_NULL, null=True, unique=True, related_name='comission_bonus')
    created_at = models.DateTimeField(auto_now_add=True)
    amount = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    completed = models.BooleanField(default=False)
    def __str__(self):
        return str(self.created_at)
    def save(self, *args, **kwargs):
        if not self.pk and not self.completed:
            self.completed = True
            self.user.balance += self.amount
            self.user.commission_earned += self.amount
            self.user.save()
        super(ReferBonus, self).save(*args, **kwargs)

class MicroGigPostTask(models.Model):
    user = models.ForeignKey(User,on_delete=models.SET_NULL, null=True, unique=True, related_name='micro_gig_worker')
    gig = models.ForeignKey(MicroGigPost, on_delete=models.SET_NULL, null=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)
    completed = models.BooleanField(default=False)
    approved = models.BooleanField(default=False)
    rejected = models.BooleanField(default=False)
    medias = models.ManyToManyField(MicroGigPostMedia, null=True, blank=True)
    submit_details = models.TextField(blank=True, null=True,default='')
    reason = models.TextField( blank=True, null=True,default='')
    task_completion_link = models.URLField(blank=True, null=True,default='')
    accepted_terms = models.BooleanField(default=True)
    accepted_condition = models.BooleanField(default=True)
    def __str__(self):
        return str(self.created_at)
    
    @property
    def is_48_hours_passed(self):
       
        return timezone.now() >= (self.created_at + timedelta(hours=48))

    def auto_approve(self):
       
        if self.is_48_hours_passed and not self.completed and not self.approved and not self.rejected:
            self.approved = True
            self.save()

    def save(self, *args, **kwargs):
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


# class MicroGigReport(models.Model):
#     user = models.ForeignKey(User,on_delete=models.SET_NULL, null=True,related_name='micro_gig_reports')
#     gig = models.ForeignKey(MicroGigPost, on_delete=models.SET_NULL, null=True,related_name='micro_gig_reports')
#     id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
#     title = models.CharField(max_length=256)
#     description = models.TextField(blank=True, null=True,default='')
#     medias = models.ManyToManyField(MicroGigPostMedia, null=True, blank=True)
#     created_at = models.DateTimeField(auto_now_add=True)
#     updated_at = models.DateTimeField(auto_now=True)
#     def __str__(self):
#         return self.title    
    
# class TaskStatus(models.TextChoices):
#     PENDING = 'PENDING', _('Pending')
#     APPROVED = 'APPROVED', _('Approved')
#     REJECTED = 'REJECTED', _('Rejected')
#     COMPLETED = 'COMPLETED', _('Completed')

# class MicroGigPostTask(models.Model):
#     user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='micro_gig_worker')
#     gig = models.ForeignKey(MicroGigPost, on_delete=models.CASCADE, null=False)
#     updated_at = models.DateTimeField(auto_now=True)
#     created_at = models.DateTimeField(auto_now_add=True)
#     status = models.CharField(
#         max_length=10,
#         choices=TaskStatus.choices,
#         default=TaskStatus.PENDING
#     )
#     medias = models.ManyToManyField(MicroGigPostMedia, blank=True)
#     reason = models.CharField(max_length=200, blank=True, null=True)
#     accepted_terms = models.BooleanField(default=True)
#     accepted_condition = models.BooleanField(default=True)

#     def __str__(self):
#         return f"Task created at {self.created_at} by {self.user}"

# # Signals for handling related updates
# @receiver(pre_save, sender=MicroGigPostTask)
# def handle_task_status_update(sender, instance, **kwargs):
#     if instance.pk:  # Only for updates
#         previous = MicroGigPostTask.objects.get(pk=instance.pk)
#         if previous.status != instance.status:
#             if instance.status == TaskStatus.APPROVED:
#                 instance.user.balance += instance.gig.price
#                 instance.user.pending_balance -= instance.gig.price
#                 instance.user.save()
#             elif instance.status == TaskStatus.REJECTED:
#                 instance.gig.filled_quantity -= 1
#                 instance.gig.save()
#                 instance.user.pending_balance -= instance.gig.price
#                 instance.user.save()
#             elif instance.status == TaskStatus.PENDING:
#                 instance.gig.filled_quantity += 1
#                 instance.gig.save()
#                 instance.user.pending_balance += instance.gig.price
#                 instance.user.save()


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
        if self.transaction_type == 'withdraw':
            self.user.balance -= self.payable_amount
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
        # Check if is neither completed, approved, nor rejected
        # if not self.completed and not self.approved and not self.rejected:
        #     self.user.balance -= Decimal(self.amount)
        #     self.user.save()

        if self.approved and not self.completed:
            self.completed = True
            # refer = self.user.refer.last()
            # refer.balance += (self.amount * refer.commission) / 100
            # refer.save()
            # create a table called commission_report and add a row with user_id, refer_id, amount, created_at
            # add refer commission

        # if self.rejected and not self.completed:
        #     self.completed = True
        #     self.user.balance -= self.amount
        #     self.user.save()
            # refund balance
        # if self.transaction_type == 'withdraw':
        #     self.user.balance -= self.payable_amount

        # Call the original save method
        super(Balance, self).save(*args, **kwargs)


# class MicroGigs(models.Model):
#     user = models.ForeignKey(User,on_delete=models.CASCADE,related_name='micro_gigs')
#     id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
#     title = models.CharField(max_length=256)
#     image = models.ImageField(upload_to='images/', blank=True, null=True)
#     created_at = models.DateTimeField(auto_now_add=True)
#     updated_at = models.DateTimeField(auto_now=True)

#     def __str__(self):
#         return self.title
    

# class Balance(models.Model):
#     user = models.ForeignKey(User,on_delete=models.CASCADE,related_name='user_balance')
#     id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
#     amount =  models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
#     created_at = models.DateTimeField(auto_now_add=True)
#     updated_at = models.DateTimeField(auto_now=True)
#     def __str__(self):
#         return f"{self.user.username}'s Service: {self.amount}"

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
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    def __str__(self):
        return self.label
    


    
# class PoliceStation(models.Model):
#     name = models.CharField(max_length=256)
    
#     def __str__(self):
#         return self.name