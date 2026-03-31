from decimal import Decimal, ROUND_HALF_UP
from math import asin, cos, radians, sin, sqrt
import logging
from datetime import timedelta

import httpx
from asgiref.sync import async_to_sync
from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import transaction
from django.utils import timezone
from channels.layers import get_channel_layer

from base.models import Balance, FCMToken
from base.fcm_service import send_fcm_notification

from .models import DriverLocation, DriverProfile, FareConfig, Ride, Vehicle


logger = logging.getLogger(__name__)


DEFAULT_FARES = {
    "bike": {
        "base_fare": Decimal("40.00"),
        "per_km_rate": Decimal("18.00"),
        "per_minute_rate": Decimal("2.00"),
        "minimum_fare": Decimal("60.00"),
        "booking_fee": Decimal("10.00"),
        "surge_multiplier": Decimal("1.00"),
    },
    "car": {
        "base_fare": Decimal("80.00"),
        "per_km_rate": Decimal("28.00"),
        "per_minute_rate": Decimal("3.50"),
        "minimum_fare": Decimal("120.00"),
        "booking_fee": Decimal("15.00"),
        "surge_multiplier": Decimal("1.00"),
    },
    "cng": {
        "base_fare": Decimal("60.00"),
        "per_km_rate": Decimal("22.00"),
        "per_minute_rate": Decimal("2.80"),
        "minimum_fare": Decimal("90.00"),
        "booking_fee": Decimal("12.00"),
        "surge_multiplier": Decimal("1.00"),
    },
}


def decimal_money(value):
    return Decimal(value).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


class RoutingService:
    @staticmethod
    def _decode_polyline(encoded, precision=6):
        if not encoded:
            return []

        coordinates = []
        index = 0
        lat = 0
        lng = 0
        factor = 10 ** precision

        while index < len(encoded):
            result = 0
            shift = 0
            while True:
                byte = ord(encoded[index]) - 63
                index += 1
                result |= (byte & 0x1F) << shift
                shift += 5
                if byte < 0x20:
                    break
            delta_lat = ~(result >> 1) if result & 1 else result >> 1
            lat += delta_lat

            result = 0
            shift = 0
            while True:
                byte = ord(encoded[index]) - 63
                index += 1
                result |= (byte & 0x1F) << shift
                shift += 5
                if byte < 0x20:
                    break
            delta_lng = ~(result >> 1) if result & 1 else result >> 1
            lng += delta_lng

            coordinates.append([lng / factor, lat / factor])

        return coordinates

    @staticmethod
    def _haversine_distance_km(lat1, lng1, lat2, lng2):
        lat1, lng1, lat2, lng2 = map(radians, [lat1, lng1, lat2, lng2])
        dlat = lat2 - lat1
        dlng = lng2 - lng1
        a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlng / 2) ** 2
        c = 2 * asin(sqrt(a))
        return 6371 * c

    @classmethod
    def _get_openstreet_route(cls, pickup_lat, pickup_lng, drop_lat, drop_lng):
        route_url = getattr(settings, "RIDESHARE_OPENSTREET_ROUTE_URL", "").strip()
        route_key = getattr(settings, "RIDESHARE_OPENSTREET_ROUTE_KEY", "").strip()
        if not route_url or not route_key:
            return None

        params = {
            "origin": f"{pickup_lat},{pickup_lng}",
            "destination": f"{drop_lat},{drop_lng}",
            "mode": "driving",
            "key": route_key,
        }
        headers = {
            "User-Agent": "adsyclub-rideshare/1.0",
            "Accept-Encoding": "gzip, deflate",
        }

        try:
            with httpx.Client(timeout=10.0, headers=headers) as client:
                response = client.get(route_url, params=params)
                response.raise_for_status()
                payload = response.json()
        except Exception:
            return None

        if payload.get("status") != "OK":
            return None

        coordinates = cls._decode_polyline(payload.get("polyline", ""), precision=6)
        return {
            "distance_km": decimal_money(Decimal(str(payload.get("total_distance", 0))) / Decimal("1000")),
            "duration_seconds": int(payload.get("total_time", 0)),
            "route_geometry": {
                "type": "LineString",
                "coordinates": coordinates,
            },
            "routing_source": "openstreet",
        }

    @classmethod
    def _get_osrm_route(cls, pickup_lat, pickup_lng, drop_lat, drop_lng):
        osrm_base_url = getattr(settings, "RIDESHARE_OSRM_URL", "http://localhost:5000")
        url = f"{osrm_base_url.rstrip('/')}/route/v1/driving/{pickup_lng},{pickup_lat};{drop_lng},{drop_lat}"
        params = {
            "overview": "full",
            "geometries": "geojson",
            "steps": "false",
            "alternatives": "false",
        }

        try:
            with httpx.Client(timeout=10.0) as client:
                response = client.get(url, params=params)
                response.raise_for_status()
                payload = response.json()

            routes = payload.get("routes") or []
            if routes:
                route = routes[0]
                return {
                    "distance_km": decimal_money(Decimal(str(route.get("distance", 0))) / Decimal("1000")),
                    "duration_seconds": int(route.get("duration", 0)),
                    "route_geometry": route.get("geometry") or {},
                    "routing_source": "osrm",
                }
        except Exception:
            return None

        return None

    @classmethod
    def get_route(cls, pickup_lat, pickup_lng, drop_lat, drop_lng):
        route_provider = getattr(settings, "RIDESHARE_ROUTE_PROVIDER", "openstreet").strip().lower()
        providers = [route_provider]
        if route_provider != "openstreet":
            providers.append("openstreet")
        if route_provider != "osrm":
            providers.append("osrm")

        for provider in providers:
            if provider == "openstreet":
                route = cls._get_openstreet_route(pickup_lat, pickup_lng, drop_lat, drop_lng)
            elif provider == "osrm":
                route = cls._get_osrm_route(pickup_lat, pickup_lng, drop_lat, drop_lng)
            else:
                route = None

            if route:
                return route

        distance_km = cls._haversine_distance_km(float(pickup_lat), float(pickup_lng), float(drop_lat), float(drop_lng))
        return {
            "distance_km": decimal_money(distance_km),
            "duration_seconds": int((distance_km / 22) * 3600) if distance_km else 0,
            "route_geometry": {
                "type": "LineString",
                "coordinates": [
                    [float(pickup_lng), float(pickup_lat)],
                    [float(drop_lng), float(drop_lat)],
                ],
            },
            "routing_source": "fallback",
        }


