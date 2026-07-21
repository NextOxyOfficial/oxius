from django.core.management.base import BaseCommand

from business_network.monetization import compute_period_earnings


class Command(BaseCommand):
    help = (
        "Recompute creator earnings (points + pool share) for a month. "
        "Run daily via cron for the current month, and once shortly after "
        "month close for the previous month."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            "--period",
            default=None,
            help="Month to compute as YYYY-MM (default: current month).",
        )

    def handle(self, *args, **options):
        summary = compute_period_earnings(options["period"])
        self.stdout.write(self.style.SUCCESS(str(summary)))
