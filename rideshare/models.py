import uuid
from decimal import Decimal

from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import models
from django.db.models import Sum
from django.utils import timezone


class DriverProfile(models.Model):
    APPROVAL_STATUS_CHOICES = [
        ("pending", "Pending"),
        ("approved", "Approved"),
        ("suspended", "Suspended"),
    ]

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="driver_profile",
    )
    license_number = models.CharField(max_length=100, blank=True, default="")
    national_id_number = models.CharField(max_length=100, blank=True, default="")
    approval_status = models.CharField(
        max_length=20, choices=APPROVAL_STATUS_CHOICES, default="pending"
    )
    is_online = models.BooleanField(default=False)
    is_available = models.BooleanField(default=False)
    service_radius_km = models.DecimalField(
        max_digits=6,
        decimal_places=2,
        default=Decimal("8.00"),
        help_text="How far away (km) the driver will accept pickup requests from.",
    )
    max_ride_distance_km = models.DecimalField(
        max_digits=6,
        decimal_places=2,
        default=Decimal("0.00"),
        help_text="Maximum ride distance (km) the driver is willing to drive. 0 = no limit.",
    )
    current_latitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True
    )
    current_longitude = models.DecimalField(
        max_digits=9, decimal_places=6, null=True, blank=True
    )
    last_location_at = models.DateTimeField(null=True, blank=True)
    total_trips = models.PositiveIntegerField(default=0)
    total_earnings = models.DecimalField(
        max_digits=10, decimal_places=2, default=Decimal("0.00")
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-updated_at"]

    def __str__(self):
        return f"DriverProfile({self.user_id})"

    def outstanding_cash_due_rides(self):
        return self.rides_assigned.filter(
            payment_method=Ride.PAYMENT_METHOD_CASH,
            payment_status="completed",
            driver_due_amount__gt=Decimal("0.00"),
            driver_due_settled_at__isnull=True,
        )

    @property
    def outstanding_cash_due_count(self):
        return self.outstanding_cash_due_rides().count()

    @property
    def outstanding_cash_due_amount(self):
        return self.outstanding_cash_due_rides().aggregate(
            total=Sum("driver_due_amount")
        ).get("total") or Decimal("0.00")

    @property
    def cash_due_limit_reached(self):
        return self.outstanding_cash_due_count >= 2


class Vehicle(models.Model):
    VEHICLE_TYPE_CHOICES = [
        ("bike", "Bike"),
        ("car", "Car"),
        ("cng", "CNG"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    driver = models.ForeignKey(
        DriverProfile, on_delete=models.CASCADE, related_name="vehicles"
    )
    vehicle_type = models.CharField(
        max_length=20, choices=VEHICLE_TYPE_CHOICES, default="bike"
    )
    brand = models.CharField(max_length=100, blank=True, default="")
    model_name = models.CharField(max_length=100, blank=True, default="")
    color = models.CharField(max_length=50, blank=True, default="")
    registration_number = models.CharField(max_length=100, unique=True)
    seat_capacity = models.PositiveIntegerField(default=1)
    is_active = models.BooleanField(default=True)
    is_default = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-is_default", "-updated_at"]

    def __str__(self):
        return f"{self.registration_number}"

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        if self.is_default:
            Vehicle.objects.filter(driver=self.driver).exclude(id=self.id).update(
                is_default=False
            )
        elif (
            not Vehicle.objects.filter(driver=self.driver, is_default=True)
            .exclude(id=self.id)
            .exists()
        ):
            Vehicle.objects.filter(id=self.id).update(is_default=True)
            self.is_default = True


class FareConfig(models.Model):
    vehicle_type = models.CharField(
        max_length=20, choices=Vehicle.VEHICLE_TYPE_CHOICES, unique=True
    )
    base_fare = models.DecimalField(
        max_digits=8, decimal_places=2, default=Decimal("25.00")
    )
    per_km_rate = models.DecimalField(
        max_digits=8, decimal_places=2, default=Decimal("12.00")
    )
    per_minute_rate = models.DecimalField(
        max_digits=8, decimal_places=2, default=Decimal("1.50")
    )
    minimum_fare = models.DecimalField(
        max_digits=8, decimal_places=2, default=Decimal("40.00")
    )
    booking_fee = models.DecimalField(
        max_digits=8, decimal_places=2, default=Decimal("5.00")
    )
    cancellation_fee = models.DecimalField(
        max_digits=8, decimal_places=2, default=Decimal("15.00")
    )
    surge_multiplier = models.DecimalField(
        max_digits=5, decimal_places=2, default=Decimal("1.00")
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["vehicle_type"]

    def __str__(self):
        return f"FareConfig({self.vehicle_type})"


class FareDistanceTier(models.Model):
    """Distance-based tiered per-km pricing.
    Example: 0-5km @12tk, 5-100km @10tk, 100-200km @8tk
    """

    fare_config = models.ForeignKey(
        FareConfig, on_delete=models.CASCADE, related_name="distance_tiers"
    )
    min_km = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        help_text="Tier starts at this distance (km). Inclusive.",
    )
    max_km = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        help_text="Tier ends at this distance (km). Exclusive. Use 9999 for unlimited.",
    )
    per_km_rate = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        help_text="Per-km rate for this tier (৳).",
    )

    class Meta:
        ordering = ["fare_config", "min_km"]
        unique_together = [("fare_config", "min_km")]

    def __str__(self):
        return f"{self.fare_config.vehicle_type}: {self.min_km}-{self.max_km} km @ ৳{self.per_km_rate}/km"


class RideshareSettings(models.Model):
    platform_fee_percent = models.DecimalField(
        max_digits=5, decimal_places=2, default=Decimal("5.00")
    )
    driver_response_timeout_seconds = models.PositiveIntegerField(default=60)
    max_search_window_minutes = models.PositiveIntegerField(default=15)
    max_passenger_search_radius_km = models.DecimalField(
        max_digits=6,
        decimal_places=2,
        default=Decimal("15.00"),
        help_text="Maximum distance (km) from pickup to search for drivers. Prevents rural ultra-long matches.",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Rideshare Settings"
        verbose_name_plural = "Rideshare Settings"

    def __str__(self):
        return "Rideshare Settings"


class Ride(models.Model):
    STATUS_REQUESTED = "requested"
    STATUS_SEARCHING = "searching_driver"
    STATUS_ACCEPTED = "accepted"
    STATUS_DRIVER_ARRIVING = "driver_arriving"
    STATUS_IN_PROGRESS = "in_progress"
    STATUS_AWAITING_CONFIRMATION = "awaiting_passenger_confirmation"
    STATUS_COMPLETED = "completed"
    STATUS_CANCELLED = "cancelled"

    STATUS_CHOICES = [
        (STATUS_REQUESTED, "Requested"),
        (STATUS_SEARCHING, "Searching Driver"),
        (STATUS_ACCEPTED, "Accepted"),
        (STATUS_DRIVER_ARRIVING, "Driver Arriving"),
        (STATUS_IN_PROGRESS, "In Progress"),
        (STATUS_AWAITING_CONFIRMATION, "Awaiting Passenger Confirmation"),
        (STATUS_COMPLETED, "Completed"),
        (STATUS_CANCELLED, "Cancelled"),
    ]

    VALID_TRANSITIONS = {
        STATUS_REQUESTED: [STATUS_SEARCHING, STATUS_CANCELLED],
        STATUS_SEARCHING: [STATUS_ACCEPTED, STATUS_CANCELLED],
        STATUS_ACCEPTED: [STATUS_DRIVER_ARRIVING, STATUS_CANCELLED],
        STATUS_DRIVER_ARRIVING: [STATUS_IN_PROGRESS, STATUS_CANCELLED],
        STATUS_IN_PROGRESS: [
            STATUS_AWAITING_CONFIRMATION,
            STATUS_COMPLETED,
            STATUS_CANCELLED,
        ],
        STATUS_AWAITING_CONFIRMATION: [
            STATUS_IN_PROGRESS,
            STATUS_COMPLETED,
            STATUS_CANCELLED,
        ],
        STATUS_COMPLETED: [],
        STATUS_CANCELLED: [],
    }

    PAYMENT_STATUS_CHOICES = [
        ("pending", "Pending"),
        ("completed", "Completed"),
        ("failed", "Failed"),
        ("refunded", "Refunded"),
    ]

    PAYMENT_METHOD_WALLET = "wallet"
    PAYMENT_METHOD_CASH = "cash"
    PAYMENT_METHOD_CHOICES = [
        (PAYMENT_METHOD_WALLET, "Wallet"),
        (PAYMENT_METHOD_CASH, "Cash"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    rider = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="rides_requested",
    )
    assigned_driver = models.ForeignKey(
        DriverProfile,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="rides_assigned",
    )
    targeted_driver = models.ForeignKey(
        DriverProfile,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="rides_targeted",
    )
    vehicle = models.ForeignKey(
        Vehicle, on_delete=models.SET_NULL, null=True, blank=True, related_name="rides"
    )
    payment_transaction = models.ForeignKey(
        "base.Balance",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="rides",
    )
    requested_vehicle_type = models.CharField(
        max_length=20, choices=Vehicle.VEHICLE_TYPE_CHOICES, default="bike"
    )
    targeted_at = models.DateTimeField(null=True, blank=True)
    dispatch_attempt = models.PositiveIntegerField(default=0)
    search_expires_at = models.DateTimeField(null=True, blank=True)
    pickup_latitude = models.DecimalField(max_digits=9, decimal_places=6)
    pickup_longitude = models.DecimalField(max_digits=9, decimal_places=6)
    drop_latitude = models.DecimalField(max_digits=9, decimal_places=6)
    drop_longitude = models.DecimalField(max_digits=9, decimal_places=6)
    pickup_address = models.CharField(max_length=255)
    drop_address = models.CharField(max_length=255)
    distance_km = models.DecimalField(
        max_digits=8, decimal_places=2, default=Decimal("0.00")
    )
    duration_seconds = models.PositiveIntegerField(default=0)
    route_geometry = models.JSONField(default=dict, blank=True)
    fare_estimate = models.DecimalField(
        max_digits=10, decimal_places=2, default=Decimal("0.00")
    )
    final_fare = models.DecimalField(
        max_digits=10, decimal_places=2, null=True, blank=True
    )
    platform_fee_percent = models.DecimalField(
        max_digits=5, decimal_places=2, default=Decimal("0.00")
    )
    platform_fee_amount = models.DecimalField(
        max_digits=10, decimal_places=2, default=Decimal("0.00")
    )
    driver_payout_amount = models.DecimalField(
        max_digits=10, decimal_places=2, default=Decimal("0.00")
    )
    status = models.CharField(
        max_length=40, choices=STATUS_CHOICES, default=STATUS_REQUESTED
    )
    payment_status = models.CharField(
        max_length=20, choices=PAYMENT_STATUS_CHOICES, default="pending"
    )
    payment_method = models.CharField(
        max_length=20,
        choices=PAYMENT_METHOD_CHOICES,
        default=PAYMENT_METHOD_WALLET,
    )
    driver_due_amount = models.DecimalField(
        max_digits=10, decimal_places=2, default=Decimal("0.00")
    )
    driver_due_settled_at = models.DateTimeField(null=True, blank=True)
    cancellation_reason = models.TextField(blank=True, default="")
    early_completion_requested_at = models.DateTimeField(null=True, blank=True)
    early_completion_distance_km = models.DecimalField(
        max_digits=8, decimal_places=2, null=True, blank=True
    )
    early_completion_duration_seconds = models.PositiveIntegerField(default=0)
    early_completion_fare = models.DecimalField(
        max_digits=10, decimal_places=2, null=True, blank=True
    )
    requested_at = models.DateTimeField(auto_now_add=True)
    accepted_at = models.DateTimeField(null=True, blank=True)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    cancelled_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["status"]),
            models.Index(fields=["rider"]),
            models.Index(fields=["assigned_driver"]),
            models.Index(fields=["created_at"]),
        ]

    def __str__(self):
        return f"Ride({self.id})"

    @property
    def is_active(self):
        return self.status in {
            self.STATUS_REQUESTED,
            self.STATUS_SEARCHING,
            self.STATUS_ACCEPTED,
            self.STATUS_DRIVER_ARRIVING,
            self.STATUS_IN_PROGRESS,
            self.STATUS_AWAITING_CONFIRMATION,
        }

    def can_transition_to(self, next_status):
        return next_status in self.VALID_TRANSITIONS.get(self.status, [])

    def transition_to(self, next_status, actor=None, metadata=None):
        if next_status == self.status:
            return self
        if not self.can_transition_to(next_status):
            raise ValidationError(
                f"Invalid ride status transition from {self.status} to {next_status}"
            )

        now = timezone.now()
        self.status = next_status
        if next_status == self.STATUS_ACCEPTED and not self.accepted_at:
            self.accepted_at = now
        elif next_status == self.STATUS_IN_PROGRESS and not self.started_at:
            self.started_at = now
        elif next_status == self.STATUS_COMPLETED and not self.completed_at:
            self.completed_at = now
        elif next_status == self.STATUS_CANCELLED and not self.cancelled_at:
            self.cancelled_at = now

        self.save(
            update_fields=[
                "status",
                "accepted_at",
                "started_at",
                "completed_at",
                "cancelled_at",
                "updated_at",
            ]
        )
        RideStatusHistory.objects.create(
            ride=self, status=next_status, actor=actor, metadata=metadata or {}
        )
        return self


class RideStatusHistory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    ride = models.ForeignKey(
        Ride, on_delete=models.CASCADE, related_name="status_history"
    )
    status = models.CharField(max_length=40, choices=Ride.STATUS_CHOICES)
    actor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="ride_status_actions",
    )
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"{self.ride_id}:{self.status}"


class RideCancellationReport(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    ride = models.ForeignKey(
        Ride, on_delete=models.CASCADE, related_name="cancellation_reports"
    )
    reporter = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="ride_cancellation_reports",
    )
    reported_driver = models.ForeignKey(
        DriverProfile,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="cancellation_reports",
    )
    details = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        unique_together = ("ride", "reporter")

    def __str__(self):
        return f"RideCancellationReport({self.ride_id}, {self.reporter_id})"


class DriverLocation(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    driver = models.ForeignKey(
        DriverProfile, on_delete=models.CASCADE, related_name="locations"
    )
    ride = models.ForeignKey(
        Ride,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="driver_locations",
    )
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    heading = models.DecimalField(max_digits=6, decimal_places=2, null=True, blank=True)
    speed_kph = models.DecimalField(
        max_digits=6, decimal_places=2, null=True, blank=True
    )
    accuracy_meters = models.DecimalField(
        max_digits=6, decimal_places=2, null=True, blank=True
    )
    recorded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-recorded_at"]
        indexes = [
            models.Index(fields=["driver", "-recorded_at"]),
        ]

    def __str__(self):
        return f"DriverLocation({self.driver_id}, {self.recorded_at})"