class LocationService:
    @staticmethod
    def _google_components_to_address(components):
        address = {}
        for component in components or []:
            types = set(component.get("types") or [])
            long_name = component.get("long_name") or ""
            if "street_number" in types:
                address["street_number"] = long_name
            if "route" in types:
                address["route"] = long_name
            if "sublocality" in types or "sublocality_level_1" in types:
                address["suburb"] = long_name
            if "neighborhood" in types:
                address["neighbourhood"] = long_name
            if "locality" in types:
                address["city"] = long_name
            if "postal_town" in types:
                address["town"] = long_name
            if "administrative_area_level_2" in types:
                address["county"] = long_name
            if "administrative_area_level_1" in types:
                address["state_district"] = long_name
            if "country" in types:
                address["country"] = long_name
            if "postal_code" in types:
                address["postcode"] = long_name

        route = address.get("route")
        street_number = address.get("street_number")
        if route and street_number:
            address["road"] = f"{street_number} {route}".strip()
        elif route:
            address["road"] = route
        return address

    @staticmethod
    def _photon_properties_to_address(properties):
        if not properties:
            return {}

        return {
            "road": properties.get("street") or properties.get("name") or "",
            "suburb": properties.get("district") or properties.get("suburb") or "",
            "city": properties.get("city") or properties.get("county") or properties.get("state") or "",
            "state_district": properties.get("state") or "",
            "country": properties.get("country") or "",
            "postcode": properties.get("postcode") or "",
        }

    @classmethod
    def _search_places_google(cls, query, limit=5):
        api_key = getattr(settings, "RIDESHARE_GOOGLE_MAPS_API_KEY", "").strip()
        base_url = getattr(settings, "RIDESHARE_GOOGLE_PLACES_TEXTSEARCH_URL", "").strip()
        if not api_key or not base_url:
            return []

        params = {
            "query": query,
            "key": api_key,
            "language": getattr(settings, "RIDESHARE_GOOGLE_LANGUAGE", "bn"),
            "region": getattr(settings, "RIDESHARE_GOOGLE_REGION", "bd"),
        }

        try:
            with httpx.Client(timeout=10.0, headers={"User-Agent": "adsyclub-rideshare/1.0"}) as client:
                response = client.get(base_url, params=params)
                response.raise_for_status()
                payload = response.json()
        except Exception:
            return []

        if payload.get("status") not in {"OK", "ZERO_RESULTS"}:
            return []

        results = []
        for item in (payload.get("results") or [])[:limit]:
            location = ((item.get("geometry") or {}).get("location") or {})
            latitude = location.get("lat")
            longitude = location.get("lng")
            if latitude is None or longitude is None:
                continue
            results.append(
                {
                    "name": item.get("formatted_address") or item.get("name") or query,
                    "latitude": latitude,
                    "longitude": longitude,
                    "address": cls._google_components_to_address(item.get("address_components") or []),
                }
            )
        return results

    @classmethod
    def _search_places_photon(cls, query, limit=5):
        base_url = getattr(settings, "RIDESHARE_PHOTON_URL", "").strip()
        if not base_url:
            return []

        params = {
            "q": query,
            "limit": limit,
            "lat": getattr(settings, "RIDESHARE_PHOTON_DEFAULT_LAT", 23.6850),
            "lon": getattr(settings, "RIDESHARE_PHOTON_DEFAULT_LNG", 90.3563),
        }

        try:
            with httpx.Client(timeout=10.0, headers={"User-Agent": "adsyclub-rideshare/1.0"}) as client:
                response = client.get(base_url, params=params)
                response.raise_for_status()
                payload = response.json()
        except Exception:
            return []

        results = []
        for item in (payload.get("features") or [])[:limit]:
            coordinates = ((item.get("geometry") or {}).get("coordinates") or [])
            if len(coordinates) < 2:
                continue
            properties = item.get("properties") or {}
            parts = [
                properties.get("name"),
                properties.get("city") or properties.get("state") or properties.get("county"),
                properties.get("country"),
            ]
            results.append(
                {
                    "name": ", ".join([part for part in parts if part]) or query,
                    "latitude": coordinates[1],
                    "longitude": coordinates[0],
                    "address": cls._photon_properties_to_address(properties),
                }
            )
        return results

    @staticmethod
    def _search_places_nominatim(query, limit=5):
        nominatim_base_url = getattr(settings, "RIDESHARE_NOMINATIM_URL", "https://nominatim.openstreetmap.org")
        url = f"{nominatim_base_url.rstrip('/')}/search"
        params = {
            "q": query,
            "format": "jsonv2",
            "limit": limit,
            "addressdetails": 1,
        }
        headers = {"User-Agent": "adsyclub-rideshare/1.0"}

        try:
            with httpx.Client(timeout=10.0, headers=headers) as client:
                response = client.get(url, params=params)
                response.raise_for_status()
                data = response.json()
        except Exception:
            return []

        results = []
        for item in data:
            results.append(
                {
                    "name": item.get("display_name", ""),
                    "latitude": item.get("lat"),
                    "longitude": item.get("lon"),
                    "address": item.get("address", {}),
                }
            )
        return results

    @classmethod
    def search_places(cls, query, limit=5):
        if not query:
            return []

        provider = getattr(settings, "RIDESHARE_LOCATION_PROVIDER", "google").strip().lower()
        providers = [provider]
        if provider != "google":
            providers.append("google")
        if provider != "photon":
            providers.append("photon")
        if provider != "nominatim":
            providers.append("nominatim")

        for current in providers:
            if current == "google":
                results = cls._search_places_google(query, limit=limit)
            elif current == "photon":
                results = cls._search_places_photon(query, limit=limit)
            elif current == "nominatim":
                results = cls._search_places_nominatim(query, limit=limit)
            else:
                results = []
            if results:
                return results
        return []

    @classmethod
    def _reverse_geocode_google(cls, lat, lng):
        api_key = getattr(settings, "RIDESHARE_GOOGLE_MAPS_API_KEY", "").strip()
        base_url = getattr(settings, "RIDESHARE_GOOGLE_GEOCODE_URL", "").strip()
        if not api_key or not base_url:
            return None

        params = {
            "latlng": f"{lat},{lng}",
            "key": api_key,
            "language": getattr(settings, "RIDESHARE_GOOGLE_LANGUAGE", "bn"),
            "region": getattr(settings, "RIDESHARE_GOOGLE_REGION", "bd"),
        }

        try:
            with httpx.Client(timeout=10.0, headers={"User-Agent": "adsyclub-rideshare/1.0"}) as client:
                response = client.get(base_url, params=params)
                response.raise_for_status()
                payload = response.json()
        except Exception:
            return None

        if payload.get("status") not in {"OK", "ZERO_RESULTS"}:
            return None

        item = (payload.get("results") or [None])[0]
        if not item:
            return None
        location = ((item.get("geometry") or {}).get("location") or {})
        return {
            "name": item.get("formatted_address", ""),
            "latitude": location.get("lat", lat),
            "longitude": location.get("lng", lng),
            "address": cls._google_components_to_address(item.get("address_components") or []),
        }

    @staticmethod
    def _reverse_geocode_nominatim(lat, lng):
        nominatim_base_url = getattr(settings, "RIDESHARE_NOMINATIM_URL", "https://nominatim.openstreetmap.org")
        url = f"{nominatim_base_url.rstrip('/')}/reverse"
        params = {
            "lat": lat,
            "lon": lng,
            "format": "jsonv2",
            "addressdetails": 1,
        }
        headers = {"User-Agent": "adsyclub-rideshare/1.0"}

        try:
            with httpx.Client(timeout=10.0, headers=headers) as client:
                response = client.get(url, params=params)
                response.raise_for_status()
                item = response.json()
        except Exception:
            return None

        return {
            "name": item.get("display_name", ""),
            "latitude": item.get("lat"),
            "longitude": item.get("lon"),
            "address": item.get("address", {}),
        }

    @classmethod
    def reverse_geocode(cls, lat, lng):
        provider = getattr(settings, "RIDESHARE_LOCATION_PROVIDER", "google").strip().lower()
        providers = [provider]
        if provider != "google":
            providers.append("google")
        if provider != "nominatim":
            providers.append("nominatim")

        for current in providers:
            if current == "google":
                result = cls._reverse_geocode_google(lat, lng)
            elif current == "nominatim":
                result = cls._reverse_geocode_nominatim(lat, lng)
            else:
                result = None
            if result:
                return result
        return None


