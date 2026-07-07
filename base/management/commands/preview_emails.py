"""Send a preview of EVERY user-facing email template to one inbox.

Usage (on the server):
    python manage.py preview_emails --to alimulislam50@gmail.com

Grabs the target user by email (falls back to a synthetic user object) and
fires every send_* template with realistic sample data, overriding the
recipient so all previews land in the same inbox. Each template is sent
synchronously and reported individually — nothing is silently skipped.
"""

import time

from django.core.management.base import BaseCommand

from base import email_service as es
from base.models import User


class _Obj:
    """Loose attribute bag for synthetic model stand-ins."""

    def __init__(self, **kw):
        self.__dict__.update(kw)

    def __getattr__(self, name):  # missing attrs -> None
        return None


class Command(BaseCommand):
    help = "Send one preview of every user-facing email template to --to"

    def add_arguments(self, parser):
        parser.add_argument("--to", required=True, help="Recipient inbox")

    def handle(self, *args, **options):
        to = options["to"].strip()

        # Use the real account when it exists so name/phone/referral fields
        # render with true data; otherwise a synthetic user.
        user = User.objects.filter(email__iexact=to).first()
        if user is None:
            user = _Obj(
                name="Alimul Islam", first_name="Alimul", last_name="Islam",
                username="alimul", email=to, phone="01763837367",
                referral_code="ADSY1234",
            )
        # Force every mail to the preview inbox even for "seller/receiver"
        # roles that would normally go elsewhere.
        user.email = to
        other = _Obj(
            name="Karim Ahmed", first_name="Karim", last_name="Ahmed",
            username="karim", email=to, phone="01712345678",
        )

        order = _Obj(
            order_number="AC-2026-0042", total_amount="1250",
            payment_method="AdsyPay", created_at=None,
            delivery_address="ধানমন্ডি, ঢাকা", phone="01763837367",
        )
        items = [
            _Obj(product_name="Wireless Earbuds", quantity=1, price="850"),
            _Obj(product_name="Phone Case", quantity=2, price="200"),
        ]
        ride = _Obj(
            id="RIDE-77",
            rider=user,
            assigned_driver=other,
            pickup_address="মিরপুর ১০",
            drop_address="গুলশান ১",
            final_fare="220",
            fare_estimate="220",
            distance_km="7.4",
            duration_seconds=1260,
            payment_method="AdsyPay",
        )
        ticket = _Obj(id="TCK-19", title="পেমেন্ট নিয়ে সমস্যা", user=user)

        previews = [
            ("welcome", lambda: es.send_welcome_email(user)),
            ("profile_completion", lambda: es.send_profile_completion_email(user)),
            ("ceo_welcome", lambda: es.send_ceo_welcome_email(user)),
            ("transfer_sent", lambda: es.send_transfer_sent_email(user, other, "500", "TRX123456")),
            ("transfer_received", lambda: es.send_transfer_received_email(user, other, "500", "TRX123456")),
            ("deposit", lambda: es.send_deposit_email(user, "1000", "DEP778899", "bKash")),
            ("withdraw_submitted", lambda: es.send_withdraw_email(user, "750", "WD445566", "Nagad", "01763837367")),
            ("withdraw_approved", lambda: es.send_withdraw_approved_email(user, "750", "WD445566")),
            ("withdraw_rejected", lambda: es.send_withdraw_rejected_email(user, "750", "WD445566", "পেমেন্ট নম্বরটা ভুল ছিল")),
            ("gig_order_placed", lambda: es.send_gig_order_placed_email(user, other, "লোগো ডিজাইন", "300", "GIG-101")),
            ("gig_order_completed", lambda: es.send_gig_order_completed_email(user, other, "লোগো ডিজাইন", "300", "GIG-101")),
            ("gig_order_status", lambda: es.send_gig_order_status_email(user, "লোগো ডিজাইন", "GIG-101", "in_progress", "Karim Ahmed")),
            ("kyc_received", lambda: es.send_kyc_received_email(user)),
            ("kyc_approved", lambda: es.send_kyc_approved_email(user)),
            ("kyc_rejected", lambda: es.send_kyc_rejected_email(user, "ছবিটা ঝাপসা এসেছে — আবার তুলে দিন")),
            ("account_suspended", lambda: es.send_account_suspended_email(user, "কমিউনিটি গাইডলাইন লঙ্ঘন")),
            ("account_unsuspended", lambda: es.send_account_unsuspended_email(user)),
            ("pro_subscription", lambda: es.send_pro_subscription_email(user, 3, "1500")),
            ("referral_reward", lambda: es.send_referral_reward_email(user, "50", "signup")),
            ("password_reset_otp", lambda: es.send_password_reset_email(user, "482913")),
            ("password_changed", lambda: es.send_password_changed_email(user)),
            ("mobile_recharge", lambda: es.send_mobile_recharge_email(user, "100", "01763837367")),
            ("product_order_seller", lambda: es.send_product_order_email(user, order, items)),
            ("order_confirmation_buyer", lambda: es.send_order_confirmation_email(user, order)),
            ("post_approved", lambda: es.send_post_approved_email(user, "আমার নতুন সার্ভিস", "post", "https://adsyclub.com")),
            ("post_rejected", lambda: es.send_post_rejected_email(user, "আমার নতুন সার্ভিস", "post", "ছবি স্পষ্ট নয়", "https://adsyclub.com")),
            ("post_received", lambda: es.send_post_received_email(user, "আমার নতুন সার্ভিস", "post", "https://adsyclub.com")),
            ("driver_approved", lambda: es.send_driver_approved_email(user)),
            ("driver_rejected", lambda: es.send_driver_rejected_email(user, "লাইসেন্সের মেয়াদ শেষ")),
            ("ride_receipt", lambda: es.send_ride_receipt_email(ride)),
            ("support_reply", lambda: es.send_support_reply_email(ticket, "আপনার সমস্যাটা আমরা ঠিক করে দিয়েছি — এখন দেখে নিন।")),
        ]

        sent, failed = [], []
        for name, fire in previews:
            try:
                fire()
                sent.append(name)
                self.stdout.write(f"[sent] {name}")
            except Exception as e:  # report, never abort the run
                failed.append((name, str(e)[:120]))
                self.stdout.write(f"[FAIL] {name}: {e}")
            # SMTP-friendly pacing; async sends queue instantly anyway.
            time.sleep(1.5)

        self.stdout.write(self.style.SUCCESS(
            f"done — sent {len(sent)}/{len(previews)}, failed {len(failed)}"))
        for name, err in failed:
            self.stdout.write(f"  failed: {name} -> {err}")
