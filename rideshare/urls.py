from django.urls import path

from .views import (
    ActiveRideView,
    AvailableRideRequestListView,
    DriverEarningsSummaryView,
    DriverLocationUpdateView,
    DriverProfileView,
    DriverToggleOnlineView,
    EstimateRideView,
    LocationSearchView,
    NearbyDriversView,
    ReverseGeocodeView,
    RideAcceptView,
    RideCancelView,
    RideCancellationReportView,
    RideConfirmEarlyCompletionView,
    RideCreateView,
    RideDetailView,
    RideEarlyCompleteView,
    RideListView,
    RideSkipView,
    RideStatusUpdateView,
    VehicleDetailView,
    VehicleListCreateView,
)

urlpatterns = [
    path("estimate/", EstimateRideView.as_view(), name="rides-estimate"),
    path("create/", RideCreateView.as_view(), name="rides-create"),
    path("", RideListView.as_view(), name="rides-list"),
    path("active/", ActiveRideView.as_view(), name="rides-active"),
    path(
        "location/search/", LocationSearchView.as_view(), name="rides-location-search"
    ),
    path(
        "location/reverse/", ReverseGeocodeView.as_view(), name="rides-location-reverse"
    ),
    path(
        "location/nearby-drivers/",
        NearbyDriversView.as_view(),
        name="rides-nearby-drivers",
    ),
    path("drivers/profile/", DriverProfileView.as_view(), name="rides-driver-profile"),
    path(
        "drivers/toggle-online/",
        DriverToggleOnlineView.as_view(),
        name="rides-driver-toggle-online",
    ),
    path(
        "drivers/location/update/",
        DriverLocationUpdateView.as_view(),
        name="rides-driver-location-update",
    ),
    path(
        "drivers/earnings-summary/",
        DriverEarningsSummaryView.as_view(),
        name="rides-driver-earnings-summary",
    ),
    path(
        "drivers/vehicles/",
        VehicleListCreateView.as_view(),
        name="rides-driver-vehicles",
    ),
    path(
        "drivers/vehicles/<uuid:id>/",
        VehicleDetailView.as_view(),
        name="rides-driver-vehicle-detail",
    ),
    path(
        "driver/available/",
        AvailableRideRequestListView.as_view(),
        name="rides-driver-available",
    ),
    path("<uuid:id>/", RideDetailView.as_view(), name="rides-detail"),
    path("<uuid:id>/accept/", RideAcceptView.as_view(), name="rides-accept"),
    path("<uuid:id>/skip/", RideSkipView.as_view(), name="rides-skip"),
    path("<uuid:id>/cancel/", RideCancelView.as_view(), name="rides-cancel"),
    path(
        "<uuid:id>/report-cancellation/",
        RideCancellationReportView.as_view(),
        name="rides-report-cancellation",
    ),
    path(
        "<uuid:id>/early-complete/",
        RideEarlyCompleteView.as_view(),
        name="rides-early-complete",
    ),
    path(
        "<uuid:id>/confirm-early-complete/",
        RideConfirmEarlyCompletionView.as_view(),
        name="rides-confirm-early-complete",
    ),
    path(
        "<uuid:id>/status/", RideStatusUpdateView.as_view(), name="rides-status-update"
    ),
]
