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


def _has_balance(state):
    try:
        return float(state.pending.get("withdrawable_balance", 0)) > 0
    except (TypeError, ValueError):
        return False


CATALOG = [
    # 1) Money on the table — verify KYC to withdraw. Highest value/intent.
    Nudge(
        key="kyc_withdraw",
        priority=100,
        cooldown_days=7,
        deep_link=f"{SITE}/deposit-withdraw",
        eligible=lambda s, u: bool(s.pending.get("kyc")) and _has_balance(s),
        build=lambda s, u: (
            "Withdraw your earnings 💰",
            f"You have ৳{int(float(s.pending['withdrawable_balance']))} ready. "
            f"Verify your KYC to withdraw it, {_name(u)}.",
        ),
    ),
    # 2) Subscription expiring — keep your store/Pro alive. Time-sensitive.
    Nudge(
        key="subscription_expiring",
        priority=95,
        cooldown_days=2,
        deep_link=f"{SITE}/upgrade-to-pro",
        eligible=lambda s, u: bool(s.pending.get("subscription_expiring")),
        build=lambda s, u: (
            "Your Pro is about to expire ⏳",
            "Renew now to keep your store visible and your Pro features active.",
        ),
    ),
    # 3) Win-back dormant users (7–30 days idle).
    Nudge(
        key="winback_dormant",
        priority=70,
        cooldown_days=7,
        deep_link=f"{SITE}/business-network",
        eligible=lambda s, u: s.lifecycle_stage == "dormant",
        build=lambda s, u: (
            f"We miss you, {_name(u)} 👋",
            "Your network has been busy while you were away — see what's new.",
        ),
    ),
    # 4) At-risk re-engagement (3–7 days idle) — pull them back early.
    Nudge(
        key="at_risk_network",
        priority=65,
        cooldown_days=5,
        deep_link=f"{SITE}/business-network",
        eligible=lambda s, u: s.lifecycle_stage == "at_risk",
        build=lambda s, u: (
            "New posts from your network 📨",
            "People you follow have shared updates. Take a quick look.",
        ),
    ),
    # 5) Onboarding nudge — help brand-new users reach their first value.
    Nudge(
        key="onboarding_explore",
        priority=60,
        cooldown_days=7,
        deep_link=f"{SITE}/business-network",
        eligible=lambda s, u: s.lifecycle_stage in ("new", "onboarding"),
        build=lambda s, u: (
            f"Welcome to AdsyClub, {_name(u)} 🎉",
            "Follow people, explore your feed, and discover ways to earn.",
        ),
    ),
]
