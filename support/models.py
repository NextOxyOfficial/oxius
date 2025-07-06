from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
import uuid

User = get_user_model()


class SupportTicket(models.Model):
    STATUS_CHOICES = [
        ("open", "Open"),
        ("in_progress", "In Progress"),
        ("resolved", "Resolved"),
        ("closed", "Closed"),
    ]
    id = models.CharField(primary_key=True, editable=False, unique=True, max_length=20)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="tickets")
    title = models.CharField(max_length=255)
    message = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="open")
    last_read_at = models.DateTimeField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

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
    ticket = models.ForeignKey(
        SupportTicket, on_delete=models.CASCADE, related_name="replies"
    )
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="ticket_replies"
    )
    message = models.TextField()
    is_from_admin = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["created_at"]

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

    ticket = models.ForeignKey(
        SupportTicket, on_delete=models.CASCADE, related_name="read_statuses"
    )
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="ticket_read_statuses"
    )
    last_read_at = models.DateTimeField(default=timezone.now)

    class Meta:
        unique_together = ["ticket", "user"]
        verbose_name = "Ticket Read Status"
        verbose_name_plural = "Ticket Read Statuses"

    def __str__(self):
        return f"{self.user.username} read {self.ticket.id} at {self.last_read_at}"

    def mark_as_read(self):
        """
        Updates the last read timestamp to current time
        """
        self.last_read_at = timezone.now()
        self.save()


class BulkTicket(models.Model):
    """
    Model for creating tickets that can be sent to multiple users or all users
    """

    TARGET_CHOICES = [
        ("selected", "Selected Users"),
        ("all", "All Users"),
        ("staff", "Staff Members Only"),
        ("non_staff", "Non-Staff Members Only"),
    ]

    title = models.CharField(max_length=255)
    message = models.TextField(help_text="Rich text content with HTML formatting")
    target_type = models.CharField(
        max_length=20, choices=TARGET_CHOICES, default="selected"
    )
    target_users = models.ManyToManyField(
        User,
        blank=True,
        help_text="Specific users to send tickets to (only used when target_type is 'selected')",
    )
    created_by = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="created_bulk_tickets"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    # Track execution
    is_processed = models.BooleanField(default=False)
    processed_at = models.DateTimeField(null=True, blank=True)
    tickets_created_count = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Bulk Ticket"
        verbose_name_plural = "Bulk Tickets"

    def __str__(self):
        return f"Bulk: {self.title} ({self.get_target_type_display()})"

    def get_target_users(self):
        """Get the list of users this bulk ticket should be sent to"""
        if self.target_type == "all":
            return User.objects.filter(is_active=True)
        elif self.target_type == "staff":
            return User.objects.filter(is_active=True, is_staff=True)
        elif self.target_type == "non_staff":
            return User.objects.filter(is_active=True, is_staff=False)
        elif self.target_type == "selected":
            return self.target_users.filter(is_active=True)
        return User.objects.none()

    def create_individual_tickets(self):
        """Create individual SupportTicket instances for each target user"""
        if self.is_processed:
            return

        target_users = self.get_target_users()
        created_count = 0

        for user in target_users:
            # Create individual ticket
            SupportTicket.objects.create(
                user=user, title=self.title, message=self.message, status="open"
            )
            created_count += 1

        # Mark as processed
        self.is_processed = True
        self.processed_at = timezone.now()
        self.tickets_created_count = created_count
        self.save()

        return created_count


class PublicContact(models.Model):
    """
    Model for storing public contact form submissions
    """

    STATUS_CHOICES = [
        ("new", "New"),
        ("read", "Read"),
        ("responded", "Responded"),
        ("closed", "Closed"),
    ]

    id = models.CharField(primary_key=True, editable=False, unique=True, max_length=20)
    name = models.CharField(max_length=255)
    email = models.EmailField()
    phone = models.CharField(max_length=20)
    message = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="new")

    # Admin fields
    admin_notes = models.TextField(
        blank=True, null=True, help_text="Internal notes for admin use"
    )
    responded_at = models.DateTimeField(blank=True, null=True)
    responded_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        blank=True,
        null=True,
        related_name="responded_contacts",
    )

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name = "Public Contact"
        verbose_name_plural = "Public Contacts"

    def save(self, *args, **kwargs):
        if not self.id:
            # Generate a unique ID
            import time
            import random

            timestamp = int(time.time())
            random_num = random.randint(0, 9999)
            self.id = f"PC{timestamp % 1000000}{random_num:04d}"[-10:]
        super(PublicContact, self).save(*args, **kwargs)

    def __str__(self):
        return f"#{self.id} - {self.name} ({self.email})"

    def mark_as_read(self, user=None):
        """Mark the contact as read"""
        if self.status == "new":
            self.status = "read"
            self.save()

    def mark_as_responded(self, user=None):
        """Mark the contact as responded"""
        self.status = "responded"
        self.responded_at = timezone.now()
        if user:
            self.responded_by = user
        self.save()
