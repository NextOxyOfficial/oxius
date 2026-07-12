"""Google Play purchase verification (server-side, mandatory for security).

Uses a Play service account (google-auth) to call the Android Publisher REST
API directly — no googleapiclient dependency. Configure via env / settings:

    GOOGLE_PLAY_PACKAGE_NAME = "com.oxius.app"
    GOOGLE_PLAY_SA_JSON      = "/path/to/service-account.json"  (or the raw JSON)

Until those are set, every verify() returns None and the caller records the
purchase as 'failed' (no entitlement granted) — so the app can be shipped now
and activated the moment the credentials land, with zero code change.
"""
import json
import logging

import requests
from django.conf import settings

logger = logging.getLogger(__name__)

_SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]
_BASE = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications"


def _credentials():
    raw = getattr(settings, "GOOGLE_PLAY_SA_JSON", "") or ""
    if not raw:
        return None
    try:
        from google.oauth2 import service_account

        if raw.strip().startswith("{"):
            info = json.loads(raw)
        else:
            with open(raw, "r", encoding="utf-8") as fh:
                info = json.load(fh)
        return service_account.Credentials.from_service_account_info(
            info, scopes=_SCOPES
        )
    except Exception:
        logger.exception("[iap] failed to load Play service account")
        return None


def _access_token():
    creds = _credentials()
    if creds is None:
        return None
    try:
        from google.auth.transport.requests import Request as GRequest

        creds.refresh(GRequest())
        return creds.token
    except Exception:
        logger.exception("[iap] failed to mint Play access token")
        return None


def _pkg():
    return getattr(settings, "GOOGLE_PLAY_PACKAGE_NAME", "") or "com.oxius.app"


def _get(url):
    tok = _access_token()
    if not tok:
        return None
    try:
        r = requests.get(
            url, headers={"Authorization": f"Bearer {tok}"}, timeout=20
        )
        if r.status_code == 200:
            return r.json()
        logger.warning("[iap] verify %s -> %s %s", url, r.status_code, r.text[:200])
    except Exception:
        logger.exception("[iap] verify request failed")
    return None


def _post(url):
    tok = _access_token()
    if not tok:
        return False
    try:
        r = requests.post(
            url, headers={"Authorization": f"Bearer {tok}"}, timeout=20
        )
        return r.status_code in (200, 204)
    except Exception:
        logger.exception("[iap] acknowledge failed")
        return False


def verify_product(product_id, purchase_token):
    """One-off product (diamonds). Returns Google's purchase state dict or None.
    purchaseState: 0=purchased, 1=canceled, 2=pending."""
    return _get(
        f"{_BASE}/{_pkg()}/purchases/products/{product_id}/tokens/{purchase_token}"
    )


def acknowledge_product(product_id, purchase_token):
    return _post(
        f"{_BASE}/{_pkg()}/purchases/products/{product_id}/tokens/"
        f"{purchase_token}:acknowledge"
    )


def verify_subscription(purchase_token):
    """Subscriptions v2 (Pro / Gold Sponsor). Returns the subscription dict
    (subscriptionState, lineItems[].expiryTime, ...) or None."""
    return _get(
        f"{_BASE}/{_pkg()}/purchases/subscriptionsv2/tokens/{purchase_token}"
    )


def acknowledge_subscription(purchase_token):
    return _post(
        f"{_BASE}/{_pkg()}/purchases/subscriptionsv2/tokens/"
        f"{purchase_token}:acknowledge"
    )
