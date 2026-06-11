"""Zonal Celery tasks."""
from celery import shared_task
from django.core.management import call_command


@shared_task
def generate_monthly_zonal_invoices():
    """Run on the 1st of each month for the PREVIOUS month's commissions."""
    call_command("generate_zonal_invoices")
    return "ok"
