"""Nudge catalog — the "Cortex" rules.

Each nudge knows who it's for (``eligible``) and what to say (``build``). The
engine (tasks.run_nudge_engine) evaluates them per user, respects caps/cooldowns,
and sends the single highest-priority eligible one via push + Updates tab.

Keep nudges genuinely useful and personal — never generic spam. Deep links use
full web URLs so the app's DeepLinkService resolves them to the right screen.
"""

from dataclasses import dataclass
from typing import Callable

SITE = "https://adsyclub.com"


def _name(user):
    n = (getattr(user, "first_name", "") or "").strip()
    if n:
        return n
    n = (getattr(user, "name", "") or "").strip()
    return n.split(" ")[0] if n else "there"


@dataclass
class Nudge:
    key: str
    priority: int            # higher wins when several are eligible
    cooldown_days: int       # don't resend this nudge within N days
    deep_link: str
    eligible: Callable       # (state, user) -> bool
    build: Callable          # (state, user) -> (title, body)
    # reliable=True: targeting is based on hard data (balance, kyc, subscription)
    # and is safe to send from day one. reliable=False: targeting depends on the
    # lifecycle heuristic, which only becomes trustworthy once a few days of
    # event data have accumulated — gated behind ENGAGEMENT_LIFECYCLE_NUDGES_ENABLED.
    reliable: bool = True


def _has_balance(state):
    try:
        return float(state.pending.get("withdrawable_balance", 0)) > 0
    except (TypeError, ValueError):
        return False


BN_MONTHS = [
    "জানুয়ারি", "ফেব্রুয়ারি", "মার্চ", "এপ্রিল", "মে", "জুন",
    "জুলাই", "আগস্ট", "সেপ্টেম্বর", "অক্টোবর", "নভেম্বর", "ডিসেম্বর",
]


def _sub_expiring_build(s, u):
    """Subscription-expiring message with a clear expiry date + days remaining,
    so the user knows exactly when and how long is left (professional + clear)."""
    from datetime import datetime, timezone as _tz
    title = "Pro-এর মেয়াদ ফুরিয়ে আসছে ⏳"
    try:
        exp = datetime.fromisoformat(s.pending.get("subscription_expiring"))
        now = datetime.now(_tz.utc) if exp.tzinfo else datetime.now()
        days = (exp - now).days
        date_str = f"{exp.day} {BN_MONTHS[exp.month - 1]} {exp.year}"
        if days <= 0:
            when = "মেয়াদ আজই ফুরাচ্ছে"
        elif days == 1:
            when = "হাতে মাত্র ১ দিন"
        else:
            when = f"হাতে আছে {days} দিন"
        body = (
            f"{_name(u)}, {date_str} তারিখে আপনার Pro শেষ হয়ে যাচ্ছে "
            f"({when})। রিনিউ না করলে স্টোর আর Pro সুবিধাগুলো আটকে যাবে — "
            "এক মিনিটেই রিনিউ করে নিন।"
        )
    except Exception:
        body = (
            f"{_name(u)}, আপনার Pro-এর মেয়াদ প্রায় শেষ। এক মিনিটে রিনিউ করে "
            "নিলে স্টোর আর Pro সুবিধা আগের মতোই চলতে থাকবে।"
        )
    return (title, body)


def _bn_count(n):
    """Bangla-numeral count, e.g. 4 -> ৪, 10 -> ১০."""
    table = str.maketrans("0123456789", "০১২৩৪৫৬৭৮৯")
    return str(int(n)).translate(table)


def _area_services_build(s, u):
    """Local service-availability message:
    'কুষ্টিয়া সদরে এখন ৪ জন Electrician, ১০ জন পানির মিস্ত্রি সেবা দিচ্ছেন...'.
    Counts/area come from UserState.pending (computed in aggregate_user_states)."""
    area = (s.pending.get("area_label") or "").strip()
    items = s.pending.get("area_services") or []
    parts = []
    for it in items:
        cat = (it.get("cat") or "").strip()
        n = it.get("n") or 0
        if cat and n:
            parts.append(f"{_bn_count(n)} জন {cat}")
    if not parts or not area:
        # Should not fire (eligibility guards it), but stay safe.
        return (
            "কাছেই মিলবে দরকারি লোক 🛠️",
            f"{_name(u)}, ‘আমার সেবা’ খুললেই আপনার আশেপাশের সার্ভিস প্রোভাইডারদের "
            "তালিকা পেয়ে যাবেন — নম্বর দেখে সরাসরি কল করা যায়।",
        )
    if len(parts) == 1:
        listing = parts[0]
    elif len(parts) == 2:
        listing = f"{parts[0]} ও {parts[1]}"
    else:
        listing = f"{parts[0]}, {parts[1]} ও {parts[2]}"
    title = f"{area}-এ এখনই ডাকার মতো লোক আছেন 🛠️"
    body = (
        f"{_name(u)}, এই মুহূর্তে {area}-এ {listing} কাজ নিচ্ছেন। ‘আমার সেবা’-তে "
        "তাঁদের প্রোফাইল দেখে পছন্দমতো একজনকে সরাসরি কল করে ফেলুন।"
    )
    return (title, body)


