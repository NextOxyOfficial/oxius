from rest_framework import serializers

from base.models import User

from .models import DriverLocation, DriverProfile, Ride, RideStatusHistory, Vehicle


class RideUserSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ["id", "username", "name", "first_name", "last_name", "phone", "image"]

    def get_image(self, obj):
        if not obj.image:
            return None
        request = self.context.get("request")
        if request:
            return request.build_absolute_uri(obj.image.url)
        return obj.image.url


class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = [
            "id",
            "vehicle_type",
            "brand",
            "model_name",
            "color",
            "registration_number",
            "seat_capacity",
            "is_active",
            "is_default",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class DriverProfileSerializer(serializers.ModelSerializer):
    user = RideUserSerializer(read_only=True)
    default_vehicle = serializers.SerializerMethodField()

    class Meta:
        model = DriverProfile
        fields = [
            "user",
            "license_number",
            "national_id_number",
            "approval_status",
            "is_online",
            "is_available",
            "service_radius_km",
            "current_latitude",
            "current_longitude",
            "last_location_at",
            "total_trips",
            "total_earnings",
            "default_vehicle",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "approval_status",
            "is_online",
            "is_available",
            "current_latitude",
            "current_longitude",
            "last_location_at",
            "total_trips",
            "total_earnings",
            "created_at",
            "updated_at",
        ]

    def get_default_vehicle(self, obj):
        vehicle = obj.vehicles.filter(is_active=True, is_default=True).first()
        if not vehicle:
            vehicle = obj.vehicles.filter(is_active=True).first()
        return VehicleSerializer(vehicle).data if vehicle else None


class RideStatusHistorySerializer(serializers.ModelSerializer):
    actor = RideUserSerializer(read_only=True)

    class Meta:
        model = RideStatusHistory
        fields = ["id", "status", "actor", "metadata", "created_at"]


class DriverLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = DriverLocation
        fields = [
            "id",
            "latitude",
            "longitude",
            "heading",
            "speed_kph",
            "accuracy_meters",
            "recorded_at",
        ]


class RideSerializer(serializers.ModelSerializer):
    rider = RideUserSerializer(read_only=True)
    assigned_driver = DriverProfileSerializer(read_only=True)
    vehicle = VehicleSerializer(read_only=True)
    latest_driver_location = serializers.SerializerMethodField()
    status_history = RideStatusHistorySerializer(many=True, read_only=True)

    class Meta:
        model = Ride
        fields = [
            "id",
            "rider",
            "assigned_driver",
            "vehicle",
            "requested_vehicle_type",
            "pickup_latitude",
            "pickup_longitude",
            "drop_latitude",
            "drop_longitude",
            "pickup_address",
            "drop_address",
            "distance_km",
            "duration_seconds",
            "route_geometry",
            "fare_estimate",
            "final_fare",
            "status",
            "payment_status",
            "cancellation_reason",
            "requested_at",
            "accepted_at",
            "started_at",
            "completed_at",
            "cancelled_at",
            "created_at",
            "updated_at",
            "latest_driver_location",
            "status_history",
        ]

    def get_latest_driver_location(self, obj):
        latest = obj.driver_locations.order_by("-recorded_at").first()
        return DriverLocationSerializer(latest).data if latest else None


class RideEstimateRequestSerializer(serializers.Serializer):
    pickup_latitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    pickup_longitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    drop_latitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    drop_longitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    pickup_address = serializers.CharField(max_length=255, required=False, allow_blank=True)
    drop_address = serializers.CharField(max_length=255, required=False, allow_blank=True)
    vehicle_type = serializers.ChoiceField(choices=Vehicle.VEHICLE_TYPE_CHOICES, default="bike")


class RideCreateSerializer(RideEstimateRequestSerializer):
    pass


class RideCancelSerializer(serializers.Serializer):
    reason = serializers.CharField(required=False, allow_blank=True, max_length=500)


class RideStatusUpdateSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=Ride.STATUS_CHOICES)
    final_fare = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)


class DriverToggleOnlineSerializer(serializers.Serializer):
    is_online = serializers.BooleanField()


class DriverLocationUpdateSerializer(serializers.Serializer):
    ride_id = serializers.UUIDField(required=False)
    latitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    longitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    heading = serializers.DecimalField(max_digits=6, decimal_places=2, required=False)
    speed_kph = serializers.DecimalField(max_digits=6, decimal_places=2, required=False)
    accuracy_meters = serializers.DecimalField(max_digits=6, decimal_places=2, required=False)
