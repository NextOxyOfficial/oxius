"""Personalized Bangla welcome SMS.

When a user first gets a phone on their account — at sign-up, or when they add a
number after Google login — we text them a warm, name-personalized greeting.
A random line is picked each time so not everyone gets the same message.
"""

import logging
import random
import threading

logger = logging.getLogger(__name__)

# Keep each line short (Bangla SMS is Unicode — ~70 chars per segment). {name}
# is the user's first name. Brand stays "AdsyClub".
WELCOME_SMS = [
    "{name}, AdsyClub-এ স্বাগতম! 🎉 এখন সেবা নিন-দিন, নেটওয়ার্ক গড়ুন আর কাজ করে আয় করুন। আপনার পথচলা শুভ হোক!",
    "প্রিয় {name}, AdsyClub পরিবারে আপনাকে স্বাগতম! কেনাবেচা, ফ্রিল্যান্সিং আর আয়ের নতুন দুনিয়ায় আজই শুরু করুন।",
    "{name}, আপনার AdsyClub অ্যাকাউন্ট প্রস্তুত! সেবা, পণ্য বা দক্ষতা দিয়ে আয় শুরু করুন। শুভকামনা রইলো।",
    "স্বাগতম {name}! AdsyClub-এ পাবেন eShop, Workspace, MicroGigs সহ আয়ের অসংখ্য সুযোগ। আজই ঘুরে দেখুন!",
    "{name}, AdsyClub-এ যুক্ত হওয়ায় ধন্যবাদ! 🙌 মানুষের সাথে কানেক্ট হোন, সেবা নিন আর প্রতিদিন আয় করুন।",
    "হ্যালো {name}, AdsyClub-এ আপনার যাত্রা শুরু! পণ্য বিক্রি, কাজ বা সেবা — সব এক জায়গায়। এগিয়ে যান!",
    "{name}, আপনাকে AdsyClub-এ পেয়ে আমরা আনন্দিত! 🎉 আয়, সেবা আর নেটওয়ার্কিং এখন আপনার হাতের মুঠোয়।",
    "প্রিয় {name}, AdsyClub-এ স্বাগতম! দক্ষতা কাজে লাগিয়ে আয় করুন, বিশ্বস্ত সেবা খুঁজে নিন। ভালো থাকুন।",
    "{name}, AdsyClub পরিবারে আপনি এখন একজন! 🌟 ছোট কাজ থেকে বড় ব্যবসা — আয়ের পথ খোলা। শুরু করে দিন!",
    "স্বাগতম {name}! AdsyClub-এ কেনাকাটা, রাইড, ফ্রিল্যান্সিং আর আয় — সব একসাথে। আপনার সফলতা কামনা করি।",
]


# Leading honorifics/titles to skip so "Md Alimul Islam" greets "Alimul", not "Md".
_TITLES = {
    "md", "mohammad", "mohammed", "muhammad", "mohd", "mr", "mrs", "ms", "miss",
    "mst", "most", "sri", "srimati", "dr", "engr", "alhaj",
    "মো", "মোঃ", "মোহাম্মদ", "জনাব", "মিস্টার", "ডা", "শ্রী",
}


def _first_name(name):
    parts = [p for p in (name or "").strip().split() if p]
    while parts and parts[0].lower().rstrip(".।") in _TITLES:
        parts.pop(0)
    return parts[0] if parts else "বন্ধু"


def pick_welcome_sms(name):
    """A random welcome line with the user's first name filled in."""
    return random.choice(WELCOME_SMS).format(name=_first_name(name))


def send_welcome_sms(name, phone):
    """Pick + send one welcome SMS (blocking). Safe to call inside a thread."""
    if not phone:
        return
    message = pick_welcome_sms(name)
    try:
        from base.views import _send_smsinbd_message
        _send_smsinbd_message(phone, message)
    except Exception as exc:  # pragma: no cover
        logger.error(f"welcome SMS failed for {phone}: {exc}")


def send_welcome_sms_async(name, phone):
    """Fire-and-forget the welcome SMS off the request thread (the SMS API call
    is a blocking ~1-2s round-trip)."""
    def _run():
        try:
            send_welcome_sms(name, phone)
        finally:
            try:
                from django.db import connections
                connections.close_all()
            except Exception:
                pass

    threading.Thread(target=_run, daemon=True).start()
