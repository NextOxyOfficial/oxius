"""Async bounce processing.

Most bounces are ASYNCHRONOUS: the receiving server accepts the message, then
later returns a "delivery status notification" (DSN) / Mailer-Daemon email to our
sending mailbox. This command logs into that mailbox over IMAP, finds those bounce
messages, extracts the address that failed, and adds it to EmailSuppression
(reason="bounced") so marketing/engagement mail stops targeting it. Transactional
mail still tries (a user may fix their address) — see base.email_service.

Run it on a schedule, e.g. every 15 min via cron:
    */15 * * * * cd /home/django/adsyclub && /home/django/venv/bin/python manage.py process_bounces >> /home/django/bounce_log.log 2>&1

Manual / safe preview:
    python manage.py process_bounces --dry-run
"""

import email
import imaplib
import re

from django.core.management.base import BaseCommand


def _extract_failed_recipient(msg):
    """Pull the failed recipient address out of a bounce/DSN message. Returns the
    address (lowercased) or None if it doesn't look like a hard failure."""
    # 1) Proper DSN: a message/delivery-status part with Final-Recipient + failed.
    for part in msg.walk():
        if part.get_content_type() == "message/delivery-status":
            text = ""
            payload = part.get_payload()
            if isinstance(payload, list):
                for p in payload:
                    try:
                        text += p.as_string()
                    except Exception:
                        pass
            else:
                raw = part.get_payload(decode=True)
                text = raw.decode("utf-8", "ignore") if raw else str(payload)
            if re.search(r"Action:\s*failed", text, re.I):
                m = re.search(r"(?:Final|Original)-Recipient:\s*rfc822;\s*([^\s>]+)", text, re.I)
                if m:
                    return m.group(1).strip().strip("<>").lower()

    # 2) Fallback: scan the message text for a recipient + a permanent-failure cue.
    raw_text = ""
    for part in msg.walk():
        if part.get_content_type() in ("text/plain", "text/rfc822-headers", "message/rfc822"):
            try:
                raw_text += (part.get_payload(decode=True) or b"").decode("utf-8", "ignore")
            except Exception:
                pass
    m = re.search(r"(?:Final|Original)-Recipient:\s*rfc822;\s*([^\s>]+)", raw_text, re.I)
    if m:
        return m.group(1).strip().strip("<>").lower()
    m = re.search(
        r"(?:550|554|5\.1\.1|does not exist|user unknown|no such user|mailbox unavailable|recipient address rejected)"
        r"[\s\S]{0,200}?([\w.+-]+@[\w.-]+\.\w{2,})",
        raw_text, re.I,
    )
    if m:
        return m.group(1).strip().lower()
    return None


class Command(BaseCommand):
    help = "Scan the sending mailbox (IMAP) for bounce/DSN messages and suppress the failed recipients."

    def add_arguments(self, parser):
        parser.add_argument("--dry-run", action="store_true", help="List what would be suppressed; change nothing.")
        parser.add_argument("--limit", type=int, default=300, help="Max bounce messages to process per run.")
        parser.add_argument("--host", default=None, help="IMAP host (default: the EmailSettings SMTP host).")
        parser.add_argument("--port", type=int, default=993, help="IMAP SSL port (default 993).")

    def handle(self, *args, **opts):
        from base.email_service import _get_email_settings, suppress_email

        cfg = _get_email_settings()
        host = opts["host"] or cfg.get("host")
        user = cfg.get("host_user")
        pw = cfg.get("host_password")
        if not (host and user and pw):
            self.stderr.write(self.style.ERROR("No SMTP/IMAP credentials in EmailSettings — aborting."))
            return

        try:
            box = imaplib.IMAP4_SSL(host, opts["port"])
            box.login(user, pw)
        except Exception as e:
            self.stderr.write(self.style.ERROR(f"IMAP connect/login failed ({host}:{opts['port']}): {e}"))
            return

        found = suppressed = 0
        try:
            box.select("INBOX")
            ids = []
            for crit in ('(UNSEEN FROM "mailer-daemon")', '(UNSEEN FROM "postmaster")',
                         '(UNSEEN SUBJECT "Undelivered")', '(UNSEEN SUBJECT "Delivery Status Notification")'):
                try:
                    typ, data = box.search(None, crit)
                    if typ == "OK" and data and data[0]:
                        ids.extend(data[0].split())
                except Exception:
                    pass
            # de-dupe message ids, cap to limit
            seen_ids, uniq = set(), []
            for i in ids:
                if i not in seen_ids:
                    seen_ids.add(i)
                    uniq.append(i)
            uniq = uniq[: opts["limit"]]

            for num in uniq:
                try:
                    typ, msgdata = box.fetch(num, "(RFC822)")
                    if typ != "OK" or not msgdata or not msgdata[0]:
                        continue
                    msg = email.message_from_bytes(msgdata[0][1])
                except Exception:
                    continue
                found += 1
                addr = _extract_failed_recipient(msg)
                if addr:
                    if opts["dry_run"]:
                        self.stdout.write(f"[dry-run] would suppress (bounced): {addr}")
                    else:
                        suppress_email(addr, reason="bounced", note="async bounce (IMAP DSN)")
                    suppressed += 1
                # Mark handled so we never reprocess it (real runs only).
                if not opts["dry_run"]:
                    try:
                        box.store(num, "+FLAGS", "\\Seen")
                    except Exception:
                        pass
        finally:
            try:
                box.logout()
            except Exception:
                pass

        self.stdout.write(self.style.SUCCESS(
            f"Bounce scan done.{' (dry-run)' if opts['dry_run'] else ''} "
            f"bounce_messages={found} addresses_suppressed={suppressed}"
        ))
