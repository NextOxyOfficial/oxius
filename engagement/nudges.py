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


CATALOG = [
    # 1) Money on the table — verify KYC to withdraw. Link → wallet (matches subject).
    Nudge(
        key="kyc_withdraw",
        priority=100,
        cooldown_days=7,
        deep_link=f"{SITE}/deposit-withdraw",
        eligible=lambda s, u: bool(s.pending.get("kyc")) and _has_balance(s),
        build=lambda s, u: (
            "৳{} তুলে নিন 💰".format(int(float(s.pending["withdrawable_balance"]))),
            "{}, আপনার ৳{} ব্যালেন্স উত্তোলনের জন্য প্রস্তুত। KYC যাচাই করে এখনই তুলে নিন।".format(
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
        build=lambda s, u: (
            "আপনার Pro-এর মেয়াদ শেষ হচ্ছে ⏳",
            "এখনই নবায়ন করুন — আপনার স্টোর দৃশ্যমান ও Pro সুবিধা চালু রাখতে।",
        ),
    ),
    # 3) Win-back dormant users (7–30 days idle). Link → feed.
    Nudge(
        key="winback_dormant",
        priority=70,
        cooldown_days=7,
        deep_link=f"{SITE}/business-network",
        eligible=lambda s, u: s.lifecycle_stage == "dormant",
        build=lambda s, u: (
            "আপনাকে মিস করছি, {} 👋".format(_name(u)),
            "আপনি না থাকার সময় আপনার নেটওয়ার্কে অনেক কিছু হয়েছে — দেখে নিন কী নতুন।",
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
            "আপনার নেটওয়ার্কে নতুন পোস্ট 📨",
            "আপনি যাদের ফলো করেন তারা নতুন আপডেট শেয়ার করেছেন। এক নজরে দেখুন।",
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
            "AdsyClub-এ স্বাগতম, {} 🎉".format(_name(u)),
            "মানুষজনকে ফলো করুন, ফিড ঘুরে দেখুন, আর আয়ের নতুন উপায় খুঁজে নিন।",
        ),
    ),
]
