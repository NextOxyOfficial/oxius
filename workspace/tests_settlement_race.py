# -*- coding: utf-8 -*-
"""An escrow hold may be released exactly once.

Written independently of `tests_order_settlement.py` to confirm the finding
rather than inherit it. These drive the real HTTP endpoints through the real
URL conf, from real OS threads on real database connections — a sequential
double-call proves nothing about the interleaving that causes the bug, and
neither does mocking.

THE SHAPE OF THE BUG

    order = GigOrder.objects.get(id=order_id)     # unlocked read
    if order.status != 'delivered':               # decided in Python
        return 400
    with transaction.atomic():
        order.status = 'completed'
        order.save(update_fields=[...])           # unconditional write
        User.objects.filter(pk=seller).update(balance=F('balance') + price)

Every concurrent request reads `delivered`, every one passes the check, every
one pays. The `F()` is not the flaw — it is what makes the payouts add up
cleanly instead of overwriting each other, so six clicks become six payouts out
of one escrow hold. `transaction.atomic()` does not help either: these are
separate transactions, and each is individually valid.

The money for the payout was held ONCE when the order was placed. Every extra
release is created out of nothing.
"""
import itertools
import threading
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.db import connections
from django.test import TransactionTestCase
from django.urls import reverse
from rest_framework.test import APIClient

from workspace.models import Gig, GigOrder

User = get_user_model()
_counter = itertools.count(1)


def _user(tag, balance="0.00"):
    n = next(_counter)
    user = User.objects.create_user(
        username="ws_%s_%d" % (tag, n), email="ws_%s_%d@example.com" % (tag, n),
        password="x", first_name=tag, phone="+88010006%05d" % n)
    User.objects.filter(pk=user.pk).update(balance=Decimal(balance))
    user.refresh_from_db()
    return user


def balance_of(user):
    return User.objects.values_list("balance", flat=True).get(pk=user.pk)


class _SettlementRaceBase(TransactionTestCase):
    """Fires N real requests at one order at the same instant."""

    price = Decimal("500.00")

    def make_order(self, status):
        self.seller = _user("seller", "0.00")
        self.buyer = _user("buyer", "0.00")
        gig = Gig.objects.create(
            user=self.seller, title="A gig", price=self.price)
        # The escrow: the buyer's money is already held, which is exactly why
        # paying it out twice invents money that nobody put in.
        return GigOrder.objects.create(
            gig=gig, buyer=self.buyer, seller=self.seller,
            price=self.price, status=status)

    def hammer(self, url, actor, count):
        """`count` threads, released together, each a real authenticated POST."""
        barrier = threading.Barrier(count)
        codes = []
        lock = threading.Lock()

        def run():
            client = APIClient()
            client.force_authenticate(user=actor)
            barrier.wait()                      # maximise the overlap
            try:
                response = client.post(url)
                with lock:
                    codes.append(response.status_code)
            except Exception as exc:            # recorded, never swallowed
                with lock:
                    codes.append(repr(exc))
            finally:
                connections.close_all()

        threads = [threading.Thread(target=run) for _ in range(count)]
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=30)
        return codes


class CompletionRaceTests(_SettlementRaceBase):
    def test_six_simultaneous_completions_pay_the_seller_once(self):
        order = self.make_order("delivered")
        url = reverse("complete-order", args=[order.id])

        codes = self.hammer(url, self.buyer, count=6)

        self.assertEqual(
            balance_of(self.seller), self.price,
            "the seller was paid %s out of a single %s hold; codes=%s"
            % (balance_of(self.seller), self.price, codes))
        self.assertEqual(
            sum(1 for c in codes if c == 200), 1,
            "more than one request believed it had completed the order")

    def test_two_simultaneous_completions_pay_the_seller_once(self):
        order = self.make_order("delivered")
        url = reverse("complete-order", args=[order.id])
        self.hammer(url, self.buyer, count=2)
        self.assertEqual(balance_of(self.seller), self.price)

    def test_the_order_ends_completed_exactly_once(self):
        order = self.make_order("delivered")
        url = reverse("complete-order", args=[order.id])
        self.hammer(url, self.buyer, count=4)
        order.refresh_from_db()
        self.assertEqual(order.status, "completed")


class CancellationRaceTests(_SettlementRaceBase):
    def test_five_simultaneous_cancellations_refund_once(self):
        order = self.make_order("pending")
        url = reverse("cancel-order", args=[order.id])

        codes = self.hammer(url, self.buyer, count=5)

        self.assertEqual(
            balance_of(self.buyer), self.price,
            "the buyer was refunded %s for a single %s hold; codes=%s"
            % (balance_of(self.buyer), self.price, codes))

    def test_buyer_and_seller_cancelling_at_once_refund_once(self):
        """Both parties are authorised to cancel. Both clicking together must
        still produce one refund."""
        order = self.make_order("in_progress")
        url = reverse("cancel-order", args=[order.id])

        barrier = threading.Barrier(2)
        lock = threading.Lock()
        codes = []

        def run(actor):
            def inner():
                client = APIClient()
                client.force_authenticate(user=actor)
                barrier.wait()
                try:
                    with lock:
                        codes.append(client.post(url).status_code)
                finally:
                    connections.close_all()
            return inner

        threads = [threading.Thread(target=run(a))
                   for a in (self.buyer, self.seller)]
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=30)

        self.assertEqual(
            balance_of(self.buyer), self.price,
            "buyer and seller cancelling together refunded twice; codes=%s"
            % (codes,))


