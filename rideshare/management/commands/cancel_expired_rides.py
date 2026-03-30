"""
Management command to cancel expired ride requests.
Run this periodically (e.g., every minute via cron or Celery beat) to auto-cancel
rides that have been searching for drivers for more than 15 minutes.

Usage:
    python manage.py cancel_expired_rides

Cron example (every minute):
    * * * * * cd /path/to/project && python manage.py cancel_expired_rides
"""
from django.core.management.base import BaseCommand

from rideshare.services import RideAutoCancel


class Command(BaseCommand):
    help = "Cancel ride requests that have been searching for drivers for more than 15 minutes"

    def handle(self, *args, **options):
        cancelled_count = RideAutoCancel.check_and_cancel_expired_rides()
        
        if cancelled_count > 0:
            self.stdout.write(
                self.style.SUCCESS(f"Auto-cancelled {cancelled_count} expired ride(s)")
            )
        else:
            self.stdout.write("No expired rides to cancel")
