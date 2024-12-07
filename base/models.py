from django.db import models
# from django.contrib.auth.models import User
import uuid
from django.contrib.auth.models import AbstractUser
from django.utils.text import slugify

# Create your models here.


class User(AbstractUser):
  id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
  name = models.CharField(max_length=100, default="No Name")
  is_vendor = models.BooleanField(default=False)
  is_active = models.BooleanField(default=True) 
  phone = models.CharField(max_length=100, default='', null=True)
#   email = models.EmailField(unique=True,default='', null=True)
  nid = models.ImageField(upload_to='images/', blank=True, null=True)
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
  
class Balance(models.Model):
    user = models.ForeignKey(User,on_delete=models.CASCADE,related_name='user_balance')
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    amount =  models.DecimalField(max_digits=10, decimal_places=2, default=0.00)

    def __str__(self):
        return f"{self.user.username}'s Service: {self.amount}"

class MicroGigs(models.Model):
    user = models.ForeignKey(User,on_delete=models.CASCADE,related_name='micro_gigs')
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=256)
    image = models.ImageField(upload_to='images/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title