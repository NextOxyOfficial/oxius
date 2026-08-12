# -*- coding: utf-8 -*-
"""A disputed order's escrow is released exactly once, to exactly one side.

THE BUG

Dispute resolution lived in six read-modify-write mutations across two entry
points that duplicate each other — the bulk admin actions `resolve_for_buyer` /
`resolve_for_seller`, and `OrderDisputeAdmin.save_model` handling the same three
outcomes when the status field is edited directly:

    order.buyer.balance += order.price
    order.buyer.save(update_fields=['balance'])

No claim, no atomicity, and — the part that reaches beyond this module — none of
the six touched the `hold` GigOrderTransaction row. Phases 3A and 3B made that
row the authoritative record of what is in escrow: `complete`, `cancel` and
`decline` all consume it, and refuse to pay when it is gone. A dispute
resolution left it `pending`, so escrow that had already been paid out to the
seller by an admin was still refundable to the buyer through `cancel` or
`decline`. That is the same money leaving twice by two different doors.

`resolved_partial` had a second problem: it refunded `obj.refund_amount` and
released `order.price - refund_amount` without either figure being checked
against what was actually held.
"""
import itertools
import threading
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.db import connections
from django.test import TestCase, TransactionTestCase
from django.urls import reverse
from rest_framework.test import APIClient

from workspace.models import Gig, GigOrder, GigOrderTransaction, OrderDispute

User = get_user_model()
_counter = itertools.count(1)


def _user(tag, balance="0.00"):
    n = next(_counter)
    user = User.objects.create_user(
        username="ds_%s_%d" % (tag, n), email="ds_%s_%d@example.com" % (tag, n),
        password="x", first_name=tag, phone="+88010003%05d" % n)
    User.objects.filter(pk=user.pk).update(balance=Decimal(balance))
    user.refresh_from_db()
    return user


def balance_of(user):
    return User.objects.values_list("balance", flat=True).get(pk=user.pk)


def money_supply():
    return sum(User.objects.values_list("balance", flat=True))


def pending_hold(order):
    return GigOrderTransaction.objects.filter(
        order=order, transaction_type="hold", status="pending").first()


class _DisputeFixture:
    price = Decimal("600.00")

    def make_disputed_order(self, status="delivered", price=None):
        price = self.price if price is None else price
        self.seller = _user("seller", "0.00")
        self.buyer = _user("buyer", "0.00")
        self.admin = _user("admin", "0.00")
        gig = Gig.objects.create(user=self.seller, title="g", price=price)
        order = GigOrder.objects.create(
            gig=gig, buyer=self.buyer, seller=self.seller,
            price=price, status=status)
        GigOrderTransaction.objects.create(
            order=order, user=self.buyer, amount=price,
            transaction_type="payment", status="completed", description="p")
        GigOrderTransaction.objects.create(
            order=order, user=self.seller, amount=price,
            transaction_type="hold", status="pending", description="h")
        dispute = OrderDispute.objects.create(
            order=order, raised_by=self.buyer, reason="quality_issues",
            description="not good", status="open")
        return order, dispute

    def settle(self, dispute, outcome, refund_amount=None):
        """Drive the production settlement path directly."""
        from workspace.views import settle_dispute
        if refund_amount is not None:
            OrderDispute.objects.filter(pk=dispute.pk).update(
                refund_amount=refund_amount)
            dispute.refresh_from_db()
        return settle_dispute(dispute, outcome=outcome, resolved_by=self.admin)


