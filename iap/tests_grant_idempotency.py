# -*- coding: utf-8 -*-
"""One Google Play purchase grants diamonds exactly once.

THE BUG

`iap_verify` looked for an existing purchase row, then verified with Google,
then GRANTED, and only then saved the row:

    existing = IapPurchase.objects.filter(purchase_token=token).first()  # None
    purchase = existing or IapPurchase(...)      # in memory, not saved
    google_data = verify.verify_product(...)     # succeeds — the payment is real
    grants.grant(...)                            # <- diamonds credited HERE
    purchase.save()                              # <- unique constraint checked HERE

The unique index on `purchase_token` therefore fired *after* the payout. Two
concurrent requests carrying the same token both found no row, both verified
successfully, and both granted; the loser then crashed with IntegrityError —
after its diamonds had already landed. One payment, N diamond packs.

Sequential replay was always safe (the `status == "granted"` early return caught
it), so only the concurrent path was exploitable — which is trivial to do from
the app.

These tests drive the real view through the real URL. Only the network call to
Google is stubbed.
"""
import itertools
import threading

from django.contrib.auth import get_user_model
from django.db import connections
from django.test import TestCase, TransactionTestCase
from django.urls import reverse
from rest_framework.test import APIClient

from iap import views as iap_views
from iap.models import IapProduct, IapPurchase

User = get_user_model()
_counter = itertools.count(1)

# Resolved, not hardcoded: the app's urls are mounted under /api/, and a
# hardcoded "/iap/verify/" silently matched a different route that answered 200,
# which made every one of these tests pass or fail for the wrong reason.
URL = reverse("iap-verify")


def _user(tag):
    n = next(_counter)
    return User.objects.create_user(
        username="iap_%s_%d" % (tag, n), email="iap_%s_%d@example.com" % (tag, n),
        password="x", first_name=tag, phone="+88010005%05d" % n)


def diamonds_of(user):
    return User.objects.values_list("diamond_balance", flat=True).get(pk=user.pk)


def _product(diamonds=50, product_id="diamonds_50"):
    return IapProduct.objects.create(
        kind="diamonds", google_product_id=product_id, diamonds=diamonds,
        is_subscription=False, is_active=True, title="%d diamonds" % diamonds)


class _StubGoogle:
    """Stands in for Google Play. Records calls so we can assert on them."""

    def __init__(self, ok=True):
        self.ok = ok
        self.verify_calls = 0
        self.ack_calls = 0

    def verify_product(self, product_id, purchase_token):
        self.verify_calls += 1
        return {"purchaseState": 0, "orderId": "GPA.TEST"} if self.ok else None

    def verify_subscription(self, purchase_token):
        self.verify_calls += 1
        return {"lineItems": []} if self.ok else None

    def acknowledge_product(self, product_id, purchase_token):
        self.ack_calls += 1

    def acknowledge_subscription(self, purchase_token):
        self.ack_calls += 1


class _GoogleStubbed:
    """Swap iap.views.verify for the stub, restore afterwards."""

    def __init__(self, ok=True):
        self.stub = _StubGoogle(ok=ok)

    def __enter__(self):
        self._real = iap_views.verify
        iap_views.verify = self.stub
        return self.stub

    def __exit__(self, *exc):
        iap_views.verify = self._real
        return False


class HappyPathTests(TestCase):
    def setUp(self):
        self.user = _user("happy")
        self.product = _product()
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

    def test_a_verified_purchase_grants_the_diamonds(self):
        with _GoogleStubbed():
            response = self.client.post(URL, {
                "product_id": "diamonds_50", "purchase_token": "tok-1",
            }, format="json")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(diamonds_of(self.user), 50)
        self.assertEqual(
            IapPurchase.objects.get(purchase_token="tok-1").status, "granted")

    def test_the_grant_uses_the_server_side_product_not_client_input(self):
        """A client claiming 999999 diamonds must still get the product's 50."""
        with _GoogleStubbed():
            self.client.post(URL, {
                "product_id": "diamonds_50", "purchase_token": "tok-2",
                "diamonds": 999999, "amount": "999999",
            }, format="json")

        self.assertEqual(diamonds_of(self.user), 50,
                         "client-supplied diamond count was honoured")

    def test_two_different_purchases_both_grant(self):
        with _GoogleStubbed():
            self.client.post(URL, {"product_id": "diamonds_50",
                                   "purchase_token": "tok-3a"}, format="json")
            self.client.post(URL, {"product_id": "diamonds_50",
                                   "purchase_token": "tok-3b"}, format="json")
        self.assertEqual(diamonds_of(self.user), 100)


