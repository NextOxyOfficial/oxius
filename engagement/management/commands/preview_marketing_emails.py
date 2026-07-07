"""Send ONE of every marketing / warm-up follow-up email to a single inbox.

These are the engagement-engine emails users receive periodically (NOT the
transactional templates): the activity nudges (balance ready, verify KYC,
finish profile, renew Pro, services near you, win-back, ...) and one email per
feature-promo family (eShop, আমার সেবা, sale, Mindforce, workspace,
rideshare, micro gigs, news). Each renders with realistic content so the
design can be reviewed exactly as recipients see it.

Usage (on the server):
    python manage.py preview_marketing_emails --to alimulislam50@gmail.com
"""

import time
from datetime import timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from base.email_service import send_engagement_email
from base.models import User
from engagement.feature_promos import FEATURE_PROMOS
from engagement.nudges import CATALOG


class _State:
    """Minimal stand-in for UserState — nudges read `.pending` and
    `.lifecycle_stage`."""

    def __init__(self, user, pending, lifecycle_stage="active"):
        self.user = user
        self.pending = pending
        self.lifecycle_stage = lifecycle_stage


class Command(BaseCommand):
    help = "Send one preview of every marketing/engagement email to --to"

    def add_arguments(self, parser):
        parser.add_argument("--to", required=True, help="Recipient inbox")

    def handle(self, *args, **options):
        to = options["to"].strip()
        user = User.objects.filter(email__iexact=to).first()
        if user is None:
            self.stderr.write(f"No user with email {to}; using a synthetic one.")

            class _U:
                def __init__(self):
                    self.name = "Alimul Islam"
                    self.first_name = "Alimul"
                    self.email = to
                    self.id = 0

            user = _U()
        # Ensure everything lands in the review inbox.
        user.email = to

        soon = (timezone.now() + timedelta(days=3)).isoformat()

        # Per-nudge synthetic state so each build() renders its real content.
        nudge_states = {
            "kyc_withdraw": _State(user, {"kyc": True, "withdrawable_balance": "1250"}),
            "subscription_expiring": _State(user, {"subscription_expiring": soon}),
            "winback_dormant": _State(user, {}, lifecycle_stage="dormant"),
            "at_risk_network": _State(user, {}, lifecycle_stage="at_risk"),
            "onboarding_explore": _State(user, {}, lifecycle_stage="new"),
            "kyc_verify": _State(user, {"kyc": True}),
            "profile_complete": _State(user, {"profile_incomplete": True}),
            "area_services": _State(
                user,
                {
                    "area_label": "কুষ্টিয়া সদর",
                    "area_services": [
                        {"cat": "Electrician", "n": 4},
                        {"cat": "পানির মিস্ত্রি", "n": 10},
                        {"cat": "গৃহশিক্ষক", "n": 6},
                    ],
                },
            ),
            "save_address": _State(user, {"no_location": True}),
        }

        sent, failed = [], []

        # 1) Activity nudges — the "balance / KYC / profile / services" mails.
        for nudge in CATALOG:
            state = nudge_states.get(nudge.key)
            if state is None:
                continue
            try:
                title, body = nudge.build(state, user)
                feature = None
                send_engagement_email(
                    user,
                    subject=f"[প্রিভিউ · nudge] {title}",
                    heading=title,
                    body_html=body,
                    button_text="এখনই দেখুন",
                    button_url=nudge.deep_link,
                    content_feature=feature,
                )
                sent.append(f"nudge:{nudge.key}")
                self.stdout.write(f"[sent] nudge:{nudge.key}")
            except Exception as e:
                failed.append((f"nudge:{nudge.key}", str(e)[:120]))
                self.stdout.write(f"[FAIL] nudge:{nudge.key}: {e}")
            time.sleep(1.5)

        # 2) One feature-promo email per family (with dynamic content, e.g.
        #    real eShop products for the eShop family).
        for feature, data in FEATURE_PROMOS.items():
            title, body = data["messages"][0]
            try:
                send_engagement_email(
                    user,
                    subject=f"[প্রিভিউ · {feature}] {title}",
                    heading=title,
                    body_html=body,
                    button_text="এখনই দেখুন",
                    button_url=data["deep_link"],
                    content_feature=feature,
                )
                sent.append(f"promo:{feature}")
                self.stdout.write(f"[sent] promo:{feature}")
            except Exception as e:
                failed.append((f"promo:{feature}", str(e)[:120]))
                self.stdout.write(f"[FAIL] promo:{feature}: {e}")
            time.sleep(1.5)

        self.stdout.write(
            self.style.SUCCESS(
                f"done — sent {len(sent)}, failed {len(failed)}"
            )
        )
        for name, err in failed:
            self.stdout.write(f"  failed: {name} -> {err}")
