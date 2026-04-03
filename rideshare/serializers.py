from decimal import Decimal, ROUND_HALF_UP

from rest_framework import serializers

from base.models import User

from .models import (
    DriverLocation,
    DriverProfile,
    Ride,
    RideCancellationReport,
    RideStatusHistory,
    Vehicle,
)


class RideUserSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()
    completed_trips = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "name",
            "first_name",
            "last_name",
            "phone",
            "image",
            "kyc",
            "is_pro",
            "completed_trips",
        ]

    def get_image(self, obj):
        if not obj.image:
            return None
        request = self.context.get("request")
        if request:
            return request.build_absolute_uri(obj.image.url)
        return obj.image.url

    def get_completed_trips(self, obj):
        return obj.rides_requested.filter(status=Ride.STATUS_COMPLETED).count()


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
    outstanding_cash_due_count = serializers.SerializerMethodField()
    outstanding_cash_due_amount = serializers.SerializerMethodField()
    cash_due_limit_reached = serializers.SerializerMethodField()

    class Meta:
        model = DriverProfile
        fields = [
            "user",
            "license_number",
            "national_id_number",
            "driver_details",
            "additional_documents",
            "approval_status",
            "is_online",
            "is_available",
            "service_radius_km",
            "max_ride_distance_km",
            "current_latitude",
            "current_longitude",
            "last_location_at",
            "total_trips",
            "total_earnings",
            "default_vehicle",
            "outstanding_cash_due_count",
            "outstanding_cash_due_amount",
            "cash_due_limit_reached",
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

    def get_outstanding_cash_due_count(self, obj):
        return obj.outstanding_cash_due_count

    def get_outstanding_cash_due_amount(self, obj):
        return obj.outstanding_cash_due_amount

    def get_cash_due_limit_reached(self, obj):
        return obj.cash_due_limit_reached

    def validate(self, attrs):
        instance = getattr(self, "instance", None)
        immutable_fields = {
            "license_number": "License number",
            "national_id_number": "National ID number",
        }

        for field_name, label in immutable_fields.items():
            if field_name not in attrs:
                continue

            incoming_value = (attrs.get(field_name) or "").strip()
            attrs[field_name] = incoming_value

            if instance is None:
                continue

            existing_value = (getattr(instance, field_name, "") or "").strip()
            if existing_value and incoming_value != existing_value:
                raise serializers.ValidationError(
                    {
                        field_name: f"{label} cannot be changed after it has been submitted.",
                    }
                )

        if "driver_details" in attrs:
            attrs["driver_details"] = (attrs.get("driver_details") or "").strip()

        if "additional_documents" in attrs:
            documents = attrs.get("additional_documents")
            if not isinstance(documents, list):
                raise serializers.ValidationError(
                    {"additional_documents": "Additional documents must be a list."}
                )

            cleaned_documents = []
            for item in documents:
                if not isinstance(item, str):
                    raise serializers.ValidationError(
                        {"additional_documents": "Each document must be a string."}
                    )
                value = item.strip()
                if value:
                    cleaned_documents.append(value)

            if len(cleaned_documents) > 10:
                raise serializers.ValidationError(
                    {"additional_documents": "You can upload up to 10 additional documents."}
                )

            attrs["additional_documents"] = cleaned_documents

        return attrs


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
    targeted_driver = DriverProfileSerializer(read_only=True)
    vehicle = VehicleSerializer(read_only=True)
    latest_driver_location = serializers.SerializerMethodField()
    status_history = RideStatusHistorySerializer(many=True, read_only=True)
    passenger_can_cancel = serializers.SerializerMethodField()
    driver_can_cancel = serializers.SerializerMethodField()
    can_report_driver = serializers.SerializerMethodField()
    targeted_driver_response_expires_at = serializers.SerializerMethodField()

    class Meta:
        model = Ride
        fields = [
            "id",
            "rider",
            "assigned_driver",
            "targeted_driver",
            "vehicle",
            "requested_vehicle_type",
            "targeted_at",
            "targeted_driver_response_expires_at",
            "dispatch_attempt",
            "search_expires_at",
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
            "platform_fee_percent",
            "platform_fee_amount",
            "driver_payout_amount",
            "status",
            "payment_status",
            "payment_method",
            "driver_due_amount",
            "driver_due_settled_at",
            "cancellation_reason",
            "early_completion_requested_at",
            "early_completion_distance_km",
            "early_completion_duration_seconds",
            "early_completion_fare",
            "requested_at",
            "accepted_at",
            "started_at",
            "completed_at",
            "cancelled_at",
            "created_at",
            "updated_at",
            "latest_driver_location",
            "passenger_can_cancel",
            "driver_can_cancel",
            "can_report_driver",
            "status_history",
        ]

    def get_targeted_driver_response_expires_at(self, obj):
        if obj.targeted_at is None or obj.targeted_driver_id is None:
            return None
        from datetime import timedelta
        from .services import get_driver_response_timeout_seconds
        expires = obj.targeted_at + timedelta(seconds=get_driver_response_timeout_seconds())
        return expires.isoformat()

    def get_latest_driver_location(self, obj):
        latest = obj.driver_locations.order_by("-recorded_at").first()
        return DriverLocationSerializer(latest).data if latest else None

    def get_passenger_can_cancel(self, obj):
        return obj.status in [
            Ride.STATUS_REQUESTED,
            Ride.STATUS_SEARCHING,
        ]

    def get_driver_can_cancel(self, obj):
        return obj.status in [
            Ride.STATUS_ACCEPTED,
            Ride.STATUS_DRIVER_ARRIVING,
            Ride.STATUS_IN_PROGRESS,
            Ride.STATUS_AWAITING_CONFIRMATION,
        ]

    def get_can_report_driver(self, obj):
        if obj.status != Ride.STATUS_CANCELLED or not obj.assigned_driver_id:
            return False

        cancel_entry = (
            obj.status_history.filter(status=Ride.STATUS_CANCELLED)
            .order_by("-created_at")
            .first()
        )
        if not cancel_entry:
            return False

        if cancel_entry.metadata.get("cancelled_by") != "driver":
            return False

        request = self.context.get("request")
        if not request or not request.user.is_authenticated:
            return False
        if request.user.id != obj.rider_id:
            return False

        return not RideCancellationReport.objects.filter(
            ride=obj, reporter=request.user
        ).exists()


class RideEstimateRequestSerializer(serializers.Serializer):
    pickup_latitude = serializers.FloatField()
    pickup_longitude = serializers.FloatField()
    drop_latitude = serializers.FloatField()
    drop_longitude = serializers.FloatField()
    pickup_address = serializers.CharField(required=False, allow_blank=True)
    drop_address = serializers.CharField(required=False, allow_blank=True)
    vehicle_type = serializers.ChoiceField(
        choices=Vehicle.VEHICLE_TYPE_CHOICES, default="bike"
    )

    @staticmethod
    def _normalize_coordinate(value, minimum, maximum, label):
        if value < minimum or value > maximum:
            raise serializers.ValidationError(
                {label: f"{label} must be between {minimum} and {maximum}."}
            )
        return Decimal(str(value)).quantize(Decimal("0.000001"), rounding=ROUND_HALF_UP)

    def validate(self, attrs):
        attrs["pickup_latitude"] = self._normalize_coordinate(
            attrs["pickup_latitude"], -90, 90, "pickup_latitude"
        )
        attrs["pickup_longitude"] = self._normalize_coordinate(
            attrs["pickup_longitude"], -180, 180, "pickup_longitude"
        )
        attrs["drop_latitude"] = self._normalize_coordinate(
            attrs["drop_latitude"], -90, 90, "drop_latitude"
        )
        attrs["drop_longitude"] = self._normalize_coordinate(
            attrs["drop_longitude"], -180, 180, "drop_longitude"
        )
        attrs["pickup_address"] = (attrs.get("pickup_address") or "")[:255]
        attrs["drop_address"] = (attrs.get("drop_address") or "")[:255]
        return attrs


class RideCreateSerializer(RideEstimateRequestSerializer):
    payment_method = serializers.ChoiceField(
        choices=Ride.PAYMENT_METHOD_CHOICES,
        required=False,
        default=Ride.PAYMENT_METHOD_WALLET,
    )


class RoutePreviewRequestSerializer(serializers.Serializer):
    origin_latitude = serializers.FloatField()
    origin_longitude = serializers.FloatField()
    destination_latitude = serializers.FloatField()
    destination_longitude = serializers.FloatField()
    origin_address = serializers.CharField(required=False, allow_blank=True)
    destination_address = serializers.CharField(required=False, allow_blank=True)

    def validate(self, attrs):
        attrs["origin_latitude"] = RideEstimateRequestSerializer._normalize_coordinate(
            attrs["origin_latitude"], -90, 90, "origin_latitude"
        )
        attrs["origin_longitude"] = RideEstimateRequestSerializer._normalize_coordinate(
            attrs["origin_longitude"], -180, 180, "origin_longitude"
        )
        attrs[
            "destination_latitude"
        ] = RideEstimateRequestSerializer._normalize_coordinate(
            attrs["destination_latitude"], -90, 90, "destination_latitude"
        )
        attrs[
            "destination_longitude"
        ] = RideEstimateRequestSerializer._normalize_coordinate(
            attrs["destination_longitude"], -180, 180, "destination_longitude"
        )
        attrs["origin_address"] = (attrs.get("origin_address") or "")[:255]
        attrs["destination_address"] = (attrs.get("destination_address") or "")[:255]
        return attrs


class RideCancelSerializer(serializers.Serializer):
    reason = serializers.CharField(required=False, allow_blank=True, max_length=500)


class RideStatusUpdateSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=Ride.STATUS_CHOICES)
    final_fare = serializers.DecimalField(
        max_digits=10, decimal_places=2, required=False
    )
    payment_method = serializers.ChoiceField(
        choices=Ride.PAYMENT_METHOD_CHOICES,
        required=False,
        default=Ride.PAYMENT_METHOD_WALLET,
    )