class BuyerWinTests(TestCase, _DisputeFixture):
    def test_resolving_for_the_buyer_refunds_the_held_amount(self):
        order, dispute = self.make_disputed_order()
        self.assertTrue(self.settle(dispute, "resolved_buyer"))
        self.assertEqual(balance_of(self.buyer), self.price)
        self.assertEqual(balance_of(self.seller), Decimal("0.00"))

    def test_the_order_is_cancelled_and_the_hold_consumed(self):
        order, dispute = self.make_disputed_order()
        self.settle(dispute, "resolved_buyer")
        order.refresh_from_db()
        self.assertEqual(order.status, "cancelled")
        self.assertIsNone(
            pending_hold(order),
            "the escrow hold survived the dispute resolution")

    def test_the_dispute_is_marked_resolved(self):
        order, dispute = self.make_disputed_order()
        self.settle(dispute, "resolved_buyer")
        dispute.refresh_from_db()
        self.assertEqual(dispute.status, "resolved_buyer")
        self.assertIsNotNone(dispute.resolved_at)

    def test_settling_twice_refunds_once(self):
        order, dispute = self.make_disputed_order()
        self.assertTrue(self.settle(dispute, "resolved_buyer"))
        self.assertFalse(self.settle(dispute, "resolved_buyer"))
        self.assertEqual(balance_of(self.buyer), self.price)


class SellerWinTests(TestCase, _DisputeFixture):
    def test_resolving_for_the_seller_pays_the_held_amount(self):
        order, dispute = self.make_disputed_order()
        self.assertTrue(self.settle(dispute, "resolved_seller"))
        self.assertEqual(balance_of(self.seller), self.price)
        self.assertEqual(balance_of(self.buyer), Decimal("0.00"))

    def test_the_order_is_completed_and_the_hold_consumed(self):
        order, dispute = self.make_disputed_order()
        self.settle(dispute, "resolved_seller")
        order.refresh_from_db()
        self.assertEqual(order.status, "completed")
        self.assertIsNone(pending_hold(order))

    def test_settling_twice_pays_once(self):
        order, dispute = self.make_disputed_order()
        self.settle(dispute, "resolved_seller")
        self.settle(dispute, "resolved_seller")
        self.assertEqual(balance_of(self.seller), self.price)

    def test_buyer_and_seller_outcomes_are_mutually_exclusive(self):
        """Whichever resolution lands first owns the escrow. The other must
        not also pay, or one hold funds two payouts."""
        order, dispute = self.make_disputed_order()
        self.assertTrue(self.settle(dispute, "resolved_seller"))
        self.assertFalse(self.settle(dispute, "resolved_buyer"))
        self.assertEqual(balance_of(self.seller), self.price)
        self.assertEqual(balance_of(self.buyer), Decimal("0.00"))


class PartialRefundTests(TestCase, _DisputeFixture):
    def test_a_partial_refund_splits_the_held_amount(self):
        order, dispute = self.make_disputed_order()
        self.settle(dispute, "resolved_partial",
                    refund_amount=Decimal("200.00"))
        self.assertEqual(balance_of(self.buyer), Decimal("200.00"))
        self.assertEqual(balance_of(self.seller), Decimal("400.00"))

    def test_a_partial_split_never_exceeds_what_was_held(self):
        """`refund_amount` is admin-entered. It must be clamped to the escrow,
        or the split pays out more than the order ever collected."""
        order, dispute = self.make_disputed_order()
        before = money_supply()

        self.settle(dispute, "resolved_partial",
                    refund_amount=Decimal("99999.00"))

        self.assertEqual(
            money_supply(), before + self.price,
            "a partial refund released more than the escrow held")
        self.assertLessEqual(balance_of(self.buyer), self.price)

    def test_a_negative_refund_amount_cannot_drain_the_buyer(self):
        order, dispute = self.make_disputed_order()
        before = money_supply()
        self.settle(dispute, "resolved_partial",
                    refund_amount=Decimal("-500.00"))
        self.assertEqual(money_supply(), before + self.price)
        self.assertGreaterEqual(balance_of(self.buyer), Decimal("0.00"))

    def test_a_partial_refund_consumes_the_hold(self):
        order, dispute = self.make_disputed_order()
        self.settle(dispute, "resolved_partial",
                    refund_amount=Decimal("200.00"))
        self.assertIsNone(pending_hold(order))


