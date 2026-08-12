# -*- coding: utf-8 -*-
"""A referral reward is paid to exactly one claim, exactly once.

THE BUG

`ReferralRewardClaim.claim_reward()` gated the payout on the object in memory:

    if self.status == 'claimed':
        return False, "Already claimed"
    if self.status != 'eligible':
        return False, "Conditions not met"

    self.user.balance += self.reward_amount
    self.user.save()
    ...
    self.status = 'claimed'
    self.save()

Two requests carrying the same claim both read `eligible`, both pass, and both
credit — the reward is minted as many times as the button is pressed in
parallel. The gap between the check and `self.save()` is wide: a wallet write, a
ledger row, and an email attempt all happen in between.

`unique_together` on the model prevents duplicate claim ROWS, which is what
makes this easy to miss — it does nothing about one row being claimed twice.
"""
import itertools
import threading
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.db import connections
from django.test import TestCase, TransactionTestCase
from rest_framework.test import APIClient

from referral_rewards.models import (ReferralRewardClaim,
                                     ReferralRewardProgram)

User = get_user_model()
_counter = itertools.count(1)


def _user(tag, balance="0.00"):
    n = next(_counter)
    user = User.objects.create_user(
        username="rr_%s_%d" % (tag, n), email="rr_%s_%d@example.com" % (tag, n),
        password="x", first_name=tag, phone="+88010000%05d" % n)
    User.objects.filter(pk=user.pk).update(balance=Decimal(balance))
    user.refresh_from_db()
    return user


def balance_of(user):
    return User.objects.values_list("balance", flat=True).get(pk=user.pk)


def money_supply():
    return sum(User.objects.values_list("balance", flat=True))


class _ClaimFixture:
    reward = Decimal("200.00")

    def make_claim(self, *, status="eligible", amount=None):
        self.owner = _user("owner", "0.00")
        self.referred = _user("referred", "0.00")
        self.program = ReferralRewardProgram.objects.create(
            name="New Year", referrer_reward=self.reward,
            referee_reward=self.reward, is_active=True)
        return ReferralRewardClaim.objects.create(
            program=self.program, user=self.owner,
            referred_user=self.referred, claim_type="referrer",
            status=status,
            reward_amount=self.reward if amount is None else amount)


class ClaimTests(TestCase, _ClaimFixture):
    def test_an_eligible_claim_pays_the_reward(self):
        claim = self.make_claim()
        ok, message = claim.claim_reward()
        self.assertTrue(ok, message)
        self.assertEqual(balance_of(self.owner), self.reward)

    def test_the_claim_is_marked_claimed(self):
        claim = self.make_claim()
        claim.claim_reward()
        claim.refresh_from_db()
        self.assertEqual(claim.status, "claimed")
        self.assertIsNotNone(claim.claimed_at)

    def test_claiming_twice_pays_once(self):
        claim = self.make_claim()
        first, _ = claim.claim_reward()
        second, message = claim.claim_reward()
        self.assertTrue(first)
        self.assertFalse(second)
        self.assertEqual(balance_of(self.owner), self.reward)

    def test_a_stale_object_cannot_claim_again(self):
        claim = self.make_claim()
        stale = ReferralRewardClaim.objects.get(pk=claim.pk)   # still eligible

        claim.claim_reward()
        stale.claim_reward()

        self.assertEqual(
            balance_of(self.owner), self.reward,
            "a stale claim object paid the reward a second time")

    def test_a_pending_claim_cannot_be_claimed(self):
        claim = self.make_claim(status="pending")
        ok, _ = claim.claim_reward()
        self.assertFalse(ok)
        self.assertEqual(balance_of(self.owner), Decimal("0.00"))

    def test_an_already_claimed_row_cannot_be_reclaimed(self):
        claim = self.make_claim(status="claimed")
        ok, _ = claim.claim_reward()
        self.assertFalse(ok)
        self.assertEqual(balance_of(self.owner), Decimal("0.00"))

    def test_the_amount_comes_from_the_record_not_the_caller(self):
        claim = self.make_claim(amount=Decimal("75.00"))
        claim.reward_amount = Decimal("99999.00")   # in-memory tampering
        claim.claim_reward()
        self.assertEqual(
            balance_of(self.owner), Decimal("75.00"),
            "the reward followed an in-memory amount instead of the record")

    def test_a_zero_reward_creates_no_money(self):
        claim = self.make_claim(amount=Decimal("0.00"))
        before = money_supply()
        claim.claim_reward()
        self.assertEqual(money_supply(), before)

    def test_a_ledger_row_is_written_once(self):
        from base.models import Balance
        claim = self.make_claim()
        claim.claim_reward()
        claim.claim_reward()
        self.assertEqual(
            Balance.objects.filter(
                user=self.owner, transaction_type="referral_reward").count(), 1)


class AuthorizationTests(TestCase, _ClaimFixture):
    def test_another_user_cannot_claim_someone_elses_reward(self):
        claim = self.make_claim()
        stranger = _user("stranger")
        client = APIClient()
        client.force_authenticate(user=stranger)

        response = client.post("/api/referral-rewards/claim/%s/" % claim.id)

        self.assertIn(response.status_code, (403, 404))
        self.assertEqual(balance_of(self.owner), Decimal("0.00"))
        self.assertEqual(balance_of(stranger), Decimal("0.00"))

    def test_an_anonymous_caller_cannot_claim(self):
        claim = self.make_claim()
        response = APIClient().post(
            "/api/referral-rewards/claim/%s/" % claim.id)
        self.assertIn(response.status_code, (401, 403))
        self.assertEqual(balance_of(self.owner), Decimal("0.00"))


class ConcurrentClaimTests(TransactionTestCase, _ClaimFixture):
    """Real threads on real connections."""

    def _race(self, target, count):
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

    def test_five_concurrent_claims_pay_once(self):
        claim = self.make_claim()

        def go():
            fresh = ReferralRewardClaim.objects.get(pk=claim.pk)
            ok, _ = fresh.claim_reward()
            return ok

        out = self._race(go, count=5)

        self.assertEqual(
            balance_of(self.owner), self.reward,
            "five concurrent claims paid %s; results=%s"
            % (balance_of(self.owner), out))
        self.assertEqual(sum(1 for r in out if r is True), 1,
                         "more than one caller believed it had claimed")

    def test_two_concurrent_claims_pay_once(self):
        claim = self.make_claim()

        def go():
            fresh = ReferralRewardClaim.objects.get(pk=claim.pk)
            ok, _ = fresh.claim_reward()
            return ok

        self._race(go, count=2)
        self.assertEqual(balance_of(self.owner), self.reward)

    def test_concurrent_claims_do_not_inflate_the_money_supply(self):
        claim = self.make_claim()
        before = money_supply()

        def go():
            fresh = ReferralRewardClaim.objects.get(pk=claim.pk)
            return fresh.claim_reward()[0]

        self._race(go, count=5)

        self.assertEqual(
            money_supply(), before + self.reward,
            "the money supply grew by more than one reward")

    def test_exactly_one_ledger_row_under_concurrency(self):
        from base.models import Balance
        claim = self.make_claim()

        def go():
            fresh = ReferralRewardClaim.objects.get(pk=claim.pk)
            return fresh.claim_reward()[0]

        self._race(go, count=5)

        self.assertEqual(
            Balance.objects.filter(
                user=self.owner, transaction_type="referral_reward").count(), 1,
            "concurrent claims wrote more than one ledger row")
