# -*- coding: utf-8 -*-
"""The withdrawal lifecycle: hold, approve, reject, refund.

THE BUG THESE EXIST FOR

`Balance.save()` holds the money by debiting `payable_amount`:

    User.objects.filter(pk=..., balance__gte=amount).update(...)   # payable_amount

and refunded a rejected withdrawal by crediting `self.amount`:

    self.user.balance += self.amount

Two different columns. Both default to 0.00, and nothing on any withdrawal
path populates `amount` — the app does not send it and `postBalance` does not
set it. So rejecting a withdrawal credited **zero**: the user's money stayed
held, `completed` was set so it could never be retried, and an email went out
telling them they had been refunded.

The refund was also non-idempotent (an in-memory `not self.completed` that two
concurrent saves both read as False) and used `self.user.save()`, which writes
every column of a possibly-stale User row and so could roll back a concurrent
deposit.
"""
import itertools
import threading
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.db import connections
from django.test import TestCase, TransactionTestCase

from base.models import Balance

User = get_user_model()
_counter = itertools.count(1)


def _user(tag, balance="0.00"):
    n = next(_counter)
    user = User.objects.create_user(
        username="wd_%s_%d" % (tag, n), email="wd_%s_%d@example.com" % (tag, n),
        password="x", first_name=tag, phone="+88010007%05d" % n)
    User.objects.filter(pk=user.pk).update(balance=Decimal(balance))
    user.refresh_from_db()
    return user


def balance_of(user):
    return User.objects.values_list("balance", flat=True).get(pk=user.pk)


def request_withdrawal(user, amount):
    """A withdrawal exactly as the API creates one: payable_amount only."""
    return Balance.objects.create(
        user=user, transaction_type="withdraw",
        payable_amount=Decimal(amount),
    )


def reject(row, reason="not verified"):
    """A rejection exactly as the admin performs one: flip the flag, save."""
    row.rejected = True
    if hasattr(row, "rejection_reason"):
        row.rejection_reason = reason
    row.save()
    return row


class HoldTests(TestCase):
    def test_requesting_a_withdrawal_holds_exactly_the_payable_amount(self):
        user = _user("hold", "1000.00")
        request_withdrawal(user, "300.00")
        self.assertEqual(balance_of(user), Decimal("700.00"))

    def test_a_withdrawal_larger_than_the_balance_is_refused(self):
        user = _user("hold2", "100.00")
        with self.assertRaises(ValidationError):
            request_withdrawal(user, "100.01")
        self.assertEqual(balance_of(user), Decimal("100.00"))

    def test_a_withdrawal_of_the_entire_balance_is_allowed(self):
        user = _user("hold3", "250.00")
        request_withdrawal(user, "250.00")
        self.assertEqual(balance_of(user), Decimal("0.00"))

    def test_a_zero_withdrawal_is_refused(self):
        user = _user("hold4", "100.00")
        with self.assertRaises(ValidationError):
            request_withdrawal(user, "0.00")
        self.assertEqual(balance_of(user), Decimal("100.00"))

    def test_a_negative_withdrawal_cannot_credit_the_wallet(self):
        """A sign error must not become a deposit."""
        user = _user("hold5", "100.00")
        with self.assertRaises(ValidationError):
            request_withdrawal(user, "-500.00")
        self.assertEqual(balance_of(user), Decimal("100.00"))

    def test_resaving_a_pending_withdrawal_does_not_hold_twice(self):
        user = _user("hold6", "1000.00")
        row = request_withdrawal(user, "200.00")
        row.save()
        row.save()
        self.assertEqual(balance_of(user), Decimal("800.00"))


