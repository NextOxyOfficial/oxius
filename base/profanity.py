"""Lightweight profanity guard for user-chosen text (names, usernames).

Blocks obviously vulgar English + Bangla words at registration so accounts
can't be created with abusive display names. Kept intentionally small and
substring/token based — the goal is to stop the blatant cases, not to be a
perfect filter.
"""

import re
import unicodedata

# Base English profanity roots (matched as substrings after normalization).
_EN_ROOTS = {
    "fuck", "fuk", "fck", "shit", "bitch", "bastard", "asshole", "dick",
    "cunt", "pussy", "penis", "vagina", "boobs", "slut", "whore", "sex",
    "porn", "xxx", "nude", "rape", "nigger", "nigga", "motherfucker", "mofo",
    "cock", "wank", "jerk off", "blowjob", "handjob", "anal", "cum",
    "faggot", "retard", "harami", "haramzada", "kutta", "kutti", "suar",
    "chutiya", "chutia", "madarchod", "madarchid", "behenchod", "bhosda",
    "bhosdi", "gaand", "gand", "lund", "lauda", "loda", "chod", "randi",
    "magi", "khanki", "kanki", "khankir", "boka", "kut+ar",
}

# Bangla-script vulgar tokens (whole-string normalized contains).
_BN_TOKENS = {
    "মাগি", "মাগী", "খানকি", "খানকী", "খাংকি", "বেশ্যা", "রেন্ডি", "রান্ডি",
    "চুদি", "চুদা", "চোদা", "চুদ", "বাল", "লেওড়া", "লেওরা", "নুনু", "ধোন",
    "গুদ", "চটি", "হারামি", "হারামজাদা", "কুত্তা", "শুয়োর", "শুওর",
    "মাদারচোদ", "বাইনচোদ", "বেহায়া", "চুতিয়া", "চুতমারানি", "পোঁদ",
}


def _normalize(text):
    t = unicodedata.normalize("NFKC", (text or "")).lower()
    # collapse common leet substitutions so f*ck / f.u.c.k / fu_ck are caught
    t = t.replace("@", "a").replace("$", "s").replace("0", "o")
    t = t.replace("1", "i").replace("3", "e").replace("!", "i")
    t = re.sub(r"[^a-zঀ-৿]+", " ", t)  # keep latin + bangla only
    return t


def contains_profanity(text):
    if not text:
        return False
    raw = text or ""
    norm = _normalize(raw)
    compact = norm.replace(" ", "")
    for root in _EN_ROOTS:
        r = root.replace(" ", "")
        if r and r in compact:
            return True
    for tok in _BN_TOKENS:
        if tok in raw:
            return True
    return False
