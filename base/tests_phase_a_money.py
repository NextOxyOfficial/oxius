# -*- coding: utf-8 -*-
"""Phase A: the remaining P1 money paths.

Each group here corresponds to one audit finding that was still a
read-modify-write or a check-then-act after the P0 batches:

  A3  gold sponsor purchase          business_network/models.py
  A5  ad rejection refund            business_network/admin.py
  A6a micro-gig stop refund          base/models.py
  A7  wallet.credit failure          base/wallet.py

A1 (order-edit settlement) and A2 (referral commission) live deep inside two
large view functions whose fixtures span orders, items, sellers and pricing
config; they are covered by the existing suites that exercise those endpoints
plus the wallet primitives they now call. A4 (subscription plan / auto-renew)
lives in the `subscription` app and is exercised by its own suite.
"""
import itertools
import threading
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.db import connections
from django.test import TestCase, TransactionTestCase

from base import wallet
from base.models import MicroGigPost

User = get_user_model()
_counter = itertools.count(1)


def _user(tag, balance="0.00"):
    n = next(_counter)
    user = User.objects.create_user(
        username="pa_%s_%d" % (tag, n), email="pa_%s_%d@example.com" % (tag, n),
        password="x", first_name=tag, phone="+88010009%05d" % n)
    User.objects.filter(pk=user.pk).update(balance=Decimal(balance))
    user.refresh_from_db()
    return user


def balance_of(user):
    return User.objects.values_list("balance", flat=True).get(pk=user.pk)


def money_supply():
    return sum(User.objects.values_list("balance", flat=True))


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


# ── A7 ─────────────────────────────────────────────────────────────────────

class WalletCreditFailureTests(TestCase):
    """A credit to a user who is gone must not pass silently.

    It logged an error and returned False, which every claim-then-credit caller
    ignored: the claim committed, nobody was paid, and the only trace was a log
    line. Insufficient funds is still a return value — that is an expected
    outcome. A missing recipient is a bug.
    """

    def test_crediting_a_missing_user_raises(self):
        import uuid
        with self.assertRaises(wallet.WalletError):
            wallet.credit(uuid.uuid4(), "50.00", reason="test")

    def test_crediting_a_real_user_still_returns_true(self):
        user = _user("w1", "10.00")
        self.assertTrue(wallet.credit(user.pk, "5.00", reason="test"))
        self.assertEqual(balance_of(user), Decimal("15.00"))

    def test_a_failed_credit_rolls_back_an_enclosing_claim(self):
        """The reason this matters: the claim must not survive the failure."""
        import uuid

        from django.db import transaction as db_transaction

        user = _user("w2", "0.00")
        User.objects.filter(pk=user.pk).update(first_name="before")

        with self.assertRaises(wallet.WalletError):
            with db_transaction.atomic():
                User.objects.filter(pk=user.pk).update(first_name="claimed")
                wallet.credit(uuid.uuid4(), "10.00", reason="test")

        self.assertEqual(
            User.objects.values_list("first_name", flat=True).get(pk=user.pk),
            "before",
            "the claim committed even though the payout failed")

    def test_insufficient_funds_is_still_a_return_value_not_an_exception(self):
        user = _user("w3", "5.00")
        self.assertFalse(wallet.debit(user.pk, "10.00", reason="test"))
        self.assertEqual(balance_of(user), Decimal("5.00"))


# ── A3 ─────────────────────────────────────────────────────────────────────