class FareService:
    @staticmethod
    def get_config(vehicle_type):
        config = FareConfig.objects.filter(vehicle_type=vehicle_type, is_active=True).first()
        if config:
            return {
                "base_fare": config.base_fare,
                "per_km_rate": config.per_km_rate,
                "per_minute_rate": config.per_minute_rate,
                "minimum_fare": config.minimum_fare,
                "booking_fee": config.booking_fee,
                "surge_multiplier": config.surge_multiplier,
            }
        return DEFAULT_FARES[vehicle_type]

    @classmethod
    def estimate(cls, vehicle_type, distance_km, duration_seconds):
        config = cls.get_config(vehicle_type)
        duration_minutes = Decimal(duration_seconds) / Decimal("60") if duration_seconds else Decimal("0")
        subtotal = (
            Decimal(config["base_fare"])
            + (Decimal(distance_km) * Decimal(config["per_km_rate"]))
            + (duration_minutes * Decimal(config["per_minute_rate"]))
            + Decimal(config["booking_fee"])
        ) * Decimal(config["surge_multiplier"])
        fare = max(subtotal, Decimal(config["minimum_fare"]))
        return decimal_money(fare)


class WalletService:
    @staticmethod
    @transaction.atomic
    def complete_ride_payment(ride):
        if ride.payment_transaction_id:
            return ride.payment_transaction

        amount = ride.final_fare or ride.fare_estimate
        if ride.rider.balance < amount:
            raise ValidationError("Insufficient wallet balance to complete this ride.")
        if not ride.assigned_driver:
            raise ValidationError("Ride has no assigned driver.")

        transaction_record = Balance.objects.create(
            user=ride.rider,
            to_user=ride.assigned_driver.user,
            transaction_type="transfer",
            payable_amount=amount,
            amount=amount,
            received_amount=amount,
            description=f"Ride payment for trip {ride.id}",
        )
        ride.payment_transaction = transaction_record
        ride.payment_status = "completed"
        ride.final_fare = amount
        ride.save(update_fields=["payment_transaction", "payment_status", "final_fare", "updated_at"])

        driver = ride.assigned_driver
        driver.total_earnings += amount
        driver.total_trips += 1
        driver.is_available = True
        driver.save(update_fields=["total_earnings", "total_trips", "is_available", "updated_at"])
        return transaction_record


