"""Manually run the guest registration-conversion push pass.

    python manage.py send_guest_nudges            # real send (honors flag)
    python manage.py send_guest_nudges --dry-run  # just report what WOULD send
    python manage.py send_guest_nudges --status    # counts only, send nothing
"""
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = "Send registration-conversion pushes to guest (unregistered) devices."

    def add_arguments(self, parser):
        parser.add_argument("--dry-run", action="store_true")
        parser.add_argument(
            "--status", action="store_true",
            help="Print guest-token counts and exit without sending.",
        )

    def handle(self, *args, **opts):
        from base.models import FCMToken
        from engagement.guest_promos import GUEST_PROMOS

        guests = FCMToken.objects.filter(user__isnull=True, is_active=True)
        total = guests.count()
        fresh = guests.filter(promo_count=0).count()
        # Series loops forever (one/day); show total pushes already sent.
        from django.db.models import Sum
        delivered = guests.aggregate(s=Sum("promo_count"))["s"] or 0
        self.stdout.write(
            "GUESTS total=%d untouched=%d pushes_sent=%d series_len=%d (loops daily)"
            % (total, fresh, delivered, len(GUEST_PROMOS))
        )
        if opts["status"]:
            return

        from engagement.tasks import run_guest_nudges
        result = run_guest_nudges(dry_run=opts["dry_run"])
        self.stdout.write("GUESTNUDGE %s" % result)
