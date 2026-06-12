"""Mobile-recharge processing.

The recharge flow is automation-ready: a recharge is created, the user's Adsy
Pay balance is charged, and then `process_recharge()` either hands it to a
configured third-party provider OR leaves it pending for manual processing.

>>> To go fully automated later, the ONLY thing to implement is
    `_call_provider_api()` — fill in the real provider request once you have the
    API details. Status flow, balance charge/refund and audit are already wired.
"""

import logging
from decimal import Decimal

from django.utils import timezone

from .models import RechargeProviderConfig

logger = logging.getLogger(__name__)


def charge_balance(user, amount):
    """Deduct `amount` from the user's Adsy Pay balance. Returns (ok, error)."""
    if user is None:
        return False, 'ব্যবহারকারী পাওয়া যায়নি।'
    amount = Decimal(str(amount))
    balance = user.balance or Decimal('0')
    if balance < amount:
        return False, 'পর্যাপ্ত Adsy Pay ব্যালেন্স নেই। অনুগ্রহ করে রিচার্জ করুন।'
    user.balance = balance - amount
    user.save(update_fields=['balance'])
    return True, None


def refund_balance(recharge):
    """Return a charged recharge's amount to the user (idempotent)."""
    if not getattr(recharge, 'balance_charged', False):
        return False
    user = recharge.user
    if user is None:
        return False
    user.balance = (user.balance or Decimal('0')) + recharge.amount
    user.save(update_fields=['balance'])
    recharge.balance_charged = False
    recharge.save(update_fields=['balance_charged'])
    return True


def _record_success_ledger(recharge):
    try:
        from base.models import Balance
        Balance.objects.create(
            user=recharge.user,
            transaction_type='mobile_recharge_successful',
            amount=recharge.amount,
            payable_amount=recharge.amount,
            completed=True,
            approved=True,
        )
    except Exception:
        logger.exception('recharge success ledger record failed')


def _active_provider():
    return (
        RechargeProviderConfig.objects.filter(is_enabled=True)
        .exclude(base_url='')
        .order_by('-updated_at')
        .first()
    )


def process_recharge(recharge):
    """Send the recharge to the active provider, or leave it pending for manual
    processing when no provider is configured yet. Returns the final status."""
    provider = _active_provider()
    if provider is None:
        # No automated provider yet — keep it pending; an admin completes it
        # (or marks it failed → auto-refund) from the admin panel.
        return recharge.status

    recharge.status = 'processing'
    recharge.save(update_fields=['status'])

    try:
        ok, reference, raw = _call_provider_api(provider, recharge)
    except Exception as e:
        ok, reference, raw = False, '', {'error': str(e)}
        logger.exception('recharge provider call failed')

    recharge.provider_response = raw if isinstance(raw, dict) else {'raw': str(raw)}
    recharge.processed_at = timezone.now()

    if ok:
        recharge.status = 'completed'
        recharge.provider_reference = reference or ''
        recharge.save(update_fields=[
            'status', 'provider_reference', 'provider_response', 'processed_at',
        ])
        _record_success_ledger(recharge)
    else:
        recharge.status = 'failed'
        recharge.failure_reason = (
            recharge.provider_response.get('message')
            or recharge.provider_response.get('error')
            or 'প্রোভাইডার রিচার্জটি কমপ্লিট করতে পারেনি।'
        )[:255]
        recharge.save(update_fields=[
            'status', 'failure_reason', 'provider_response', 'processed_at',
        ])
        refund_balance(recharge)

    return recharge.status


def _call_provider_api(provider, recharge):
    """STUB — implement the real third-party request here once API details are
    known. Must return ``(ok: bool, reference: str, raw_response: dict)``.

    Example (replace with the actual provider contract)::

        import requests
        resp = requests.post(
            f"{provider.base_url.rstrip('/')}/recharge",
            json={
                "api_key": provider.api_key,
                "api_secret": provider.api_secret,
                "msisdn": recharge.phone_number,
                "amount": str(recharge.amount),
                "operator": recharge.operator.name if recharge.operator else "",
                **(provider.extra_config or {}),
            },
            timeout=30,
        )
        data = resp.json()
        return data.get("status") == "success", data.get("txn_id", ""), data
    """
    raise NotImplementedError(
        'Recharge provider API not implemented yet. Provide the API details and '
        'fill in _call_provider_api().'
    )