class RideEarlyCompleteSerializer(serializers.Serializer):
    latitude = serializers.FloatField(required=False)
    longitude = serializers.FloatField(required=False)


class RideConfirmEarlyCompletionSerializer(serializers.Serializer):
    confirm = serializers.BooleanField(default=True)
    payment_method = serializers.ChoiceField(
        choices=Ride.PAYMENT_METHOD_CHOICES,
        required=False,
        default=Ride.PAYMENT_METHOD_WALLET,
    )


class RideCancellationReportSerializer(serializers.Serializer):
    details = serializers.CharField(required=False, allow_blank=True, max_length=1000)


class DriverToggleOnlineSerializer(serializers.Serializer):
    is_online = serializers.BooleanField()


class DriverCashDueSettlementSerializer(serializers.Serializer):
    go_online_after_payment = serializers.BooleanField(required=False, default=False)


class DriverLocationUpdateSerializer(serializers.Serializer):
    ride_id = serializers.UUIDField(required=False)
    latitude = serializers.FloatField()
    longitude = serializers.FloatField()
    heading = serializers.FloatField(required=False)
    speed_kph = serializers.FloatField(required=False)
    accuracy_meters = serializers.FloatField(required=False)

    def validate(self, attrs):
        attrs["latitude"] = round(float(attrs["latitude"]), 6)
        attrs["longitude"] = round(float(attrs["longitude"]), 6)

        if not -90 <= attrs["latitude"] <= 90:
            raise serializers.ValidationError(
                {"latitude": "Latitude must be between -90 and 90."}
            )
        if not -180 <= attrs["longitude"] <= 180:
            raise serializers.ValidationError(
                {"longitude": "Longitude must be between -180 and 180."}
            )

        for field_name in ("heading", "speed_kph", "accuracy_meters"):
            value = attrs.get(field_name)
            if value is None:
                continue
            if value != value or value in (float("inf"), float("-inf")):
                attrs.pop(field_name, None)
                continue
            attrs[field_name] = round(float(value), 2)

        return attrs