class RefundTests(TestCase):
    """The core of this batch."""

    def test_rejecting_a_withdrawal_refunds_the_money(self):
        """The headline bug: this refunded 0.00."""
        user = _user("ref1", "1000.00")
        row = request_withdrawal(user, "300.00")
        self.assertEqual(balance_of(user), Decimal("700.00"))

        reject(row)

        self.assertEqual(
            balance_of(user), Decimal("1000.00"),
            "the rejected withdrawal did not give the money back")

    def test_the_refund_equals_the_amount_that_was_held(self):
        """Not `amount`, not a client figure — the column the hold debited."""
        user = _user("ref2", "500.00")
        row = request_withdrawal(user, "175.50")
        held = Decimal("500.00") - balance_of(user)
        reject(row)
        refunded = balance_of(user) - (Decimal("500.00") - held)
        self.assertEqual(refunded, held)

    def test_a_stale_amount_column_cannot_inflate_the_refund(self):
        """`amount` is a separate column. Even set to something large, the
        refund must follow what was actually held."""
        user = _user("ref3", "1000.00")
        row = request_withdrawal(user, "100.00")
        Balance.objects.filter(pk=row.pk).update(amount=Decimal("99999.00"))
        row.refresh_from_db()

        reject(row)

        self.assertEqual(
            balance_of(user), Decimal("1000.00"),
            "the refund followed `amount` instead of what was held")

    def test_a_zero_amount_column_cannot_swallow_the_refund(self):
        """The production state: amount == 0.00 on every real row."""
        user = _user("ref4", "800.00")
        row = request_withdrawal(user, "250.00")
        self.assertEqual(row.amount, Decimal("0.00"),
                         "premise check: amount is never populated")
        reject(row)
        self.assertEqual(balance_of(user), Decimal("800.00"))

    def test_a_rejected_withdrawal_is_marked_settled(self):
        user = _user("ref5", "400.00")
        row = request_withdrawal(user, "100.00")
        reject(row)
        row.refresh_from_db()
        self.assertTrue(row.completed)
        self.assertTrue(row.rejected)


class DoubleRefundTests(TestCase):
    def test_saving_a_rejected_row_again_does_not_refund_again(self):
        user = _user("dbl1", "1000.00")
        row = request_withdrawal(user, "300.00")
        reject(row)
        self.assertEqual(balance_of(user), Decimal("1000.00"))

        row.save()
        row.save()

        self.assertEqual(
            balance_of(user), Decimal("1000.00"),
            "re-saving a rejected withdrawal minted money")

    def test_rejecting_an_already_rejected_row_is_a_no_op(self):
        user = _user("dbl2", "600.00")
        row = request_withdrawal(user, "200.00")
        reject(row)
        reject(row, "again")
        self.assertEqual(balance_of(user), Decimal("600.00"))

    def test_a_second_object_over_the_same_row_cannot_refund_again(self):
        """Two admins with the page open, both loaded before either saved."""
        user = _user("dbl3", "1000.00")
        row = request_withdrawal(user, "400.00")
        first = Balance.objects.get(pk=row.pk)
        second = Balance.objects.get(pk=row.pk)   # both see completed=False

        reject(first)
        reject(second)

        self.assertEqual(
            balance_of(user), Decimal("1000.00"),
            "two stale objects each paid the refund")


