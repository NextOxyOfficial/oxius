from django.db import models
# from django.contrib.auth.models import User
import uuid
from django.contrib.auth.models import AbstractUser
from django.utils.text import slugify

# Create your models here.


class User(AbstractUser):
  id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
  name = models.CharField(max_length=100,blank=True, default="")
  is_vendor = models.BooleanField(default=False)
  is_active = models.BooleanField(default=True) 
  phone = models.CharField(max_length=100, default='', blank=True)
  email = models.EmailField(unique=True,default='', null=True)
  nid = models.ImageField(upload_to='images/', blank=True, null=True)
  address = models.CharField(max_length=256,blank=True, default="")
  city=models.CharField(max_length=256,blank=True, default="")
  state=models.CharField(max_length=256,blank=True, default="")
  zip=models.CharField(max_length=256,blank=True, default="")
  USER_TYPES = [
      ('admin', 'Admin'),
      ('user', 'User'),
      ('vendor', 'Vendor'),
  ]
  user_type = models.CharField(
      max_length=20, choices=USER_TYPES, default='user')

  def __str__(self):
      return self.email


class ClassifiedCategory(models.Model):
  user = models.ForeignKey(User,on_delete=models.CASCADE,related_name='classified_categories')
  id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
  title = models.CharField(max_length=256)
  image = models.ImageField(upload_to='images/', blank=True, null=True)
  created_at = models.DateTimeField(auto_now_add=True)
  updated_at = models.DateTimeField(auto_now=True)

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

class MicroGigPost(models.Model):
    user = models.ForeignKey(User,on_delete=models.CASCADE,related_name='micro_gig_posts')
    category = models.ForeignKey(MicroGigCategory,on_delete=models.CASCADE,related_name='micro_gig_posts')
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=256)
    price = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    required_quantity= models.IntegerField()
    filled_quantity = models.IntegerField()
    image = models.ImageField(upload_to='images/', blank=True, null=True)
    instructions = models.TextField(blank=True, null=True,default="")
    NETWORK_CHOICES = [
        ('wifi', 'WiFi'),
        ('cellular', 'Cellular'),
    ]
    quality = models.CharField(max_length=10, choices=NETWORK_CHOICES)
    TARGET_COUNTRY = [
        ('bangladesh', 'Bangladesh'),
    ]
    target_country = models.CharField(max_length=10, choices=TARGET_COUNTRY,default='bangladesh')
    TARGET_DEVICE = [
        ('all', 'All'),
        ('iphone', 'iPhone'),
        ('android', 'Android'),
        ('windows', 'Windows'),
        ('linux', 'Linux'),
    ]
    target_device = models.CharField(max_length=10, choices=TARGET_DEVICE,default='all')
    total_cost = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    accepted_terms = models.BooleanField(default=True)
    accepted_privacy = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    def __str__(self):
        return self.title
  
class Balance(models.Model):
    user = models.ForeignKey(User,on_delete=models.CASCADE,related_name='user_balance')
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
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
