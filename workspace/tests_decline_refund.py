# -*- coding: utf-8 -*-
"""A seller declining a paid order must give the buyer their money back.

THE BUG

`workspace/urls.py` routes `orders/<uuid>/<str:action>/` to
`update_order_status` as a catch-all beneath the explicit `complete/` and
`cancel/` paths. Those two have their own handlers that move money. `decline`
did not — it fell through to the catch-all, which did:

    order.status = action_config['to_status']    # 'cancelled'
    order.save(update_fields=['status', 'updated_at'])

and nothing else. Measured against that code:

    POST /api/workspace/orders/<id>/decline/
      -> HTTP 200 | order.status='cancelled' | buyer balance 0.00

The buyer's balance was debited when the order was placed. The seller declining
it ended the order and kept the money out of circulation permanently. This is
not money being created — it is a legitimate buyer silently losing what they
paid, which is why it never showed up as a balance anomaly.

The status write was also an unguarded read-modify-write, the same shape that
let concurrent completions pay a seller four times over in Phase 3A.
"""
import itertools
import threading
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.db import connections
from django.test import TestCase, TransactionTestCase
from django.urls import reverse
from rest_framework.test import APIClient

from workspace.models import Gig, GigOrder, GigOrderTransaction

User = get_user_model()
_counter = itertools.count(1)


def _user(tag, balance="0.00"):
    n = next(_counter)
    user = User.objects.create_user(
        username="dc_%s_%d" % (tag, n), email="dc_%s_%d@example.com" % (tag, n),
        password="x", first_name=tag, phone="+88010005%05d" % n)
    User.objects.filter(pk=user.pk).update(balance=Decimal(balance))
    user.refresh_from_db()
    return user


def balance_of(user):
    return User.objects.values_list("balance", flat=True).get(pk=user.pk)


def money_supply():
    return sum(User.objects.values_list("balance", flat=True))


class _EscrowFixture:
    """Builds the exact state `create_order` leaves behind."""

    price = Decimal("500.00")

    def make_parties(self, buyer_balance="0.00"):
        self.seller = _user("seller", "0.00")
        self.buyer = _user("buyer", buyer_balance)
        self.gig = Gig.objects.create(
            user=self.seller, title="A gig", price=self.price, status="active")

    def make_paid_order(self, price=None, hold_amount=None, status="pending"):
        """An order whose buyer has already been debited.

        `hold_amount` defaults to the price but can be set independently — that
        is how the tests prove the refund follows the ESCROW RECORD rather than
        the order's current price.
        """
        price = self.price if price is None else price
        order = GigOrder.objects.create(
            gig=self.gig, buyer=self.buyer, seller=self.seller,
            price=price, status=status)
        GigOrderTransaction.objects.create(
            order=order, user=self.buyer, amount=price,
            transaction_type="payment", status="completed", description="p")
        held = price if hold_amount is None else hold_amount
        if held > 0:
            GigOrderTransaction.objects.create(
                order=order, user=self.seller, amount=held,
                transaction_type="hold", status="pending", description="h")
        return order

    def decline_url(self, order):
        return "/api/workspace/orders/%s/decline/" % order.id

    def client_for(self, actor):
        c = APIClient()
        c.force_authenticate(user=actor)
        return c


class RealOrderFlowTests(TestCase, _EscrowFixture):
    """One test that uses the genuine purchase endpoint, so the hand-built
    fixture above is anchored to what production actually writes."""

    def test_a_real_purchase_then_decline_returns_the_money(self):
        self.make_parties(buyer_balance="1000.00")

        placed = self.client_for(self.buyer).post(
            reverse("create-order", args=[self.gig.id]), {"requirements": "x"},
            format="json")
        self.assertEqual(placed.status_code, 201, placed.content)
        self.assertEqual(
            balance_of(self.buyer), Decimal("500.00"),
            "premise: placing the order debits the buyer")

        order = GigOrder.objects.get(buyer=self.buyer)
        self.assertTrue(
            GigOrderTransaction.objects.filter(
                order=order, transaction_type="hold", status="pending").exists(),
            "premise: a pending hold row records the escrow")

        response = self.client_for(self.seller).post(self.decline_url(order))

        self.assertEqual(response.status_code, 200, response.content)
        self.assertEqual(
            balance_of(self.buyer), Decimal("1000.00"),
            "the seller declined a paid order and the buyer was not made whole")


