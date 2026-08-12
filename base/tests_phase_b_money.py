# -*- coding: utf-8 -*-
"""Phase B: the P2 money paths, plus one P0 that fell between batches.

  B9   ReferBonus                     base/models.py
  B10  product-slot purchase          base/views.py
  B11  diamond gift / bonus / admin   base/models.py
  B12  diamond engagement reward      business_network/tasks.py
  P0*  creator ad-revenue payout      business_network/tasks.py

The last one was rated P0 by the money-flow audit and never got assigned a
batch number, so it survived every P0 round: `if row.credited: continue`, read
off an object fetched before the credit, with `row.credited = True` written
after the money moved. It pays real money, nightly, unattended, and duplicate
celery beat schedulers are a known hazard on this deployment.

B13 (wallet/Balance ledger drift) is deliberately NOT changed — see the report.
"""
import itertools
import threading
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.db import connections
from django.test import TestCase, TransactionTestCase

from base.models import DiamondTransaction, ReferBonus

User = get_user_model()
_counter = itertools.count(1)


def _user(tag, balance="0.00", diamonds=0):
    n = next(_counter)
    user = User.objects.create_user(
        username="pb_%s_%d" % (tag, n), email="pb_%s_%d@example.com" % (tag, n),
        password="x", first_name=tag, phone="+88010008%05d" % n)
    User.objects.filter(pk=user.pk).update(
        balance=Decimal(balance), diamond_balance=diamonds)
    user.refresh_from_db()
    return user


def balance_of(user):
    return User.objects.values_list("balance", flat=True).get(pk=user.pk)


def diamonds_of(user):
    return User.objects.values_list("diamond_balance", flat=True).get(pk=user.pk)


def commission_of(user):
    return User.objects.values_list("commission_earned", flat=True).get(pk=user.pk)


def _race(target, count):
    barrier = threading.Barrier(count)
    lock = threading.Lock()
    out = []

    def run():
        barrier.wait()
        try:
            r = target()
            with lock:
                out.append(r)
        except Exception as exc:
            with lock:
                out.append(exc)
        finally:
            connections.close_all()

    threads = [threading.Thread(target=run) for _ in range(count)]
    for t in threads:
        t.start()
    for t in threads:
        t.join(timeout=30)
    return out


class ReferBonusTests(TestCase):
    def test_a_refer_bonus_credits_balance_and_commission_together(self):
        referrer = _user("r1", "0.00")
        referred = _user("r2", "0.00")
        ReferBonus.objects.create(
            user=referrer, referred_user=referred, amount=Decimal("25.00"))
        self.assertEqual(balance_of(referrer), Decimal("25.00"))
        self.assertEqual(commission_of(referrer), Decimal("25.00"))

    def test_resaving_a_refer_bonus_does_not_pay_again(self):
        referrer = _user("r3", "0.00")
        bonus = ReferBonus.objects.create(
            user=referrer, amount=Decimal("25.00"))
        bonus.save()
        bonus.save()
        self.assertEqual(balance_of(referrer), Decimal("25.00"))
        self.assertEqual(commission_of(referrer), Decimal("25.00"))

    def test_a_refer_bonus_does_not_clobber_a_concurrent_balance_change(self):
        referrer = _user("r4", "100.00")
        stale = User.objects.get(pk=referrer.pk)
        User.objects.filter(pk=referrer.pk).update(
            balance=Decimal("100.00") + Decimal("500.00"))

        ReferBonus.objects.create(user=stale, amount=Decimal("25.00"))

        self.assertEqual(
            balance_of(referrer), Decimal("625.00"),
            "the refer bonus discarded a concurrent deposit")

    def test_a_zero_bonus_moves_nothing(self):
        referrer = _user("r5", "10.00")
        ReferBonus.objects.create(user=referrer, amount=Decimal("0.00"))
        self.assertEqual(balance_of(referrer), Decimal("10.00"))