class InvalidTransitionTests(TestCase):
    def test_an_approved_withdrawal_is_not_refunded_when_rejected_later(self):
        """Approval means the money was paid out off-platform. Rejecting
        afterwards must not hand it back as well."""
        user = _user("inv1", "1000.00")
        row = request_withdrawal(user, "250.00")
        row.approved = True
        row.save()
        after_approval = balance_of(user)
        self.assertEqual(after_approval, Decimal("750.00"))

        reject(row)

        self.assertEqual(
            balance_of(user), after_approval,
            "an approved (paid out) withdrawal was also refunded")

    def test_approving_a_withdrawal_moves_no_money(self):
        user = _user("inv2", "1000.00")
        row = request_withdrawal(user, "300.00")
        row.approved = True
        row.save()
        self.assertEqual(balance_of(user), Decimal("700.00"))

    def test_approval_does_not_clobber_a_concurrent_balance_change(self):
        """`self.user.save()` wrote every column of a stale User row, so
        approving a withdrawal could roll back a deposit that landed in
        between."""
        user = _user("inv3", "1000.00")
        row = request_withdrawal(user, "200.00")          # -> 800
        stale = Balance.objects.get(pk=row.pk)
        stale.user                                        # cache the User row

        User.objects.filter(pk=user.pk).update(           # a concurrent credit
            balance=Decimal("800.00") + Decimal("500.00"))

        stale.approved = True
        stale.save()

        self.assertEqual(
            balance_of(user), Decimal("1300.00"),
            "approving the withdrawal discarded a concurrent credit")

    def test_a_rejection_does_not_clobber_a_concurrent_balance_change(self):
        user = _user("inv4", "1000.00")
        row = request_withdrawal(user, "200.00")          # -> 800
        stale = Balance.objects.get(pk=row.pk)
        stale.user

        User.objects.filter(pk=user.pk).update(
            balance=Decimal("800.00") + Decimal("500.00"))   # -> 1300

        reject(stale)

        self.assertEqual(
            balance_of(user), Decimal("1500.00"),
            "the refund overwrote a concurrent credit instead of adding to it")

    def test_a_stale_object_cannot_refund_a_withdrawal_approved_meanwhile(self):
        """An admin opens the row, someone else approves and the payout goes
        out by hand, then the first admin presses reject on their stale copy.
        The settle token is already gone, so nothing may be refunded."""
        user = _user("inv7", "1000.00")
        row = request_withdrawal(user, "300.00")
        stale = Balance.objects.get(pk=row.pk)      # completed=False in memory

        approver = Balance.objects.get(pk=row.pk)
        approver.approved = True
        approver.save()                             # settles the row

        stale.rejected = True
        stale.save()

        self.assertEqual(
            balance_of(user), Decimal("700.00"),
            "a stale reject refunded a withdrawal that was already paid out")

    def test_a_row_born_rejected_neither_holds_nor_refunds(self):
        """Nothing was held, so nothing may be paid back."""
        user = _user("inv5", "500.00")
        Balance.objects.create(
            user=user, transaction_type="withdraw",
            payable_amount=Decimal("100.00"), rejected=True)
        self.assertEqual(
            balance_of(user), Decimal("500.00"),
            "a withdrawal that never held money moved money anyway")

    def test_rejecting_a_deposit_refunds_nothing(self):
        """The refund path is withdrawal-only."""
        user = _user("inv6", "0.00")
        row = Balance.objects.create(
            user=user, transaction_type="deposit",
            payable_amount=Decimal("100.00"))
        after_deposit = balance_of(user)
        row.rejected = True
        row.save()
        self.assertEqual(balance_of(user), after_deposit)


class DepositIdempotencyTests(TestCase):
    """Found by this batch, not planned for it.

    The deposit branch of Balance.save() had no guard at all — not even the
    in-memory `not self.completed` the refund had. Every save() credited the
    balance again, so opening a settled deposit in the admin and pressing Save
    minted the whole amount a second time.
    """

    def _deposit(self, user, amount):
        return Balance.objects.create(
            user=user, transaction_type="deposit",
            payable_amount=Decimal(amount))

    def test_a_deposit_credits_once(self):
        user = _user("dep1", "0.00")
        self._deposit(user, "500.00")
        self.assertEqual(balance_of(user), Decimal("500.00"))

    def test_resaving_a_deposit_does_not_credit_again(self):
        user = _user("dep2", "0.00")
        row = self._deposit(user, "500.00")

        row.save()
        row.save()
        row.save()

        self.assertEqual(
            balance_of(user), Decimal("500.00"),
            "re-saving the deposit minted money")

    def test_editing_a_settled_deposit_in_the_admin_mints_nothing(self):
        """The exact production path: load the row fresh, change an unrelated
        field, save."""
        user = _user("dep3", "100.00")
        row = self._deposit(user, "250.00")
        self.assertEqual(balance_of(user), Decimal("350.00"))

        fresh = Balance.objects.get(pk=row.pk)
        if hasattr(fresh, "rejection_reason"):
            fresh.rejection_reason = "note"
        fresh.save()

        self.assertEqual(balance_of(user), Decimal("350.00"))

    def test_a_deposit_does_not_clobber_a_concurrent_balance_change(self):
        user = _user("dep4", "0.00")
        row = self._deposit(user, "100.00")            # -> 100
        stale = Balance.objects.get(pk=row.pk)
        stale.user                                     # cache the User row

        User.objects.filter(pk=user.pk).update(
            balance=Decimal("100.00") + Decimal("700.00"))   # -> 800

        stale.save()

        self.assertEqual(
            balance_of(user), Decimal("800.00"),
            "saving the deposit row discarded a concurrent credit")


class OwnershipTests(TestCase):
    def test_a_rejection_credits_only_the_requesting_user(self):
        owner = _user("own1", "1000.00")
        bystander = _user("own2", "1000.00")
        row = request_withdrawal(owner, "300.00")

        reject(row)

        self.assertEqual(balance_of(owner), Decimal("1000.00"))
        self.assertEqual(
            balance_of(bystander), Decimal("1000.00"),
            "an unrelated user's balance moved")