class BasicBehaviourTests(TestCase, _EscrowFixture):
    def setUp(self):
        self.make_parties()

    def test_seller_declining_refunds_the_buyer(self):
        order = self.make_paid_order()
        response = self.client_for(self.seller).post(self.decline_url(order))
        self.assertEqual(response.status_code, 200, response.content)
        self.assertEqual(balance_of(self.buyer), self.price)

    def test_the_order_becomes_cancelled(self):
        order = self.make_paid_order()
        self.client_for(self.seller).post(self.decline_url(order))
        order.refresh_from_db()
        self.assertEqual(order.status, "cancelled")

    def test_the_refund_is_the_amount_HELD_not_the_orders_current_price(self):
        """The escrow record is authoritative. If the order's price has since
        drifted, the buyer gets back what actually left their wallet."""
        order = self.make_paid_order(price=Decimal("500.00"),
                                     hold_amount=Decimal("500.00"))
        GigOrder.objects.filter(pk=order.pk).update(price=Decimal("9999.00"))
        order.refresh_from_db()

        self.client_for(self.seller).post(self.decline_url(order))

        self.assertEqual(
            balance_of(self.buyer), Decimal("500.00"),
            "the refund followed order.price instead of the escrow record")

    def test_the_hold_row_is_marked_refunded(self):
        order = self.make_paid_order()
        self.client_for(self.seller).post(self.decline_url(order))
        self.assertFalse(
            GigOrderTransaction.objects.filter(
                order=order, transaction_type="hold", status="pending").exists())

    def test_a_refund_transaction_is_recorded(self):
        order = self.make_paid_order()
        self.client_for(self.seller).post(self.decline_url(order))
        refund = GigOrderTransaction.objects.filter(
            order=order, transaction_type="refund").first()
        self.assertIsNotNone(refund)
        self.assertEqual(refund.amount, self.price)
        self.assertEqual(refund.user_id, self.buyer.id)

    def test_a_free_order_creates_no_money(self):
        order = self.make_paid_order(price=Decimal("0.00"),
                                     hold_amount=Decimal("0.00"))
        before = money_supply()
        response = self.client_for(self.seller).post(self.decline_url(order))
        self.assertEqual(response.status_code, 200, response.content)
        self.assertEqual(balance_of(self.buyer), Decimal("0.00"))
        self.assertEqual(money_supply(), before, "a free order minted money")

    def test_an_order_with_no_escrow_held_refunds_nothing(self):
        """No pending hold row means nothing is owed back."""
        order = self.make_paid_order()
        GigOrderTransaction.objects.filter(
            order=order, transaction_type="hold").delete()
        before = money_supply()

        self.client_for(self.seller).post(self.decline_url(order))

        self.assertEqual(balance_of(self.buyer), Decimal("0.00"))
        self.assertEqual(money_supply(), before)

    def test_accepting_an_order_does_not_refund(self):
        """Only transitions that END the order as cancelled release escrow."""
        order = self.make_paid_order()
        response = self.client_for(self.seller).post(
            "/api/workspace/orders/%s/accept/" % order.id)
        self.assertEqual(response.status_code, 200, response.content)
        self.assertEqual(
            balance_of(self.buyer), Decimal("0.00"),
            "accepting the order returned the escrow while work is pending")


class IdempotencyTests(TestCase, _EscrowFixture):
    def setUp(self):
        self.make_parties()

    def test_declining_twice_refunds_once(self):
        order = self.make_paid_order()
        url = self.decline_url(order)
        first = self.client_for(self.seller).post(url)
        second = self.client_for(self.seller).post(url)

        self.assertEqual(first.status_code, 200)
        self.assertNotEqual(second.status_code, 200)
        self.assertEqual(balance_of(self.buyer), self.price)

    def test_declining_five_times_in_sequence_refunds_once(self):
        order = self.make_paid_order()
        url = self.decline_url(order)
        for _ in range(5):
            self.client_for(self.seller).post(url)
        self.assertEqual(balance_of(self.buyer), self.price)

    def test_declining_an_already_cancelled_order_refunds_nothing(self):
        order = self.make_paid_order()
        self.client_for(self.buyer).post(reverse("cancel-order", args=[order.id]))
        after_cancel = balance_of(self.buyer)

        self.client_for(self.seller).post(self.decline_url(order))

        self.assertEqual(
            balance_of(self.buyer), after_cancel,
            "cancel and decline each paid out the same escrow")

    def test_declining_a_completed_order_refunds_nothing(self):
        """The seller has been paid. Refunding the buyer too would release the
        same escrow twice, by two different routes."""
        order = self.make_paid_order(status="delivered")
        self.client_for(self.buyer).post(
            reverse("complete-order", args=[order.id]))
        self.assertEqual(balance_of(self.seller), self.price)

        response = self.client_for(self.seller).post(self.decline_url(order))

        self.assertNotEqual(response.status_code, 200)
        self.assertEqual(balance_of(self.buyer), Decimal("0.00"))
        self.assertEqual(balance_of(self.seller), self.price)

    def test_a_stale_order_object_cannot_refund_again(self):
        order = self.make_paid_order()
        stale = GigOrder.objects.get(pk=order.pk)      # read while pending
        self.client_for(self.seller).post(self.decline_url(order))
        self.assertEqual(balance_of(self.buyer), self.price)

        self.client_for(self.seller).post(self.decline_url(stale))

        self.assertEqual(balance_of(self.buyer), self.price)


