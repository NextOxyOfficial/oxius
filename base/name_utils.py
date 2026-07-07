"""Shared name helpers for greetings (push / email).

`friendly_first_name` returns the name to greet a user by. A bare first-token
split is wrong for Bangladeshi names that lead with an honorific — "Md Alimul
Islam" would greet "Md". When the first token is an honorific (Md, Mst, Mrs,
Dr, ...), the actual given name follows, so we keep BOTH tokens: "Md Alimul".
"""

# Honorifics compared case-insensitively with any trailing dot stripped.
_HONORIFICS = {
    "md", "mohammad", "mohammed", "muhammad", "mohd", "mohd",
    "mst", "most", "musammat", "mosammat",
    "mrs", "mr", "miss", "ms", "sri", "srimati", "smt",
    "dr", "prof", "engr", "adv", "hafez", "mawlana", "moulana",
}


def friendly_first_name(full_name, fallback="বন্ধু"):
    """Best display first-name for a greeting.

    "Md Alimul Islam" -> "Md Alimul"; "Karim Ahmed" -> "Karim";
    "" / None -> fallback.
    """
    name = (full_name or "").strip()
    if not name:
        return fallback
    parts = name.split()
    first = parts[0]
    if first.lower().rstrip(".") in _HONORIFICS and len(parts) > 1:
        return f"{parts[0]} {parts[1]}"
    return first


def greeting_name(user, fallback="বন্ধু"):
    """friendly_first_name from a user object (name -> first_name -> username)."""
    for attr in ("name", "first_name", "username"):
        val = (getattr(user, attr, "") or "").strip()
        if val:
            return friendly_first_name(val, fallback=fallback)
    return fallback
