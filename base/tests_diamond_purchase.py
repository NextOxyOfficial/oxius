# -*- coding: utf-8 -*-
"""Buying diamonds cannot spend money the wallet does not have.

THE BUG

`DiamondTransaction.save()` decided affordability in Python and then wrote:

    if self.user.balance >= self.cost:
        self.user.balance -= self.cost
        self.user.diamond_balance += self.amount
        self.user.save()

Two purchases interleaved there both read the same balance, both pass, and both
write — the wallet goes below zero and diamonds are created against money that
was never there.

SCOPE, HONESTLY

The live HTTP endpoint (`base/views.py`, diamond package purchase) already wraps
this in `transaction.atomic()` with `select_for_update()` on the user row, so an
ordinary buyer cannot currently trigger it. The model is nonetheless unsafe on
its own, and it has a second live caller that holds no lock: the Django admin,
where `DiamondTransaction` is registered and staff can create a purchase row
directly. These tests exercise the model the way an unlocked caller does.

The `self.user.save()` was a separate hazard: a full-row write from a possibly
stale object, so a diamond purchase could roll back a deposit that landed while
the buyer was choosing a package.
"""
import itertools
import threading
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.db import connections
from django.test import TestCase, TransactionTestCase

from base.models import DiamondTransaction

User = get_user_model()
_counter = itertools.count(1)


def _user(tag, balance="0.00", diamonds=0):
    n = next(_counter)
    user = User.objects.create_user(
        username="dm_%s_%d" % (tag, n), email="dm_%s_%d@example.com" % (tag, n),
        password="x", first_name=tag, phone="+88010002%05d" % n)
    User.objects.filter(pk=user.pk).update(
        balance=Decimal(balance), diamond_balance=diamonds)
    user.refresh_from_db()
    return user


def balance_of(user):
    return User.objects.values_list("balance", flat=True).get(pk=user.pk)


def diamonds_of(user):
    return User.objects.values_list("diamond_balance", flat=True).get(pk=user.pk)


def buy(user, *, cost, diamonds):
    return DiamondTransaction.objects.create(
        user=user, transaction_type="purchase",
        amount=diamonds, cost=Decimal(cost))


class PurchaseTests(TestCase):
    def test_a_purchase_takes_the_money_and_grants_the_diamonds(self):
        user = _user("p1", "500.00")
        buy(user, cost="100.00", diamonds=50)
        self.assertEqual(balance_of(user), Decimal("400.00"))
        self.assertEqual(diamonds_of(user), 50)

    def test_a_purchase_is_marked_completed_and_approved(self):
        user = _user("p2", "500.00")
        txn = buy(user, cost="100.00", diamonds=50)
        txn.refresh_from_db()
        self.assertTrue(txn.completed)
        self.assertTrue(txn.approved)

    def test_an_unaffordable_purchase_is_refused(self):
        user = _user("p3", "50.00")
        with self.assertRaises(ValidationError):
            buy(user, cost="50.01", diamonds=10)
        self.assertEqual(balance_of(user), Decimal("50.00"))
        self.assertEqual(diamonds_of(user), 0)

    def test_a_refused_purchase_creates_no_transaction_row(self):
        user = _user("p4", "10.00")
        before = DiamondTransaction.objects.count()
        try:
            buy(user, cost="999.00", diamonds=100)
        except ValidationError:
            pass
        self.assertEqual(DiamondTransaction.objects.count(), before)

    def test_spending_the_exact_balance_is_allowed(self):
        user = _user("p5", "100.00")
        buy(user, cost="100.00", diamonds=25)
        self.assertEqual(balance_of(user), Decimal("0.00"))
        self.assertEqual(diamonds_of(user), 25)

    def test_a_zero_cost_purchase_still_grants_diamonds(self):
        """Promotional packs exist; a free pack must not be refused, and must
        not touch the wallet."""
        user = _user("p6", "10.00")
        buy(user, cost="0.00", diamonds=5)
        self.assertEqual(balance_of(user), Decimal("10.00"))
        self.assertEqual(diamonds_of(user), 5)

    def test_resaving_a_completed_purchase_does_not_charge_again(self):
        user = _user("p7", "500.00")
        txn = buy(user, cost="100.00", diamonds=50)
        txn.save()
        txn.save()
        self.assertEqual(balance_of(user), Decimal("400.00"))
        self.assertEqual(diamonds_of(user), 50)

    def test_a_purchase_does_not_clobber_a_concurrent_balance_change(self):
        """`self.user.save()` wrote every column from a stale object."""
        user = _user("p8", "500.00")
        stale = User.objects.get(pk=user.pk)

        User.objects.filter(pk=user.pk).update(
            balance=Decimal("500.00") + Decimal("300.00"))

        DiamondTransaction.objects.create(
            user=stale, transaction_type="purchase",
            amount=10, cost=Decimal("100.00"))

        self.assertEqual(
            balance_of(user), Decimal("700.00"),
            "the diamond purchase discarded a concurrent deposit")


