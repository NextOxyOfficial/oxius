import logging
from datetime import timedelta
from decimal import Decimal

from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import transaction
from django.db.models import Q, Sum
from django.shortcuts import get_object_or_404
from django.http import Http404
from django.utils import timezone
from rest_framework import generics, status
from rest_framework.exceptions import APIException, PermissionDenied, ValidationError
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import DriverProfile, Ride, Vehicle
from .permissions import IsApprovedDriver
from .serializers import (
    DriverCashDueSettlementSerializer,
    DriverLocationUpdateSerializer,
    DriverProfileSerializer,
    DriverToggleOnlineSerializer,
    RideCancellationReportSerializer,
    RideCancelSerializer,
    RideCreateSerializer,
    RideEarlyCompleteSerializer,
    RideConfirmEarlyCompletionSerializer,
    RideSerializer,
    RideStatusUpdateSerializer,
    RideEstimateRequestSerializer,
    VehicleSerializer,
)
from .services import (
    assign_driver_to_ride,
    attempt_auto_assign_driver,
    check_driver_has_active_ride,
    check_user_has_active_ride,
    DispatchService,
    DriverLocationService,
    EarlyCompletionService,
    FareService,
    get_user_active_ride,
    get_driver_response_timeout_seconds,
    get_max_search_window_minutes,
    get_rideshare_settings,
    LocationService,
    NearestDriverDispatch,
    RideAutoCancel,
    RideNotificationService,
    RoutingService,
    WalletService,
    get_driver_default_vehicle,
)


logger = logging.getLogger(__name__)


def api_success(data=None, message="Success", status_code=status.HTTP_200_OK):
    return Response(
        {"success": True, "message": message, "data": data}, status=status_code
    )


def api_error(message, status_code=status.HTTP_400_BAD_REQUEST, errors=None):
    payload = {"success": False, "message": message}
    if errors is not None:
        payload["errors"] = errors
    return Response(payload, status=status_code)


def first_error_message(errors):
    if isinstance(errors, dict):
        first_value = next(iter(errors.values()), None)
        return first_error_message(first_value)
    if isinstance(errors, (list, tuple)):
        return first_error_message(errors[0]) if errors else "Validation failed."
    if errors:
        return str(errors)
    return "Validation failed."


