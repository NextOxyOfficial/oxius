"""One-off announcement: a new AdsyClub version is live.

Sends a single broadcast push to every active device AND an update email to
every active user with a valid, non-suppressed address. Safe to re-run:
  --push-only / --email-only  limit to one channel
  --test EMAIL                send only to that address (dry check the layout)
  --limit N                   cap the number of emails (smoke test)
"""
import time

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand

PLAY_URL = "https://play.google.com/store/apps/details?id=com.oxius.app"
APPSTORE_URL = "https://apps.apple.com/app/id6760218370"

PUSH_TITLE = "নতুন আপডেট এসেছে 🎉"
PUSH_BODY = (
    "AdsyClub-এর নতুন ভার্সন এখন লাইভ — আরও দ্রুত, আরও সুন্দর। "
    "অ্যাপ চালিয়ে যেতে এখনই আপডেট করুন।"
)
EMAIL_SUBJECT = "AdsyClub-এর গুরুত্বপূর্ণ নতুন আপডেট এসেছে 🎉"


def _email_html():
    from base.email_service import _base_template, _button

    body = f"""
<tr><td class="ec-pad" style="padding:8px 36px 0;">
<h1 style="margin:0 0 12px;color:#0f172a;font-size:22px;font-weight:800;line-height:1.3;">
নতুন আপডেট এসেছে 🎉</h1>
<p style="margin:0 0 14px;color:#475569;font-size:15px;line-height:1.7;">
AdsyClub-এর নতুন ভার্সন <strong>(v8.1.30)</strong> এখন Google Play ও App Store-এ লাইভ।
এই আপডেটে অ্যাপ আরও দ্রুত, আরও সুন্দর এবং নতুন অনেক ফিচার যুক্ত হয়েছে —
কনটেন্ট মনিটাইজেশন, উন্নত AdsyConnect চ্যাট, নতুন হোম ডিজাইন সহ আরও অনেক কিছু।</p>
<p style="margin:0 0 20px;color:#475569;font-size:15px;line-height:1.7;">
নিরবচ্ছিন্নভাবে অ্যাপ ব্যবহার চালিয়ে যেতে অনুগ্রহ করে <strong>এখনই আপডেট</strong> করে নিন।</p>
</td></tr>
<tr><td class="ec-pad" style="padding:0 36px 8px;">{_button('Google Play থেকে আপডেট করুন', PLAY_URL)}</td></tr>
<tr><td class="ec-pad" style="padding:0 36px 24px;">{_button('App Store থেকে আপডেট করুন', APPSTORE_URL)}</td></tr>
"""
    return _base_template(
        "AdsyClub নতুন আপডেট",
        body,
        footer_note="আপনি AdsyClub-এর সদস্য বলে এই ইমেইলটি পেয়েছেন।",
    )


class Command(BaseCommand):
    help = "Broadcast the new-version announcement via push + email."

    def add_arguments(self, parser):
        parser.add_argument("--push-only", action="store_true")
        parser.add_argument("--email-only", action="store_true")
        parser.add_argument("--test", default=None, help="Send only to this email.")
        parser.add_argument("--limit", type=int, default=0)

    def handle(self, *args, **opts):
        # ── Push (one broadcast row + fan-out to all active devices) ────────
        if not opts["email_only"] and not opts["test"]:
            from base.push_notifications import send_push_notification

            send_push_notification(
                title=PUSH_TITLE,
                body=PUSH_BODY,
                notification_type="app_update",
                broadcast=True,
            )
            self.stdout.write(self.style.SUCCESS("Broadcast push sent."))

        if opts["push_only"]:
            return

        # ── Email ───────────────────────────────────────────────────────────
        from base.email_service import _send_email, is_email_suppressed

        html = _email_html()
        text = (
            "AdsyClub-এর নতুন ভার্সন (v8.1.30) এখন লাইভ। অ্যাপ চালিয়ে যেতে "
            f"আপডেট করুন।\nGoogle Play: {PLAY_URL}\nApp Store: {APPSTORE_URL}"
        )

        if opts["test"]:
            _send_email(EMAIL_SUBJECT, opts["test"], text, html, wait=True)
            self.stdout.write(self.style.SUCCESS(f"Test email -> {opts['test']}"))
            return

        User = get_user_model()
        users = (
            User.objects.filter(is_active=True)
            .exclude(email="")
            .exclude(email__isnull=True)
        )
        sent = skipped = 0
        for user in users.iterator():
            email = (user.email or "").strip()
            if not email:
                continue
            if is_email_suppressed(email):
                skipped += 1
                continue
            try:
                _send_email(EMAIL_SUBJECT, email, text, html, wait=True)
                sent += 1
            except Exception as exc:  # never let one bad address stop the run
                skipped += 1
                self.stderr.write(f"skip {email}: {exc}")
                continue
            if opts["limit"] and sent >= opts["limit"]:
                break
            time.sleep(0.35)  # SMTP-friendly pacing
            if sent % 100 == 0:
                self.stdout.write(f"  ...{sent} sent")

        self.stdout.write(
            self.style.SUCCESS(f"Emails sent: {sent}, skipped: {skipped}")
        )