class DispatchService:
    @staticmethod
    def _group_send(group_name, payload):
        channel_layer = get_channel_layer()
        if not channel_layer:
            return
        try:
            async_to_sync(channel_layer.group_send)(group_name, payload)
        except Exception:
            logger.exception("Rideshare dispatch broadcast failed for group %s", group_name)
            return

    @classmethod
    def broadcast_ride_request(cls, ride):
        cls._group_send(
            "drivers_online",
            {
                "type": "ride.request",
                "ride_id": str(ride.id),
                "status": ride.status,
                "pickup_address": ride.pickup_address,
                "drop_address": ride.drop_address,
                "distance_km": str(ride.distance_km),
                "fare_estimate": str(ride.fare_estimate),
                "requested_vehicle_type": ride.requested_vehicle_type,
                "requested_at": ride.requested_at.isoformat(),
            },
        )

    @classmethod
    def send_ride_event(cls, ride, event_name, extra=None):
        payload = {
            "type": "ride.event",
            "event": event_name,
            "ride_id": str(ride.id),
            "status": ride.status,
            "assigned_driver_id": str(ride.assigned_driver_id) if ride.assigned_driver_id else None,
            "timestamp": timezone.now().isoformat(),
        }
        if extra:
            payload.update(extra)
        cls._group_send(f"ride_{ride.id}", payload)
        if ride.assigned_driver_id:
            cls._group_send(f"driver_{ride.assigned_driver.user_id}", payload)
        if event_name in {"ride_accepted", "ride_cancelled"}:
            cls._group_send("drivers_online", payload)

    @classmethod
    def broadcast_driver_location(cls, ride, location):
        cls._group_send(
            f"ride_{ride.id}",
            {
                "type": "driver.location",
                "ride_id": str(ride.id),
                "driver_id": str(location.driver.user_id),
                "latitude": str(location.latitude),
                "longitude": str(location.longitude),
                "heading": str(location.heading) if location.heading is not None else None,
                "speed_kph": str(location.speed_kph) if location.speed_kph is not None else None,
                "accuracy_meters": str(location.accuracy_meters) if location.accuracy_meters is not None else None,
                "recorded_at": location.recorded_at.isoformat(),
            },
        )


