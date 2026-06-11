"""Zonal Celery tasks."""
from celery import shared_task
from django.core.management import call_command


@shared_task
def generate_monthly_zonal_invoices():
    """Run on the 1st of each month for the PREVIOUS month's commissions
    (finalizes the just-ended month so it becomes payable)."""
    call_command("generate_zonal_invoices")
    return "ok"


@shared_task
def refresh_current_zonal_invoices():
    """Keep the CURRENT month's invoice up to date daily so the payout report
    is always populated — no manual run ever needed. A paid invoice is never
    overwritten; current-month amounts are excluded from 'payable' in the
    balance API (shown as live accrual), so this never double counts."""
    call_command("generate_zonal_invoices", "--current")
    return "ok"