class ConcurrentRefundTests(TransactionTestCase):
    """Real threads. Two admins clicking reject at the same instant."""

    def _race(self, target, count):
        barrier = threading.Barrier(count)
        results = []

        def run():
            barrier.wait()
            try:
                results.append(target())
            except Exception as exc:            # noqa: BLE001 - recorded
                results.append(exc)
            finally:
                connections.close_all()

        threads = [threading.Thread(target=run) for _ in range(count)]
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=20)
        return results

    def test_two_simultaneous_rejections_refund_exactly_once(self):
        user = _user("race1", "1000.00")
        row = request_withdrawal(user, "400.00")
        self.assertEqual(balance_of(user), Decimal("600.00"))

        def do_reject():
            fresh = Balance.objects.get(pk=row.pk)
            fresh.rejected = True
            fresh.save()
            return True

        self._race(do_reject, count=2)

        self.assertEqual(
            balance_of(user), Decimal("1000.00"),
            "the refund was paid more than once")

    def test_five_simultaneous_rejections_refund_exactly_once(self):
        user = _user("race2", "1000.00")
        row = request_withdrawal(user, "250.00")

        def do_reject():
            fresh = Balance.objects.get(pk=row.pk)
            fresh.rejected = True
            fresh.save()
            return True

        self._race(do_reject, count=5)

        self.assertEqual(balance_of(user), Decimal("1000.00"))

    def test_approving_and_rejecting_at_once_settles_only_one_way(self):
        """A withdrawal is paid out OR refunded, never both.

        Approval moves no money, so it used to skip the settle-claim entirely
        — leaving a simultaneous rejection free to refund cash that an admin
        was at that moment sending by hand.
        """
        user = _user("race4", "1000.00")
        row = request_withdrawal(user, "300.00")
        self.assertEqual(balance_of(user), Decimal("700.00"))

        def do_approve():
            fresh = Balance.objects.get(pk=row.pk)
            fresh.approved = True
            fresh.save()
            return "approve"

        def do_reject():
            fresh = Balance.objects.get(pk=row.pk)
            fresh.rejected = True
            fresh.save()
            return "reject"

        calls = [do_approve, do_reject]
        barrier = threading.Barrier(2)
        results = []

        def run(fn):
            def inner():
                barrier.wait()
                try:
                    results.append(fn())
                finally:
                    connections.close_all()
            return inner

        threads = [threading.Thread(target=run(fn)) for fn in calls]
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=20)

        final = balance_of(user)
        self.assertIn(
            final, (Decimal("700.00"), Decimal("1000.00")),
            "the withdrawal was both paid out and refunded — balance %s" % final)

    def test_simultaneous_withdrawals_cannot_overdraw(self):
        user = _user("race3", "100.00")

        def do_withdraw():
            try:
                request_withdrawal(user, "100.00")
                return True
            except ValidationError:
                return False

        results = self._race(do_withdraw, count=3)

        self.assertEqual(sum(1 for r in results if r is True), 1,
                         "100.00 funded more than one 100.00 withdrawal")
        self.assertEqual(balance_of(user), Decimal("0.00"))


class InvariantTests(TestCase):
    def test_a_hold_and_a_refund_conserve_money_exactly(self):
        user = _user("iv1", "1234.56")
        before = balance_of(user)
        row = request_withdrawal(user, "789.01")
        reject(row)
        self.assertEqual(balance_of(user), before)

    def test_the_money_supply_is_unchanged_by_a_reject_cycle(self):
        a = _user("iv2", "500.00")
        b = _user("iv3", "300.00")
        total_before = balance_of(a) + balance_of(b)

        row = request_withdrawal(a, "120.00")
        reject(row)

        self.assertEqual(balance_of(a) + balance_of(b), total_before)

    def test_many_reject_cycles_do_not_drift(self):
        user = _user("iv4", "1000.00")
        for i in range(10):
            reject(request_withdrawal(user, "33.33"))
        self.assertEqual(balance_of(user), Decimal("1000.00"))

    def test_a_failed_withdrawal_request_leaves_no_trace_on_the_balance(self):
        user = _user("iv5", "50.00")
        try:
            request_withdrawal(user, "5000.00")
        except ValidationError:
            pass
        self.assertEqual(balance_of(user), Decimal("50.00"))