class DriverLocationService:
    @staticmethod
    @transaction.atomic
    def update_location(driver_profile, latitude, longitude, ride=None, heading=None, speed_kph=None, accuracy_meters=None):
        driver_profile.current_latitude = latitude
        driver_profile.current_longitude = longitude
        driver_profile.last_location_at = timezone.now()
        driver_profile.save(update_fields=["current_latitude", "current_longitude", "last_location_at", "updated_at"])

        location = DriverLocation.objects.create(
            driver=driver_profile,
            ride=ride,
            latitude=latitude,
            longitude=longitude,
            heading=heading,
            speed_kph=speed_kph,
            accuracy_meters=accuracy_meters,
        )
        if ride:
            DispatchService.broadcast_driver_location(ride, location)
        return location

    @staticmethod
    def get_nearby_drivers(latitude, longitude, radius_km=5, vehicle_type=None, limit=10):
        """Get nearby online drivers within radius"""
        query = DriverProfile.objects.filter(
            approval_status="approved",
            is_online=True,
            is_available=True,
            current_latitude__isnull=False,
            current_longitude__isnull=False,
        ).select_related("user")
        
        if vehicle_type:
            query = query.filter(vehicles__is_active=True, vehicles__vehicle_type=vehicle_type).distinct()
        
        nearby_drivers = []
        for driver in query[:limit * 3]:
            if driver.current_latitude and driver.current_longitude:
                distance = RoutingService._haversine_distance_km(
                    float(latitude),
                    float(longitude),
                    float(driver.current_latitude),
                    float(driver.current_longitude),
                )
                if distance <= radius_km:
                    driver.distance = distance
                    driver.vehicle_type = vehicle_type or "bike"
                    nearby_drivers.append(driver)
        
        nearby_drivers.sort(key=lambda d: d.distance)
        return nearby_drivers[:limit]


def get_driver_default_vehicle(driver_profile):
    return driver_profile.vehicles.filter(is_active=True, is_default=True).first() or driver_profile.vehicles.filter(is_active=True).first()


def assign_driver_to_ride(ride, driver_profile, actor=None, assignment_source="manual"):
    if ride.status != Ride.STATUS_SEARCHING or ride.assigned_driver_id:
        raise ValidationError("Ride is no longer available.")
    if ride.rider_id == driver_profile.user_id:
        raise ValidationError("You cannot accept your own ride request.")
    if driver_profile.approval_status != "approved":
        raise ValidationError("Driver is not approved for dispatch.")
    if not driver_profile.is_online:
        raise ValidationError("Driver is offline.")
    if not driver_profile.is_available:
        raise ValidationError("Driver is currently unavailable for new rides.")

    vehicle = get_driver_default_vehicle(driver_profile)
    if not vehicle:
        raise ValidationError("Add an active vehicle before accepting rides.")
    if vehicle.vehicle_type != ride.requested_vehicle_type:
        raise ValidationError("Driver vehicle type does not match this ride.")

    ride.assigned_driver = driver_profile
    ride.vehicle = vehicle
    ride.save(update_fields=["assigned_driver", "vehicle", "updated_at"])

    driver_profile.is_available = False
    driver_profile.save(update_fields=["is_available", "updated_at"])

    status_actor = actor or getattr(driver_profile, "user", None)
    ride.transition_to(
        Ride.STATUS_ACCEPTED,
        actor=status_actor,
        metadata={"vehicle_id": str(vehicle.id), "assignment_source": assignment_source},
    )
    DispatchService.send_ride_event(ride, "ride_accepted", {"assignment_source": assignment_source})
    return ride


def _driver_sort_key_for_ride(driver_profile, ride):
    if driver_profile.current_latitude is None or driver_profile.current_longitude is None:
        return (1, float("inf"), 0)

    distance = RoutingService._haversine_distance_km(
        float(driver_profile.current_latitude),
        float(driver_profile.current_longitude),
        float(ride.pickup_latitude),
        float(ride.pickup_longitude),
    )
    return (0, distance, -(driver_profile.last_location_at.timestamp() if driver_profile.last_location_at else 0))


def attempt_auto_assign_driver(ride):
    if ride.status != Ride.STATUS_SEARCHING or ride.assigned_driver_id:
        return None

    candidates = list(
        DriverProfile.objects.filter(
            approval_status="approved",
            is_online=True,
            is_available=True,
            vehicles__is_active=True,
            vehicles__vehicle_type=ride.requested_vehicle_type,
        )
        .exclude(user=ride.rider)
        .select_related("user")
        .distinct()
    )

    if not candidates:
        return None

    candidates.sort(key=lambda driver_profile: _driver_sort_key_for_ride(driver_profile, ride))

    for driver_profile in candidates:
        try:
            service_radius = float(driver_profile.service_radius_km or 0)
        except (TypeError, ValueError):
            service_radius = 0

        if driver_profile.current_latitude is not None and driver_profile.current_longitude is not None and service_radius > 0:
            distance = RoutingService._haversine_distance_km(
                float(driver_profile.current_latitude),
                float(driver_profile.current_longitude),
                float(ride.pickup_latitude),
                float(ride.pickup_longitude),
            )
            if distance > service_radius:
                continue

        try:
            return assign_driver_to_ride(ride, driver_profile, actor=driver_profile.user, assignment_source="auto_dispatch")
        except ValidationError:
            continue

    return None