class MoneySupplyTests(_SettlementRaceBase):
    def test_completion_does_not_change_the_money_supply(self):
        """The strongest statement: releasing escrow moves money between two
        accounts. It must never increase the total."""
        order = self.make_order("delivered")
        User.objects.filter(pk=self.buyer.pk).update(balance=Decimal("1000.00"))
        total_before = balance_of(self.buyer) + balance_of(self.seller)

        self.hammer(reverse("complete-order", args=[order.id]),
                    self.buyer, count=5)

        total_after = balance_of(self.buyer) + balance_of(self.seller)
        self.assertEqual(
            total_after, total_before + self.price,
            "the money supply grew by more than the one escrow hold")


class SequentialAndAuthorizationTests(_SettlementRaceBase):
    """Behaviour that must survive the fix."""

    def _client(self, actor):
        c = APIClient()
        c.force_authenticate(user=actor)
        return c

    def test_a_delivered_order_completes_and_pays_the_seller(self):
        order = self.make_order("delivered")
        response = self._client(self.buyer).post(
            reverse("complete-order", args=[order.id]))
        self.assertEqual(response.status_code, 200, response.content)
        self.assertEqual(balance_of(self.seller), self.price)

    def test_completing_twice_in_sequence_pays_once(self):
        order = self.make_order("delivered")
        url = reverse("complete-order", args=[order.id])
        self._client(self.buyer).post(url)
        second = self._client(self.buyer).post(url)
        self.assertNotEqual(second.status_code, 200)
        self.assertEqual(balance_of(self.seller), self.price)

    def test_only_the_buyer_may_complete(self):
        order = self.make_order("delivered")
        response = self._client(self.seller).post(
            reverse("complete-order", args=[order.id]))
        self.assertEqual(response.status_code, 403)
        self.assertEqual(balance_of(self.seller), Decimal("0.00"))

    def test_a_stranger_may_not_complete_or_cancel(self):
        order = self.make_order("delivered")
        stranger = _user("stranger")
        self.assertEqual(
            self._client(stranger).post(
                reverse("complete-order", args=[order.id])).status_code, 403)
        self.assertEqual(
            self._client(stranger).post(
                reverse("cancel-order", args=[order.id])).status_code, 403)
        self.assertEqual(balance_of(self.seller), Decimal("0.00"))
        self.assertEqual(balance_of(self.buyer), Decimal("0.00"))

    def test_an_undelivered_order_cannot_be_completed(self):
        order = self.make_order("pending")
        response = self._client(self.buyer).post(
            reverse("complete-order", args=[order.id]))
        self.assertEqual(response.status_code, 400)
        self.assertEqual(balance_of(self.seller), Decimal("0.00"))

    def test_a_completed_order_cannot_then_be_cancelled(self):
        """Otherwise the seller keeps the payout and the buyer gets a refund —
        the same money released twice by two different routes."""
        order = self.make_order("delivered")
        self._client(self.buyer).post(reverse("complete-order", args=[order.id]))
        response = self._client(self.buyer).post(
            reverse("cancel-order", args=[order.id]))
        self.assertNotEqual(response.status_code, 200)
        self.assertEqual(balance_of(self.seller), self.price)
        self.assertEqual(balance_of(self.buyer), Decimal("0.00"))

    def test_a_cancelled_order_cannot_then_be_completed(self):
        order = self.make_order("pending")
        self._client(self.buyer).post(reverse("cancel-order", args=[order.id]))
        response = self._client(self.buyer).post(
            reverse("complete-order", args=[order.id]))
        self.assertNotEqual(response.status_code, 200)
        self.assertEqual(balance_of(self.buyer), self.price)
        self.assertEqual(balance_of(self.seller), Decimal("0.00"))

    def test_cancelling_a_pending_order_refunds_the_buyer_once(self):
        order = self.make_order("pending")
        response = self._client(self.buyer).post(
            reverse("cancel-order", args=[order.id]))
        self.assertEqual(response.status_code, 200, response.content)
        self.assertEqual(balance_of(self.buyer), self.price)

    def test_the_seller_may_also_cancel(self):
        order = self.make_order("in_progress")
        response = self._client(self.seller).post(
            reverse("cancel-order", args=[order.id]))
        self.assertEqual(response.status_code, 200, response.content)
        self.assertEqual(balance_of(self.buyer), self.price)
