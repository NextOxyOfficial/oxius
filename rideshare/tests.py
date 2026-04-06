from decimal import Decimal

from django.test import TestCase

from base.models import User
from rideshare.models import DriverProfile, Ride
from rideshare.services import WalletService


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