class RideshareApiMixin:
    def handle_exception(self, exc):
        if isinstance(exc, Http404):
            return api_error("Resource not found.", status.HTTP_404_NOT_FOUND)
        if isinstance(exc, PermissionDenied):
            return api_error(
                str(exc) or "Permission denied.", status.HTTP_403_FORBIDDEN
            )
        if isinstance(exc, ValidationError):
            return api_error(
                "Validation failed.", status.HTTP_400_BAD_REQUEST, exc.detail
            )
        if isinstance(exc, DjangoValidationError):
            message = exc.message_dict if hasattr(exc, "message_dict") else exc.messages
            return api_error("Validation failed.", status.HTTP_400_BAD_REQUEST, message)
        if isinstance(exc, APIException):
            detail = getattr(exc, "detail", None)
            return api_error(
                str(detail) if detail else "Request failed.", exc.status_code
            )
        logger.exception("Unhandled rideshare API error", exc_info=exc)
        return api_error(
            "Something went wrong. Please try again later.",
            status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


def _cascade_expired_targets_safely():
    """Best-effort cascade trigger for environments where Celery beat is unavailable."""
    try:
        NearestDriverDispatch.check_and_cascade_expired_targets()
    except Exception as exc:
        logger.warning("Inline cascade check failed: %s", exc)


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
        fare = FareService.estimate(
            data["vehicle_type"], route["distance_km"], route["duration_seconds"]
        )

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
                Ride.STATUS_AWAITING_CONFIRMATION,
            ],
        ).first()
        if existing_active_ride:
            return api_error(
                "You already have an active ride.",
                errors={"ride_id": str(existing_active_ride.id)},
            )

        route = RoutingService.get_route(
            data["pickup_latitude"],
            data["pickup_longitude"],
            data["drop_latitude"],
            data["drop_longitude"],
        )
        fare = FareService.estimate(
            data["vehicle_type"], route["distance_km"], route["duration_seconds"]
        )
        settings_obj = get_rideshare_settings()
        search_expires_at = timezone.now() + timedelta(
            minutes=get_max_search_window_minutes()
        )

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
            platform_fee_percent=settings_obj.platform_fee_percent,
            search_expires_at=search_expires_at,
            status=Ride.STATUS_SEARCHING,
        )
        ride.status_history.create(
            status=Ride.STATUS_SEARCHING,
            actor=request.user,
            metadata={"routing_source": route["routing_source"]},
        )

        DispatchService.send_ride_event(
            ride,
            "search_status_updated",
            {
                "message": "Searching for nearby drivers...",
                "dispatch_attempt": ride.dispatch_attempt,
                "driver_response_timeout_seconds": get_driver_response_timeout_seconds(),
                "search_expires_at": search_expires_at.isoformat(),
            },
        )

        # Send push notification to rider
        RideNotificationService.send_ride_notification(
            request.user, "searching_driver", ride
        )

        # Dispatch to nearest driver (1-minute cascade system)
        nearest_driver = NearestDriverDispatch.dispatch_to_nearest_driver(ride)

        DispatchService.send_ride_event(
            ride,
            "ride_created",
            {
                "targeted_driver_id": (
                    str(nearest_driver.id) if nearest_driver else None
                ),
            },
        )
        ride.refresh_from_db()

        # Auto-cancel if no drivers available
        if not nearest_driver:
            RideAutoCancel.cancel_expired_ride(ride)
            return api_success(
                RideSerializer(ride, context={"request": request}).data,
                "No drivers available. Ride cancelled automatically.",
            )

        # If driver was auto-assigned, notify about acceptance
        if ride.assigned_driver:
            RideNotificationService.notify_ride_status_change(ride)

        return api_success(
            RideSerializer(ride, context={"request": request}).data,
            "Ride requested successfully.",
            status.HTTP_201_CREATED,
        )


class RideListView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated]

    def get_queryset(self, request):
        as_driver = request.query_params.get("as_driver") in ["1", "true", "True"]
        queryset = Ride.objects.select_related(
            "rider", "assigned_driver__user", "targeted_driver__user", "vehicle"
        ).prefetch_related("status_history", "driver_locations")
        if request.user.is_superuser:
            return queryset
        if as_driver:
            return queryset.filter(assigned_driver__user=request.user)
        return queryset.filter(
            Q(rider=request.user) | Q(assigned_driver__user=request.user)
        )

    def get(self, request):
        queryset = self.get_queryset(request).order_by("-created_at")
        try:
            page_size = max(1, min(int(request.query_params.get("page_size", 20)), 100))
        except (ValueError, TypeError):
            page_size = 20
        try:
            page = max(1, int(request.query_params.get("page", 1)))
        except (ValueError, TypeError):
            page = 1
        total_count = queryset.count()
        start = (page - 1) * page_size
        end = start + page_size
        page_qs = queryset[start:end]
        serializer = RideSerializer(page_qs, many=True, context={"request": request})
        return api_success({
            "results": serializer.data,
            "count": total_count,
            "page": page,
            "page_size": page_size,
            "has_next": end < total_count,
        })


class ActiveRideView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        _cascade_expired_targets_safely()
        ride = (
            Ride.objects.select_related(
                "rider", "assigned_driver__user", "targeted_driver__user", "vehicle"
            )
            .prefetch_related("status_history", "driver_locations")
            .filter(
                Q(rider=request.user) | Q(assigned_driver__user=request.user),
                status__in=[
                    Ride.STATUS_REQUESTED,
                    Ride.STATUS_SEARCHING,
                    Ride.STATUS_ACCEPTED,
                    Ride.STATUS_DRIVER_ARRIVING,
                    Ride.STATUS_IN_PROGRESS,
                    Ride.STATUS_AWAITING_CONFIRMATION,
                ],
            )
            .order_by("-created_at")
            .first()
        )
        if not ride:
            return api_success(None, "No active ride found.")
        return api_success(RideSerializer(ride, context={"request": request}).data)


