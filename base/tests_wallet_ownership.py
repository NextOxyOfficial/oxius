# -*- coding: utf-8 -*-
"""Nobody may move money in a wallet that is not theirs.

`UserBalance` is a ListCreateAPIView whose `get_queryset` filters by
`request.user` — which scoped the GET and made the view look safe. Nothing
governed the POST: DRF's inherited `create()` read `user` from the request
body, and `Balance.save()` then moved that account's money. `deposit` credits
unconditionally, so it minted; `withdraw` runs the hold, so it drained.

Every test here fails against the code as it was.
"""
import itertools
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from base.models import Balance

User = get_user_model()
_counter = itertools.count(1)


def _user(tag, balance="0.00"):
    n = next(_counter)
    user = User.objects.create_user(
        username="own_%s_%d" % (tag, n), email="own_%s_%d@example.com" % (tag, n),
        password="x", first_name=tag, phone="+88010008%05d" % n)
    User.objects.filter(pk=user.pk).update(balance=Decimal(balance))
    user.refresh_from_db()
    return user


def balance_of(user):
    return User.objects.values_list("balance", flat=True).get(pk=user.pk)


class WalletOwnershipTests(TestCase):
    def setUp(self):
        self.attacker = _user("attacker", "0.00")
        self.victim = _user("victim", "5000.00")
        self.client = APIClient()
        self.client.force_authenticate(user=self.attacker)
        self.url = "/api/user-balance/%s/" % self.attacker.email

    # ── the mint ────────────────────────────────────────────────────────────

    def test_cannot_mint_into_own_wallet_by_posting_a_deposit(self):
        """`deposit` credits unconditionally in Balance.save()."""
        before = balance_of(self.attacker)
        self.client.post(self.url, {
            "user": str(self.attacker.id),
            "transaction_type": "deposit",
            "payable_amount": "999999.00",
        }, format="json")
        self.assertEqual(
            balance_of(self.attacker), before,
            "a self-posted deposit credited the wallet — money was minted")

    def test_cannot_mint_into_another_users_wallet(self):
        before = balance_of(self.victim)
        self.client.post(self.url, {
            "user": str(self.victim.id),
            "transaction_type": "deposit",
            "payable_amount": "999999.00",
        }, format="json")
        self.assertEqual(balance_of(self.victim), before)

    # ── the drain ───────────────────────────────────────────────────────────

    def test_cannot_drain_another_users_wallet_with_a_withdrawal(self):
        """`withdraw` runs the hold, which debits."""
        before = balance_of(self.victim)
        self.client.post(self.url, {
            "user": str(self.victim.id),
            "transaction_type": "withdraw",
            "payable_amount": "5000.00",
        }, format="json")
        self.assertEqual(
            balance_of(self.victim), before,
            "another user's wallet was debited")

    def test_a_row_created_here_is_always_owned_by_the_caller(self):
        """Even a 'successful' create must be bound to the authenticated user."""
        self.client.post(self.url, {
            "user": str(self.victim.id),
            "transaction_type": "deposit",
            "payable_amount": "10.00",
        }, format="json")
        for row in Balance.objects.all():
            self.assertEqual(
                row.user_id, self.attacker.id,
                "a ledger row was attributed to a user who did not create it")

    def test_the_email_in_the_url_does_not_choose_the_wallet(self):
        """The route carries <str:email>, which the view never reads."""
        before = balance_of(self.victim)
        self.client.post("/api/user-balance/%s/" % self.victim.email, {
            "transaction_type": "deposit",
            "payable_amount": "500.00",
        }, format="json")
        self.assertEqual(balance_of(self.victim), before)

    # ── the settlement flags ────────────────────────────────────────────────

    def test_cannot_pre_approve_a_withdrawal_to_skip_the_debit(self):
        rows_before = Balance.objects.count()
        self.client.post(self.url, {
            "transaction_type": "withdraw",
            "payable_amount": "100.00",
            "approved": True,
            "completed": True,
        }, format="json")
        for row in Balance.objects.all()[rows_before:]:
            self.assertFalse(row.approved)
            self.assertFalse(row.completed)

    def test_cannot_set_the_refund_amount_that_a_rejection_pays_out(self):
        """`amount` is what a rejection refunds. Client-settable, it is a mint:
        hold 200, declare amount=99999, get rejected, receive 99999."""
        self.client.post(self.url, {
            "transaction_type": "withdraw",
            "payable_amount": "100.00",
            "amount": "99999.00",
        }, format="json")
        for row in Balance.objects.filter(transaction_type="withdraw"):
            self.assertNotEqual(
                row.amount, Decimal("99999.00"),
                "the client set the field that a rejection refunds")

    # ── reading ─────────────────────────────────────────────────────────────

    def test_the_list_shows_only_the_callers_own_rows(self):
        Balance.objects.create(
            user=self.victim, transaction_type="deposit",
            payable_amount=Decimal("10.00"), completed=True, approved=True)
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 200)
        body = response.json()
        rows = body if isinstance(body, list) else body.get("results", [])
        for row in rows:
            self.assertEqual(str(row.get("user")), str(self.attacker.id))

    def test_the_endpoint_does_not_accept_writes_at_all(self):
        """The create half had no legitimate caller, so it was removed rather
        than guarded. 405 is the correct answer to every write verb."""
        for verb in ("post", "put", "patch", "delete"):
            response = getattr(self.client, verb)(self.url, {}, format="json")
            self.assertEqual(
                response.status_code, 405,
                "%s is still accepted on the wallet ledger endpoint" % verb.upper())

    def test_anonymous_callers_are_refused(self):
        anon = APIClient()
        response = anon.post(self.url, {
            "user": str(self.victim.id),
            "transaction_type": "deposit",
            "payable_amount": "100.00",
        }, format="json")
        self.assertIn(response.status_code, (401, 403, 405))
        self.assertEqual(balance_of(self.victim), Decimal("5000.00"))

    # ── invariant ───────────────────────────────────────────────────────────

    def test_no_request_to_this_endpoint_changes_the_money_supply(self):
        """The strongest statement: whatever a client posts here, the total
        amount of money in the system must not change."""
        total_before = sum(
            User.objects.values_list("balance", flat=True))
        for payload in (
            {"user": str(self.victim.id), "transaction_type": "deposit",
             "payable_amount": "1000.00"},
            {"user": str(self.attacker.id), "transaction_type": "deposit",
             "payable_amount": "1000.00"},
            {"transaction_type": "deposit", "payable_amount": "1000.00"},
            {"user": str(self.victim.id), "transaction_type": "withdraw",
             "payable_amount": "1000.00"},
        ):
            self.client.post(self.url, payload, format="json")
        total_after = sum(User.objects.values_list("balance", flat=True))
        self.assertEqual(
            total_after, total_before,
            "the money supply changed — this endpoint can create or destroy money")
