# -*- coding: utf-8 -*-
"""The wallet primitive, including the races it exists to prevent.

Every test here corresponds to a way money was actually being lost or created
in this codebase. The concurrency tests use real threads and real database
connections — a test that only calls the function twice in sequence proves
nothing about the interleaving that causes the bug.
"""
import itertools
import threading
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.db import connection, connections
from django.test import TransactionTestCase

from base.wallet import WalletError, credit, debit, move_pending, to_money, transfer

User = get_user_model()


_counter = itertools.count(1)


def _make_user(tag, balance="0.00", pending="0.00"):
    # A deterministic sequence, not hash(): PYTHONHASHSEED is randomised per
    # process, so hashing the tag would produce a different phone number on
    # every run and collide unpredictably against the unique constraint.
    n = next(_counter)
    user = User.objects.create_user(
        username="w_%s_%d" % (tag, n), email="w_%s_%d@example.com" % (tag, n),
        password="x", first_name=tag, phone="+88010009%05d" % n)
    User.objects.filter(pk=user.pk).update(
        balance=Decimal(balance), pending_balance=Decimal(pending))
    user.refresh_from_db()
    return user


def balance_of(user):
    return User.objects.values_list("balance", flat=True).get(pk=user.pk)


def pending_of(user):
    return User.objects.values_list("pending_balance", flat=True).get(pk=user.pk)


class AmountValidationTests(TransactionTestCase):
    def test_floats_do_not_drift(self):
        # Decimal(0.1) is 0.1000000000000000055…; money arithmetic on that is
        # how a ledger stops balancing.
        self.assertEqual(to_money(0.1), Decimal("0.10"))

    def test_currency_rounds_half_up_not_bankers(self):
        """Decimal's default is ROUND_HALF_EVEN, which sends 10.005 to 10.00.
        A user looking at their wallet expects half to round away from zero."""
        self.assertEqual(to_money("10.005"), Decimal("10.01"))
        self.assertEqual(to_money("10.015"), Decimal("10.02"))
        self.assertEqual(to_money("10.014"), Decimal("10.01"))

    def test_rubbish_is_refused(self):
        for bad in ("abc", None, object()):
            with self.assertRaises(WalletError):
                to_money(bad)

    def test_zero_and_negative_are_refused(self):
        user = _make_user("val", "100.00")
        for bad in (0, "0.00", -5):
            with self.assertRaises(WalletError):
                debit(user.pk, bad, reason="test")
            with self.assertRaises(WalletError):
                credit(user.pk, bad, reason="test")

    def test_a_negative_credit_cannot_masquerade_as_a_debit(self):
        user = _make_user("sign", "100.00")
        with self.assertRaises(WalletError):
            credit(user.pk, -50, reason="sign error")
        self.assertEqual(balance_of(user), Decimal("100.00"))


class DebitCreditTests(TransactionTestCase):
    def test_debit_moves_the_money(self):
        user = _make_user("d1", "100.00")
        self.assertTrue(debit(user.pk, "30.00", reason="test"))
        self.assertEqual(balance_of(user), Decimal("70.00"))

    def test_debit_refuses_to_overdraw_and_says_so(self):
        user = _make_user("d2", "10.00")
        self.assertFalse(debit(user.pk, "10.01", reason="test"))
        self.assertEqual(balance_of(user), Decimal("10.00"))

    def test_debit_of_the_exact_balance_is_allowed(self):
        user = _make_user("d3", "10.00")
        self.assertTrue(debit(user.pk, "10.00", reason="test"))
        self.assertEqual(balance_of(user), Decimal("0.00"))

    def test_allow_negative_is_opt_in_only(self):
        user = _make_user("d4", "5.00")
        self.assertTrue(debit(user.pk, "20.00", reason="fee",
                              allow_negative=True))
        self.assertEqual(balance_of(user), Decimal("-15.00"))

    def test_credit_adds(self):
        user = _make_user("c1", "5.00")
        self.assertTrue(credit(user.pk, "2.50", reason="test"))
        self.assertEqual(balance_of(user), Decimal("7.50"))

    def test_credit_to_a_missing_user_raises(self):
        """This asserted `credit()` returns False, which is the contract that
        was deliberately tightened: every claim-then-credit caller ignored the
        return value, so the claim committed and nobody was paid. A missing
        recipient is a bug, so it now raises and rolls the claim back.
        Insufficient funds is still a return value — see debit() below."""
        import uuid
        with self.assertRaises(WalletError):
            credit(uuid.uuid4(), "5.00", reason="test")


