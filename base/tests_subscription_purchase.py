# -*- coding: utf-8 -*-
"""Buying Pro charges exactly once, and only if the money is there.

THE BUG

`base.models.Subscription.save()` charged on creation with no check at all:

    if not self.pk:
        self.user.is_pro = True
        self.user.pro_validity = ...
        self.user.balance -= Decimal(self.total)
        self.user.save()

There is no `balance >= total` anywhere in the model. The only affordability
check lives in the view that creates it, in Python, against an unlocked read —
so the balance goes straight through zero and the buyer gets Pro for money they
did not have. Two concurrent purchases both pass the view's check and both
charge.

WHAT MUST NOT CHANGE

`if not self.pk` is load-bearing: a subscription that is merely edited or
re-saved must never charge again. `base.models.Subscription` has exactly one
programmatic creator (`base/views.py`, the Pro purchase endpoint) plus the
Django admin. The `subscription` app's own models are a different system and
are not touched here.
"""
import itertools
import threading
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.db import connections
from django.test import TestCase, TransactionTestCase

from base.models import Subscription

User = get_user_model()
_counter = itertools.count(1)


def _user(tag, balance="0.00"):
    n = next(_counter)
    user = User.objects.create_user(
        username="sb_%s_%d" % (tag, n), email="sb_%s_%d@example.com" % (tag, n),
        password="x", first_name=tag, phone="+88010001%05d" % n)
    User.objects.filter(pk=user.pk).update(balance=Decimal(balance))
    user.refresh_from_db()
    return user


def balance_of(user):
    return User.objects.values_list("balance", flat=True).get(pk=user.pk)


def is_pro(user):
    return User.objects.values_list("is_pro", flat=True).get(pk=user.pk)


class PurchaseTests(TestCase):
    def test_buying_pro_charges_the_total(self):
        user = _user("s1", "500.00")
        Subscription.objects.create(user=user, months=1, total=Decimal("149.00"))
        self.assertEqual(balance_of(user), Decimal("351.00"))

    def test_buying_pro_grants_pro_status_and_validity(self):
        user = _user("s2", "500.00")
        Subscription.objects.create(user=user, months=2, total=Decimal("298.00"))
        user.refresh_from_db()
        self.assertTrue(is_pro(user))
        self.assertIsNotNone(user.pro_validity)

    def test_an_unaffordable_purchase_is_refused(self):
        user = _user("s3", "100.00")
        with self.assertRaises(ValidationError):
            Subscription.objects.create(
                user=user, months=1, total=Decimal("149.00"))
        self.assertEqual(balance_of(user), Decimal("100.00"))

    def test_an_unaffordable_purchase_does_not_grant_pro(self):
        """The whole point: no money, no Pro."""
        user = _user("s4", "10.00")
        try:
            Subscription.objects.create(
                user=user, months=1, total=Decimal("149.00"))
        except ValidationError:
            pass
        self.assertFalse(is_pro(user), "Pro was granted without payment")

    def test_an_unaffordable_purchase_leaves_no_subscription_row(self):
        user = _user("s5", "10.00")
        try:
            Subscription.objects.create(
                user=user, months=1, total=Decimal("149.00"))
        except ValidationError:
            pass
        self.assertFalse(Subscription.objects.filter(user=user).exists())

    def test_the_balance_never_goes_negative(self):
        user = _user("s6", "148.99")
        try:
            Subscription.objects.create(
                user=user, months=1, total=Decimal("149.00"))
        except ValidationError:
            pass
        self.assertGreaterEqual(
            balance_of(user), Decimal("0.00"),
            "the wallet went negative buying Pro")

    def test_spending_the_exact_balance_is_allowed(self):
        user = _user("s7", "149.00")
        Subscription.objects.create(user=user, months=1, total=Decimal("149.00"))
        self.assertEqual(balance_of(user), Decimal("0.00"))
        self.assertTrue(is_pro(user))

    def test_a_zero_total_subscription_charges_nothing(self):
        """Comped/promotional Pro must not be refused by the money guard."""
        user = _user("s8", "5.00")
        Subscription.objects.create(user=user, months=1, total=Decimal("0.00"))
        self.assertEqual(balance_of(user), Decimal("5.00"))
        self.assertTrue(is_pro(user))


class EditingTests(TestCase):
    """A subscription that already exists must never charge again."""

    def test_resaving_an_existing_subscription_does_not_charge(self):
        user = _user("e1", "500.00")
        sub = Subscription.objects.create(
            user=user, months=1, total=Decimal("149.00"))
        after_purchase = balance_of(user)

        sub.save()
        sub.save()

        self.assertEqual(balance_of(user), after_purchase)

    def test_editing_the_months_of_an_existing_subscription_does_not_charge(self):
        user = _user("e2", "500.00")
        sub = Subscription.objects.create(
            user=user, months=1, total=Decimal("149.00"))
        after_purchase = balance_of(user)

        sub.months = 12
        sub.save()

        self.assertEqual(
            balance_of(user), after_purchase,
            "editing an existing subscription charged the user again")

    def test_a_stale_subscription_object_does_not_recharge(self):
        user = _user("e3", "500.00")
        sub = Subscription.objects.create(
            user=user, months=1, total=Decimal("149.00"))
        stale = Subscription.objects.get(pk=sub.pk)
        after_purchase = balance_of(user)

        stale.save()

        self.assertEqual(balance_of(user), after_purchase)

    def test_a_subscription_does_not_clobber_a_concurrent_balance_change(self):
        user = _user("e4", "500.00")
        stale = User.objects.get(pk=user.pk)

        User.objects.filter(pk=user.pk).update(
            balance=Decimal("500.00") + Decimal("200.00"))

        Subscription.objects.create(
            user=stale, months=1, total=Decimal("149.00"))

        self.assertEqual(
            balance_of(user), Decimal("551.00"),
            "buying Pro discarded a concurrent deposit")


class ConcurrentPurchaseTests(TransactionTestCase):
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
        user = _user("c1", "149.00")
        results = self._race(
            lambda: Subscription.objects.create(
                user=User.objects.get(pk=user.pk), months=1,
                total=Decimal("149.00")), count=2)

        self.assertGreaterEqual(
            balance_of(user), Decimal("0.00"),
            "the wallet went negative: %s" % balance_of(user))
        self.assertEqual(sum(1 for r in results if r), 1,
                         "149.00 funded two subscriptions")

    def test_five_concurrent_purchases_spend_at_most_the_balance(self):
        user = _user("c2", "300.00")
        self._race(
            lambda: Subscription.objects.create(
                user=User.objects.get(pk=user.pk), months=1,
                total=Decimal("149.00")), count=5)

        self.assertGreaterEqual(balance_of(user), Decimal("0.00"))
        self.assertEqual(balance_of(user), Decimal("2.00"),
                         "300.00 can only fund two 149.00 subscriptions")

    def test_every_subscription_row_corresponds_to_money_taken(self):
        user = _user("c3", "300.00")
        self._race(
            lambda: Subscription.objects.create(
                user=User.objects.get(pk=user.pk), months=1,
                total=Decimal("149.00")), count=5)

        rows = Subscription.objects.filter(user=user).count()
        spent = Decimal("300.00") - balance_of(user)
        self.assertEqual(
            spent, rows * Decimal("149.00"),
            "%d subscription rows exist but %s was taken" % (rows, spent))
