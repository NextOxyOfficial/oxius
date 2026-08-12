# -*- coding: utf-8 -*-
"""Micro-gig escrow: reserve once, release once, refund once.

THE MONEY MODEL

An advertiser funds a gig; `MicroGigPost.balance` is that pot. A worker submits
a task, which RESERVES one unit of `gig.price`: the gig's pot goes down and the
worker's `pending_balance` goes up. The advertiser then approves (pending ->
the worker's real balance) or rejects (pending is discarded and the pot is
restored). The money is only ever in one of three places, and the three must
always sum to the same total.

THE BUG

All three transitions were read-modify-write, and the approve/reject gate was
the in-memory `not self.completed`:

    if self.approved and not self.completed:
        self.completed = True
        self.user.balance += self.gig.price
        self.user.pending_balance -= self.gig.price
        self.user.save()

Two concurrent approvals of one submission both read `completed=False`, both
pass, and both pay — one reservation, two payouts. The reservation itself was
just as exposed: two workers submitting to the same gig both read the same
`gig.balance` and the same `filled_quantity`, so the pot could be spent past
zero and the slot count past its limit.
"""
import itertools
import threading
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.db import connections
from django.test import TestCase, TransactionTestCase

from base.models import MicroGigPost, MicroGigPostTask

User = get_user_model()
_counter = itertools.count(1)


def _user(tag, balance="0.00", pending="0.00"):
    n = next(_counter)
    user = User.objects.create_user(
        username="mg_%s_%d" % (tag, n), email="mg_%s_%d@example.com" % (tag, n),
        password="x", first_name=tag, phone="+88010004%05d" % n)
    User.objects.filter(pk=user.pk).update(
        balance=Decimal(balance), pending_balance=Decimal(pending))
    user.refresh_from_db()
    return user


def balance_of(user):
    return User.objects.values_list("balance", flat=True).get(pk=user.pk)


def pending_of(user):
    return User.objects.values_list("pending_balance", flat=True).get(pk=user.pk)


def gig_balance(gig):
    return MicroGigPost.objects.values_list("balance", flat=True).get(pk=gig.pk)


def gig_filled(gig):
    return MicroGigPost.objects.values_list("filled_quantity", flat=True).get(pk=gig.pk)


class _MicroGigFixture:
    price = Decimal("50.00")

    def make_gig(self, *, funded="500.00", quantity=10, price=None):
        self.advertiser = _user("adv", "0.00")
        price = self.price if price is None else price
        gig = MicroGigPost.objects.create(
            user=self.advertiser, title="Do a thing", price=price,
            required_quantity=quantity, filled_quantity=0,
            balance=Decimal(funded), total_cost=Decimal(funded),
            active_gig=True, gig_status="approved")
        return gig

    def submit(self, gig, worker):
        """A worker submitting a task — this is what reserves the money."""
        return MicroGigPostTask.objects.create(
            gig=gig, user=worker, submit_details="done",
            task_completion_link="http://x")


class ReservationTests(TestCase, _MicroGigFixture):
    def test_submitting_reserves_one_unit_from_the_gig(self):
        gig = self.make_gig()
        worker = _user("w")
        self.submit(gig, worker)

        self.assertEqual(gig_balance(gig), Decimal("450.00"))
        self.assertEqual(pending_of(worker), self.price)
        self.assertEqual(balance_of(worker), Decimal("0.00"))
        self.assertEqual(gig_filled(gig), 1)

    def test_resaving_a_pending_task_does_not_reserve_again(self):
        gig = self.make_gig()
        worker = _user("w")
        task = self.submit(gig, worker)
        task.save()
        task.save()
        self.assertEqual(gig_balance(gig), Decimal("450.00"))
        self.assertEqual(pending_of(worker), self.price)

    def test_an_underfunded_gig_cannot_be_submitted_to(self):
        gig = self.make_gig(funded="40.00")
        worker = _user("w")
        with self.assertRaises(ValidationError):
            self.submit(gig, worker)
        self.assertEqual(gig_balance(gig), Decimal("40.00"))
        self.assertEqual(pending_of(worker), Decimal("0.00"))

    def test_a_full_gig_cannot_be_submitted_to(self):
        gig = self.make_gig(quantity=1)
        self.submit(gig, _user("w1"))
        with self.assertRaises(ValidationError):
            self.submit(gig, _user("w2"))
        self.assertEqual(gig_filled(gig), 1)