class RideDetailView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, id):
        ride = get_object_or_404(
            Ride.objects.select_related(
                "rider", "assigned_driver__user", "targeted_driver__user", "vehicle"
            ).prefetch_related("status_history", "driver_locations"),
            id=id,
        )
        if (
            not request.user.is_superuser
            and ride.rider_id != request.user.id
            and getattr(ride.assigned_driver, "user_id", None) != request.user.id
        ):
            return api_error(
                "You do not have permission to access this ride.",
                status.HTTP_403_FORBIDDEN,
            )
        return api_success(RideSerializer(ride, context={"request": request}).data)


class AvailableRideRequestListView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated, IsApprovedDriver]

    def get(self, request):
        _cascade_expired_targets_safely()
        driver_profile = request.user.driver_profile

        # Only show rides explicitly targeted to this driver (sequential 1-at-a-time dispatch)
        queryset = (
            Ride.objects.filter(
                status=Ride.STATUS_SEARCHING,
                assigned_driver__isnull=True,
                targeted_driver=driver_profile,
            )
            .exclude(
                rider=request.user,
            )
        )

        default_vehicle = get_driver_default_vehicle(driver_profile)
        if default_vehicle:
            queryset = queryset.filter(
                requested_vehicle_type=default_vehicle.vehicle_type
            )
        rides = queryset.select_related("rider").order_by("-created_at")[:20]
        return api_success(
            RideSerializer(rides, many=True, context={"request": request}).data
        )


class RideAcceptView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated, IsApprovedDriver]

    @transaction.atomic
    def post(self, request, id):
        ride = get_object_or_404(
            Ride.objects.select_for_update().select_related("rider"), id=id
        )
        driver_profile = request.user.driver_profile

        if ride.rider_id == request.user.id:
            return api_error(
                "You cannot accept your own ride request.", status.HTTP_403_FORBIDDEN
            )

        # Check if driver already has an active ride
        if check_driver_has_active_ride(driver_profile):
            return api_error(
                "You already have an active ride. Complete it before accepting a new one."
            )

        # Check if this ride is targeted to a specific driver (and it's not this driver)
        if ride.targeted_driver_id and ride.targeted_driver_id != driver_profile.id:
            return api_error("This ride is currently assigned to another driver.")

        try:
            ride = assign_driver_to_ride(
                ride, driver_profile, actor=request.user, assignment_source="manual"
            )
        except DjangoValidationError as exc:
            return api_error(str(exc))

        ride.refresh_from_db()

        # Send push notification to rider about driver acceptance
        RideNotificationService.notify_ride_status_change(ride)

        return api_success(
            RideSerializer(ride, context={"request": request}).data,
            "Ride accepted successfully.",
        )


class RideSkipView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated, IsApprovedDriver]

    @transaction.atomic
    def post(self, request, id):
        ride = get_object_or_404(
            Ride.objects.select_for_update().select_related(
                "rider"
            ),
            id=id,
        )
        driver_profile = request.user.driver_profile

        if ride.status != Ride.STATUS_SEARCHING or ride.assigned_driver_id:
            return api_error("Ride is no longer available.")
        if ride.rider_id == request.user.id:
            return api_error(
                "You cannot skip your own ride request.", status.HTTP_403_FORBIDDEN
            )
        if ride.targeted_driver_id and ride.targeted_driver_id != driver_profile.id:
            return api_error(
                "This ride is currently assigned to another driver.",
                status.HTTP_403_FORBIDDEN,
            )
        if not ride.targeted_driver_id:
            return api_success(None, "Ride skipped.")

        timeout_seconds = get_driver_response_timeout_seconds()
        if ride.targeted_at and ride.targeted_at < timezone.now() - timedelta(
            seconds=timeout_seconds
        ):
            return api_error("This ride request has expired.")

        old_target_id = ride.targeted_driver_id
        old_target_name = (
            ride.targeted_driver.user.name
            or ride.targeted_driver.user.username
            or "Driver"
        )

        ride.targeted_driver = None
        ride.targeted_at = None
        ride.save(update_fields=["targeted_driver", "targeted_at", "updated_at"])

        ride.status_history.create(
            status=ride.status,
            actor=request.user,
            metadata={
                "event": "driver_skipped",
                "targeted_driver_id": str(old_target_id),
                "targeted_driver_name": old_target_name,
            },
        )

        next_driver = NearestDriverDispatch.dispatch_to_nearest_driver(ride)
        if not next_driver and ride.status == Ride.STATUS_SEARCHING and not ride.assigned_driver_id:
            RideAutoCancel.cancel_expired_ride(ride)

        return api_success(None, "Ride skipped.")