class CrossPathTests(TestCase, _DisputeFixture):
    """The reason this matters beyond the admin: Phase 3A/3B endpoints share
    the same escrow record."""

    def _client(self, actor):
        c = APIClient()
        c.force_authenticate(user=actor)
        return c

    def test_a_seller_win_cannot_then_be_refunded_by_cancel(self):
        order, dispute = self.make_disputed_order(status="pending")
        self.settle(dispute, "resolved_seller")
        self.assertEqual(balance_of(self.seller), self.price)

        self._client(self.buyer).post(reverse("cancel-order", args=[order.id]))

        self.assertEqual(
            balance_of(self.buyer), Decimal("0.00"),
            "escrow paid to the seller was refunded to the buyer as well")
        self.assertEqual(balance_of(self.seller), self.price)

    def test_a_seller_win_cannot_then_be_refunded_by_decline(self):
        order, dispute = self.make_disputed_order(status="pending")
        self.settle(dispute, "resolved_seller")

        self._client(self.seller).post(
            "/api/workspace/orders/%s/decline/" % order.id)

        self.assertEqual(
            balance_of(self.buyer), Decimal("0.00"),
            "a declined dispute-resolved order paid the escrow out twice")

    def test_a_buyer_win_cannot_then_be_paid_by_complete(self):
        order, dispute = self.make_disputed_order(status="delivered")
        self.settle(dispute, "resolved_buyer")
        self.assertEqual(balance_of(self.buyer), self.price)

        self._client(self.buyer).post(
            reverse("complete-order", args=[order.id]))

        self.assertEqual(
            balance_of(self.seller), Decimal("0.00"),
            "escrow refunded to the buyer was also released to the seller")

    def test_a_cancelled_order_cannot_then_be_dispute_resolved(self):
        order, dispute = self.make_disputed_order(status="pending")
        self._client(self.buyer).post(reverse("cancel-order", args=[order.id]))
        self.assertEqual(balance_of(self.buyer), self.price)

        self.settle(dispute, "resolved_seller")

        self.assertEqual(
            balance_of(self.seller), Decimal("0.00"),
            "a refunded order was also paid out to the seller by the admin")

    def test_the_money_supply_never_grows_beyond_one_escrow(self):
        order, dispute = self.make_disputed_order(status="pending")
        before = money_supply()

        self.settle(dispute, "resolved_seller")
        self._client(self.buyer).post(reverse("cancel-order", args=[order.id]))
        self._client(self.seller).post(
            "/api/workspace/orders/%s/decline/" % order.id)
        self.settle(dispute, "resolved_buyer")

        self.assertEqual(
            money_supply(), before + self.price,
            "four settlement attempts released more than one escrow")


class AdminEntryPointTests(TestCase, _DisputeFixture):
    """The helper is not the product — the admin is.

    An early version of this fix wired `save_model` to `settle_dispute` without
    importing it there, and every test in this file still passed because they
    all called the helper directly. These drive the two real entry points.
    """

    def _admin(self):
        from django.contrib.admin.sites import AdminSite
        from workspace.admin import OrderDisputeAdmin
        a = OrderDisputeAdmin(OrderDispute, AdminSite())
        a.message_user = lambda *args, **kwargs: None
        return a

    def _request(self):
        from django.test import RequestFactory
        r = RequestFactory().get("/")
        r.user = self.admin
        return r

    class _Form:
        changed_data = ["status"]

        def __init__(self, old):
            self.initial = {"status": old}

    def test_the_bulk_action_resolves_for_the_buyer_once(self):
        order, dispute = self.make_disputed_order()
        adm, req = self._admin(), self._request()

        adm.resolve_for_buyer(req, OrderDispute.objects.filter(pk=dispute.pk))
        self.assertEqual(balance_of(self.buyer), self.price)

        # Re-running it must not pay again.
        adm.resolve_for_buyer(req, OrderDispute.objects.filter(pk=dispute.pk))
        self.assertEqual(balance_of(self.buyer), self.price)

    def test_the_bulk_action_resolves_for_the_seller_once(self):
        order, dispute = self.make_disputed_order()
        adm, req = self._admin(), self._request()

        adm.resolve_for_seller(req, OrderDispute.objects.filter(pk=dispute.pk))
        adm.resolve_for_seller(req, OrderDispute.objects.filter(pk=dispute.pk))

        self.assertEqual(balance_of(self.seller), self.price)

    def test_editing_the_status_to_resolved_buyer_pays_through_save_model(self):
        order, dispute = self.make_disputed_order()
        dispute.status = "resolved_buyer"
        self._admin().save_model(
            self._request(), dispute, self._Form("open"), True)
        self.assertEqual(balance_of(self.buyer), self.price)

    def test_editing_the_status_to_resolved_seller_pays_through_save_model(self):
        order, dispute = self.make_disputed_order()
        dispute.status = "resolved_seller"
        self._admin().save_model(
            self._request(), dispute, self._Form("under_review"), True)
        self.assertEqual(balance_of(self.seller), self.price)

    def test_save_model_partial_is_bounded_by_the_escrow(self):
        order, dispute = self.make_disputed_order()
        OrderDispute.objects.filter(pk=dispute.pk).update(
            refund_amount=Decimal("99999.00"))
        dispute.refresh_from_db()
        dispute.status = "resolved_partial"
        before = money_supply()

        self._admin().save_model(
            self._request(), dispute, self._Form("under_review"), True)

        self.assertEqual(
            money_supply(), before + self.price,
            "the admin form released more than the escrow held")

    def test_the_two_entry_points_cannot_pay_between_them(self):
        """Bulk action first, then a direct status edit on a stale object."""
        order, dispute = self.make_disputed_order()
        adm, req = self._admin(), self._request()
        stale = OrderDispute.objects.get(pk=dispute.pk)

        adm.resolve_for_seller(req, OrderDispute.objects.filter(pk=dispute.pk))
        stale.status = "resolved_buyer"
        adm.save_model(req, stale, self._Form("open"), True)

        self.assertEqual(
            balance_of(self.seller) + balance_of(self.buyer), self.price,
            "the action and the form each released the same escrow")


