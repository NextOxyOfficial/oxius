from decimal import Decimal

from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import transaction
from django.db.models import Q, Sum
from django.shortcuts import get_object_or_404
from django.http import Http404
from rest_framework import generics, status
from rest_framework.exceptions import APIException, PermissionDenied, ValidationError
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import DriverProfile, Ride, Vehicle
from .permissions import IsApprovedDriver
from .serializers import (
    DriverLocationUpdateSerializer,
    DriverProfileSerializer,
    DriverToggleOnlineSerializer,
    RideCancelSerializer,
    RideCreateSerializer,
    RideSerializer,
    RideStatusUpdateSerializer,
    RideEstimateRequestSerializer,
    VehicleSerializer,
)
from .services import (
    assign_driver_to_ride,
    attempt_auto_assign_driver,
    DispatchService,
    DriverLocationService,
    FareService,
    LocationService,
    RoutingService,
    WalletService,
    get_driver_default_vehicle,
)


def api_success(data=None, message="Success", status_code=status.HTTP_200_OK):
    return Response({"success": True, "message": message, "data": data}, status=status_code)


def api_error(message, status_code=status.HTTP_400_BAD_REQUEST, errors=None):
    payload = {"success": False, "message": message}
    if errors is not None:
        payload["errors"] = errors
    return Response(payload, status=status_code)


class RideshareApiMixin:
    def handle_exception(self, exc):
        if isinstance(exc, Http404):
            return api_error("Resource not found.", status.HTTP_404_NOT_FOUND)
        if isinstance(exc, PermissionDenied):
            return api_error(str(exc) or "Permission denied.", status.HTTP_403_FORBIDDEN)
        if isinstance(exc, ValidationError):
            return api_error("Validation failed.", status.HTTP_400_BAD_REQUEST, exc.detail)
        if isinstance(exc, DjangoValidationError):
            message = exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            return api_error("Validation failed.", status.HTTP_400_BAD_REQUEST, message)
        if isinstance(exc, APIException):
            detail = getattr(exc, "detail", None)
            return api_error(str(detail) if detail else "Request failed.", exc.status_code)
        return super().handle_exception(exc)


class EstimateRideView(RideshareApiMixin, APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RideEstimateRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        route = RoutingService.get_route(
            data["pickup_latitude"],
            data["pickup_longitude"],
            data["drop_latitude"],
            data["drop_longitude"],
        )
        fare = FareService.estimate(data["vehicle_type"], route["distance_km"], route["duration_seconds"])

        response = {
            "vehicle_type": data["vehicle_type"],
            "pickup_address": data.get("pickup_address") or "",
            "drop_address": data.get("drop_address") or "",
            "distance_km": str(route["distance_km"]),
            "eta_seconds": route["duration_seconds"],
            "fare": str(fare),
            "route_geometry": route["route_geometry"],
            "routing_source": route["routing_source"],
        }
        return api_success(response, "Ride estimate generated.")


class RideCreateView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        serializer = RideCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        existing_active_ride = Ride.objects.filter(
            rider=request.user,
            status__in=[
                Ride.STATUS_REQUESTED,
                Ride.STATUS_SEARCHING,
                Ride.STATUS_ACCEPTED,
                Ride.STATUS_DRIVER_ARRIVING,
                Ride.STATUS_IN_PROGRESS,
            ],
        ).first()
        if existing_active_ride:
            return api_error("You already have an active ride.", errors={"ride_id": str(existing_active_ride.id)})

        route = RoutingService.get_route(
            data["pickup_latitude"],
            data["pickup_longitude"],
            data["drop_latitude"],
            data["drop_longitude"],
        )
        fare = FareService.estimate(data["vehicle_type"], route["distance_km"], route["duration_seconds"])

        if request.user.balance < fare:
            return api_error("Insufficient wallet balance for this ride estimate.")

        ride = Ride.objects.create(
            rider=request.user,
            requested_vehicle_type=data["vehicle_type"],
            pickup_latitude=data["pickup_latitude"],
            pickup_longitude=data["pickup_longitude"],
            drop_latitude=data["drop_latitude"],
            drop_longitude=data["drop_longitude"],
            pickup_address=data.get("pickup_address") or "Pinned pickup location",
            drop_address=data.get("drop_address") or "Pinned drop location",
            distance_km=route["distance_km"],
            duration_seconds=route["duration_seconds"],
            route_geometry=route["route_geometry"],
            fare_estimate=fare,
            final_fare=fare,
            status=Ride.STATUS_SEARCHING,
        )
        ride.status_history.create(status=Ride.STATUS_SEARCHING, actor=request.user, metadata={"routing_source": route["routing_source"]})
        DispatchService.broadcast_ride_request(ride)
        attempt_auto_assign_driver(ride)
        DispatchService.send_ride_event(ride, "ride_created")
        ride.refresh_from_db()
        return api_success(RideSerializer(ride, context={"request": request}).data, "Ride requested successfully.", status.HTTP_201_CREATED)


class RideListView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated]

    def get_queryset(self, request):
        as_driver = request.query_params.get("as_driver") in ["1", "true", "True"]
        queryset = Ride.objects.select_related("rider", "assigned_driver__user", "vehicle").prefetch_related("status_history", "driver_locations")
        if request.user.is_superuser:
            return queryset
        if as_driver:
            return queryset.filter(assigned_driver__user=request.user)
        return queryset.filter(Q(rider=request.user) | Q(assigned_driver__user=request.user))

    def get(self, request):
        queryset = self.get_queryset(request)
        serializer = RideSerializer(queryset, many=True, context={"request": request})
        return api_success(serializer.data)


