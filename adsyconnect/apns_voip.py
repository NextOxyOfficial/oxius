import time
import uuid

import httpx
import jwt
from django.conf import settings


def _apns_setting(name, default=""):
    return str(getattr(settings, name, default) or "").strip()


def is_configured():
    return all(
        [
            _apns_setting("APNS_AUTH_KEY_PATH"),
            _apns_setting("APNS_KEY_ID"),
            _apns_setting("APNS_TEAM_ID"),
            _apns_setting("APNS_VOIP_TOPIC"),
        ]
    )


def _provider_token():
    key_path = _apns_setting("APNS_AUTH_KEY_PATH")
    with open(key_path, "r", encoding="utf-8") as key_file:
        signing_key = key_file.read()

    headers = {
        "alg": "ES256",
        "kid": _apns_setting("APNS_KEY_ID"),
    }
    claims = {
        "iss": _apns_setting("APNS_TEAM_ID"),
        "iat": int(time.time()),
    }
    return jwt.encode(claims, signing_key, algorithm="ES256", headers=headers)


def send_voip_push(device_token, payload, *, collapse_id=None, environment=None):
    """Send a direct APNs VoIP push for iOS CallKit wakeups."""
    if not is_configured():
        return {
            "sent": False,
            "disabled": True,
            "error": "APNs VoIP credentials are not configured",
        }

    token = str(device_token or "").strip()
    if not token:
        return {"sent": False, "disabled": False, "error": "empty VoIP token"}

    apns_environment = (
        str(environment or "").strip()
        or _apns_setting("APNS_ENVIRONMENT", "production")
        or "production"
    )
    host = (
        "https://api.sandbox.push.apple.com"
        if apns_environment == "sandbox"
        else "https://api.push.apple.com"
    )
    topic = _apns_setting("APNS_VOIP_TOPIC")
    url = f"{host}/3/device/{token}"

    headers = {
        "authorization": f"bearer {_provider_token()}",
        "apns-topic": topic,
        "apns-push-type": "voip",
        "apns-priority": "10",
        "apns-expiration": str(int(time.time()) + 60),
        "apns-id": str(uuid.uuid4()),
    }
    if collapse_id:
        headers["apns-collapse-id"] = str(collapse_id)[:64]

    body = {
        "aps": {"content-available": 1},
        **payload,
    }

    with httpx.Client(http2=True, timeout=5.0) as client:
        response = client.post(url, headers=headers, json=body)

    if response.status_code == 200:
        return {"sent": True, "disabled": False, "error": None}

    return {
        "sent": False,
        "disabled": False,
        "error": f"APNs {response.status_code}: {response.text[:200]}",
    }
