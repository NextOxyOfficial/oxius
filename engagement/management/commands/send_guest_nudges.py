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
        from engagement.guest_promos import GUEST_PROMO_MAX

        guests = FCMToken.objects.filter(user__isnull=True, is_active=True)
        total = guests.count()
        finished = guests.filter(promo_count__gte=GUEST_PROMO_MAX).count()
        fresh = guests.filter(promo_count=0).count()
        self.stdout.write(
            "GUESTS total=%d untouched=%d finished=%d series_len=%d"
            % (total, fresh, finished, GUEST_PROMO_MAX)
        )
        if opts["status"]:
            return

        from engagement.tasks import run_guest_nudges
        result = run_guest_nudges(dry_run=opts["dry_run"])
        self.stdout.write("GUESTNUDGE %s" % result)
