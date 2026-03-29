from decimal import Decimal
import random

from django.core.management.base import BaseCommand
from django.utils import timezone

from base.models import User
from rideshare.models import DriverProfile, FareConfig, Ride, Vehicle


class Command(BaseCommand):
    help = "Seed demo rideshare data: drivers, vehicles, fare configs, and sample rides"

    def handle(self, *args, **options):
        users = list(User.objects.all()[:10])
        if len(users) < 3:
            self.stdout.write(self.style.ERROR("Need at least 3 users. Create some users first."))
            return

        # --------------- Fare Configs ---------------
        fare_defaults = {
            "bike": {
                "base_fare": Decimal("40.00"),
                "per_km_rate": Decimal("18.00"),
                "per_minute_rate": Decimal("2.00"),
                "minimum_fare": Decimal("60.00"),
                "booking_fee": Decimal("10.00"),
            },
            "car": {
                "base_fare": Decimal("80.00"),
                "per_km_rate": Decimal("28.00"),
                "per_minute_rate": Decimal("3.50"),
                "minimum_fare": Decimal("120.00"),
                "booking_fee": Decimal("15.00"),
            },
            "cng": {
                "base_fare": Decimal("60.00"),
                "per_km_rate": Decimal("22.00"),
                "per_minute_rate": Decimal("2.80"),
                "minimum_fare": Decimal("90.00"),
                "booking_fee": Decimal("12.00"),
            },
        }
        for vtype, defaults in fare_defaults.items():
            obj, created = FareConfig.objects.get_or_create(
                vehicle_type=vtype,
                defaults={**defaults, "surge_multiplier": Decimal("1.00"), "is_active": True},
            )
            tag = "created" if created else "exists"
            self.stdout.write(f"  FareConfig {vtype}: {tag}")

        # --------------- Driver Profiles & Vehicles ---------------
        driver_users = users[:4]
        vehicle_templates = [
            {"vehicle_type": "bike", "make": "Honda", "model": "CBR 150R", "year": 2023, "color": "Red", "plate_number": "DH-BA-11-1234"},
            {"vehicle_type": "car", "make": "Toyota", "model": "Axio", "year": 2022, "color": "White", "plate_number": "DH-KA-22-5678"},
            {"vehicle_type": "cng", "make": "Bajaj", "model": "RE Compact", "year": 2021, "color": "Green", "plate_number": "DH-GA-33-9012"},
            {"vehicle_type": "bike", "make": "Yamaha", "model": "FZS V3", "year": 2024, "color": "Blue", "plate_number": "DH-BA-44-3456"},
        ]

        driver_profiles = []
        for i, user in enumerate(driver_users):
            dp, created = DriverProfile.objects.get_or_create(
                user=user,
                defaults={
                    "license_number": f"DL-{1000 + i}",
                    "national_id_number": f"NID-{2000 + i}",
                    "approval_status": "approved",
                    "is_online": True,
                    "is_available": True,
                    "service_radius_km": Decimal("10.00"),
                },
            )
            if not created:
                dp.approval_status = "approved"
                dp.is_online = True
                dp.is_available = True
                dp.save(update_fields=["approval_status", "is_online", "is_available", "updated_at"])
            driver_profiles.append(dp)

            vt = vehicle_templates[i]
            vehicle, v_created = Vehicle.objects.get_or_create(
                driver=dp,
                plate_number=vt["plate_number"],
                defaults={
                    "vehicle_type": vt["vehicle_type"],
                    "make": vt["make"],
                    "model": vt["model"],
                    "year": vt["year"],
                    "color": vt["color"],
                    "is_active": True,
                    "is_default": True,
                },
            )
            tag = "created" if v_created else "exists"
            self.stdout.write(f"  Driver {user.email} ({vt['vehicle_type']}): {tag}")

        # --------------- Sample Rides ---------------
        dhaka_locations = [
            {"name": "Dhanmondi 27", "lat": 23.7465, "lng": 90.3760},
            {"name": "Gulshan 1 Circle", "lat": 23.7808, "lng": 90.4168},
            {"name": "Mirpur 10", "lat": 23.8069, "lng": 90.3687},
            {"name": "Uttara Sector 3", "lat": 23.8759, "lng": 90.3795},
            {"name": "Motijheel", "lat": 23.7330, "lng": 90.4176},
            {"name": "Banani Road 11", "lat": 23.7936, "lng": 90.4043},
            {"name": "Farmgate", "lat": 23.7575, "lng": 90.3876},
            {"name": "Shahbag", "lat": 23.7387, "lng": 90.3959},
        ]

        rider_users = [u for u in users if u not in driver_users]
        if not rider_users:
            rider_users = users[-2:]

        ride_count = 0
        statuses_pool = [
            Ride.STATUS_COMPLETED,
            Ride.STATUS_COMPLETED,
            Ride.STATUS_COMPLETED,
            Ride.STATUS_CANCELLED,
            Ride.STATUS_SEARCHING,
        ]

        for _ in range(8):
            pickup = random.choice(dhaka_locations)
            drop = random.choice([loc for loc in dhaka_locations if loc != pickup])
            rider = random.choice(rider_users)
            dp = random.choice(driver_profiles)
            vtype = dp.vehicles.filter(is_default=True).first()
            if not vtype:
                continue
            status = random.choice(statuses_pool)
            distance = Decimal(str(round(random.uniform(2.0, 15.0), 2)))
            duration = int(distance * 120)
            fare = Decimal(str(round(float(distance) * 20 + 40, 2)))

            ride = Ride.objects.create(
                rider=rider,
                requested_vehicle_type=vtype.vehicle_type,
                pickup_latitude=Decimal(str(pickup["lat"])),
                pickup_longitude=Decimal(str(pickup["lng"])),
                drop_latitude=Decimal(str(drop["lat"])),
                drop_longitude=Decimal(str(drop["lng"])),
                pickup_address=pickup["name"],
                drop_address=drop["name"],
                distance_km=distance,
                duration_seconds=duration,
                route_geometry={"type": "LineString", "coordinates": [[pickup["lng"], pickup["lat"]], [drop["lng"], drop["lat"]]]},
                fare_estimate=fare,
                final_fare=fare if status == Ride.STATUS_COMPLETED else None,
                status=status,
                assigned_driver=dp if status != Ride.STATUS_SEARCHING else None,
                vehicle=vtype if status != Ride.STATUS_SEARCHING else None,
            )
            ride.status_history.create(status=status, actor=rider)
            ride_count += 1

        self.stdout.write(self.style.SUCCESS(f"Seeded {len(driver_profiles)} drivers, vehicles, 3 fare configs, {ride_count} sample rides."))
