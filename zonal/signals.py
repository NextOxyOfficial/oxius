"""Log every commission-rate change to the effective-dated history.

Catches edits from the API, Django admin inline, and shell alike. The first
time a feature is touched without prior history we also seed a baseline at
EPOCH using the OLD value, so sales before the change keep the old rate and
only sales after `now` get the new rate.
"""
from datetime import datetime
from zoneinfo import ZoneInfo

from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.utils import timezone

from .models import (
    AreaManager,
    AreaManagerCommission,
    AreaManagerRateChange,
    ZoneFeatureCommission,
    ZoneRateChange,
)

EPOCH = datetime(2000, 1, 1, tzinfo=ZoneInfo("Asia/Dhaka"))


def _capture_old(sender, instance):
    if instance.pk:
        old = sender.objects.filter(pk=instance.pk).first()
        if old:
            instance._old_type = old.commission_type
            instance._old_value = old.value
            return
    instance._old_type = None
    instance._old_value = None


@receiver(pre_save, sender=ZoneFeatureCommission)
def _zfc_pre(sender, instance, **kwargs):
    _capture_old(sender, instance)


@receiver(pre_save, sender=AreaManagerCommission)
def _amc_pre(sender, instance, **kwargs):
    _capture_old(sender, instance)


def _log_change(log_model, owner_field, owner, instance):
    """Append rate-change rows so the timeline stays correct."""
    old_type = getattr(instance, "_old_type", None)
    old_value = getattr(instance, "_old_value", None)
    changed = (old_value is None) or (
        old_value != instance.value or old_type != instance.commission_type
    )
    if not changed:
        return

    qs = log_model.objects.filter(**{owner_field: owner, "feature": instance.feature})
    now = timezone.now()
    if not qs.exists():
        # No history yet → seed a baseline so past sales keep the prior rate.
        base_type = old_type if old_type is not None else instance.commission_type
        base_value = old_value if old_value is not None else instance.value
        log_model.objects.create(
            **{owner_field: owner}, feature=instance.feature,
            commission_type=base_type, value=base_value, effective_from=EPOCH,
        )
        # If this save actually changed the value from the baseline, date it now.
        if base_value != instance.value or base_type != instance.commission_type:
            log_model.objects.create(
                **{owner_field: owner}, feature=instance.feature,
                commission_type=instance.commission_type, value=instance.value,
                effective_from=now,
            )
    else:
        log_model.objects.create(
            **{owner_field: owner}, feature=instance.feature,
            commission_type=instance.commission_type, value=instance.value,
            effective_from=now,
        )


@receiver(post_save, sender=ZoneFeatureCommission)
def _zfc_post(sender, instance, **kwargs):
    _log_change(ZoneRateChange, "office", instance.office, instance)


@receiver(post_save, sender=AreaManagerCommission)
def _amc_post(sender, instance, **kwargs):
    _log_change(AreaManagerRateChange, "manager", instance.manager, instance)
