"""Helpers to turn raw/technical errors into clean, human-readable messages.

Use these so the API never leaks DRF serializer dumps, exception reprs, or
field codes to the app. Returns Bangla-friendly text the client can show as-is.
"""

# Friendly labels for known fields (Bangla, since the app's audience is Bengali).
FIELD_LABELS = {
    "phone": "ফোন নম্বর",
    "email": "ইমেইল",
    "first_name": "প্রথম নাম",
    "last_name": "শেষ নাম",
    "name": "নাম",
    "username": "ইউজারনেম",
    "password": "পাসওয়ার্ড",
    "date_of_birth": "জন্ম তারিখ",
    "address": "ঠিকানা",
    "city": "শহর",
    "state": "বিভাগ",
    "zip": "জিপ কোড",
    "gender": "লিঙ্গ",
    "profession": "পেশা",
    "about": "পরিচিতি",
    "store_name": "স্টোরের নাম",
}

# Rewrite the most common raw DRF/Django validator phrases into plain language.
_PHRASE_FIXES = (
    ("This field may not be blank.", "এই তথ্যটি প্রয়োজন।"),
    ("This field is required.", "এই তথ্যটি প্রয়োজন।"),
    ("This field may not be null.", "এই তথ্যটি প্রয়োজন।"),
    ("already exists", "ইতিমধ্যে ব্যবহৃত হয়েছে"),
    ("Enter a valid email address.", "সঠিক ইমেইল দিন।"),
    ("Date has wrong format", "তারিখের ফরম্যাট সঠিক নয়"),
    ("Ensure this field has no more than", "অক্ষর সীমা অতিক্রম করেছে:"),
)


def _clean_phrase(text):
    text = str(text).strip()
    for raw, nice in _PHRASE_FIXES:
        if raw in text:
            return nice
    return text


def humanize_errors(errors, default="দেওয়া তথ্যে কিছু সমস্যা আছে।"):
    """Convert DRF ``serializer.errors`` into ``(message, {field: message})``.

    ``message`` is a single short, human-readable line suitable for a snackbar.
    ``field`` map lets the client highlight the exact inputs that failed.
    """
    if not isinstance(errors, dict):
        return (_clean_phrase(errors) or default, {})

    field_map = {}
    parts = []
    for field, value in errors.items():
        if isinstance(value, (list, tuple)):
            msg = "; ".join(_clean_phrase(v) for v in value if str(v).strip())
        elif isinstance(value, dict):
            nested_msg, _ = humanize_errors(value, default)
            msg = nested_msg
        else:
            msg = _clean_phrase(value)
        if not msg:
            continue
        field_map[field] = msg
        if field == "non_field_errors":
            parts.append(msg)
        else:
            label = FIELD_LABELS.get(field, field.replace("_", " ").strip().title())
            parts.append(f"{label}: {msg}")

    return (parts[0] if parts else default, field_map)


def custom_exception_handler(exc, context):
    """Project-wide DRF exception handler.

    Non-destructive: it keeps the original error payload (so existing clients
    that read ``detail`` / field errors keep working) but guarantees a clean,
    human-readable ``message`` is always present for the app to display — so a
    raw serializer dump or exception code is never the only thing the user sees.
    """
    from rest_framework.views import exception_handler as drf_exception_handler

    response = drf_exception_handler(exc, context)
    if response is None:
        return response

    data = response.data
    if isinstance(data, dict):
        if "message" not in data or not str(data.get("message") or "").strip():
            # DRF puts a single string under "detail" for auth/permission/throttle.
            detail = data.get("detail")
            if isinstance(detail, str) and detail.strip():
                data["message"] = _clean_phrase(detail)
            else:
                msg, _ = humanize_errors(data)
                data["message"] = msg
    elif isinstance(data, list):
        msg, _ = humanize_errors({"non_field_errors": data})
        response.data = {"message": msg, "errors": data}

    return response
