from django.db import models
from django.contrib.auth import get_user_model
import uuid

User = get_user_model()

class SupportTicket(models.Model):
    STATUS_CHOICES = [
        ('open', 'Open'),
        ('in_progress', 'In Progress'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed'),
    ]
    
    id = models.CharField(primary_key=True, editable=False, unique=True, max_length=20)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='tickets')
    title = models.CharField(max_length=255)
    message = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def save(self, *args, **kwargs):
        if not self.id:
            self.id = str(uuid.uuid4())[:20]
        super(SupportTicket, self).save(*args, **kwargs)
    
    def __str__(self):
        return f"#{self.id[:8]} - {self.title}"


class TicketReply(models.Model):
    id = models.CharField(primary_key=True, editable=False, unique=True, max_length=20)
    ticket = models.ForeignKey(SupportTicket, on_delete=models.CASCADE, related_name='replies')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ticket_replies')
    message = models.TextField()
    is_from_admin = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['created_at']
    
    def save(self, *args, **kwargs):
        if not self.id:
            self.id = str(uuid.uuid4())[:20]
        super(TicketReply, self).save(*args, **kwargs)
    
    def __str__(self):
        return f"Reply to {self.ticket}"
