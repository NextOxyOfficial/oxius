# -*- coding: utf-8 -*-
"""A gig order settles exactly once: the seller is paid once, or the buyer is
refunded once — never twice, and never both.

THE BUG

Both settlement endpoints checked the status in Python and then paid:

    order = GigOrder.objects.get(id=order_id)      # no lock
    if order.status != 'delivered': return 400     # check
    with transaction.atomic():
        order.status = 'completed'
        order.save(update_fields=[...])            # unconditional
        User.objects.filter(pk=seller).update(balance=F('balance') + order.price)

Two requests read the same status, both pass the check, and both pay. A buyer
double-tapping "Complete" — or the app retrying after a timeout — paid the
seller twice out of a single escrow hold. `cancel_order` had the same shape, so
two concurrent cancels refunded the buyer twice.

`transaction.atomic()` did nothing to prevent this: neither transaction locked
the row or re-checked it, and `F()` guarantees BOTH increments land rather than
preventing the second.

The fix is a compare-and-swap on the status. These tests drive the real views
through the real URLs.
"""
import itertools
import threading
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.db import connections
from django.test import TestCase, TransactionTestCase
from django.urls import reverse
from rest_framework.test import APIClient

from workspace.models import Gig, GigOrder

User = get_user_model()
_counter = itertools.count(1)


def _user(tag, balance="0.00"):
    n = next(_counter)
    user = User.objects.create_user(
        username="ws_%s_%d" % (tag, n), email="ws_%s_%d@example.com" % (tag, n),
        password="x", first_name=tag, phone="+88010004%05d" % n)
    User.objects.filter(pk=user.pk).update(balance=Decimal(balance))
    user.refresh_from_db()
    return user


def balance_of(user):
    return User.objects.values_list("balance", flat=True).get(pk=user.pk)


def make_order(buyer, seller, price="500.00", status="delivered"):
    """An order whose escrow has already been taken from the buyer."""
    gig = Gig.objects.create(
        user=seller, title="Logo design", price=Decimal(price),
        category="design", delivery_time=3, status="active")
    return GigOrder.objects.create(
        gig=gig, buyer=buyer, seller=seller,
        price=Decimal(price), status=status)


def complete_url(order):
    return reverse("complete-order", kwargs={"order_id": order.id})


def cancel_url(order):
    return reverse("cancel-order", kwargs={"order_id": order.id})


def client_for(user):
    c = APIClient()
    c.force_authenticate(user=user)
    return c


class CompletionHappyPathTests(TestCase):
    def test_completing_a_delivered_order_pays_the_seller_once(self):
        buyer, seller = _user("b1"), _user("s1")
        order = make_order(buyer, seller)

        response = client_for(buyer).post(complete_url(order))

        self.assertEqual(response.status_code, 200)
        self.assertEqual(balance_of(seller), Decimal("500.00"))
        order.refresh_from_db()
        self.assertEqual(order.status, "completed")
        self.assertIsNotNone(order.completed_at)

    def test_only_the_buyer_may_complete(self):
        buyer, seller = _user("b2"), _user("s2")
        stranger = _user("x2")
        order = make_order(buyer, seller)

        response = client_for(stranger).post(complete_url(order))

        self.assertEqual(response.status_code, 403)
        self.assertEqual(balance_of(seller), Decimal("0.00"))

    def test_the_seller_cannot_complete_their_own_order(self):
        buyer, seller = _user("b3"), _user("s3")
        order = make_order(buyer, seller)

        response = client_for(seller).post(complete_url(order))

        self.assertEqual(response.status_code, 403)
        self.assertEqual(balance_of(seller), Decimal("0.00"))

    def test_an_undelivered_order_cannot_be_completed(self):
        buyer, seller = _user("b4"), _user("s4")
        order = make_order(buyer, seller, status="in_progress")

        response = client_for(buyer).post(complete_url(order))

        self.assertEqual(response.status_code, 400)
        self.assertEqual(balance_of(seller), Decimal("0.00"))


class SequentialDoubleSettleTests(TestCase):
    def test_completing_twice_pays_once(self):
        buyer, seller = _user("b5"), _user("s5")
        order = make_order(buyer, seller)
        c = client_for(buyer)

        first = c.post(complete_url(order))
        second = c.post(complete_url(order))

        self.assertEqual(first.status_code, 200)
        self.assertIn(second.status_code, (400, 409))
        self.assertEqual(
            balance_of(seller), Decimal("500.00"),
            "the seller was paid twice for one order")

    def test_cancelling_twice_refunds_once(self):
        buyer, seller = _user("b6"), _user("s6")
        order = make_order(buyer, seller, status="pending")
        c = client_for(buyer)

        c.post(cancel_url(order))
        c.post(cancel_url(order))

        self.assertEqual(
            balance_of(buyer), Decimal("500.00"),
            "the buyer was refunded twice for one order")

    def test_a_completed_order_cannot_then_be_cancelled_for_a_refund(self):
        """Otherwise the seller keeps the payout AND the buyer gets the money."""
        buyer, seller = _user("b7"), _user("s7")
        order = make_order(buyer, seller)

        client_for(buyer).post(complete_url(order))
        client_for(buyer).post(cancel_url(order))

        self.assertEqual(balance_of(seller), Decimal("500.00"))
        self.assertEqual(
            balance_of(buyer), Decimal("0.00"),
            "the order was both paid out and refunded")