class AuthorizationTests(TestCase, _EscrowFixture):
    def setUp(self):
        self.make_parties()

    def test_the_buyer_cannot_invoke_the_sellers_decline(self):
        order = self.make_paid_order()
        response = self.client_for(self.buyer).post(self.decline_url(order))
        self.assertEqual(response.status_code, 403)
        self.assertEqual(
            balance_of(self.buyer), Decimal("0.00"),
            "the buyer refunded themselves through a seller-only action")

    def test_a_stranger_cannot_decline_someone_elses_order(self):
        order = self.make_paid_order()
        stranger = _user("stranger")
        response = self.client_for(stranger).post(self.decline_url(order))
        self.assertEqual(response.status_code, 403)
        self.assertEqual(balance_of(self.buyer), Decimal("0.00"))

    def test_an_anonymous_caller_cannot_decline(self):
        order = self.make_paid_order()
        response = APIClient().post(self.decline_url(order))
        self.assertIn(response.status_code, (401, 403))
        self.assertEqual(balance_of(self.buyer), Decimal("0.00"))

    def test_a_nonexistent_order_triggers_no_refund(self):
        import uuid
        self.make_paid_order()
        before = money_supply()
        response = self.client_for(self.seller).post(
            "/api/workspace/orders/%s/decline/" % uuid.uuid4())
        self.assertEqual(response.status_code, 404)
        self.assertEqual(money_supply(), before)


class ConcurrentDeclineTests(TransactionTestCase, _EscrowFixture):
    """Real threads, real connections, released together."""

    def hammer(self, url, actor, count):
        barrier = threading.Barrier(count)
        lock = threading.Lock()
        codes = []

        def run():
            client = APIClient()
            client.force_authenticate(user=actor)
            barrier.wait()
            try:
                code = client.post(url).status_code
                with lock:
                    codes.append(code)
            except Exception as exc:
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

    def test_two_concurrent_declines_refund_once(self):
        self.make_parties()
        order = self.make_paid_order()
        codes = self.hammer(self.decline_url(order), self.seller, count=2)
        self.assertEqual(
            balance_of(self.buyer), self.price,
            "two concurrent declines refunded %s; codes=%s"
            % (balance_of(self.buyer), codes))

    def test_five_concurrent_declines_refund_once(self):
        self.make_parties()
        order = self.make_paid_order()
        codes = self.hammer(self.decline_url(order), self.seller, count=5)
        self.assertEqual(
            balance_of(self.buyer), self.price,
            "five concurrent declines refunded %s; codes=%s"
            % (balance_of(self.buyer), codes))
        self.assertEqual(
            sum(1 for c in codes if c == 200), 1,
            "more than one request believed it had declined the order")

    def test_the_buyer_ends_with_exactly_their_starting_balance_plus_one_refund(self):
        self.make_parties(buyer_balance="250.00")
        order = self.make_paid_order()
        self.hammer(self.decline_url(order), self.seller, count=5)
        self.assertEqual(balance_of(self.buyer), Decimal("250.00") + self.price)

    def test_concurrent_declines_do_not_inflate_the_money_supply(self):
        self.make_parties(buyer_balance="100.00")
        order = self.make_paid_order()
        before = money_supply()

        self.hammer(self.decline_url(order), self.seller, count=5)

        self.assertEqual(
            money_supply(), before + self.price,
            "the money supply grew by more than the single escrow hold")

    def test_a_concurrent_decline_and_cancel_release_the_escrow_once(self):
        """Two routes to 'cancelled' exist. Together they must still pay once."""
        self.make_parties()
        order = self.make_paid_order()
        decline_url = self.decline_url(order)
        cancel_url = reverse("cancel-order", args=[order.id])

        barrier = threading.Barrier(2)
        lock = threading.Lock()
        codes = []

        def run(actor, url):
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

        threads = [
            threading.Thread(target=run(self.seller, decline_url)),
            threading.Thread(target=run(self.buyer, cancel_url)),
        ]
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=30)

        self.assertEqual(
            balance_of(self.buyer), self.price,
            "decline and cancel both released the same escrow; codes=%s" % (codes,))