class ActiveRideView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        ride = Ride.objects.select_related("rider", "assigned_driver__user", "vehicle").prefetch_related("status_history", "driver_locations").filter(
            Q(rider=request.user) | Q(assigned_driver__user=request.user),
            status__in=[
                Ride.STATUS_REQUESTED,
                Ride.STATUS_SEARCHING,
                Ride.STATUS_ACCEPTED,
                Ride.STATUS_DRIVER_ARRIVING,
                Ride.STATUS_IN_PROGRESS,
            ],
        ).order_by("-created_at").first()
        if not ride:
            return api_success(None, "No active ride found.")
        return api_success(RideSerializer(ride, context={"request": request}).data)


class RideDetailView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, id):
        ride = get_object_or_404(
            Ride.objects.select_related("rider", "assigned_driver__user", "vehicle").prefetch_related("status_history", "driver_locations"),
            id=id,
        )
        if not request.user.is_superuser and ride.rider_id != request.user.id and getattr(ride.assigned_driver, "user_id", None) != request.user.id:
            return api_error("You do not have permission to access this ride.", status.HTTP_403_FORBIDDEN)
        return api_success(RideSerializer(ride, context={"request": request}).data)


class AvailableRideRequestListView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated, IsApprovedDriver]

    def get(self, request):
        driver_profile = request.user.driver_profile
        queryset = Ride.objects.filter(status=Ride.STATUS_SEARCHING, assigned_driver__isnull=True)
        default_vehicle = get_driver_default_vehicle(driver_profile)
        if default_vehicle:
            queryset = queryset.filter(requested_vehicle_type=default_vehicle.vehicle_type)
        rides = queryset.select_related("rider").order_by("-created_at")[:20]
        return api_success(RideSerializer(rides, many=True, context={"request": request}).data)


class RideAcceptView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated, IsApprovedDriver]

    @transaction.atomic
    def post(self, request, id):
        ride = get_object_or_404(Ride.objects.select_for_update().select_related("rider"), id=id)
        driver_profile = request.user.driver_profile

        try:
            ride = assign_driver_to_ride(ride, driver_profile, actor=request.user, assignment_source="manual")
        except DjangoValidationError as exc:
            return api_error(str(exc))

        ride.refresh_from_db()
        return api_success(RideSerializer(ride, context={"request": request}).data, "Ride accepted successfully.")