class ApprovalTests(TestCase, _MicroGigFixture):
    def setUp(self):
        self.gig = self.make_gig()
        self.worker = _user("w")
        self.task = self.submit(self.gig, self.worker)

    def test_approving_pays_the_worker_once(self):
        self.task.approved = True
        self.task.save()

        self.assertEqual(balance_of(self.worker), self.price)
        self.assertEqual(pending_of(self.worker), Decimal("0.00"))

    def test_approving_marks_the_task_completed(self):
        self.task.approved = True
        self.task.save()
        self.task.refresh_from_db()
        self.assertTrue(self.task.completed)

    def test_resaving_an_approved_task_does_not_pay_again(self):
        self.task.approved = True
        self.task.save()
        self.task.save()
        self.task.save()
        self.assertEqual(
            balance_of(self.worker), self.price,
            "re-saving an approved task paid the worker again")

    def test_two_stale_objects_cannot_both_approve(self):
        """Two admins with the review page open, both loaded before either saved."""
        first = MicroGigPostTask.objects.get(pk=self.task.pk)
        second = MicroGigPostTask.objects.get(pk=self.task.pk)

        first.approved = True
        first.save()
        second.approved = True
        second.save()

        self.assertEqual(
            balance_of(self.worker), self.price,
            "two stale objects each paid the worker")
        self.assertEqual(pending_of(self.worker), Decimal("0.00"))

    def test_a_rejected_task_cannot_then_be_approved(self):
        self.task.rejected = True
        self.task.save()
        after_reject = balance_of(self.worker)

        fresh = MicroGigPostTask.objects.get(pk=self.task.pk)
        fresh.approved = True
        fresh.save()

        self.assertEqual(balance_of(self.worker), after_reject)
        self.assertEqual(balance_of(self.worker), Decimal("0.00"))


class RejectionTests(TestCase, _MicroGigFixture):
    def setUp(self):
        self.gig = self.make_gig()
        self.worker = _user("w")
        self.task = self.submit(self.gig, self.worker)

    def test_rejecting_returns_the_money_to_the_gig(self):
        self.task.rejected = True
        self.task.save()

        self.assertEqual(gig_balance(self.gig), Decimal("500.00"))
        self.assertEqual(pending_of(self.worker), Decimal("0.00"))
        self.assertEqual(balance_of(self.worker), Decimal("0.00"))
        self.assertEqual(gig_filled(self.gig), 0)

    def test_resaving_a_rejected_task_does_not_refund_the_gig_twice(self):
        self.task.rejected = True
        self.task.save()
        self.task.save()
        self.assertEqual(
            gig_balance(self.gig), Decimal("500.00"),
            "re-saving a rejected task refunded the gig twice")

    def test_an_approved_task_cannot_then_be_rejected(self):
        """Otherwise the worker keeps the payout and the gig gets its money
        back — the same reservation released twice."""
        self.task.approved = True
        self.task.save()
        self.assertEqual(balance_of(self.worker), self.price)

        fresh = MicroGigPostTask.objects.get(pk=self.task.pk)
        fresh.rejected = True
        fresh.save()

        self.assertEqual(balance_of(self.worker), self.price)
        self.assertEqual(
            gig_balance(self.gig), Decimal("450.00"),
            "the gig was refunded for work it had already paid for")


class InvariantTests(TestCase, _MicroGigFixture):
    """gig.balance + worker.pending + worker.balance is conserved."""

    def total(self, gig, workers):
        return (gig_balance(gig)
                + sum(pending_of(w) for w in workers)
                + sum(balance_of(w) for w in workers))

    def test_reserve_then_approve_conserves_money(self):
        gig = self.make_gig()
        worker = _user("w")
        before = self.total(gig, [worker])
        task = self.submit(gig, worker)
        task.approved = True
        task.save()
        self.assertEqual(self.total(gig, [worker]), before)

    def test_reserve_then_reject_conserves_money(self):
        gig = self.make_gig()
        worker = _user("w")
        before = self.total(gig, [worker])
        task = self.submit(gig, worker)
        task.rejected = True
        task.save()
        self.assertEqual(self.total(gig, [worker]), before)

    def test_ten_submissions_and_approvals_conserve_money(self):
        gig = self.make_gig(funded="500.00", quantity=10)
        workers = [_user("w%d" % i) for i in range(10)]
        before = self.total(gig, workers)
        for w in workers:
            t = self.submit(gig, w)
            t.approved = True
            t.save()
        self.assertEqual(self.total(gig, workers), before)
        self.assertEqual(gig_balance(gig), Decimal("0.00"))