class RideCancelView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request, id):
        ride = get_object_or_404(
            Ride.objects.select_for_update().select_related("rider"), id=id
        )
        serializer = RideCancelSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        reason = serializer.validated_data.get("reason") or ""

        is_driver = getattr(ride.assigned_driver, "user_id", None) == request.user.id
        is_rider = ride.rider_id == request.user.id

        if not request.user.is_superuser and not is_rider and not is_driver:
            return api_error(
                "You do not have permission to cancel this ride.",
                status.HTTP_403_FORBIDDEN,
            )
        if ride.status in [Ride.STATUS_COMPLETED, Ride.STATUS_CANCELLED]:
            return api_error("This ride can no longer be cancelled.")
        if is_rider and ride.status in [
            Ride.STATUS_ACCEPTED,
            Ride.STATUS_DRIVER_ARRIVING,
            Ride.STATUS_IN_PROGRESS,
            Ride.STATUS_AWAITING_CONFIRMATION,
        ]:
            return api_error(
                "You cannot cancel a ride after a driver has accepted it."
            )

        cancelled_by = (
            "admin" if request.user.is_superuser else "driver" if is_driver else "rider"
        )
        cancellation_reason = reason or (
            "Cancelled by driver"
            if cancelled_by == "driver"
            else "Cancelled by passenger"
        )

        ride.cancellation_reason = cancellation_reason
        ride.save(update_fields=["cancellation_reason", "updated_at"])
        ride.transition_to(
            Ride.STATUS_CANCELLED,
            actor=request.user,
            metadata={
                "reason": cancellation_reason,
                "cancelled_by": cancelled_by,
            },
        )
        if ride.assigned_driver_id:
            ride.assigned_driver.is_available = True
            ride.assigned_driver.save(update_fields=["is_available", "updated_at"])
        DispatchService.send_ride_event(
            ride,
            "ride_cancelled",
            {
                "reason": cancellation_reason,
                "cancelled_by": cancelled_by,
            },
        )

        # Send push notification about cancellation
        RideNotificationService.notify_ride_status_change(ride)

        return api_success(
            RideSerializer(ride, context={"request": request}).data,
            "Ride cancelled successfully.",
        )