CATALOG = [
    # 1) Money on the table — verify KYC to withdraw. Link → wallet (matches subject).
    Nudge(
        key="kyc_withdraw",
        priority=100,
        cooldown_days=7,
        deep_link=f"{SITE}/deposit-withdraw",
        eligible=lambda s, u: bool(s.pending.get("kyc")) and _has_balance(s),
        build=lambda s, u: (
            "৳{} উইথড্রর অপেক্ষায় 💰".format(int(float(s.pending["withdrawable_balance"]))),
            "{}, আপনার ব্যালেন্সে ৳{} জমে আছে — KYC ভেরিফাই হয়ে গেলেই টাকাটা হাতে পেয়ে যাবেন। আজই সেরে ফেলুন।".format(
                _name(u), int(float(s.pending["withdrawable_balance"]))
            ),
        ),
    ),
    # 2) Subscription expiring — keep your store/Pro alive. Link → upgrade-to-pro.
    Nudge(
        key="subscription_expiring",
        priority=95,
        cooldown_days=2,
        deep_link=f"{SITE}/upgrade-to-pro",
        eligible=lambda s, u: bool(s.pending.get("subscription_expiring")),
        build=_sub_expiring_build,
    ),
    # 3) Win-back dormant users (7–30 days idle). Link → feed.
    Nudge(
        key="winback_dormant",
        priority=70,
        cooldown_days=7,
        deep_link=f"{SITE}/business-network",
        eligible=lambda s, u: s.lifecycle_stage == "dormant",
        build=lambda s, u: (
            "{}, ফিডে অনেক কিছু জমে গেছে 👋".format(_name(u)),
            "কদিনে আপনার নেটওয়ার্কে নতুন পোস্ট আর অফার জমেছে — দুই মিনিট ঘুরে দেখলেই সব আপডেট পেয়ে যাবেন।",
        ),
        reliable=False,
    ),
    # 4) At-risk re-engagement (3–7 days idle). Link → feed.
    Nudge(
        key="at_risk_network",
        priority=65,
        cooldown_days=5,
        deep_link=f"{SITE}/business-network",
        eligible=lambda s, u: s.lifecycle_stage == "at_risk",
        build=lambda s, u: (
            "ফলো করা মানুষদের নতুন খবর 📨",
            "গত কয়েকদিনে তাঁরা কী কী শেয়ার করলেন — ফিডে ঢুকে এক নজরে দেখে নিন।",
        ),
        reliable=False,
    ),
    # 5) Onboarding nudge — help brand-new users reach their first value. Link → feed.
    Nudge(
        key="onboarding_explore",
        priority=60,
        cooldown_days=7,
        deep_link=f"{SITE}/business-network",
        eligible=lambda s, u: s.lifecycle_stage in ("new", "onboarding"),
        build=lambda s, u: (
            "চলুন শুরু করা যাক, {} 😊".format(_name(u)),
            "প্রথম কাজ: পছন্দের কয়েকজনকে ফলো করে ফেলুন — ফিড জমে উঠবে, আর MicroGigs-এ আয়ের রাস্তাও পেয়ে যাবেন।",
        ),
    ),
    # 6) Verify identity (KYC) — unlock withdrawals, selling and full access.
    #    Lower priority than kyc_withdraw (#1) so a user with money waiting gets
    #    the stronger "money on the table" message instead.
    Nudge(
        key="kyc_verify",
        priority=85,
        cooldown_days=10,
        deep_link=f"{SITE}/my-account",
        eligible=lambda s, u: bool(s.pending.get("kyc")),
        build=lambda s, u: (
            "KYC-টা বাকি রয়ে গেছে 🪪",
            "{}, NID-র ছবি তুলে দিলেই ৫ মিনিটে KYC হয়ে যায় — তারপর উইথড্র, বিক্রি সবকিছুর দরজা খোলা।".format(
                _name(u)
            ),
        ),
    ),
    # 7) Complete your profile — more reach, more trust, better matches.
    Nudge(
        key="profile_complete",
        priority=50,
        cooldown_days=12,
        deep_link=f"{SITE}/my-account",
        eligible=lambda s, u: bool(s.pending.get("profile_incomplete")),
        build=lambda s, u: (
            "প্রোফাইলটা একটু সাজিয়ে নিন 📸",
            "{}, একটা ছবি আর দু-লাইন তথ্য বসিয়ে দিন — সার্চে সামনে আসবেন, মানুষও ভরসা পেয়ে যোগাযোগ করবে।".format(
                _name(u)
            ),
        ),
    ),
    # 8) Local service availability — "N electricians, M plumbers in your area".
    #    High priority because it's concrete, personal and conversion-driving.
    Nudge(
        key="area_services",
        priority=80,
        cooldown_days=6,
        # /classified (the আমার সেবা hub) — resolves in-app via the deep-link
        # alias AND is a valid web page; /classified-categories was opening
        # the browser on builds whose alias map lacked that segment.
        deep_link=f"{SITE}/classified",
        eligible=lambda s, u: bool(s.pending.get("area_services")),
        build=_area_services_build,
    ),
    # 9) Ask for an address so we CAN target locally (only when we have no
    #    location at all — neither saved address nor a past service search).
    Nudge(
        key="save_address",
        priority=40,
        cooldown_days=14,
        deep_link=f"{SITE}/my-account",
        eligible=lambda s, u: bool(s.pending.get("no_location")),
        build=lambda s, u: (
            "আপনার এলাকাটা বলে রাখুন 📍",
            "{}, একবার ঠিকানা সেভ করে রাখলেই কাছের ইলেকট্রিশিয়ান, মিস্ত্রি বা টিউটর "
            "কারা আছেন — সেই খবর আমরা আগেভাগে আপনাকে জানিয়ে দেব।".format(_name(u)),
        ),
    ),
]