class ConcurrencyTests(TransactionTestCase):
    """The bugs this module exists to prevent, reproduced with real threads."""

    def _race(self, target, count=2):
        barrier = threading.Barrier(count)
        results = []

        def run():
            barrier.wait()          # maximise the overlap
            try:
                results.append(target())
            finally:
                connections.close_all()

        threads = [threading.Thread(target=run) for _ in range(count)]
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=20)
        return results

    def test_two_concurrent_debits_cannot_both_spend_one_balance(self):
        """The read-modify-write bug: both requests read 100, both pass the
        check, and the second write discards the first deduction."""
        user = _make_user("race1", "100.00")
        results = self._race(
            lambda: debit(user.pk, "100.00", reason="race"), count=2)

        self.assertEqual(sorted(results), [False, True],
                         "exactly one debit must win")
        self.assertEqual(balance_of(user), Decimal("0.00"),
                         "balance went wrong — one spend was lost")

    def test_five_concurrent_debits_spend_at_most_the_balance(self):
        user = _make_user("race2", "50.00")
        results = self._race(
            lambda: debit(user.pk, "20.00", reason="race"), count=5)
        self.assertEqual(sum(1 for r in results if r), 2,
                         "50.00 can only fund two 20.00 debits")
        self.assertEqual(balance_of(user), Decimal("10.00"))

    def test_concurrent_credits_are_all_applied(self):
        """The mirror image: a lost credit is money the user never receives."""
        user = _make_user("race3", "0.00")
        self._race(lambda: credit(user.pk, "10.00", reason="race"), count=5)
        self.assertEqual(balance_of(user), Decimal("50.00"),
                         "a concurrent credit was lost")

    def test_concurrent_releases_of_the_same_escrow_pay_once(self):
        """The double-tapped gig approval."""
        user = _make_user("race4", "0.00", pending="100.00")
        results = self._race(
            lambda: move_pending(user.pk, "100.00", to_balance=True,
                                 reason="approve"),
            count=3)
        self.assertEqual(sum(1 for r in results if r), 1,
                         "the same escrow was released more than once")
        self.assertEqual(balance_of(user), Decimal("100.00"))
        self.assertEqual(pending_of(user), Decimal("0.00"))


class TransferTests(TransactionTestCase):
    def test_a_transfer_moves_both_sides(self):
        a = _make_user("t1", "100.00")
        b = _make_user("t2", "0.00")
        self.assertTrue(transfer(a.pk, b.pk, "40.00", reason="test"))
        self.assertEqual(balance_of(a), Decimal("60.00"))
        self.assertEqual(balance_of(b), Decimal("40.00"))

    def test_a_self_transfer_is_refused_because_it_mints_money(self):
        user = _make_user("t3", "100.00")
        with self.assertRaises(WalletError):
            transfer(user.pk, user.pk, "50.00", reason="test")
        self.assertEqual(balance_of(user), Decimal("100.00"))

    def test_an_underfunded_transfer_moves_nothing(self):
        a = _make_user("t4", "10.00")
        b = _make_user("t5", "0.00")
        self.assertFalse(transfer(a.pk, b.pk, "50.00", reason="test"))
        self.assertEqual(balance_of(a), Decimal("10.00"))
        self.assertEqual(balance_of(b), Decimal("0.00"),
                         "the recipient was credited without the sender paying")


class EscrowTests(TransactionTestCase):
    def test_reserve_then_release_conserves_money(self):
        user = _make_user("e1", "100.00")
        self.assertTrue(move_pending(user.pk, "40.00", to_balance=False,
                                     reason="reserve"))
        self.assertEqual(balance_of(user), Decimal("60.00"))
        self.assertEqual(pending_of(user), Decimal("40.00"))

        self.assertTrue(move_pending(user.pk, "40.00", to_balance=True,
                                     reason="release"))
        self.assertEqual(balance_of(user), Decimal("100.00"))
        self.assertEqual(pending_of(user), Decimal("0.00"))

    def test_cannot_release_escrow_that_was_never_reserved(self):
        user = _make_user("e2", "0.00", pending="10.00")
        self.assertFalse(move_pending(user.pk, "50.00", to_balance=True,
                                      reason="release"))
        self.assertEqual(balance_of(user), Decimal("0.00"))

    def test_cannot_reserve_more_than_the_balance(self):
        user = _make_user("e3", "10.00")
        self.assertFalse(move_pending(user.pk, "50.00", to_balance=False,
                                      reason="reserve"))
        self.assertEqual(pending_of(user), Decimal("0.00"))


class InvariantTests(TransactionTestCase):
    def test_money_is_conserved_across_a_transfer(self):
        a = _make_user("i1", "70.00")
        b = _make_user("i2", "30.00")
        before = balance_of(a) + balance_of(b)
        transfer(a.pk, b.pk, "25.00", reason="test")
        self.assertEqual(balance_of(a) + balance_of(b), before)

    def test_money_is_conserved_across_an_escrow_round_trip(self):
        user = _make_user("i3", "80.00", pending="20.00")
        before = balance_of(user) + pending_of(user)
        move_pending(user.pk, "30.00", to_balance=False, reason="reserve")
        move_pending(user.pk, "30.00", to_balance=True, reason="release")
        self.assertEqual(balance_of(user) + pending_of(user), before)

    def test_a_failed_debit_changes_nothing(self):
        user = _make_user("i4", "5.00")
        debit(user.pk, "100.00", reason="test")
        self.assertEqual(balance_of(user), Decimal("5.00"))