class RideCancelView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request, id):
        ride = get_object_or_404(Ride.objects.select_for_update().select_related("rider"), id=id)
        serializer = RideCancelSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        reason = serializer.validated_data.get("reason") or ""

        if not request.user.is_superuser and ride.rider_id != request.user.id and getattr(ride.assigned_driver, "user_id", None) != request.user.id:
            return api_error("You do not have permission to cancel this ride.", status.HTTP_403_FORBIDDEN)
        if ride.status in [Ride.STATUS_COMPLETED, Ride.STATUS_CANCELLED]:
            return api_error("This ride can no longer be cancelled.")

        ride.cancellation_reason = reason
        ride.save(update_fields=["cancellation_reason", "updated_at"])
        ride.transition_to(Ride.STATUS_CANCELLED, actor=request.user, metadata={"reason": reason})
        if ride.assigned_driver_id:
            ride.assigned_driver.is_available = True
            ride.assigned_driver.save(update_fields=["is_available", "updated_at"])
        DispatchService.send_ride_event(ride, "ride_cancelled", {"reason": reason})
        return api_success(RideSerializer(ride, context={"request": request}).data, "Ride cancelled successfully.")


class RideStatusUpdateView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request, id):
        ride = get_object_or_404(Ride.objects.select_for_update().select_related("rider"), id=id)
        serializer = RideStatusUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        next_status = serializer.validated_data["status"]

        is_driver = getattr(ride.assigned_driver, "user_id", None) == request.user.id
        is_rider = ride.rider_id == request.user.id
        if not request.user.is_superuser and not is_driver and not is_rider:
            return api_error("You do not have permission to update this ride.", status.HTTP_403_FORBIDDEN)

        if next_status in [Ride.STATUS_ACCEPTED, Ride.STATUS_CANCELLED, Ride.STATUS_SEARCHING, Ride.STATUS_REQUESTED]:
            return api_error("Use the dedicated accept or cancel endpoints for this action.")

        if next_status in [Ride.STATUS_DRIVER_ARRIVING, Ride.STATUS_IN_PROGRESS, Ride.STATUS_COMPLETED] and not (is_driver or request.user.is_superuser):
            return api_error("Only the assigned driver can set this status.", status.HTTP_403_FORBIDDEN)

        if next_status == Ride.STATUS_COMPLETED:
            ride.final_fare = serializer.validated_data.get("final_fare") or ride.final_fare or ride.fare_estimate
            ride.save(update_fields=["final_fare", "updated_at"])
            if not ride.payment_transaction_id and ride.rider.balance < ride.final_fare:
                return api_error("Insufficient wallet balance to complete this ride.")

        try:
            ride.transition_to(next_status, actor=request.user)
            if next_status == Ride.STATUS_COMPLETED:
                WalletService.complete_ride_payment(ride)
        except DjangoValidationError as exc:
            return api_error(str(exc))
        if ride.assigned_driver_id and next_status in [Ride.STATUS_COMPLETED, Ride.STATUS_CANCELLED]:
            ride.assigned_driver.is_available = True
            ride.assigned_driver.save(update_fields=["is_available", "updated_at"])

        DispatchService.send_ride_event(ride, "ride_status_updated", {"status": ride.status})
        return api_success(RideSerializer(ride, context={"request": request}).data, "Ride status updated successfully.")


class DriverProfileView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        driver_profile, _ = DriverProfile.objects.get_or_create(user=request.user)
        return api_success(DriverProfileSerializer(driver_profile, context={"request": request}).data)

    def put(self, request):
        driver_profile, _ = DriverProfile.objects.get_or_create(user=request.user)
        serializer = DriverProfileSerializer(driver_profile, data=request.data, partial=True, context={"request": request})
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return api_success(serializer.data, "Driver profile updated successfully.")


class DriverToggleOnlineView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated, IsApprovedDriver]

    def post(self, request):
        serializer = DriverToggleOnlineSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        driver_profile = request.user.driver_profile
        is_online = serializer.validated_data["is_online"]

        if is_online and not get_driver_default_vehicle(driver_profile):
            return api_error("Add an active vehicle before going online.")

        driver_profile.is_online = is_online
        driver_profile.is_available = is_online
        driver_profile.save(update_fields=["is_online", "is_available", "updated_at"])
        return api_success(DriverProfileSerializer(driver_profile, context={"request": request}).data, "Driver availability updated successfully.")


