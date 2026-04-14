from decimal import Decimal

from django.test import TestCase

from base.models import Balance, User
from rideshare.models import DriverProfile, Ride
from rideshare.services import CustomLocationService, LocationService, WalletService


class WalletServiceRidePaymentTests(TestCase):
    def setUp(self):
        self.rider = User.objects.create_user(
            username="rider",
            email="rider@example.com",
            password="testpass123",
            phone="01700000001",
            balance=Decimal("1000.00"),
        )
        self.driver_user = User.objects.create_user(
            username="driver",
            email="driver@example.com",
            password="testpass123",
            phone="01700000002",
            balance=Decimal("120.00"),
        )
        self.driver_profile = DriverProfile.objects.create(
            user=self.driver_user,
            approval_status="approved",
        )

    def _create_ride(self, payment_method):
        return Ride.objects.create(
            rider=self.rider,
            assigned_driver=self.driver_profile,
            requested_vehicle_type="bike",
            pickup_latitude=Decimal("23.780000"),
            pickup_longitude=Decimal("90.410000"),
            drop_latitude=Decimal("23.790000"),
            drop_longitude=Decimal("90.420000"),
            pickup_address="Pickup",
            drop_address="Drop",
            distance_km=Decimal("4.50"),
            duration_seconds=900,
            route_geometry={},
            fare_estimate=Decimal("200.00"),
            final_fare=Decimal("200.00"),
            platform_fee_percent=Decimal("10.00"),
            payment_method=payment_method,
            status=Ride.STATUS_IN_PROGRESS,
        )

    def test_wallet_completion_moves_wallet_balance_to_driver(self):
        ride = self._create_ride(Ride.PAYMENT_METHOD_WALLET)

        transaction = WalletService.complete_ride_payment(
            ride,
            payment_method=Ride.PAYMENT_METHOD_WALLET,
        )

        self.rider.refresh_from_db()
        self.driver_user.refresh_from_db()
        self.driver_profile.refresh_from_db()
        ride.refresh_from_db()

        self.assertEqual(self.rider.balance, Decimal("800.00"))
        self.assertEqual(self.driver_user.balance, Decimal("300.00"))
        self.assertEqual(transaction.to_user_id, self.driver_user.id)
        self.assertEqual(ride.driver_due_amount, Decimal("0.00"))
        self.assertIsNotNone(ride.driver_due_settled_at)
        self.assertEqual(self.driver_profile.total_earnings, Decimal("180.00"))

    def test_cash_completion_keeps_driver_wallet_unchanged_and_adds_due(self):
        ride = self._create_ride(Ride.PAYMENT_METHOD_CASH)

        transaction = WalletService.complete_ride_payment(
            ride,
            payment_method=Ride.PAYMENT_METHOD_CASH,
        )

        self.rider.refresh_from_db()
        self.driver_user.refresh_from_db()
        self.driver_profile.refresh_from_db()
        ride.refresh_from_db()

        self.assertEqual(self.rider.balance, Decimal("1000.00"))
        self.assertEqual(self.driver_user.balance, Decimal("120.00"))
        self.assertIsNone(transaction.to_user)
        self.assertEqual(ride.driver_due_amount, Decimal("20.00"))
        self.assertIsNone(ride.driver_due_settled_at)
        self.assertEqual(self.driver_profile.total_earnings, Decimal("180.00"))
        self.assertEqual(self.driver_profile.outstanding_cash_due_count, 1)
        self.assertEqual(self.driver_profile.outstanding_cash_due_amount, Decimal("20.00"))


class UserCustomLocationTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="custom-rider",
            email="custom-rider@example.com",
            password="testpass123",
            phone="01700000111",
            balance=Decimal("500.00"),
        )

    def test_creating_custom_location_deducts_wallet_and_records_balance_transaction(self):
        result = CustomLocationService.create_user_location(
            self.user,
            name="My Village Home",
            subtitle="Khalishpur, Khulna",
            search_keywords="village home, bari",
            latitude="22.845641",
            longitude="89.540328",
        )

        self.user.refresh_from_db()
        location = result["location"]
        transaction = result["transaction"]

        self.assertEqual(self.user.balance, Decimal("301.00"))
        self.assertEqual(location.fee_paid, Decimal("199.00"))
        self.assertEqual(transaction.transaction_type, "ride_custom_location")
        self.assertEqual(transaction.user_id, self.user.id)
        self.assertTrue(
            Balance.objects.filter(id=transaction.id, completed=True, approved=True).exists()
        )

    def test_search_places_prioritizes_users_custom_location(self):
        CustomLocationService.create_user_location(
            self.user,
            name="Dakbangla Mor",
            subtitle="Khalishpur, Khulna",
            search_keywords="dakbangla, my stop",
            latitude="22.845641",
            longitude="89.540328",
        )

        results = LocationService.search_places(
            "dakbangla",
            limit=5,
            focus_lat=22.845600,
            focus_lng=89.540300,
            user=self.user,
        )

        self.assertGreaterEqual(len(results), 1)
        self.assertEqual(results[0]["title"], "Dakbangla Mor")
        self.assertEqual(results[0].get("badge"), "My Custom Location")
        self.assertTrue(results[0].get("is_custom"))

    def test_reverse_geocode_prefers_users_custom_location(self):
        CustomLocationService.create_user_location(
            self.user,
            name="My Farm Gate",
            subtitle="Bheramara, Kushtia",
            search_keywords="farm gate",
            latitude="23.905722",
            longitude="89.136444",
        )

        result = LocationService.reverse_geocode(
            23.905720,
            89.136440,
            user=self.user,
        )

        self.assertEqual(result["title"], "My Farm Gate")
        self.assertEqual(result.get("badge"), "My Custom Location")