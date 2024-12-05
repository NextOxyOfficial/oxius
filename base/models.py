from django.db import models
from django.contrib.auth.models import User
import uuid

# Create your models here.


class ClassifiedCategory(models.Model):
  user = models.ForeignKey(User,on_delete=models.CASCADE,related_name='classified_services')
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