"""Generate monthly commission invoices for zonal offices + area managers.

    python manage.py generate_zonal_invoices              # previous month
    python manage.py generate_zonal_invoices --current    # current month (live)
    python manage.py generate_zonal_invoices --year 2026 --month 5

Idempotent: re-running a period UPDATES that period's unpaid invoice with the
latest numbers; a PAID invoice is never overwritten (history stays intact).
Run from Celery beat on the 1st of each month for the previous month.
"""
from datetime import date

from django.core.management.base import BaseCommand
from django.utils import timezone

from zonal.metrics import (
    DHAKA,
    commission_for_manager,
    month_range,
    zone_net_commission,
)
from zonal.models import AreaManager, AreaManagerInvoice, ZonalInvoice, ZonalOffice


class Command(BaseCommand):
    help = "Generate/refresh monthly commission invoices for zones and area managers."

    def add_arguments(self, parser):
        parser.add_argument("--year", type=int)
        parser.add_argument("--month", type=int)
        parser.add_argument(
            "--current", action="store_true",
            help="Use the current month instead of the previous one.",
        )

    def handle(self, *args, **opts):
        today = timezone.now().astimezone(DHAKA).date()
        if opts.get("year") and opts.get("month"):
            year, month = opts["year"], opts["month"]
        elif opts.get("current"):
            year, month = today.year, today.month
        else:
            first = today.replace(day=1)
            prev = first - __import__("datetime").timedelta(days=1)
            year, month = prev.year, prev.month

        start, end = month_range(year, month)
        zones = made = 0

        for office in ZonalOffice.objects.filter(is_active=True):
            # Rate-history aware AND net of area-manager cuts — the zone is
            # invoiced for what it actually keeps.
            rows, total, _g, _d, _m = zone_net_commission(office, start, end)
            inv = ZonalInvoice.objects.filter(
                office=office, period_year=year, period_month=month
            ).first()
            if inv and inv.status == "paid":
                continue  # don't rewrite a paid invoice
            ZonalInvoice.objects.update_or_create(
                office=office, period_year=year, period_month=month,
                defaults={"amount": total, "breakdown": rows},
            )
            zones += 1

            for mgr in office.area_managers.filter(is_active=True):
                mrows, mtotal = commission_for_manager(office, mgr, start, end)
                minv = AreaManagerInvoice.objects.filter(
                    manager=mgr, period_year=year, period_month=month
                ).first()
                if minv and minv.status == "paid":
                    continue
                AreaManagerInvoice.objects.update_or_create(
                    manager=mgr, period_year=year, period_month=month,
                    defaults={"amount": mtotal, "breakdown": mrows},
                )
                made += 1

        self.stdout.write(
            "INVOICES period=%04d-%02d zones=%d managers=%d" % (year, month, zones, made)
        )
