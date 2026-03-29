from decimal import Decimal, ROUND_HALF_UP
from math import asin, cos, radians, sin, sqrt

import httpx
from asgiref.sync import async_to_sync
from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import transaction
from django.utils import timezone
from channels.layers import get_channel_layer

from base.models import Balance

from .models import DriverLocation, DriverProfile, FareConfig, Ride, Vehicle


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
    def _haversine_distance_km(lat1, lng1, lat2, lng2):
        lat1, lng1, lat2, lng2 = map(radians, [lat1, lng1, lat2, lng2])
        dlat = lat2 - lat1
        dlng = lng2 - lng1
        a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlng / 2) ** 2
        c = 2 * asin(sqrt(a))
        return 6371 * c

    @classmethod
    def get_route(cls, pickup_lat, pickup_lng, drop_lat, drop_lng):
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
            pass

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
    def search_places(query, limit=5):
        if not query:
            return []

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

    @staticmethod
    def reverse_geocode(lat, lng):
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
        async_to_sync(channel_layer.group_send)(group_name, payload)

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


def get_driver_default_vehicle(driver_profile):
    return driver_profile.vehicles.filter(is_active=True, is_default=True).first() or driver_profile.vehicles.filter(is_active=True).first()