class DriverLocationUpdateView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated, IsApprovedDriver]

    def post(self, request):
        serializer = DriverLocationUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        driver_profile = request.user.driver_profile
        ride = None
        if data.get("ride_id"):
            ride = get_object_or_404(Ride, id=data["ride_id"], assigned_driver=driver_profile)

        location = DriverLocationService.update_location(
            driver_profile=driver_profile,
            latitude=data["latitude"],
            longitude=data["longitude"],
            ride=ride,
            heading=data.get("heading"),
            speed_kph=data.get("speed_kph"),
            accuracy_meters=data.get("accuracy_meters"),
        )
        return api_success({
            "id": str(location.id),
            "recorded_at": location.recorded_at.isoformat(),
        }, "Driver location updated successfully.")


class DriverEarningsSummaryView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated, IsApprovedDriver]

    def get(self, request):
        driver_profile = request.user.driver_profile
        completed_rides = Ride.objects.filter(assigned_driver=driver_profile, status=Ride.STATUS_COMPLETED)
        earnings = completed_rides.aggregate(total=Sum("final_fare"))
        summary = {
            "total_trips": completed_rides.count(),
            "total_earnings": str(earnings["total"] or Decimal("0.00")),
            "is_online": driver_profile.is_online,
            "is_available": driver_profile.is_available,
        }
        return api_success(summary)


class VehicleListCreateView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        driver_profile, _ = DriverProfile.objects.get_or_create(user=request.user)
        vehicles = driver_profile.vehicles.all().order_by("-is_default", "-updated_at")
        return api_success(VehicleSerializer(vehicles, many=True).data)

    def post(self, request):
        driver_profile, _ = DriverProfile.objects.get_or_create(user=request.user)
        serializer = VehicleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(driver=driver_profile)
        return api_success(serializer.data, "Vehicle added successfully.", status.HTTP_201_CREATED)


class VehicleDetailView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, id):
        driver_profile, _ = DriverProfile.objects.get_or_create(user=request.user)
        vehicle = get_object_or_404(Vehicle, id=id, driver=driver_profile)
        serializer = VehicleSerializer(vehicle, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return api_success(serializer.data, "Vehicle updated successfully.")

    def delete(self, request, id):
        driver_profile, _ = DriverProfile.objects.get_or_create(user=request.user)
        vehicle = get_object_or_404(Vehicle, id=id, driver=driver_profile)
        vehicle.delete()
        return api_success(None, "Vehicle deleted successfully.")


class LocationSearchView(RideshareApiMixin, APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        query = request.query_params.get("q", "")
        try:
            limit = max(1, min(int(request.query_params.get("limit", 5)), 10))
        except (TypeError, ValueError):
            limit = 5
        return api_success(LocationService.search_places(query, limit=limit))


class ReverseGeocodeView(RideshareApiMixin, APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        lat = request.query_params.get("lat")
        lng = request.query_params.get("lng")
        if lat is None or lng is None:
            return api_error("lat and lng query parameters are required.")
        return api_success(LocationService.reverse_geocode(lat, lng))


class NearbyDriversView(RideshareApiMixin, APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        lat = request.query_params.get("lat")
        lng = request.query_params.get("lng")
        vehicle_type = request.query_params.get("vehicle_type", "bike")
        
        if lat is None or lng is None:
            return api_error("lat and lng query parameters are required.")
        
        try:
            latitude = Decimal(str(lat))
            longitude = Decimal(str(lng))
        except (ValueError, TypeError):
            return api_error("Invalid latitude or longitude.")
        
        # Get nearby online drivers with the requested vehicle type
        nearby_drivers = DriverLocationService.get_nearby_drivers(
            latitude=latitude,
            longitude=longitude,
            radius_km=5,
            vehicle_type=vehicle_type,
            limit=10
        )
        
        drivers_data = [
            {
                "latitude": float(driver.latest_location.latitude),
                "longitude": float(driver.latest_location.longitude),
                "name": f"{driver.vehicle_type.title()} Driver",
                "vehicle_type": driver.vehicle_type,
            }
            for driver in nearby_drivers
            if driver.latest_location
        ]
        
        return api_success(drivers_data)