class OtherTransactionTypeTests(TestCase):
    """Behaviour that must survive the fix."""

    def test_a_bonus_grants_diamonds_without_touching_the_wallet(self):
        user = _user("b1", "100.00")
        DiamondTransaction.objects.create(
            user=user, transaction_type="bonus", amount=20)
        self.assertEqual(diamonds_of(user), 20)
        self.assertEqual(balance_of(user), Decimal("100.00"))

    def test_an_admin_adjustment_still_applies(self):
        user = _user("b2", "0.00", diamonds=10)
        DiamondTransaction.objects.create(
            user=user, transaction_type="admin", amount=-5)
        self.assertEqual(diamonds_of(user), 5)

    def test_a_gift_moves_diamonds_between_users(self):
        sender = _user("g1", "0.00", diamonds=30)
        recipient = _user("g2", "0.00", diamonds=0)
        DiamondTransaction.objects.create(
            user=sender, to_user=recipient,
            transaction_type="gift", amount=10)
        self.assertEqual(diamonds_of(sender), 20)
        self.assertEqual(diamonds_of(recipient), 10)

    def test_a_prepaid_row_logged_as_completed_grants_nothing_again(self):
        """The IAP path writes a completed purchase row purely as history —
        the diamonds were already granted by the store flow."""
        user = _user("g3", "100.00", diamonds=0)
        DiamondTransaction.objects.create(
            user=user, transaction_type="purchase", amount=99,
            cost=Decimal("50.00"), completed=True, approved=True)
        self.assertEqual(balance_of(user), Decimal("100.00"))
        self.assertEqual(diamonds_of(user), 0)


class ConcurrentPurchaseTests(TransactionTestCase):
    """Real threads, no caller-side lock — the Django admin's situation."""

    def _race(self, target, count):
        barrier = threading.Barrier(count)
        lock = threading.Lock()
        results = []

        def run():
            barrier.wait()
            try:
                target()
                with lock:
                    results.append(True)
            except Exception:
                with lock:
                    results.append(False)
            finally:
                connections.close_all()

        threads = [threading.Thread(target=run) for _ in range(count)]
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=30)
        return results

    def test_two_concurrent_purchases_cannot_overdraw(self):
        user = _user("r1", "100.00")
        results = self._race(
            lambda: buy(User.objects.get(pk=user.pk),
                        cost="100.00", diamonds=50), count=2)

        self.assertGreaterEqual(
            balance_of(user), Decimal("0.00"),
            "the wallet went negative: %s" % balance_of(user))
        self.assertEqual(sum(1 for r in results if r), 1,
                         "100.00 funded more than one 100.00 purchase")
        self.assertEqual(diamonds_of(user), 50)

    def test_five_concurrent_purchases_spend_at_most_the_balance(self):
        user = _user("r2", "100.00")
        self._race(
            lambda: buy(User.objects.get(pk=user.pk),
                        cost="40.00", diamonds=10), count=5)

        self.assertGreaterEqual(balance_of(user), Decimal("0.00"))
        self.assertEqual(balance_of(user), Decimal("20.00"),
                         "100.00 can only fund two 40.00 purchases")
        self.assertEqual(diamonds_of(user), 20)

    def test_diamonds_granted_always_match_the_money_taken(self):
        """The invariant: every diamond granted was paid for."""
        user = _user("r3", "100.00")
        self._race(
            lambda: buy(User.objects.get(pk=user.pk),
                        cost="25.00", diamonds=5), count=6)

        spent = Decimal("100.00") - balance_of(user)
        self.assertEqual(
            diamonds_of(user) * Decimal("5.00"), spent,
            "diamonds granted (%s) do not match money taken (%s)"
            % (diamonds_of(user), spent))

    def test_a_failed_purchase_grants_no_diamonds(self):
        user = _user("r4", "30.00")
        self._race(
            lambda: buy(User.objects.get(pk=user.pk),
                        cost="30.00", diamonds=10), count=4)
        self.assertEqual(diamonds_of(user), 10)
        self.assertEqual(balance_of(user), Decimal("0.00"))