class CancellationHappyPathTests(TestCase):
    def test_cancelling_a_pending_order_refunds_the_buyer(self):
        buyer, seller = _user("b8"), _user("s8")
        order = make_order(buyer, seller, status="pending")

        response = client_for(buyer).post(cancel_url(order))

        self.assertEqual(response.status_code, 200)
        self.assertEqual(balance_of(buyer), Decimal("500.00"))
        order.refresh_from_db()
        self.assertEqual(order.status, "cancelled")

    def test_the_seller_may_also_cancel(self):
        buyer, seller = _user("b9"), _user("s9")
        order = make_order(buyer, seller, status="in_progress")

        response = client_for(seller).post(cancel_url(order))

        self.assertEqual(response.status_code, 200)
        self.assertEqual(balance_of(buyer), Decimal("500.00"))

    def test_a_stranger_cannot_cancel(self):
        buyer, seller = _user("b10"), _user("s10")
        stranger = _user("x10")
        order = make_order(buyer, seller, status="pending")

        response = client_for(stranger).post(cancel_url(order))

        self.assertEqual(response.status_code, 403)
        self.assertEqual(balance_of(buyer), Decimal("0.00"))

    def test_a_delivered_order_cannot_be_cancelled(self):
        buyer, seller = _user("b11"), _user("s11")
        order = make_order(buyer, seller, status="delivered")

        response = client_for(buyer).post(cancel_url(order))

        self.assertEqual(response.status_code, 400)
        self.assertEqual(balance_of(buyer), Decimal("0.00"))


class ConcurrentSettlementTests(TransactionTestCase):
    """The vulnerability, with real threads."""

    def _race(self, target, count):
        barrier = threading.Barrier(count)
        results, errors = [], []

        def run():
            barrier.wait()
            try:
                results.append(target())
            except Exception as exc:            # noqa: BLE001 - asserted on
                errors.append(exc)
            finally:
                connections.close_all()

        threads = [threading.Thread(target=run) for _ in range(count)]
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=30)
        return results, errors

    def test_two_simultaneous_completions_pay_the_seller_once(self):
        buyer, seller = _user("rb1"), _user("rs1")
        order = make_order(buyer, seller, "500.00")

        results, errors = self._race(
            lambda: client_for(buyer).post(complete_url(order)).status_code,
            count=2)

        self.assertEqual(errors, [])
        self.assertEqual(
            balance_of(seller), Decimal("500.00"),
            "double-tapping Complete paid the seller %s" % balance_of(seller))
        self.assertEqual(sorted(results).count(200), 1,
                         "more than one request believed it settled the order")

    def test_six_simultaneous_completions_pay_the_seller_once(self):
        buyer, seller = _user("rb2"), _user("rs2")
        order = make_order(buyer, seller, "300.00")

        _, errors = self._race(
            lambda: client_for(buyer).post(complete_url(order)).status_code,
            count=6)

        self.assertEqual(errors, [])
        self.assertEqual(balance_of(seller), Decimal("300.00"))

    def test_two_simultaneous_cancellations_refund_once(self):
        buyer, seller = _user("rb3"), _user("rs3")
        order = make_order(buyer, seller, "700.00", status="pending")

        _, errors = self._race(
            lambda: client_for(buyer).post(cancel_url(order)).status_code,
            count=2)

        self.assertEqual(errors, [])
        self.assertEqual(
            balance_of(buyer), Decimal("700.00"),
            "two concurrent cancels refunded %s" % balance_of(buyer))

    def test_five_simultaneous_cancellations_refund_once(self):
        buyer, seller = _user("rb4"), _user("rs4")
        order = make_order(buyer, seller, "250.00", status="in_progress")

        _, errors = self._race(
            lambda: client_for(buyer).post(cancel_url(order)).status_code,
            count=5)

        self.assertEqual(errors, [])
        self.assertEqual(balance_of(buyer), Decimal("250.00"))

    def test_the_money_supply_is_unchanged_by_concurrent_completions(self):
        """One escrow hold of 500 may release exactly 500, no matter how many
        requests try to release it."""
        buyer, seller = _user("rb5"), _user("rs5")
        order = make_order(buyer, seller, "500.00")
        before = sum(User.objects.values_list("balance", flat=True))

        self._race(
            lambda: client_for(buyer).post(complete_url(order)).status_code,
            count=4)

        after = sum(User.objects.values_list("balance", flat=True))
        self.assertEqual(
            after - before, Decimal("500.00"),
            "4 concurrent completions moved %s" % (after - before))
