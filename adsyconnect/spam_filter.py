"""Lightweight keyword-based spam classifier for AdsyConnect messages.

We deliberately keep this dependency-free and fast: every inbound text message
is scanned once at send time, so it must be O(len(message)). It flags three
broad abuse categories a small marketplace chat actually sees — vulgar/abusive
language, gambling/betting solicitation, and unsolicited marketing/scam blasts.

The goal is a "Maybe spam" bucket, not moderation truth: false positives just
land a message in a secondary tab the user can still open, so we bias toward
recall on the obvious cases and keep the lists conservative to avoid nuking
normal conversation.
"""
import re

# Substrings (matched case-insensitively, Unicode-aware). Bengali + English
# terms that in practice only show up in abusive/gambling/marketing blasts.
_VULGAR = [
    "fuck", "motherfucker", "bitch", "asshole", "bastard", "dick pic",
    "nude", "nudes", "sex chat", "sexchat", "horny", "porn", "xxx",
    "খানকি", "মাগি", "মাগী", "চুদ", "চোদ", "বেশ্যা", "বেশ্যার", "রেন্ডি",
    "শুয়োর", "কুত্তার বাচ্চা", "হারামি", "হারামজাদা",
]

_GAMBLING = [
    "betting", "bet365", "1xbet", "melbet", "casino", "jackpot", "lottery",
    "poker", "roulette", "baji", "baazi", "jeetbuzz", "jitbuzz", "krikya",
    "জুয়া", "বাজি", "ক্যাসিনো", "বেটিং", "লটারি", "জিতুন", "জিতে নিন",
]

_MARKETING = [
    "earn money online", "work from home", "investment plan", "double your money",
    "guaranteed profit", "guaranteed income", "loan approved", "click this link",
    "limited offer", "act now", "whatsapp me", "inbox me for", "dm me for",
    "promo code", "discount code", "hot deal", "buy now cheap",
    "টাকা ইনকাম", "ইনকাম করুন", "ঘরে বসে আয়", "বিনিয়োগ করুন", "লোন পাবেন",
    "অফার চলছে", "ফ্রি টাকা", "ডাবল করুন",
]

_CATEGORIES = (
    ("vulgar", _VULGAR),
    ("gambling", _GAMBLING),
    ("marketing", _MARKETING),
)

# A raw URL plus a money/urgency word is a classic spam blast shape.
_URL_RE = re.compile(r"https?://|www\.|\b[a-z0-9-]+\.(?:com|net|xyz|link|top|bet)\b",
                     re.IGNORECASE)
_MONEY_HINT_RE = re.compile(
    r"(?:\$|৳|taka|টাকা|bkash|বিকাশ|nagad|নগদ|free|ফ্রি|offer|অফার)",
    re.IGNORECASE,
)


def classify_message(text):
    """Return (is_spam: bool, category: str) for a message body.

    category is one of vulgar/gambling/marketing/link, or '' when clean.
    """
    if not text:
        return False, ""
    low = text.lower()

    for category, terms in _CATEGORIES:
        for term in terms:
            if term in low:
                return True, category

    # Link + money/urgency hint together → treat as a marketing/scam blast.
    if _URL_RE.search(text) and _MONEY_HINT_RE.search(text):
        return True, "link"

    return False, ""