class SequentialReplayTests(TestCase):
    def setUp(self):
        self.user = _user("replay")
        self.product = _product()
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

    def test_replaying_a_token_grants_nothing_extra(self):
        with _GoogleStubbed():
            for _ in range(5):
                response = self.client.post(URL, {
                    "product_id": "diamonds_50", "purchase_token": "tok-4",
                }, format="json")
                self.assertEqual(response.status_code, 200)

        self.assertEqual(diamonds_of(self.user), 50,
                         "a replayed purchase token granted again")
        self.assertEqual(IapPurchase.objects.filter(purchase_token="tok-4").count(), 1)

    def test_another_account_cannot_claim_someone_elses_token(self):
        with _GoogleStubbed():
            self.client.post(URL, {"product_id": "diamonds_50",
                                   "purchase_token": "tok-5"}, format="json")

        attacker = _user("attacker")
        other = APIClient()
        other.force_authenticate(user=attacker)
        with _GoogleStubbed():
            response = other.post(URL, {"product_id": "diamonds_50",
                                        "purchase_token": "tok-5"}, format="json")

        self.assertEqual(response.status_code, 409)
        self.assertEqual(diamonds_of(attacker), 0)


class VerificationFailureTests(TestCase):
    def setUp(self):
        self.user = _user("failverify")
        self.product = _product()
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

    def test_a_failed_verification_grants_nothing(self):
        with _GoogleStubbed(ok=False):
            response = self.client.post(URL, {
                "product_id": "diamonds_50", "purchase_token": "tok-6",
            }, format="json")

        self.assertEqual(response.status_code, 402)
        self.assertEqual(diamonds_of(self.user), 0)

    def test_a_transient_verification_failure_can_be_retried_successfully(self):
        """Google being down must not permanently consume the purchase."""
        with _GoogleStubbed(ok=False):
            self.client.post(URL, {"product_id": "diamonds_50",
                                   "purchase_token": "tok-7"}, format="json")
        self.assertEqual(diamonds_of(self.user), 0)

        with _GoogleStubbed(ok=True):
            response = self.client.post(URL, {"product_id": "diamonds_50",
                                              "purchase_token": "tok-7"}, format="json")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(diamonds_of(self.user), 50,
                         "the buyer could never be credited after a Google outage")

    def test_a_grant_failure_leaves_the_purchase_retryable(self):
        """If granting itself fails, the row must not stay 'granted'."""
        real_grant = iap_views.grants.grant
        iap_views.grants.grant = lambda *a, **k: False
        try:
            with _GoogleStubbed():
                self.client.post(URL, {"product_id": "diamonds_50",
                                       "purchase_token": "tok-8"}, format="json")
        finally:
            iap_views.grants.grant = real_grant

        self.assertEqual(diamonds_of(self.user), 0)
        self.assertEqual(
            IapPurchase.objects.get(purchase_token="tok-8").status, "failed",
            "a failed grant left the purchase marked granted — unrecoverable")

        with _GoogleStubbed():
            self.client.post(URL, {"product_id": "diamonds_50",
                                   "purchase_token": "tok-8"}, format="json")
        self.assertEqual(diamonds_of(self.user), 50)


class ConcurrentGrantTests(TransactionTestCase):
    """The vulnerability itself: N simultaneous verifications of one token."""

    def _race(self, target, count):
        barrier = threading.Barrier(count)
        results, errors = [], []

        def run():
            barrier.wait()
            try:
                results.append(target())
            except Exception as exc:            # noqa: BLE001 - asserted on
                errors.append(exc)
            finally:
                connections.close_all()

        threads = [threading.Thread(target=run) for _ in range(count)]
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=30)
        return results, errors

    def _post(self, user, token):
        client = APIClient()
        client.force_authenticate(user=user)
        return client.post(URL, {
            "product_id": "diamonds_50", "purchase_token": token,
        }, format="json").status_code

    def test_two_simultaneous_verifications_grant_once(self):
        user = _user("race1")
        _product()
        with _GoogleStubbed():
            _, errors = self._race(lambda: self._post(user, "race-tok-1"), count=2)

        self.assertEqual(errors, [], "a concurrent verification raised")
        self.assertEqual(diamonds_of(user), 50,
                         "one purchase granted %d diamonds" % diamonds_of(user))
        self.assertEqual(IapPurchase.objects.filter(
            purchase_token="race-tok-1").count(), 1)

    def test_six_simultaneous_verifications_grant_exactly_one_pack(self):
        user = _user("race2")
        _product(diamonds=200)
        with _GoogleStubbed():
            _, errors = self._race(lambda: self._post(user, "race-tok-2"), count=6)

        self.assertEqual(errors, [])
        self.assertEqual(
            diamonds_of(user), 200,
            "6 concurrent verifications granted %d diamonds for one purchase"
            % diamonds_of(user))

    def test_no_concurrent_request_returns_a_server_error(self):
        """The loser used to crash on IntegrityError after granting."""
        user = _user("race3")
        _product()
        with _GoogleStubbed():
            results, errors = self._race(
                lambda: self._post(user, "race-tok-3"), count=4)

        self.assertEqual(errors, [])
        self.assertTrue(all(code == 200 for code in results),
                        "a concurrent verification returned %r" % (results,))