class ConcurrentDisputeTests(TransactionTestCase, _DisputeFixture):
    def _race(self, fns):
        barrier = threading.Barrier(len(fns))
        lock = threading.Lock()
        out = []

        def run(fn):
            def inner():
                barrier.wait()
                try:
                    r = fn()
                    with lock:
                        out.append(r)
                except Exception as exc:
                    with lock:
                        out.append(exc)
                finally:
                    connections.close_all()
            return inner

        threads = [threading.Thread(target=run(f)) for f in fns]
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=30)
        return out

    def test_five_concurrent_buyer_resolutions_refund_once(self):
        order, dispute = self.make_disputed_order()

        def go():
            fresh = OrderDispute.objects.get(pk=dispute.pk)
            return self.settle(fresh, "resolved_buyer")

        out = self._race([go] * 5)

        self.assertEqual(
            balance_of(self.buyer), self.price,
            "concurrent resolutions refunded %s; results=%s"
            % (balance_of(self.buyer), out))
        # settle_dispute returns the split it moved, or None when it lost.
        self.assertEqual(
            sum(1 for r in out if isinstance(r, dict)), 1,
            "more than one caller believed it had settled the dispute")

    def test_concurrent_buyer_and_seller_resolutions_pay_one_side_only(self):
        order, dispute = self.make_disputed_order()

        def buyer_win():
            return self.settle(OrderDispute.objects.get(pk=dispute.pk),
                               "resolved_buyer")

        def seller_win():
            return self.settle(OrderDispute.objects.get(pk=dispute.pk),
                               "resolved_seller")

        self._race([buyer_win, seller_win])

        total = balance_of(self.buyer) + balance_of(self.seller)
        self.assertEqual(
            total, self.price,
            "both sides were paid from one escrow (buyer=%s seller=%s)"
            % (balance_of(self.buyer), balance_of(self.seller)))

    def test_a_dispute_resolution_racing_a_cancel_releases_once(self):
        order, dispute = self.make_disputed_order(status="pending")

        def resolve():
            return self.settle(OrderDispute.objects.get(pk=dispute.pk),
                               "resolved_seller")

        def cancel():
            c = APIClient()
            c.force_authenticate(user=self.buyer)
            return c.post(reverse("cancel-order", args=[order.id])).status_code

        self._race([resolve, cancel])

        total = balance_of(self.buyer) + balance_of(self.seller)
        self.assertEqual(
            total, self.price,
            "the admin and the buyer each released the same escrow")
