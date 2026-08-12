# -*- coding: utf-8 -*-
"""Error tracking.

Until this existed, a production 500 was invisible. The custom exception
handler turns every unhandled exception into a tidy JSON body for the client
(base/error_utils.py), and the only trace left behind was a bare `print()` to
gunicorn's stdout — no stack, no request, no user, nothing anyone would ever
read. Failures were found by users complaining.

Two rules shape everything here:

1. NO DSN, NO SENTRY. If SENTRY_DSN is unset the whole thing is a no-op, so
   this is safe to merge and deploy before the Sentry project exists, and safe
   in tests and local development where it would only be noise.

2. NOTHING SENSITIVE LEAVES THE BOX. This app carries wallet balances, OTPs,
   KYC data, phone numbers and payment-gateway credentials. send_default_pii
   stays off, and _scrub() below removes this codebase's own secret-bearing
   keys on top of Sentry's generic defaults — an error report is not worth a
   data breach.
"""
import os

#: Keys whose VALUE must never be transmitted, matched case-insensitively as a
#: substring so `card_number`, `payment_number` and `sp_password` are all
#: caught. Sentry scrubs a generic set already; these are ours.
_SENSITIVE_SUBSTRINGS = (
    "password",
    "passwd",
    "secret",
    "token",
    "otp",
    "authorization",
    "api_key",
    "apikey",
    "card_number",
    "payment_number",
    "card",
    "cvv",
    "pin",
    "nid",
    "balance",
    "private_key",
    "credential",
    "session",
    "cookie",
    # PII. send_default_pii=False only stops Sentry ATTACHING the user's
    # identity automatically — it does nothing about an email or a phone number
    # sitting in a request body, which is exactly where this app's are.
    "email",
    "phone",
    "mobile",
    "address",
    "date_of_birth",
    "dob",
)

_REDACTED = "[redacted]"


def _looks_sensitive(key):
    # Separators are normalised because the same secret arrives under several
    # spellings depending on where it came from: `api_key` in a JSON body,
    # `X-Api-Key` in a header, `api key` in a form field. Matching only the
    # underscore form let the header spelling — the likeliest one to carry a
    # live credential — straight through.
    lowered = str(key).lower().replace("-", "_").replace(" ", "_")
    return any(marker in lowered for marker in _SENSITIVE_SUBSTRINGS)


def _scrub(value, depth=0):
    """Recursively redact sensitive values in an event payload.

    Depth-limited because an event can carry deeply nested frames and a
    runaway recursion inside the error reporter would be its own outage.
    """
    if depth > 12:
        return value
    if isinstance(value, dict):
        return {
            key: (_REDACTED if _looks_sensitive(key) else _scrub(item, depth + 1))
            for key, item in value.items()
        }
    if isinstance(value, (list, tuple)):
        scrubbed = [_scrub(item, depth + 1) for item in value]
        return type(value)(scrubbed) if isinstance(value, tuple) else scrubbed
    return value


def _before_send(event, hint):
    """Last gate before an event leaves the process."""
    try:
        return _scrub(event)
    except Exception:
        # A scrubber that raises must not take the request down with it, and an
        # unscrubbed event must never be sent — drop it instead.
        return None


def init_sentry():
    """Start error tracking, if a DSN is configured. Safe to call always."""
    dsn = (os.getenv("SENTRY_DSN") or "").strip()
    if not dsn:
        return False

    try:
        import sentry_sdk
        from sentry_sdk.integrations.celery import CeleryIntegration
        from sentry_sdk.integrations.django import DjangoIntegration
        from sentry_sdk.integrations.logging import LoggingIntegration
    except ImportError:
        # The package is optional at runtime; a missing dependency must not
        # stop the site from booting.
        return False

    environment = (
        os.getenv("SENTRY_ENVIRONMENT")
        or ("development" if os.getenv("DEBUG", "").lower() in ("true", "1", "yes", "on")
            else "production")
    )

    sentry_sdk.init(
        dsn=dsn,
        environment=environment,
        release=os.getenv("SENTRY_RELEASE") or None,
        integrations=[
            # Covers WSGI (gunicorn) and ASGI (daphne) requests, and the ORM.
            DjangoIntegration(),
            CeleryIntegration(),
            # ERROR and above become events; INFO becomes breadcrumbs.
            LoggingIntegration(level=None, event_level="ERROR"),
        ],
        # OFF, deliberately. This app carries wallet balances, OTPs, KYC and
        # phone numbers; PII in an error report is a breach waiting to happen.
        send_default_pii=False,
        # Performance tracing is sampled at zero by default: this runs on one
        # 3.8GB box that also hosts Postgres and Redis, and tracing every
        # request would cost more than it tells us. Raise it deliberately, and
        # temporarily, when investigating something.
        traces_sample_rate=float(os.getenv("SENTRY_TRACES_SAMPLE_RATE", "0") or 0),
        # Source context helps; local variables can hold a password mid-frame.
        include_local_variables=False,
        max_breadcrumbs=30,
        before_send=_before_send,
    )
    return True
