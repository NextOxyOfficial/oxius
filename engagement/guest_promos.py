"""Registration-conversion push series for GUEST devices.

These go to FCMToken rows with user=None — people who installed the app but
haven't registered. We rotate through the list (one per device per run,
respecting a cooldown) so each guest gets a varied set of reasons to sign up,
not the same message twice. Natural spoken Bangla per the product voice.

Each item: (title, body, deep_link). deep_link points at a screen that nudges
sign-up; the app routes unauthenticated users to login/register first.
"""

SITE = "https://adsyclub.com"

# Ordered by persuasiveness; the engine sends index = promo_count (so a device
# gets #0 first, then #1, ...). Keep every message standalone and inviting.
GUEST_PROMOS = [
    (
        "একটা অ্যাকাউন্টেই সব দরজা খোলা 🔑",
        "আয়, কেনাবেচা, সার্ভিস, রাইড — সবকিছুর জন্য লাগবে শুধু একটা ফ্রি "
        "অ্যাকাউন্ট। নাম আর নম্বর দিলেই হয়ে যাবে।",
        f"{SITE}/auth/register",
    ),
    (
        "অ্যাপ তো নামালেন, আয়টাও শুরু হোক 💸",
        "রেজিস্টার করলেই MicroGigs-এর ছোট ছোট কাজ খুলে যাবে — ফোন থেকেই "
        "করা যায়, টাকা জমে ওয়ালেটে।",
        f"{SITE}/micro-gigs",
    ),
    (
        "মিস্ত্রি-টিউটর খোঁজার সহজ রাস্তা 🔧",
        "‘আমার সেবা’-তে এলাকা বাছলেই কাছের সার্ভিস প্রোভাইডারদের নম্বর হাতে — "
        "ফ্রি অ্যাকাউন্ট খুলে খোঁজা শুরু করুন।",
        f"{SITE}/classified",
    ),
    (
        "দরকারি জিনিসটা এখানেই মিলবে 🛍️",
        "নতুন পণ্য eShop-এ, পুরোনোটা কেনাবেচা মার্কেটে — অ্যাকাউন্ট খুললেই "
        "দুটোই হাতের মুঠোয়, ক্যাশ অন ডেলিভারিসহ।",
        f"{SITE}/eshop",
    ),
    (
        "আপনার ব্যবসার কথা মানুষ জানুক 📣",
        "Business Network-এ ফ্রি প্রোফাইল খুলে পোস্ট দিন — পরিচিতি বাড়বে, "
        "নতুন কাস্টমারও আসবে সেখান থেকেই।",
        f"{SITE}/business-network",
    ),
    (
        "সাইনআপে লাগে আধা মিনিটও না ⏱️",
        "নাম, নম্বর, পাসওয়ার্ড — ব্যস, হয়ে গেল। তারপর ওয়ালেট, মোবাইল রিচার্জ, "
        "রাইড শেয়ার সব একসাথে চালু।",
        f"{SITE}/auth/register",
    ),
]

# Stop after the whole series has been shown this many times total.
GUEST_PROMO_MAX = len(GUEST_PROMOS)