class RideStatusUpdateView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request, id):
        ride = get_object_or_404(
            Ride.objects.select_for_update().select_related("rider"), id=id
        )
        serializer = RideStatusUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        next_status = serializer.validated_data["status"]

        is_driver = getattr(ride.assigned_driver, "user_id", None) == request.user.id
        is_rider = ride.rider_id == request.user.id
        if not request.user.is_superuser and not is_driver and not is_rider:
            return api_error(
                "You do not have permission to update this ride.",
                status.HTTP_403_FORBIDDEN,
            )

        if next_status in [
            Ride.STATUS_ACCEPTED,
            Ride.STATUS_CANCELLED,
            Ride.STATUS_SEARCHING,
            Ride.STATUS_REQUESTED,
        ]:
            return api_error(
                "Use the dedicated accept or cancel endpoints for this action."
            )

        if next_status in [
            Ride.STATUS_DRIVER_ARRIVING,
            Ride.STATUS_IN_PROGRESS,
            Ride.STATUS_COMPLETED,
        ] and not (is_driver or request.user.is_superuser):
            return api_error(
                "Only the assigned driver can set this status.",
                status.HTTP_403_FORBIDDEN,
            )

        if next_status == Ride.STATUS_AWAITING_CONFIRMATION:
            return api_error(
                "Use the dedicated early completion endpoint for this action."
            )

        if next_status == Ride.STATUS_COMPLETED:
            payment_method = serializer.validated_data.get(
                "payment_method", Ride.PAYMENT_METHOD_WALLET
            )
            if ride.status == Ride.STATUS_AWAITING_CONFIRMATION:
                return api_error(
                    "Passenger confirmation is required before completing this early-finished ride."
                )

            payable_amount = ride.fare_estimate
            if (
                request.user.is_superuser
                and serializer.validated_data.get("final_fare") is not None
            ):
                payable_amount = serializer.validated_data["final_fare"]

            ride.final_fare = payable_amount
            ride.save(update_fields=["final_fare", "updated_at"])
            if (
                payment_method == Ride.PAYMENT_METHOD_WALLET
                and not ride.payment_transaction_id
                and ride.rider.balance < ride.final_fare
            ):
                return api_error("Insufficient wallet balance to complete this ride.")

        try:
            if next_status == Ride.STATUS_COMPLETED:
                WalletService.complete_ride_payment(
                    ride,
                    amount=ride.final_fare,
                    payment_method=payment_method,
                )
            ride.transition_to(next_status, actor=request.user)
        except DjangoValidationError as exc:
            return api_error(str(exc))
        if ride.assigned_driver_id and next_status in [
            Ride.STATUS_COMPLETED,
            Ride.STATUS_CANCELLED,
        ]:
            ride.assigned_driver.is_available = True
            ride.assigned_driver.save(update_fields=["is_available", "updated_at"])

        event_payload = {"status": ride.status}
        if next_status == Ride.STATUS_COMPLETED:
            event_payload.update(
                {
                    "final_fare": str(ride.final_fare),
                    "payment_method": ride.payment_method,
                    "platform_fee_amount": str(ride.platform_fee_amount),
                    "driver_payout_amount": str(ride.driver_payout_amount),
                    "driver_due_amount": str(ride.driver_due_amount),
                }
            )
        DispatchService.send_ride_event(ride, "ride_status_updated", event_payload)

        # Send push notification about status change
        RideNotificationService.notify_ride_status_change(ride)

        return api_success(
            RideSerializer(ride, context={"request": request}).data,
            "Ride status updated successfully.",
        )


class RideEarlyCompleteView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated, IsApprovedDriver]

    @transaction.atomic
    def post(self, request, id):
        ride = get_object_or_404(
            Ride.objects.select_for_update()
            .select_related("rider", "assigned_driver__user")
            .prefetch_related("driver_locations"),
            id=id,
        )
        serializer = RideEarlyCompleteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            ride = EarlyCompletionService.request(
                ride,
                request.user.driver_profile,
                latitude=serializer.validated_data.get("latitude"),
                longitude=serializer.validated_data.get("longitude"),
            )
        except DjangoValidationError as exc:
            return api_error(str(exc))

        return api_success(
            RideSerializer(ride, context={"request": request}).data,
            "Early completion request sent to the passenger.",
        )


class RideConfirmEarlyCompletionView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request, id):
        ride = get_object_or_404(
            Ride.objects.select_for_update()
            .select_related("rider", "assigned_driver__user")
            .prefetch_related("driver_locations"),
            id=id,
        )
        if not request.user.is_superuser and ride.rider_id != request.user.id:
            return api_error(
                "Only the passenger can confirm this early completion.",
                status.HTTP_403_FORBIDDEN,
            )

        serializer = RideConfirmEarlyCompletionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            ride = EarlyCompletionService.confirm(
                ride,
                request.user,
                confirm=serializer.validated_data["confirm"],
                payment_method=serializer.validated_data.get(
                    "payment_method", Ride.PAYMENT_METHOD_WALLET
                ),
            )
        except DjangoValidationError as exc:
            return api_error(str(exc))

        message = (
            "Ride completed successfully."
            if serializer.validated_data["confirm"]
            else "Ride will continue until the passenger is ready to finish."
        )
        return api_success(
            RideSerializer(ride, context={"request": request}).data, message
        )


