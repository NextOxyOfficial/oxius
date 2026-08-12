# -*- coding: utf-8 -*-
"""A genuine payment must credit the wallet exactly once, however it arrives.

THE BUG

`_finalize_verified_deposit` decided whether a payment had already been credited
with a SELECT:

    existing = Balance.objects.filter(merchant_invoice_no=inv, ...).first()
    if existing: return already_processed
    Balance.objects.create(...)          # credits

Two requests carrying the same real payment both run the SELECT before either
runs the INSERT. Both see nothing. Both credit. `merchant_invoice_no` had no
unique index, so nothing downstream caught it either.

Reaching that function needs no session: `finalizePaymentWithState` is
unauthenticated (no @permission_classes, and the project sets no
DEFAULT_PERMISSION_CLASSES, so DRF falls back to AllowAny), it takes the user
identity from a cached payment_ref that `cache.get` never consumed, and there
was no throttle. One real deposit could therefore be replayed into N credits.

These tests drive the real production function, not a copy of its logic.
"""
import itertools
import threading
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.db import connections
from django.test import TestCase, TransactionTestCase

from base.models import Balance
from base.pay import _finalize_verified_deposit
from payments.models import ProcessedPayment

User = get_user_model()
_counter = itertools.count(1)


def _user(tag, balance="0.00"):
    n = next(_counter)
    user = User.objects.create_user(
        username="pay_%s_%d" % (tag, n), email="pay_%s_%d@example.com" % (tag, n),
        password="x", first_name=tag, phone="+88010006%05d" % n)
    User.objects.filter(pk=user.pk).update(balance=Decimal(balance))
    user.refresh_from_db()
    return user


def balance_of(user):
    return User.objects.values_list("balance", flat=True).get(pk=user.pk)


def details(invoice, amount="500.00"):
    """A ShurjoPay verification payload for a genuinely successful payment."""
    return {
        "merchant_invoice_no": invoice,
        "payable_amount": amount,
        "amount": amount,
        "received_amount": amount,
        "payment_method": "shurjopay",
        "shurjopay_order_id": "sp_%s" % invoice,
        "bank_status": "Success",
        "shurjopay_message": "Success",
    }


def deposit_rows(user):
    return Balance.objects.filter(user=user, transaction_type="deposit")


class HappyPathTests(TestCase):
    def test_a_genuine_payment_credits_once(self):
        user = _user("happy", "0.00")
        result = _finalize_verified_deposit(user=user, payment_details=details("INV-1"))

        self.assertFalse(result["already_processed"])
        self.assertEqual(balance_of(user), Decimal("500.00"))
        self.assertEqual(deposit_rows(user).count(), 1)

    def test_the_claim_records_the_payment(self):
        user = _user("claim", "0.00")
        _finalize_verified_deposit(user=user, payment_details=details("INV-2"))

        claim = ProcessedPayment.objects.get(provider="shurjopay", invoice_no="INV-2")
        self.assertEqual(claim.amount, Decimal("500.00"))
        self.assertEqual(claim.account_id, str(user.pk))
        self.assertTrue(claim.balance_id, "the claim did not record the Balance row")

    def test_two_different_payments_both_credit(self):
        """The gate must not be so tight that real deposits are refused."""
        user = _user("two", "0.00")
        _finalize_verified_deposit(user=user, payment_details=details("INV-3", "100.00"))
        _finalize_verified_deposit(user=user, payment_details=details("INV-4", "250.00"))

        self.assertEqual(balance_of(user), Decimal("350.00"))
        self.assertEqual(deposit_rows(user).count(), 2)

    def test_different_users_may_use_unrelated_invoices(self):
        a = _user("ua", "0.00")
        b = _user("ub", "0.00")
        _finalize_verified_deposit(user=a, payment_details=details("INV-A", "100.00"))
        _finalize_verified_deposit(user=b, payment_details=details("INV-B", "100.00"))
        self.assertEqual(balance_of(a), Decimal("100.00"))
        self.assertEqual(balance_of(b), Decimal("100.00"))


class SequentialReplayTests(TestCase):
    def test_replaying_the_same_payment_does_not_credit_again(self):
        user = _user("replay", "0.00")
        _finalize_verified_deposit(user=user, payment_details=details("INV-5"))

        for _ in range(5):
            again = _finalize_verified_deposit(
                user=user, payment_details=details("INV-5"))
            self.assertTrue(again["already_processed"])

        self.assertEqual(balance_of(user), Decimal("500.00"),
                         "a replayed payment credited the wallet again")
        self.assertEqual(deposit_rows(user).count(), 1)

    def test_a_replay_cannot_change_the_amount(self):
        """Re-sending the same invoice with a bigger amount must credit nothing."""
        user = _user("inflate", "0.00")
        _finalize_verified_deposit(user=user, payment_details=details("INV-6", "100.00"))

        _finalize_verified_deposit(
            user=user, payment_details=details("INV-6", "999999.00"))

        self.assertEqual(balance_of(user), Decimal("100.00"))

    def test_another_user_cannot_claim_a_used_invoice(self):
        """The invoice is globally unique, so a second account replaying someone
        else's invoice number gets nothing."""
        victim = _user("v1", "0.00")
        attacker = _user("v2", "0.00")
        _finalize_verified_deposit(user=victim, payment_details=details("INV-7", "500.00"))

        result = _finalize_verified_deposit(
            user=attacker, payment_details=details("INV-7", "500.00"))

        self.assertTrue(result["already_processed"])
        self.assertEqual(balance_of(attacker), Decimal("0.00"),
                         "a replayed invoice credited a different account")

    def test_a_missing_invoice_number_is_refused(self):
        user = _user("noinv", "0.00")
        with self.assertRaises(ValueError):
            _finalize_verified_deposit(
                user=user, payment_details={"payable_amount": "100.00"})
        self.assertEqual(balance_of(user), Decimal("0.00"))


