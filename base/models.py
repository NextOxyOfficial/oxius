from django.db import models
# from django.contrib.auth.models import User
import uuid
from django.contrib.auth.models import AbstractUser
from django.utils.text import slugify
from django.dispatch import receiver
from django.utils.translation import gettext_lazy as _
from django.db.models.signals import post_save, pre_save

# Create your models here.

class NID(models.Model):
    image = models.ImageField(upload_to='images/', blank=True, null=True)
    def __str__(self):
      return str(self.id)

class User(AbstractUser):
  id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
  name = models.CharField(max_length=100,blank=True, default="")
  about = models.TextField(null=True, blank=True, default="")
  face_link=models.CharField(null=True, blank=True, default="")
  instagram_link=models.CharField(null=True, blank=True, default="")
  gmail_link=models.CharField(null=True, blank=True, default="")
  whatsapp_link=models.CharField(null=True, blank=True, default="")
  is_vendor = models.BooleanField(default=False)
  is_active = models.BooleanField(default=True)
  phone = models.CharField(max_length=100, default='', blank=True)
  email = models.EmailField(unique=True,default='', null=True)
  nid = models.ManyToManyField(NID,null=True, blank=True)
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

  def __str__(self):
      return self.email





class Logo(models.Model):
    image = models.ImageField(upload_to='images/', blank=True, null=True)
    def __str__(self):
        return f"Site Logo"
    
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
  user = models.ForeignKey(User,on_delete=models.CASCADE,related_name='classified_categories')
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
    user = models.ForeignKey(User,on_delete=models.CASCADE,related_name='classified_categories_post')
    category = models.ForeignKey(ClassifiedCategory,on_delete=models.CASCADE,related_name='classified_categories_post')
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=256)
    location = models.TextField(max_length=512)
    price = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    negotiable = models.BooleanField(default=False)
    country = models.CharField(null=True, blank=True,default='')
    state = models.CharField(null=True, blank=True,default='')
    city = models.CharField(null=True, blank=True,default='')
    medias = models.ManyToManyField(ClassifiedCategoryPostMedia, null=True, blank=True)
    instructions = models.TextField(blank=True, null=True,default="")
    accepted_terms = models.BooleanField(default=True)
    accepted_privacy = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    GIG_STATUS = [
      ('pending', 'Pending'),
      ('approved', 'Approved'),
      ('rejected', 'Rejected'),
    ]
    gig_status = models.CharField(
      max_length=20, choices=GIG_STATUS, default='pending')
    def __str__(self):
        return self.title

class MicroGigCategory(models.Model):
    user = models.ForeignKey(User,on_delete=models.CASCADE,related_name='micro_gigs')
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=256)
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
    user = models.ForeignKey(User,on_delete=models.CASCADE,related_name='micro_gig_posts')
    category = models.ForeignKey(MicroGigCategory,on_delete=models.CASCADE,related_name='micro_gig_posts')
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
    accepted_terms = models.BooleanField(default=True)
    accepted_privacy = models.BooleanField(default=True)
    active_gig = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    GIG_STATUS = [
      ('pending', 'Pending'),
      ('approved', 'Approved'),
      ('rejected', 'Rejected'),
    ]
    gig_status = models.CharField(
      max_length=20, choices=GIG_STATUS, default='pending')
    def __str__(self):
        return self.title

class MicroGigPostTask(models.Model):
    user = models.ForeignKey(User,on_delete=models.CASCADE,related_name='micro_gig_worker')
    gig = models.ForeignKey(MicroGigPost, on_delete=models.CASCADE)
    updated_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)
    completed = models.BooleanField(default=False)
    approved = models.BooleanField(default=False)
    rejected = models.BooleanField(default=False)
    medias = models.ManyToManyField(MicroGigPostMedia, null=True, blank=True)
    submit_details = models.TextField(blank=True, null=True,default='')
    reason = models.TextField( blank=True, null=True,default='')
    accepted_terms = models.BooleanField(default=True)
    accepted_condition = models.BooleanField(default=True)
    def __str__(self):
        return str(self.created_at)

    def save(self, *args, **kwargs):
        # Check if task is neither completed, approved, nor rejected
        if not self.completed and not self.approved and not self.rejected:
            self.gig.filled_quantity += 1
            self.gig.save()
            self.user.pending_balance += self.gig.price
            self.user.save()

        # Mark as completed if approved
        if self.approved and self.completed:
            self.completed = True
            self.user.balance += self.gig.price
            self.user.pending_balance -= self.gig.price
            self.user.save()
            # add balance

        # Reduce filled quantity and mark as completed if rejected
        if self.rejected and not self.completed:
            self.gig.filled_quantity -= 1
            self.gig.save()
            self.completed = True
            self.user.pending_balance -= self.gig.price
            self.user.save()

        # Call the original save method
        super(MicroGigPostTask, self).save(*args, **kwargs)


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
    user = models.ForeignKey(User,on_delete=models.CASCADE,related_name='user_balance')
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    PAYMENT_STATUS = [
      ('pending', 'Pending'),
      ('approved', 'Approved'),
    ]
    status = models.CharField(choices=PAYMENT_STATUS,default='pending')
    transaction_type = models.CharField(default='',blank=True,null=True)
    amount =  models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username}'s Service: {self.amount}"

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
    user = models.ForeignKey(User,on_delete=models.CASCADE,related_name='pending_tasks')
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=256)
    price = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    def __str__(self):
        return self.title
    