class RideCancellationReportView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated]

    @transaction.atomic
    def post(self, request, id):
        ride = get_object_or_404(
            Ride.objects.select_related("assigned_driver__user", "rider"), id=id
        )
        if ride.rider_id != request.user.id:
            return api_error(
                "Only the passenger can report a cancelled ride.",
                status.HTTP_403_FORBIDDEN,
            )
        if ride.status != Ride.STATUS_CANCELLED:
            return api_error("This ride has not been cancelled.")

        cancel_entry = (
            ride.status_history.filter(status=Ride.STATUS_CANCELLED)
            .order_by("-created_at")
            .first()
        )
        if not cancel_entry or cancel_entry.metadata.get("cancelled_by") != "driver":
            return api_error(
                "Driver reporting is only available when the driver cancels the ride."
            )

        serializer = RideCancellationReportSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        report, created = ride.cancellation_reports.get_or_create(
            reporter=request.user,
            defaults={
                "reported_driver": ride.assigned_driver,
                "details": serializer.validated_data.get("details") or "",
            },
        )
        if not created:
            return api_error("You have already reported this cancellation.")

        DispatchService.send_ride_event(
            ride,
            "driver_cancellation_reported",
            {
                "reporter_id": str(request.user.id),
            },
        )
        return api_success(
            {"id": str(report.id)},
            "Driver report submitted successfully.",
            status.HTTP_201_CREATED,
        )


class DriverProfileView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            driver_profile = DriverProfile.objects.get(user=request.user)
        except DriverProfile.DoesNotExist:
            return api_error(
                "No driver profile found. Please apply to become a driver first.",
                status.HTTP_404_NOT_FOUND,
            )
        return api_success(
            DriverProfileSerializer(driver_profile, context={"request": request}).data
        )

    def put(self, request):
        try:
            driver_profile = DriverProfile.objects.get(user=request.user)
        except DriverProfile.DoesNotExist:
            return api_error(
                "No driver profile found. Please apply to become a driver first.",
                status.HTTP_404_NOT_FOUND,
            )
        serializer = DriverProfileSerializer(
            driver_profile,
            data=request.data,
            partial=True,
            context={"request": request},
        )
        if not serializer.is_valid():
            return api_error(
                first_error_message(serializer.errors),
                status.HTTP_400_BAD_REQUEST,
                serializer.errors,
            )
        serializer.save()
        return api_success(serializer.data, "Driver profile updated successfully.")