class FailureRollbackTests(TestCase):
    def test_a_failed_credit_releases_the_claim_so_a_retry_works(self):
        """If crediting blows up, the buyer has paid and MUST still be able to
        get their money. A claim left behind would block that forever."""
        user = _user("rollback", "0.00")
        boom = details("INV-8")

        import base.pay as pay
        original = pay.Balance.objects.create

        def explode(*args, **kwargs):
            raise RuntimeError("database went away mid-credit")

        pay.Balance.objects.create = explode
        try:
            with self.assertRaises(RuntimeError):
                _finalize_verified_deposit(user=user, payment_details=boom)
        finally:
            pay.Balance.objects.create = original

        self.assertFalse(
            ProcessedPayment.objects.filter(invoice_no="INV-8").exists(),
            "the claim survived a failed credit and would block the retry")
        self.assertEqual(balance_of(user), Decimal("0.00"))

        # The retry now succeeds.
        result = _finalize_verified_deposit(user=user, payment_details=boom)
        self.assertFalse(result["already_processed"])
        self.assertEqual(balance_of(user), Decimal("500.00"))


class ConcurrentReplayTests(TransactionTestCase):
    """The actual vulnerability, with real threads and real connections."""

    def _race(self, target, count):
        barrier = threading.Barrier(count)
        results = []
        errors = []

        def run():
            barrier.wait()
            try:
                results.append(target())
            except Exception as exc:          # noqa: BLE001 - recorded, asserted on
                errors.append(exc)
            finally:
                connections.close_all()

        threads = [threading.Thread(target=run) for _ in range(count)]
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=30)
        return results, errors

    def test_two_simultaneous_finalizations_credit_once(self):
        user = _user("race1", "0.00")

        results, errors = self._race(
            lambda: _finalize_verified_deposit(
                user=user, payment_details=details("RACE-1", "500.00")),
            count=2)

        self.assertEqual(errors, [], "a concurrent finalization raised")
        self.assertEqual(
            balance_of(user), Decimal("500.00"),
            "one payment was credited more than once")
        self.assertEqual(deposit_rows(user).count(), 1)
        self.assertEqual(
            sum(1 for r in results if not r["already_processed"]), 1,
            "more than one request believed it was the first")

    def test_eight_simultaneous_finalizations_credit_once(self):
        """The attack as it would actually be run: fire the replay in parallel."""
        user = _user("race2", "0.00")

        results, errors = self._race(
            lambda: _finalize_verified_deposit(
                user=user, payment_details=details("RACE-2", "1000.00")),
            count=8)

        self.assertEqual(errors, [], "a concurrent finalization raised")
        self.assertEqual(
            balance_of(user), Decimal("1000.00"),
            "8 concurrent replays minted %s" % balance_of(user))
        self.assertEqual(deposit_rows(user).count(), 1)
        self.assertEqual(
            ProcessedPayment.objects.filter(invoice_no="RACE-2").count(), 1)

    def test_concurrent_replays_across_two_accounts_credit_once_in_total(self):
        """The same invoice pointed at two different accounts."""
        a = _user("racea", "0.00")
        b = _user("raceb", "0.00")
        users = itertools.cycle([a, b])
        lock = threading.Lock()

        def attempt():
            with lock:
                who = next(users)
            return _finalize_verified_deposit(
                user=who, payment_details=details("RACE-3", "400.00"))

        _, errors = self._race(attempt, count=6)

        self.assertEqual(errors, [])
        self.assertEqual(
            balance_of(a) + balance_of(b), Decimal("400.00"),
            "one invoice credited more than 400.00 across accounts")

    def test_the_money_supply_grows_by_exactly_the_payment(self):
        """The invariant that matters: N replays must not create money."""
        user = _user("supply", "0.00")
        before = sum(User.objects.values_list("balance", flat=True))

        self._race(
            lambda: _finalize_verified_deposit(
                user=user, payment_details=details("RACE-4", "750.00")),
            count=5)

        after = sum(User.objects.values_list("balance", flat=True))
        self.assertEqual(
            after - before, Decimal("750.00"),
            "the money supply grew by %s for a 750.00 payment" % (after - before))
