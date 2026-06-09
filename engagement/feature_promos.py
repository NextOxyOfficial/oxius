"""Feature-awareness promo catalog.

Light, friendly Bangla one-liners that introduce each AdsyClub feature. The
engine (tasks.run_feature_promos) sends ~2 per user per day at random times
between 9am–9pm (Bangladesh time), never repeating a line it sent the same user
in the last week — so it feels human, not robotic.

Each promo key is "promo_<feature>_<n>" so we can dedupe + measure per line.
"""

import random

SITE = "https://adsyclub.com"

# feature -> { "deep_link": url, "messages": [(title, body), ...] }
FEATURE_PROMOS = {
    # Amar Sheba = everyday SERVICE ads (post a service, find a service person).
    # /classified resolves on the app (services screen); web /classified redirects
    # to /classified-categories.
    "amarseba": {
        "deep_link": SITE + "/classified",
        "messages": [
            ("আপনার সেবা এখন সবার হাতের নাগালে 🛠️",
             "ইলেকট্রিশিয়ান, টিউটর, পার্লার — যেকোনো সেবা দিন বা নিন ‘আমার সেবা’-তে। আজই দেখুন!"),
            ("নতুন কাজের সুযোগ — আমার সেবা 💼",
             "আপনার দক্ষতা দিয়ে আয় করুন। ‘আমার সেবা’-তে আপনার সার্ভিস ফ্রি-তে পোস্ট করুন।"),
            ("ঘরের কাছেই দরকারি সেবা খুঁজুন 📍",
             "আপনার এলাকার বিশ্বস্ত সেবাদাতা খুঁজে পেতে ‘আমার সেবা’ দেখুন।"),
            ("সেবা দিয়ে আয় শুরু করুন আজই 🌟",
             "হাজারো মানুষ ‘আমার সেবা’-তে কাস্টমার পাচ্ছে — আপনিও যুক্ত হোন।"),
            ("আমার সেবা-তে কী খুঁজছেন? 🔎",
             "প্লাম্বার থেকে গৃহশিক্ষক — সব সেবা এক জায়গায়। এখনই ব্রাউজ করুন।"),
        ],
    },
    # eShop = brand-NEW products / e-commerce (sellers' stores).
    "eshop": {
        "deep_link": SITE + "/eshop",
        "messages": [
            ("eShop-এ নতুন পণ্যের সম্ভার 🛒",
             "ব্র্যান্ড-নিউ পণ্য দারুণ দামে কিনুন AdsyClub eShop-এ। আজই দেখে নিন!"),
            ("নিজের স্টোর খুলুন eShop-এ 🏪",
             "Pro হয়ে আপনার পণ্য সারা দেশে বিক্রি করুন। আজই স্টোর চালু করুন।"),
            ("আজকের সেরা ডিল eShop-এ 🔥",
             "হাতছাড়া করবেন না! eShop-এ নতুন অফারগুলো দেখে নিন এখনই।"),
            ("কেনাকাটা এখন আরও সহজ 🛍️",
             "ঘরে বসেই অর্ডার করুন, ক্যাশ অন ডেলিভারিতে পান। eShop দেখুন।"),
            ("eShop — বিক্রি করুন, আয় করুন 💵",
             "আপনার নতুন পণ্যের ছবি দিন, অর্ডার পান। eShop-এ ব্যবসা শুরু করুন।"),
        ],
    },
    # Sale marketplace = buy/sell USED / second-hand items.
    "sale": {
        "deep_link": SITE + "/sale",
        "messages": [
            ("পুরোনো জিনিস বিক্রি করুন সহজে 📦",
             "ব্যবহৃত ফোন, ফার্নিচার, গাড়ি — যা আছে বিক্রি করুন পুরোনো কেনাবেচা মার্কেটপ্লেসে।"),
            ("কম দামে ভালো জিনিস কিনুন 🛒",
             "পুরোনো কেনাবেচা মার্কেটপ্লেসে ব্যবহৃত পণ্য কিনুন সাশ্রয়ী দামে। আজই ঘুরে দেখুন।"),
            ("অব্যবহৃত জিনিস পড়ে আছে? বিক্রি করুন 💰",
             "ঘরের অপ্রয়োজনীয় জিনিস পুরোনো কেনাবেচা মার্কেটপ্লেসে পোস্ট করে আয় করুন।"),
            ("পুরোনো কেনাবেচা মার্কেটপ্লেস — পুরোনো জিনিসের কেনাবেচা 🔄",
             "সেকেন্ড-হ্যান্ড জিনিস কেনা-বেচার সবচেয়ে সহজ জায়গা। দেখে নিন।"),
            ("আপনার এলাকায় পুরোনো জিনিস খুঁজুন 📍",
             "কাছাকাছি ব্যবহৃত পণ্য কিনুন বা বিক্রি করুন পুরোনো কেনাবেচা মার্কেটপ্লেসে।"),
        ],
    },
    "mindforce": {
        "deep_link": SITE + "/mindforce",
        "messages": [
            ("প্রশ্ন আছে? উত্তর পান Mindforce-এ 🧠",
             "যেকোনো সমস্যা পোস্ট করুন, কমিউনিটির সাহায্য নিন Mindforce-এ।"),
            ("জ্ঞান শেয়ার করুন, এগিয়ে যান 🏆",
             "Mindforce-এ অন্যদের প্রশ্নের উত্তর দিন আর নিজের পরিচিতি বাড়ান।"),
            ("Mindforce — সবার বুদ্ধির মেলা 💡",
             "নতুন আইডিয়া, পরামর্শ আর সমাধান — সব এক জায়গায়। দেখে নিন।"),
            ("আটকে গেছেন কোথাও? Mindforce আছে 🤝",
             "আপনার প্রশ্ন করুন, দ্রুত সাহায্য পান কমিউনিটি থেকে।"),
            ("আজ Mindforce-এ নতুন কী? 🔥",
             "চলমান আলোচনা আর প্রশ্নগুলো দেখে নিন, যোগ দিন কথোপকথনে।"),
        ],
    },
    "workspace": {
        "deep_link": SITE + "/business-network/workspaces",
        "messages": [
            ("কাজ খুঁজছেন? Workspace দেখুন 💼",
             "ফ্রিল্যান্স গিগ পোস্ট করুন বা কাজ নিন AdsyClub Workspace-এ।"),
            ("দক্ষতা দিয়ে আয় করুন Workspace-এ 🚀",
             "আপনার সার্ভিস গিগ হিসেবে দিন, নতুন ক্লায়েন্ট পান।"),
            ("নতুন প্রজেক্ট, নতুন আয় 💰",
             "Workspace-এ আপনার পরবর্তী কাজ খুঁজে নিন আজই।"),
            ("ফ্রিল্যান্সিং শুরু করুন AdsyClub-এ 🌐",
             "Workspace-এ গিগ তৈরি করে নিজের অনলাইন ব্যবসা গড়ুন।"),
            ("Workspace — কাজ আর ফ্রিল্যান্সার একসাথে 🤝",
             "দরকারি কাজের জন্য দক্ষ ফ্রিল্যান্সার খুঁজুন এক জায়গায়।"),
        ],
    },
    "rideshare": {
        "deep_link": SITE + "/rideshare",
        "messages": [
            ("কোথাও যাবেন? রাইড নিন 🚗",
             "AdsyClub Rideshare-এ সহজে রাইড বুক করুন, নিরাপদে পৌঁছান।"),
            ("ড্রাইভার হয়ে আয় করুন 🚕",
             "নিজের গাড়ি/বাইকে রাইড দিয়ে ইনকাম করুন Rideshare-এ।"),
            ("দ্রুত, সাশ্রয়ী রাইড 🛵",
             "এক ট্যাপে রাইড বুক করুন। Rideshare এখনই দেখে নিন।"),
            ("Rideshare — যাত্রা সহজ করুন 🗺️",
             "শহরের যেকোনো প্রান্তে যান সহজে, কম খরচে।"),
            ("আজ Rideshare ট্রাই করেছেন? 🚙",
             "রাইড বুক করা এখন আগের চেয়ে সহজ — একবার দেখুন।"),
        ],
    },
    "microgigs": {
        "deep_link": SITE + "/micro-gigs",
        "messages": [
            ("ছোট কাজ, বড় আয় — MicroGigs 💸",
             "অল্প সময়ে ছোট কাজ করে আয় করুন AdsyClub MicroGigs-এ।"),
            ("ফ্রি সময়ে আয় করুন ⏱️",
             "সহজ মাইক্রো টাস্ক করুন, প্রতিদিন কিছু ইনকাম করুন MicroGigs-এ।"),
            ("নতুন মাইক্রো গিগ এসেছে 🆕",
             "MicroGigs-এ নতুন কাজগুলো দেখুন, শুরু করুন এখনই।"),
            ("হাতে কিছু সময়? আয় করুন 🤳",
             "ছোট ছোট কাজ করে পকেট মানি ইনকাম করুন MicroGigs-এ।"),
            ("MicroGigs — যত কাজ, তত আয় 📈",
             "যত বেশি টাস্ক করবেন, তত বেশি আয়। আজই শুরু করুন।"),
        ],
    },
    "news": {
        "deep_link": SITE + "/adsy-news",
        "messages": [
            ("আজকের খবর AdsyNews-এ 📰",
             "দেশ-বিদেশের সর্বশেষ খবর পড়ুন AdsyClub News-এ।"),
            ("ব্রেকিং নিউজ মিস করবেন না 🔔",
             "গুরুত্বপূর্ণ আপডেট পেতে News সেকশন দেখে নিন।"),
            ("News — জেনে রাখুন সবার আগে 🌍",
             "প্রযুক্তি, খেলা, বিনোদন — সব খবর এক জায়গায়।"),
            ("আজ কী ঘটছে? News-এ দেখুন 📲",
             "সর্বশেষ সংবাদের সাথে আপডেট থাকুন AdsyNews-এ।"),
            ("একটু বিরতি? খবর পড়ে নিন ☕",
             "চায়ের সাথে আজকের শিরোনামগুলো দেখে নিন AdsyNews-এ।"),
        ],
    },
}


def all_promo_keys():
    keys = []
    for feature, data in FEATURE_PROMOS.items():
        for i in range(len(data["messages"])):
            keys.append(f"promo_{feature}_{i + 1}")
    return keys


def pick_promo(exclude_keys=None):
    """Return a random (key, title, body, deep_link), avoiding `exclude_keys`
    (recently-sent lines). Falls back to the full pool if everything's excluded."""
    exclude = set(exclude_keys or ())
    pool = []
    for feature, data in FEATURE_PROMOS.items():
        for i, (title, body) in enumerate(data["messages"]):
            key = f"promo_{feature}_{i + 1}"
            pool.append((key, title, body, data["deep_link"]))
    fresh = [p for p in pool if p[0] not in exclude]
    chosen_from = fresh or pool
    return random.choice(chosen_from)