class DriverApplyView(RideshareApiMixin, APIView):
    """Explicit driver registration — creates a new pending DriverProfile."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        if DriverProfile.objects.filter(user=request.user).exists():
            driver_profile = DriverProfile.objects.get(user=request.user)
            return api_success(
                DriverProfileSerializer(
                    driver_profile, context={"request": request}
                ).data,
                "You already have a driver profile.",
            )

        serializer = DriverProfileSerializer(
            data=request.data, partial=True, context={"request": request}
        )
        if not serializer.is_valid():
            return api_error(
                first_error_message(serializer.errors),
                status.HTTP_400_BAD_REQUEST,
                serializer.errors,
            )
        driver_profile = serializer.save(user=request.user, approval_status="pending")
        return api_success(
            DriverProfileSerializer(driver_profile, context={"request": request}).data,
            "Driver application submitted! Please wait for admin approval.",
            status.HTTP_201_CREATED,
        )


class DriverToggleOnlineView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated, IsApprovedDriver]

    def post(self, request):
        serializer = DriverToggleOnlineSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        driver_profile = request.user.driver_profile
        is_online = serializer.validated_data["is_online"]

        if is_online and not get_driver_default_vehicle(driver_profile):
            return api_error("Add an active vehicle before going online.")

        if is_online and driver_profile.cash_due_limit_reached:
            return api_error(
                "You have unpaid rideshare cash dues. Pay them from your Adsy balance before going online.",
                errors={
                    "outstanding_cash_due_count": driver_profile.outstanding_cash_due_count,
                    "outstanding_cash_due_amount": str(driver_profile.outstanding_cash_due_amount),
                },
            )

        driver_profile.is_online = is_online
        driver_profile.is_available = is_online
        driver_profile.save(update_fields=["is_online", "is_available", "updated_at"])
        return api_success(
            DriverProfileSerializer(driver_profile, context={"request": request}).data,
            "Driver availability updated successfully.",
        )


class DriverCashDueSettlementView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated, IsApprovedDriver]

    @transaction.atomic
    def post(self, request):
        serializer = DriverCashDueSettlementSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        driver_profile = request.user.driver_profile
        try:
            settlement = WalletService.settle_driver_cash_dues(driver_profile)
        except DjangoValidationError as exc:
            return api_error(exc.messages[0] if exc.messages else str(exc))

        driver_profile.refresh_from_db()
        data = DriverProfileSerializer(
            driver_profile, context={"request": request}
        ).data
        data.update(
            {
                "settled_amount": str(settlement["settled_amount"]),
                "settled_count": settlement["settled_count"],
            }
        )
        return api_success(
            data,
            "Cash due paid successfully from your Adsy balance.",
        )


class DriverLocationUpdateView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated, IsApprovedDriver]

    def post(self, request):
        serializer = DriverLocationUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        driver_profile = request.user.driver_profile
        ride = None
        if data.get("ride_id"):
            ride = get_object_or_404(
                Ride, id=data["ride_id"], assigned_driver=driver_profile
            )

        location = DriverLocationService.update_location(
            driver_profile=driver_profile,
            latitude=data["latitude"],
            longitude=data["longitude"],
            ride=ride,
            heading=data.get("heading"),
            speed_kph=data.get("speed_kph"),
            accuracy_meters=data.get("accuracy_meters"),
        )
        return api_success(
            {
                "id": str(location.id),
                "recorded_at": location.recorded_at.isoformat(),
            },
            "Driver location updated successfully.",
        )


class DriverEarningsSummaryView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated, IsApprovedDriver]

    def get(self, request):
        driver_profile = request.user.driver_profile
        completed_rides = Ride.objects.filter(
            assigned_driver=driver_profile, status=Ride.STATUS_COMPLETED
        )
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
        driver_profile = get_object_or_404(DriverProfile, user=request.user)
        vehicles = driver_profile.vehicles.all().order_by("-is_default", "-updated_at")
        return api_success(VehicleSerializer(vehicles, many=True).data)

    def post(self, request):
        driver_profile = get_object_or_404(DriverProfile, user=request.user)
        if driver_profile.approval_status != "approved":
            return api_error(
                "Your KYC must be approved before you can add a vehicle.",
                status.HTTP_403_FORBIDDEN,
            )
        serializer = VehicleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(driver=driver_profile)
        return api_success(
            serializer.data, "Vehicle added successfully.", status.HTTP_201_CREATED
        )


class VehicleDetailView(RideshareApiMixin, APIView):
    permission_classes = [IsAuthenticated]

    # Only allow toggling is_default / is_active; block all other field edits.
    ALLOWED_PATCH_FIELDS = {"is_default", "is_active"}

    def patch(self, request, id):
        driver_profile = get_object_or_404(DriverProfile, user=request.user)
        vehicle = get_object_or_404(Vehicle, id=id, driver=driver_profile)

        blocked_fields = set(request.data.keys()) - self.ALLOWED_PATCH_FIELDS
        if blocked_fields:
            return api_error(
                "Vehicle details cannot be edited. Please contact support to make changes.",
                status.HTTP_403_FORBIDDEN,
            )

        serializer = VehicleSerializer(vehicle, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return api_success(serializer.data, "Vehicle updated successfully.")

    def delete(self, request, id):
        driver_profile = get_object_or_404(DriverProfile, user=request.user)
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
            limit=10,
        )

        drivers_data = [
            {
                "latitude": float(driver.current_latitude),
                "longitude": float(driver.current_longitude),
                "name": f"{driver.vehicle_type.title()} Driver",
                "vehicle_type": driver.vehicle_type,
                "distance": round(float(getattr(driver, "distance", 0.0)), 2),
            }
            for driver in nearby_drivers
            if driver.current_latitude is not None
            and driver.current_longitude is not None
        ]

        return api_success(drivers_data)
