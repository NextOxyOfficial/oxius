# -*- coding: utf-8 -*-
"""Error tracking must never become the thing that leaks the data.

This app carries wallet balances, OTPs, KYC details, phone numbers and
payment-gateway credentials. An error reporter sees request bodies and stack
frames, so the scrubber in backend/observability.py is a security control, not
a nicety — these tests are what stop a future edit from quietly widening it.
"""
import os
from unittest import mock

from django.test import TestCase

from backend.observability import _before_send, _scrub, init_sentry


class ScrubberTests(TestCase):
    def test_secrets_are_redacted(self):
        data = _scrub({
            "password": "hunter2",
            "otp": "483920",
            "api_key": "sk_live_x",
            "card_number": "4111111111111111",
            "payment_number": "+8801700000000",
            "authorization": "Bearer abc",
            "sp_password": "gateway-secret",
        })
        for key, value in data.items():
            self.assertEqual(value, "[redacted]", "%s leaked" % key)

    def test_pii_is_redacted(self):
        """send_default_pii=False only stops Sentry ATTACHING identity — it
        does nothing about PII sitting in a request body."""
        data = _scrub({
            "email": "u@x.com",
            "phone": "+8801",
            "address": "Dhaka",
            "date_of_birth": "1990-01-01",
        })
        for key, value in data.items():
            self.assertEqual(value, "[redacted]", "%s leaked" % key)

    def test_money_amounts_are_redacted(self):
        self.assertEqual(_scrub({"balance": "1200.00"})["balance"], "[redacted]")
        self.assertEqual(
            _scrub({"pending_balance": "5.00"})["pending_balance"], "[redacted]")

    def test_harmless_fields_survive(self):
        """Over-scrubbing makes the tool useless — debugging needs context."""
        data = _scrub({
            "post_id": "123",
            "transaction_type": "withdraw",
            "status": "pending",
            "first_name": "Rahim",
        })
        self.assertEqual(data["post_id"], "123")
        self.assertEqual(data["transaction_type"], "withdraw")
        self.assertEqual(data["status"], "pending")

    def test_it_reaches_into_nested_structures(self):
        data = _scrub({"request": {"data": {"inner": [{"otp": "1"}]}}})
        self.assertEqual(data["request"]["data"]["inner"][0]["otp"], "[redacted]")

    def test_matching_is_case_insensitive_and_substring(self):
        data = _scrub({"OTP": "1", "user_password": "2"})
        self.assertTrue(all(v == "[redacted]" for v in data.values()), data)

    def test_header_style_spellings_are_caught(self):
        """Headers use hyphens, and headers are where live credentials are."""
        data = _scrub({
            "X-Api-Key": "1",
            "X-Auth-Token": "2",
            "Set-Cookie": "3",
            "api key": "4",
        })
        for key, value in data.items():
            self.assertEqual(value, "[redacted]", "%s leaked" % key)

    def test_deep_recursion_is_bounded(self):
        """A runaway recursion inside the reporter would be its own outage."""
        payload = current = {}
        for _ in range(40):
            current["next"] = {}
            current = current["next"]
        current["otp"] = "deep"
        self.assertIsNotNone(_scrub(payload))

    def test_before_send_drops_the_event_rather_than_send_it_unscrubbed(self):
        with mock.patch("backend.observability._scrub",
                        side_effect=RuntimeError("boom")):
            self.assertIsNone(_before_send({"any": "thing"}, None))


class InitTests(TestCase):
    def test_no_dsn_is_a_complete_no_op(self):
        """Safe to deploy before the Sentry project exists."""
        with mock.patch.dict(os.environ, {"SENTRY_DSN": ""}, clear=False):
            self.assertFalse(init_sentry())

    def test_whitespace_dsn_counts_as_absent(self):
        with mock.patch.dict(os.environ, {"SENTRY_DSN": "   "}, clear=False):
            self.assertFalse(init_sentry())


class CaptureTests(TestCase):
    """The end-to-end shape: a real exception, captured, with no runtime leak."""

    def test_exception_is_captured_without_local_variables(self):
        import sentry_sdk

        captured = []
        sentry_sdk.init(
            dsn="https://public@o0.ingest.sentry.io/0",
            transport=lambda event: captured.append(event),
            before_send=_before_send,
            send_default_pii=False,
            include_local_variables=False,
        )
        try:
            secret_at_runtime = "hunter2"  # noqa: F841
            raise ValueError("probe failure")
        except ValueError:
            sentry_sdk.capture_exception()
        sentry_sdk.flush(timeout=5)

        self.assertEqual(len(captured), 1)
        frame = captured[0]["exception"]["values"][0]["stacktrace"]["frames"][-1]
        # Locals are the dangerous part — a frame mid-request holds passwords,
        # tokens and balances. They must not be collected at all.
        self.assertNotIn("vars", frame)