class DiamondGiftTests(TestCase):
    def test_a_gift_moves_diamonds(self):
        sender = _user("d1", diamonds=100)
        recipient = _user("d2", diamonds=0)
        DiamondTransaction.objects.create(
            user=sender, to_user=recipient, transaction_type="gift", amount=30)
        self.assertEqual(diamonds_of(sender), 70)
        self.assertEqual(diamonds_of(recipient), 30)

    def test_a_gift_beyond_the_balance_is_refused(self):
        sender = _user("d3", diamonds=10)
        recipient = _user("d4", diamonds=0)
        with self.assertRaises(ValidationError):
            DiamondTransaction.objects.create(
                user=sender, to_user=recipient,
                transaction_type="gift", amount=11)
        self.assertEqual(diamonds_of(sender), 10)
        self.assertEqual(diamonds_of(recipient), 0)

    def test_resaving_a_gift_does_not_move_diamonds_again(self):
        sender = _user("d5", diamonds=100)
        recipient = _user("d6", diamonds=0)
        txn = DiamondTransaction.objects.create(
            user=sender, to_user=recipient, transaction_type="gift", amount=30)
        txn.save()
        txn.save()
        self.assertEqual(diamonds_of(sender), 70)
        self.assertEqual(diamonds_of(recipient), 30)

    def test_a_gift_conserves_the_diamond_supply(self):
        sender = _user("d7", diamonds=100)
        recipient = _user("d8", diamonds=40)
        before = diamonds_of(sender) + diamonds_of(recipient)
        DiamondTransaction.objects.create(
            user=sender, to_user=recipient, transaction_type="gift", amount=25)
        self.assertEqual(diamonds_of(sender) + diamonds_of(recipient), before)

    def test_an_admin_adjustment_can_be_negative(self):
        user = _user("d9", diamonds=50)
        DiamondTransaction.objects.create(
            user=user, transaction_type="admin", amount=-20)
        self.assertEqual(diamonds_of(user), 30)

    def test_a_bonus_adds_diamonds(self):
        user = _user("d10", diamonds=5)
        DiamondTransaction.objects.create(
            user=user, transaction_type="bonus", amount=15)
        self.assertEqual(diamonds_of(user), 20)


class DiamondGiftConcurrencyTests(TransactionTestCase):
    def test_concurrent_gifts_cannot_exceed_the_senders_diamonds(self):
        sender = _user("dc1", diamonds=100)
        recipients = [_user("dr%d" % i, diamonds=0) for i in range(5)]

        def gift(recipient):
            def inner():
                DiamondTransaction.objects.create(
                    user=User.objects.get(pk=sender.pk),
                    to_user=User.objects.get(pk=recipient.pk),
                    transaction_type="gift", amount=40)
                return True
            return inner

        barrier = threading.Barrier(5)
        lock = threading.Lock()
        out = []

        def run(r):
            def inner():
                barrier.wait()
                try:
                    gift(r)()
                    with lock:
                        out.append(True)
                except Exception:
                    with lock:
                        out.append(False)
                finally:
                    connections.close_all()
            return inner

        threads = [threading.Thread(target=run(r)) for r in recipients]
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=30)

        received = sum(diamonds_of(r) for r in recipients)
        self.assertGreaterEqual(
            diamonds_of(sender), 0, "the sender's diamonds went negative")
        self.assertEqual(
            diamonds_of(sender) + received, 100,
            "the diamond supply changed: sender=%s received=%s"
            % (diamonds_of(sender), received))
        self.assertEqual(
            sum(1 for r in out if r), 2,
            "100 diamonds funded more than two 40-diamond gifts")


class CreatorAdEarningTests(TransactionTestCase):
    """The P0 that fell between batches."""

    def _row(self, creator, amount="200.00"):
        from business_network.models import CreatorAdEarning
        from django.utils import timezone
        return CreatorAdEarning.objects.create(
            creator=creator, date=timezone.localdate(),
            amount=Decimal(amount), credited=False)

    def test_claiming_an_earning_row_credits_once(self):
        from business_network.models import CreatorAdEarning
        from base import wallet

        creator = _user("c1", "0.00")
        row = self._row(creator, "200.00")

        def settle():
            if not CreatorAdEarning.objects.filter(
                pk=row.pk, credited=False).update(credited=True):
                return False
            wallet.credit(creator.pk, row.amount, reason="test")
            return True

        out = _race(settle, count=5)

        self.assertEqual(
            balance_of(creator), Decimal("200.00"),
            "one earning row credited %s; results=%s"
            % (balance_of(creator), out))
        self.assertEqual(sum(1 for r in out if r is True), 1)

    def test_an_already_credited_row_is_skipped(self):
        from business_network.models import CreatorAdEarning
        creator = _user("c2", "0.00")
        row = self._row(creator, "200.00")
        CreatorAdEarning.objects.filter(pk=row.pk).update(credited=True)

        claimed = CreatorAdEarning.objects.filter(
            pk=row.pk, credited=False).update(credited=True)

        self.assertEqual(claimed, 0)
        self.assertEqual(balance_of(creator), Decimal("0.00"))