class RideNotificationService:
    """Service to handle push notifications for ride events"""
    
    NOTIFICATION_MESSAGES = {
        "requested": ("🚗 Ride Requested", "Your ride request has been submitted. Looking for nearby drivers..."),
        "searching_driver": ("🔍 Searching Driver", "We're finding the best driver for your trip."),
        "accepted": ("✅ Driver Assigned", "A driver has accepted your ride and is on the way!"),
        "driver_arriving": ("🚙 Driver Arriving", "Your driver is arriving at the pickup location."),
        "in_progress": ("🛣️ Trip Started", "Your trip has started. Enjoy your ride!"),
        "completed": ("🎉 Trip Completed", "Your trip has been completed. Thank you for riding with us!"),
        "cancelled": ("❌ Ride Cancelled", "Your ride has been cancelled."),
        "no_driver_available": ("😔 No Driver Available", "Sorry, no drivers are available near you right now. Please try again later."),
        "auto_cancelled": ("⏰ Ride Expired", "Your ride was cancelled because no driver accepted within 15 minutes."),
    }
    
    @classmethod
    def _get_user_fcm_tokens(cls, user):
        """Get active FCM tokens for a user"""
        return list(
            FCMToken.objects.filter(user=user, is_active=True)
            .values_list("token", flat=True)
        )
    
    @classmethod
    def send_ride_notification(cls, user, notification_type, ride=None, extra_data=None):
        """Send push notification to user about ride status"""
        if notification_type not in cls.NOTIFICATION_MESSAGES:
            logger.warning(f"Unknown notification type: {notification_type}")
            return False
        
        title, body = cls.NOTIFICATION_MESSAGES[notification_type]
        
        # Add ride-specific info to body if available
        if ride:
            if notification_type == "accepted" and ride.assigned_driver:
                driver_name = ride.assigned_driver.user.name or ride.assigned_driver.user.username
                body = f"{driver_name} has accepted your ride!"
            elif notification_type == "completed" and ride.final_fare:
                body = f"Trip completed! Total fare: ৳{ride.final_fare}"
        
        tokens = cls._get_user_fcm_tokens(user)
        if not tokens:
            logger.info(f"No FCM tokens for user {user.id}")
            return False
        
        data = {
            "type": "rideshare_update",
            "notification_type": notification_type,
        }
        if ride:
            data["ride_id"] = str(ride.id)
            data["status"] = ride.status
        if extra_data:
            data.update(extra_data)
        
        # Send to all user's devices
        success = False
        for token in tokens:
            if send_fcm_notification(token, title, body, data):
                success = True
        
        return success
    
    @classmethod
    def notify_ride_status_change(cls, ride, old_status=None):
        """Notify relevant parties about ride status change"""
        # Notify rider
        cls.send_ride_notification(ride.rider, ride.status, ride)
        
        # Notify driver if assigned
        if ride.assigned_driver and ride.assigned_driver.user:
            driver_title = f"🚗 Ride Update"
            driver_body = f"Ride status: {ride.status.replace('_', ' ').title()}"
            
            if ride.status == Ride.STATUS_CANCELLED:
                driver_title = "❌ Ride Cancelled"
                driver_body = "The passenger has cancelled the ride."
            elif ride.status == Ride.STATUS_IN_PROGRESS:
                driver_title = "🛣️ Trip Started"
                driver_body = "Trip is now in progress."
            elif ride.status == Ride.STATUS_COMPLETED:
                driver_title = "🎉 Trip Completed"
                driver_body = f"Trip completed! Earned: ৳{ride.final_fare or ride.fare_estimate}"
            
            tokens = cls._get_user_fcm_tokens(ride.assigned_driver.user)
            data = {
                "type": "rideshare_update",
                "notification_type": ride.status,
                "ride_id": str(ride.id),
                "status": ride.status,
            }
            for token in tokens:
                send_fcm_notification(token, driver_title, driver_body, data)
    
    @classmethod
    def notify_new_ride_request(cls, ride):
        """Notify online drivers about new ride request"""
        # Get all online drivers with matching vehicle type
        drivers = DriverProfile.objects.filter(
            approval_status="approved",
            is_online=True,
            is_available=True,
            vehicles__is_active=True,
            vehicles__vehicle_type=ride.requested_vehicle_type,
        ).select_related("user").distinct()
        
        title = "🚗 New Ride Request"
        body = f"New {ride.requested_vehicle_type} ride: {ride.pickup_address[:30]}... → {ride.drop_address[:30]}... | ৳{ride.fare_estimate}"
        
        data = {
            "type": "new_ride_request",
            "ride_id": str(ride.id),
            "pickup_address": ride.pickup_address,
            "drop_address": ride.drop_address,
            "fare_estimate": str(ride.fare_estimate),
            "vehicle_type": ride.requested_vehicle_type,
        }
        
        for driver in drivers:
            tokens = cls._get_user_fcm_tokens(driver.user)
            for token in tokens:
                send_fcm_notification(token, title, body, data)


