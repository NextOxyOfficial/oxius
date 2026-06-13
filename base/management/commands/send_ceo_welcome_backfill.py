"""One-time (idempotent) backfill: send the personal CEO welcome email to every
active user with a valid email who has NOT received it yet.

The CEO welcome auto-sends on new registration; this command covers users who
registered before that feature existed. It is safe to re-run — `ceo_welcome_sent`
is flipped to True on each successful send, so a second run skips them. It also
skips unsubscribed/bounced addresses (EmailSuppression) and rate-limits sends.

Examples (run on the server, in the project venv):
    python manage.py send_ceo_welcome_backfill --dry-run
    python manage.py send_ceo_welcome_backfill --before 2026-06-12 --sleep 2
    python manage.py send_ceo_welcome_backfill --limit 200
"""

import time
from datetime import datetime

from django.core.management.base import BaseCommand
from django.utils import timezone


class Command(BaseCommand):
    help = "Send the personal CEO welcome email to all valid-email users who haven't received it."

    def add_arguments(self, parser):
        parser.add_argument(
            "--dry-run", action="store_true",
            help="List who would be emailed and the count; send nothing.",
        )
        parser.add_argument(
            "--limit", type=int, default=0,
            help="Stop after this many sends (0 = no limit).",
        )
        parser.add_argument(
            "--sleep", type=float, default=1.5,
            help="Seconds to wait between sends (rate limit; default 1.5).",
        )
        parser.add_argument(
            "--before", type=str, default=None,
            help="Only users who joined before this date (YYYY-MM-DD). Use to "
                 "skip recent registrants who already received it.",
        )

    def handle(self, *args, **opts):
        from base.models import User
        from base.email_service import send_ceo_welcome_email, is_email_suppressed

        qs = (
            User.objects.filter(ceo_welcome_sent=False, is_active=True)
            .exclude(email__isnull=True)
            .exclude(email="")
        )

        if opts["before"]:
            try:
                dt = timezone.make_aware(
                    datetime.strptime(opts["before"], "%Y-%m-%d")
                )
            except (ValueError, Exception):
                self.stderr.write(self.style.ERROR("Invalid --before date; use YYYY-MM-DD"))
                return
            qs = qs.filter(date_joined__lt=dt)

        qs = qs.order_by("id")
        total = qs.count()
        self.stdout.write(
            f"Candidates (ceo_welcome_sent=False, active, has email"
            + (f", joined before {opts['before']}" if opts["before"] else "")
            + f"): {total}"
        )
        if opts["dry_run"]:
            self.stdout.write(self.style.WARNING("DRY RUN — nothing will be sent."))

        sent = skipped = failed = 0
        for u in qs.iterator():
            email = (u.email or "").strip()
            if not email:
                continue
            if is_email_suppressed(email):
                skipped += 1
                continue

            if opts["dry_run"]:
                self.stdout.write(f"[dry-run] would send -> {email}")
                sent += 1
            else:
                try:
                    ok = send_ceo_welcome_email(u)  # marks ceo_welcome_sent on success
                except Exception as exc:
                    ok = False
                    self.stderr.write(f"ERROR sending to {email}: {exc}")
                if ok:
                    sent += 1
                    self.stdout.write(f"sent -> {email}")
                else:
                    failed += 1
                    self.stderr.write(self.style.ERROR(f"FAILED -> {email}"))
                if opts["sleep"]:
                    time.sleep(opts["sleep"])

            if opts["limit"] and sent >= opts["limit"]:
                self.stdout.write(f"Reached --limit {opts['limit']}, stopping.")
                break

        self.stdout.write(
            self.style.SUCCESS(
                f"Done. {'(dry-run) ' if opts['dry_run'] else ''}"
                f"sent={sent} skipped_suppressed={skipped} failed={failed}"
            )
        )
