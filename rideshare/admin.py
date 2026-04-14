from django.contrib import admin

from .models import (
    DriverLocation,
    DriverProfile,
    FareConfig,
    FareDistanceTier,
    Ride,
    RideCancellationReport,
    RideshareSettings,
    RideStatusHistory,
    SearchableLocation,
    UserCustomLocation,
    Vehicle,
)


@admin.register(DriverProfile)
class DriverProfileAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "approval_status",
        "is_online",
        "is_available",
        "service_radius_km",
        "max_ride_distance_km",
        "total_trips",
        "total_earnings",
        "updated_at",
    )
    list_filter = ("approval_status", "is_online", "is_available")
    search_fields = ("user__username", "user__email", "user__phone", "license_number")


@admin.register(Vehicle)
class VehicleAdmin(admin.ModelAdmin):
    list_display = (
        "registration_number",
        "driver",
        "vehicle_type",
        "is_default",
        "is_active",
        "updated_at",
    )
    list_filter = ("vehicle_type", "is_default", "is_active")
    search_fields = (
        "registration_number",
        "driver__user__username",
        "brand",
        "model_name",
    )


class FareDistanceTierInline(admin.TabularInline):
    model = FareDistanceTier
    extra = 1
    fields = ("min_km", "max_km", "per_km_rate")


@admin.register(FareConfig)
class FareConfigAdmin(admin.ModelAdmin):
    list_display = (
        "vehicle_type",
        "base_fare",
        "per_km_rate",
        "per_minute_rate",
        "minimum_fare",
        "booking_fee",
        "surge_multiplier",
        "is_active",
    )
    list_filter = ("vehicle_type", "is_active")
    inlines = [FareDistanceTierInline]


@admin.register(RideshareSettings)
class RideshareSettingsAdmin(admin.ModelAdmin):
    list_display = (
        "platform_fee_percent",
        "driver_response_timeout_seconds",
        "max_search_window_minutes",
        "google_maps_key_configured",
        "updated_at",
    )
    readonly_fields = ("google_maps_key_configured",)
    fields = (
        "platform_fee_percent",
        "driver_response_timeout_seconds",
        "max_search_window_minutes",
        "google_maps_api_key",
        "google_maps_key_configured",
    )

    @admin.display(boolean=True, description="Google key configured")
    def google_maps_key_configured(self, obj):
        return bool(obj and obj.google_maps_api_key.strip())


@admin.register(SearchableLocation)
class SearchableLocationAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "subtitle",
        "latitude",
        "longitude",
        "is_active",
        "updated_at",
    )
    list_filter = ("is_active",)
    search_fields = ("name", "subtitle", "search_keywords")
    list_editable = ("is_active",)
    fields = (
        "name",
        "subtitle",
        "search_keywords",
        "latitude",
        "longitude",
        "is_active",
    )
    ordering = ("name", "subtitle")


@admin.register(UserCustomLocation)
class UserCustomLocationAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "name",
        "subtitle",
        "fee_paid",
        "is_active",
        "updated_at",
    )
    list_filter = ("is_active", "created_at", "updated_at")
    search_fields = ("user__username", "user__phone", "name", "subtitle", "search_keywords")
    list_editable = ("is_active",)
    autocomplete_fields = ("user",)
    readonly_fields = ("payment_transaction", "fee_paid", "created_at", "updated_at")
    fields = (
        "user",
        "name",
        "subtitle",
        "search_keywords",
        "latitude",
        "longitude",
        "payment_transaction",
        "fee_paid",
        "is_active",
        "created_at",
        "updated_at",
    )


class RideStatusHistoryInline(admin.TabularInline):
    model = RideStatusHistory
    extra = 0
    readonly_fields = ("status", "actor", "metadata", "created_at")


@admin.register(Ride)
class RideAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "rider",
        "assigned_driver",
        "requested_vehicle_type",
        "status",
        "fare_estimate",
        "final_fare",
        "payment_status",
        "created_at",
    )
    list_filter = ("status", "requested_vehicle_type", "payment_status")
    search_fields = (
        "id",
        "rider__username",
        "rider__email",
        "pickup_address",
        "drop_address",
    )
    readonly_fields = (
        "created_at",
        "updated_at",
        "requested_at",
        "accepted_at",
        "started_at",
        "completed_at",
        "cancelled_at",
    )
    inlines = [RideStatusHistoryInline]


@admin.register(DriverLocation)
class DriverLocationAdmin(admin.ModelAdmin):
    list_display = ("driver", "ride", "latitude", "longitude", "recorded_at")
    list_filter = ("recorded_at",)
    search_fields = ("driver__user__username", "ride__id")


@admin.register(RideCancellationReport)
class RideCancellationReportAdmin(admin.ModelAdmin):
    list_display = ("ride", "reporter", "reported_driver", "created_at")
    search_fields = (
        "ride__id",
        "reporter__username",
        "reported_driver__user__username",
    )
    readonly_fields = ("ride", "reporter", "reported_driver", "details", "created_at")
