from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
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
    last_read_at = models.DateTimeField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def save(self, *args, **kwargs):
        if not self.id:
            # Generate a 10-digit numeric ID based on timestamp and random numbers
            import time
            import random
            timestamp = int(time.time())
            random_num = random.randint(0, 9999)
            self.id = f"{timestamp % 1000000}{random_num:04d}"[-10:]
        super(SupportTicket, self).save(*args, **kwargs)
    
    def __str__(self):
        return f"#{self.id} - {self.title}"


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


class TicketReadStatus(models.Model):
    """
    Tracks when a ticket was last read by a user
    This helps to identify unread tickets and new replies
    """
    ticket = models.ForeignKey(SupportTicket, on_delete=models.CASCADE, related_name='read_statuses')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ticket_read_statuses')
    last_read_at = models.DateTimeField(default=timezone.now)
    
    class Meta:
        unique_together = ['ticket', 'user']
        verbose_name = 'Ticket Read Status'
        verbose_name_plural = 'Ticket Read Statuses'
    
    def __str__(self):
        return f"{self.user.username} read {self.ticket.id} at {self.last_read_at}"
    
    def mark_as_read(self):
        """
        Updates the last read timestamp to current time
        """
        self.last_read_at = timezone.now()
        self.save()