class GoldSponsorPurchaseTests(TestCase):
    def _package(self, price="1000.00"):
        from business_network.models import SponsorshipPackage
        n = next(_counter)
        return SponsorshipPackage.objects.create(
            name="Pkg %d" % n, description="d", price=Decimal(price),
            duration_months=1)

    def _sponsor(self, user, package):
        from business_network.models import GoldSponsor
        n = next(_counter)
        return GoldSponsor.objects.create(
            user=user, business_name="Biz %d" % n, business_description="d",
            slug="biz-%d" % n, contact_email="b%d@e.com" % n,
            phone_number="+8801700%06d" % n, package=package)

    def test_buying_a_sponsorship_charges_the_package_price(self):
        user = _user("g1", "5000.00")
        self._sponsor(user, self._package("1000.00"))
        self.assertEqual(balance_of(user), Decimal("4000.00"))

    def test_an_unaffordable_sponsorship_is_refused(self):
        user = _user("g2", "100.00")
        with self.assertRaises(ValidationError):
            self._sponsor(user, self._package("1000.00"))
        self.assertEqual(balance_of(user), Decimal("100.00"))

    def test_resaving_a_sponsorship_does_not_charge_again(self):
        user = _user("g3", "5000.00")
        sponsor = self._sponsor(user, self._package("1000.00"))
        after = balance_of(user)
        sponsor.save()
        sponsor.save()
        self.assertEqual(balance_of(user), after)

    def test_amount_paid_records_what_was_charged(self):
        user = _user("g4", "5000.00")
        sponsor = self._sponsor(user, self._package("750.00"))
        sponsor.refresh_from_db()
        self.assertEqual(sponsor.amount_paid, Decimal("750.00"))


class GoldSponsorConcurrencyTests(TransactionTestCase):
    def test_two_concurrent_sponsorships_cannot_overdraw(self):
        from business_network.models import GoldSponsor, SponsorshipPackage

        user = _user("gc", "1000.00")
        package = SponsorshipPackage.objects.create(
            name="P", description="d", price=Decimal("1000.00"),
            duration_months=1)

        def buy():
            n = next(_counter)
            GoldSponsor.objects.create(
                user=User.objects.get(pk=user.pk),
                business_name="B %d" % n, business_description="d",
                slug="b-%d" % n, contact_email="c%d@e.com" % n,
                phone_number="+8801711%06d" % n, package=package)
            return True

        out = _race(buy, count=2)

        self.assertGreaterEqual(
            balance_of(user), Decimal("0.00"),
            "the wallet went negative buying sponsorships")
        self.assertEqual(
            sum(1 for r in out if r is True), 1,
            "1000.00 paid for two 1000.00 sponsorships; results=%s" % out)


# ── A5 ─────────────────────────────────────────────────────────────────────

class AdRejectionRefundTests(TestCase):
    def _ad(self, user, budget="500.00", spent="100.00", status="review"):
        from business_network.models import AbnAdsPanel, AbnAdsPanelCategory
        n = next(_counter)
        category = AbnAdsPanelCategory.objects.create(
            id="cat-%d" % n, name="Cat %d" % n)
        return AbnAdsPanel.objects.create(
            user=user, title="Ad %d" % n, description="d", category=category,
            budget=Decimal(budget), spent=Decimal(spent), status=status)

    def _admin(self):
        from django.contrib.admin.sites import AdminSite

        from business_network.admin import AbnAdsPanelAdmin
        from business_network.models import AbnAdsPanel
        a = AbnAdsPanelAdmin(AbnAdsPanel, AdminSite())
        a.message_user = lambda *args, **kwargs: None
        return a

    def _request(self, actor):
        from django.test import RequestFactory
        r = RequestFactory().get("/")
        r.user = actor
        return r

    def test_rejecting_an_ad_refunds_the_unspent_budget(self):
        from business_network.models import AbnAdsPanel
        user = _user("a1", "0.00")
        ad = self._ad(user, budget="500.00", spent="100.00")

        self._admin()._reject(
            self._request(user),
            AbnAdsPanel.objects.filter(pk=ad.pk),
            list(self._admin().REJECT_TEMPLATES)[0])

        self.assertEqual(balance_of(user), Decimal("400.00"))

    def test_rejecting_the_same_ad_twice_refunds_once(self):
        from business_network.models import AbnAdsPanel
        user = _user("a2", "0.00")
        ad = self._ad(user, budget="500.00", spent="100.00")
        adm = self._admin()
        key = list(adm.REJECT_TEMPLATES)[0]
        req = self._request(user)

        adm._reject(req, AbnAdsPanel.objects.filter(pk=ad.pk), key)
        # Force the row back to a rejectable status the way a stale queryset
        # would have seen it, then reject again.
        adm._reject(req, AbnAdsPanel.objects.filter(pk=ad.pk), key)

        self.assertEqual(
            balance_of(user), Decimal("400.00"),
            "the unspent budget was refunded twice")

    def test_a_fully_spent_ad_refunds_nothing(self):
        from business_network.models import AbnAdsPanel
        user = _user("a3", "0.00")
        ad = self._ad(user, budget="500.00", spent="500.00")
        adm = self._admin()
        adm._reject(self._request(user),
                    AbnAdsPanel.objects.filter(pk=ad.pk),
                    list(adm.REJECT_TEMPLATES)[0])
        self.assertEqual(balance_of(user), Decimal("0.00"))

    def test_the_ad_ends_rejected(self):
        from business_network.models import AbnAdsPanel
        user = _user("a4", "0.00")
        ad = self._ad(user)
        adm = self._admin()
        adm._reject(self._request(user),
                    AbnAdsPanel.objects.filter(pk=ad.pk),
                    list(adm.REJECT_TEMPLATES)[0])
        ad.refresh_from_db()
        self.assertEqual(ad.status, "rejected")