class ConcurrentApprovalTests(TransactionTestCase, _MicroGigFixture):
    """Real threads on real connections."""

    def _race(self, target, count):
        barrier = threading.Barrier(count)
        lock = threading.Lock()
        results = []

        def run():
            barrier.wait()
            try:
                r = target()
                with lock:
                    results.append(r)
            except Exception as exc:
                with lock:
                    results.append(exc)
            finally:
                connections.close_all()

        threads = [threading.Thread(target=run) for _ in range(count)]
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=30)
        return results

    def test_five_concurrent_approvals_pay_once(self):
        gig = self.make_gig()
        worker = _user("w")
        task = self.submit(gig, worker)

        def approve():
            fresh = MicroGigPostTask.objects.get(pk=task.pk)
            fresh.approved = True
            fresh.save()
            return True

        self._race(approve, count=5)

        self.assertEqual(
            balance_of(worker), self.price,
            "one reservation produced %s of payout" % balance_of(worker))
        self.assertEqual(pending_of(worker), Decimal("0.00"))

    def test_two_concurrent_approvals_pay_once(self):
        gig = self.make_gig()
        worker = _user("w")
        task = self.submit(gig, worker)

        def approve():
            fresh = MicroGigPostTask.objects.get(pk=task.pk)
            fresh.approved = True
            fresh.save()
            return True

        self._race(approve, count=2)
        self.assertEqual(balance_of(worker), self.price)

    def test_concurrent_approve_and_reject_release_the_escrow_once(self):
        gig = self.make_gig()
        worker = _user("w")
        task = self.submit(gig, worker)

        def approve():
            fresh = MicroGigPostTask.objects.get(pk=task.pk)
            fresh.approved = True
            fresh.save()
            return "a"

        def reject():
            fresh = MicroGigPostTask.objects.get(pk=task.pk)
            fresh.rejected = True
            fresh.save()
            return "r"

        barrier = threading.Barrier(2)
        lock = threading.Lock()
        out = []

        def run(fn):
            def inner():
                barrier.wait()
                try:
                    with lock:
                        out.append(fn())
                except Exception as exc:
                    with lock:
                        out.append(exc)
                finally:
                    connections.close_all()
            return inner

        threads = [threading.Thread(target=run(f)) for f in (approve, reject)]
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=30)

        total = gig_balance(gig) + pending_of(worker) + balance_of(worker)
        self.assertEqual(
            total, Decimal("500.00"),
            "approve and reject both released the same reservation")
        self.assertEqual(pending_of(worker), Decimal("0.00"))

    def test_concurrent_submissions_cannot_overspend_the_gig(self):
        """Two slots of funding, five workers submitting at once."""
        gig = self.make_gig(funded="100.00", quantity=10)
        workers = [_user("w%d" % i) for i in range(5)]

        def make(w):
            def inner():
                try:
                    self.submit(gig, w)
                    return True
                except ValidationError:
                    return False
            return inner

        barrier = threading.Barrier(5)
        lock = threading.Lock()
        results = []

        def run(w):
            def inner():
                barrier.wait()
                try:
                    with lock:
                        results.append(make(w)())
                finally:
                    connections.close_all()
            return inner

        threads = [threading.Thread(target=run(w)) for w in workers]
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=30)

        self.assertGreaterEqual(
            gig_balance(gig), Decimal("0.00"),
            "the gig's funding pot went negative")
        self.assertEqual(
            gig_balance(gig) + sum(pending_of(w) for w in workers),
            Decimal("100.00"),
            "reservations do not add up to the funding that existed")

    def test_concurrent_submissions_cannot_oversubscribe_the_slots(self):
        gig = self.make_gig(funded="1000.00", quantity=2)
        workers = [_user("w%d" % i) for i in range(5)]

        barrier = threading.Barrier(5)
        lock = threading.Lock()
        ok = []

        def run(w):
            def inner():
                barrier.wait()
                try:
                    self.submit(gig, w)
                    with lock:
                        ok.append(True)
                except Exception:
                    pass
                finally:
                    connections.close_all()
            return inner

        threads = [threading.Thread(target=run(w)) for w in workers]
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=30)

        self.assertLessEqual(
            gig_filled(gig), 2,
            "more submissions were accepted than the gig had slots")