class RideAutoCancel:
    """Service to handle automatic ride cancellation after timeout"""
    
    TIMEOUT_MINUTES = 15
    
    @classmethod
    def check_and_cancel_expired_rides(cls):
        """Check for rides that have been searching for too long and cancel them"""
        timeout_threshold = timezone.now() - timedelta(minutes=cls.TIMEOUT_MINUTES)
        
        expired_rides = Ride.objects.filter(
            status=Ride.STATUS_SEARCHING,
            requested_at__lt=timeout_threshold,
            assigned_driver__isnull=True,
        )
        
        cancelled_count = 0
        for ride in expired_rides:
            try:
                cls.cancel_expired_ride(ride)
                cancelled_count += 1
            except Exception as e:
                logger.exception(f"Failed to auto-cancel ride {ride.id}: {e}")
        
        return cancelled_count
    
    @classmethod
    @transaction.atomic
    def cancel_expired_ride(cls, ride):
        """Cancel a single expired ride and notify the passenger"""
        if ride.status != Ride.STATUS_SEARCHING:
            return False
        
        ride.transition_to(
            Ride.STATUS_CANCELLED,
            actor=None,
            metadata={"cancellation_reason": "auto_cancelled_no_driver", "timeout_minutes": cls.TIMEOUT_MINUTES},
        )
        
        # Send push notification to passenger
        RideNotificationService.send_ride_notification(
            ride.rider,
            "auto_cancelled",
            ride,
            {"cancellation_reason": "no_driver_available", "timeout_minutes": str(cls.TIMEOUT_MINUTES)}
        )
        
        # Also send websocket event
        DispatchService.send_ride_event(ride, "ride_auto_cancelled", {
            "reason": "no_driver_available",
            "timeout_minutes": cls.TIMEOUT_MINUTES,
        })
        
        logger.info(f"Auto-cancelled ride {ride.id} after {cls.TIMEOUT_MINUTES} minutes with no driver")
        return True
    
    @classmethod
    def should_cancel_ride(cls, ride):
        """Check if a ride should be auto-cancelled"""
        if ride.status != Ride.STATUS_SEARCHING:
            return False
        if ride.assigned_driver_id:
            return False

        if ride.dispatch_attempt >= NearestDriverDispatch.MAX_DRIVER_ATTEMPTS:
            return True
        
        timeout_threshold = timezone.now() - timedelta(minutes=cls.TIMEOUT_MINUTES)
        return ride.requested_at < timeout_threshold


