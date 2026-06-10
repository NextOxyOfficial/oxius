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
        "AdsyClub-এ স্বাগতম! 🎉",
        "ফ্রি অ্যাকাউন্ট খুলে আয়, কেনা-বেচা আর সব সার্ভিস এক জায়গায় পান। "
        "মাত্র ৩০ সেকেন্ডে রেজিস্ট্রেশন করুন।",
        f"{SITE}/auth/register",
    ),
    (
        "ঘরে বসে আয় করুন 💰",
        "মাইক্রো গিগ করে, রেফার করে আর সার্ভিস দিয়ে ইনকাম করুন। "
        "অ্যাকাউন্ট খুলেই শুরু করুন — একদম ফ্রি।",
        f"{SITE}/micro-gigs",
    ),
    (
        "আপনার এলাকার সব সার্ভিস এক অ্যাপে 🛠️",
        "ইলেকট্রিশিয়ান, মিস্ত্রি, টিউটর — কাছের বিশ্বস্ত সার্ভিস প্রোভাইডার "
        "খুঁজুন ‘আমার সেবা’-তে। রেজিস্টার করে দেখুন।",
        f"{SITE}/classified",
    ),
    (
        "কেনা-বেচা আর eShop একসাথে 🛒",
        "নতুন পণ্য, পুরোনো জিনিস — সব কিনুন-বেচুন AdsyClub-এ। "
        "ফ্রি অ্যাকাউন্ট খুলে আজই দেখুন।",
        f"{SITE}/eshop",
    ),
    (
        "হাজারো মানুষের নেটওয়ার্কে যুক্ত হোন 🤝",
        "বিজনেস নেটওয়ার্কে ফ্রি প্রোফাইল খুলে পোস্ট করুন, ফলো করুন, "
        "নতুন কাস্টমার পান। এখনই জয়েন করুন।",
        f"{SITE}/business-network",
    ),
    (
        "৩০ সেকেন্ডে সব ফিচার আনলক করুন ✅",
        "রেজিস্ট্রেশন করে ওয়ালেট, রাইড শেয়ার, মোবাইল রিচার্জ আর আয়ের সব "
        "সুযোগ চালু করুন। অপেক্ষা কেন?",
        f"{SITE}/auth/register",
    ),
]

# Stop after the whole series has been shown this many times total.
GUEST_PROMO_MAX = len(GUEST_PROMOS)
