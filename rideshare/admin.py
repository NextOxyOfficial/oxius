from django.contrib import admin

from .models import DriverLocation, DriverProfile, FareConfig, Ride, RideStatusHistory, Vehicle


@admin.register(DriverProfile)
class DriverProfileAdmin(admin.ModelAdmin):
    list_display = ("user", "approval_status", "is_online", "is_available", "total_trips", "total_earnings", "updated_at")
    list_filter = ("approval_status", "is_online", "is_available")
    search_fields = ("user__username", "user__email", "user__phone", "license_number")


@admin.register(Vehicle)
class VehicleAdmin(admin.ModelAdmin):
    list_display = ("registration_number", "driver", "vehicle_type", "is_default", "is_active", "updated_at")
    list_filter = ("vehicle_type", "is_default", "is_active")
    search_fields = ("registration_number", "driver__user__username", "brand", "model_name")


@admin.register(FareConfig)
class FareConfigAdmin(admin.ModelAdmin):
    list_display = ("vehicle_type", "base_fare", "per_km_rate", "per_minute_rate", "minimum_fare", "booking_fee", "surge_multiplier", "is_active")
    list_filter = ("vehicle_type", "is_active")


class RideStatusHistoryInline(admin.TabularInline):
    model = RideStatusHistory
    extra = 0
    readonly_fields = ("status", "actor", "metadata", "created_at")


@admin.register(Ride)
class RideAdmin(admin.ModelAdmin):
    list_display = ("id", "rider", "assigned_driver", "requested_vehicle_type", "status", "fare_estimate", "final_fare", "payment_status", "created_at")
    list_filter = ("status", "requested_vehicle_type", "payment_status")
    search_fields = ("id", "rider__username", "rider__email", "pickup_address", "drop_address")
    readonly_fields = ("created_at", "updated_at", "requested_at", "accepted_at", "started_at", "completed_at", "cancelled_at")
    inlines = [RideStatusHistoryInline]


@admin.register(DriverLocation)
class DriverLocationAdmin(admin.ModelAdmin):
    list_display = ("driver", "ride", "latitude", "longitude", "recorded_at")
    list_filter = ("recorded_at",)
    search_fields = ("driver__user__username", "ride__id")