class NearestDriverDispatch:
    """Service to dispatch ride requests to nearest driver with 1-minute timeout cascade"""
    
    DRIVER_TIMEOUT_SECONDS = 60  # 1 minute per driver
    MAX_DRIVER_ATTEMPTS = 15
    
    @classmethod
    def get_sorted_drivers_for_ride(cls, ride, exclude_drivers=None):
        """Get drivers sorted by distance from pickup, excluding already tried drivers"""
        exclude_ids = set(exclude_drivers or [])
        
        candidates = list(
            DriverProfile.objects.filter(
                approval_status="approved",
                is_online=True,
                is_available=True,
                vehicles__is_active=True,
                vehicles__vehicle_type=ride.requested_vehicle_type,
            )
            .exclude(id__in=exclude_ids)
            .select_related("user")
            .distinct()
        )
        
        if not candidates:
            return []
        
        # Calculate distance and sort
        drivers_with_distance = []
        for driver in candidates:
            if driver.current_latitude is None or driver.current_longitude is None:
                continue
            
            distance = RoutingService._haversine_distance_km(
                float(driver.current_latitude),
                float(driver.current_longitude),
                float(ride.pickup_latitude),
                float(ride.pickup_longitude),
            )
            
            # Check if within service radius
            service_radius = float(driver.service_radius_km or 10)
            if distance <= service_radius:
                drivers_with_distance.append((driver, distance))
        
        # Sort by distance (nearest first)
        drivers_with_distance.sort(key=lambda x: x[1])
        return [d[0] for d in drivers_with_distance]
    
    @classmethod
    @transaction.atomic
    def dispatch_to_nearest_driver(cls, ride):
        """Dispatch ride to the nearest available driver"""
        if ride.status != Ride.STATUS_SEARCHING or ride.assigned_driver_id:
            return None
        if ride.dispatch_attempt >= cls.MAX_DRIVER_ATTEMPTS:
            logger.info(
                f"Ride {ride.id} reached max dispatch attempts ({cls.MAX_DRIVER_ATTEMPTS})"
            )
            return None
        
        # Get list of already tried drivers from status history
        tried_drivers = set(
            Ride.objects.filter(id=ride.id)
            .values_list("status_history__metadata__targeted_driver_id", flat=True)
        )
        tried_drivers.discard(None)
        
        drivers = cls.get_sorted_drivers_for_ride(ride, exclude_drivers=tried_drivers)
        
        if not drivers:
            return None
        
        # Target the nearest driver
        nearest_driver = drivers[0]
        ride.targeted_driver = nearest_driver
        ride.targeted_at = timezone.now()
        ride.dispatch_attempt += 1
        ride.save(update_fields=["targeted_driver", "targeted_at", "dispatch_attempt", "updated_at"])
        
        # Send targeted notification to this driver
        cls._notify_targeted_driver(ride, nearest_driver)
        
        logger.info(f"Dispatched ride {ride.id} to driver {nearest_driver.id} (attempt {ride.dispatch_attempt})")
        return nearest_driver
    
    @classmethod
    def _notify_targeted_driver(cls, ride, driver):
        """Send notification to targeted driver"""
        title = "🚗 New Ride Request For You!"
        body = f"{ride.pickup_address[:40]}... → {ride.drop_address[:40]}... | ৳{ride.fare_estimate}"
        
        data = {
            "type": "targeted_ride_request",
            "ride_id": str(ride.id),
            "pickup_address": ride.pickup_address,
            "drop_address": ride.drop_address,
            "fare_estimate": str(ride.fare_estimate),
            "vehicle_type": ride.requested_vehicle_type,
            "timeout_seconds": str(cls.DRIVER_TIMEOUT_SECONDS),
        }
        
        tokens = RideNotificationService._get_user_fcm_tokens(driver.user)
        for token in tokens:
            send_fcm_notification(token, title, body, data)
        
        # Also send websocket event to specific driver
        DispatchService._group_send(f"driver_{driver.user_id}", {
            "type": "ride.targeted",
            "ride_id": str(ride.id),
            "status": ride.status,
            "pickup_address": ride.pickup_address,
            "drop_address": ride.drop_address,
            "distance_km": str(ride.distance_km),
            "fare_estimate": str(ride.fare_estimate),
            "requested_vehicle_type": ride.requested_vehicle_type,
            "timeout_seconds": cls.DRIVER_TIMEOUT_SECONDS,
        })
    
    @classmethod
    def check_and_cascade_expired_targets(cls):
        """Check for rides where targeted driver didn't respond and cascade to next"""
        timeout_threshold = timezone.now() - timedelta(seconds=cls.DRIVER_TIMEOUT_SECONDS)
        
        expired_targets = Ride.objects.filter(
            status=Ride.STATUS_SEARCHING,
            assigned_driver__isnull=True,
            targeted_driver__isnull=False,
            targeted_at__lt=timeout_threshold,
        )
        
        cascaded_count = 0
        for ride in expired_targets:
            try:
                # Clear current target and try next driver
                old_target_id = ride.targeted_driver_id
                ride.targeted_driver = None
                ride.targeted_at = None
                ride.save(update_fields=["targeted_driver", "targeted_at", "updated_at"])
                
                # Record the timeout in history
                RideStatusHistory.objects.create(
                    ride=ride,
                    status=ride.status,
                    metadata={"event": "driver_timeout", "targeted_driver_id": str(old_target_id)},
                )
                
                # Try next driver
                next_driver = cls.dispatch_to_nearest_driver(ride)
                if next_driver:
                    cascaded_count += 1
                else:
                    if RideAutoCancel.should_cancel_ride(ride):
                        RideAutoCancel.cancel_expired_ride(ride)
                        logger.info(f"Auto-cancelled ride {ride.id} after dispatch cascade ended")
                    else:
                        logger.info(f"No more drivers available for ride {ride.id}")
            except Exception as e:
                logger.exception(f"Failed to cascade ride {ride.id}: {e}")
        
        return cascaded_count


def check_user_has_active_ride(user):
    """Check if user (as passenger) has an active ride"""
    return Ride.objects.filter(
        rider=user,
        status__in=[
            Ride.STATUS_REQUESTED,
            Ride.STATUS_SEARCHING,
            Ride.STATUS_ACCEPTED,
            Ride.STATUS_DRIVER_ARRIVING,
            Ride.STATUS_IN_PROGRESS,
        ]
    ).exists()


def check_driver_has_active_ride(driver_profile):
    """Check if driver has an active ride"""
    return Ride.objects.filter(
        assigned_driver=driver_profile,
        status__in=[
            Ride.STATUS_ACCEPTED,
            Ride.STATUS_DRIVER_ARRIVING,
            Ride.STATUS_IN_PROGRESS,
        ]
    ).exists()


def get_user_active_ride(user):
    """Get user's active ride if any"""
    return Ride.objects.filter(
        rider=user,
        status__in=[
            Ride.STATUS_REQUESTED,
            Ride.STATUS_SEARCHING,
            Ride.STATUS_ACCEPTED,
            Ride.STATUS_DRIVER_ARRIVING,
            Ride.STATUS_IN_PROGRESS,
        ]
    ).first()