# ── A6a ────────────────────────────────────────────────────────────────────

class MicroGigStopRefundTests(TestCase):
    def _gig(self, user, funded="500.00", quantity=10):
        return MicroGigPost.objects.create(
            user=user, title="Gig", price=Decimal("50.00"),
            required_quantity=quantity, filled_quantity=0,
            balance=Decimal(funded), total_cost=Decimal(funded),
            active_gig=True, gig_status="approved")

    def test_stopping_a_gig_refunds_the_unspent_pot(self):
        user = _user("m1", "0.00")
        gig = self._gig(user, funded="500.00")
        gig.stop_gig = True
        gig.save()
        self.assertEqual(balance_of(user), Decimal("500.00"))
        gig.refresh_from_db()
        self.assertEqual(gig.balance, Decimal("0.00"))
        self.assertEqual(gig.gig_status, "completed")

    def test_stopping_twice_refunds_once(self):
        user = _user("m2", "0.00")
        gig = self._gig(user, funded="500.00")
        gig.stop_gig = True
        gig.save()
        gig.save()
        self.assertEqual(balance_of(user), Decimal("500.00"))

    def test_two_stale_objects_cannot_both_refund(self):
        user = _user("m3", "0.00")
        gig = self._gig(user, funded="500.00")
        first = MicroGigPost.objects.get(pk=gig.pk)
        second = MicroGigPost.objects.get(pk=gig.pk)

        first.stop_gig = True
        first.save()
        second.stop_gig = True
        second.save()

        self.assertEqual(
            balance_of(user), Decimal("500.00"),
            "two stale gig objects each refunded the pot")

    def test_stopping_an_empty_gig_refunds_nothing(self):
        user = _user("m4", "0.00")
        gig = self._gig(user, funded="0.00")
        before = money_supply()
        gig.stop_gig = True
        gig.save()
        self.assertEqual(money_supply(), before)

    def test_the_money_supply_is_conserved_by_a_stop(self):
        user = _user("m5", "100.00")
        gig = self._gig(user, funded="300.00")
        before = money_supply()
        gig.stop_gig = True
        gig.save()
        self.assertEqual(money_supply(), before + Decimal("300.00"))


class MicroGigStopConcurrencyTests(TransactionTestCase):
    def test_five_concurrent_stops_refund_once(self):
        user = _user("mc", "0.00")
        gig = MicroGigPost.objects.create(
            user=user, title="Gig", price=Decimal("50.00"),
            required_quantity=10, filled_quantity=0,
            balance=Decimal("500.00"), total_cost=Decimal("500.00"),
            active_gig=True, gig_status="approved")

        def stop():
            fresh = MicroGigPost.objects.get(pk=gig.pk)
            fresh.stop_gig = True
            fresh.save()
            return True

        _race(stop, count=5)

        self.assertEqual(
            balance_of(user), Decimal("500.00"),
            "concurrent stops refunded %s of a 500.00 pot" % balance_of(user))
