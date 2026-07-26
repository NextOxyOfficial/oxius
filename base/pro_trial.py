"""Free Pro trial — one per account, KYC-gated.

Kept out of views.py because the eligibility rules are the whole feature: the
client shows them as steps, and the server is what actually enforces them.
"""

from datetime import timedelta

from django.db import transaction
from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import ProTrialConfig, User


def _state(user, cfg):
    """Everything the client needs to render the steps and the CTA."""
    now = timezone.now()
    trial_active = bool(
        user.pro_trial_used_at
        and user.is_pro
        and user.pro_validity
        and user.pro_validity > now
    )

    kyc_ok = bool(user.kyc) if cfg.require_kyc else True
    already_used = user.pro_trial_used_at is not None
    # An existing paid Pro shouldn't be overwritten by a shorter trial.
    is_pro_now = bool(user.is_pro and user.pro_validity and user.pro_validity > now)

    if not cfg.enabled:
        reason = "disabled"
    elif already_used:
        reason = "already_used"
    elif not kyc_ok:
        reason = "kyc_required"
    elif is_pro_now:
        reason = "already_pro"
    else:
        reason = ""

    return {
        "enabled": cfg.enabled,
        "days": cfg.days,
        "requires_kyc": cfg.require_kyc,
        "kyc_verified": bool(user.kyc),
        "kyc_pending": bool(user.kyc_pending),
        "already_used": already_used,
        "is_pro": is_pro_now,
        "trial_active": trial_active,
        "pro_validity": user.pro_validity,
        "eligible": reason == "",
        "reason": reason,
    }


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def pro_trial_status(request):
    return Response(_state(request.user, ProTrialConfig.get()))


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def activate_pro_trial(request):
    cfg = ProTrialConfig.get()
    user = request.user
    state = _state(user, cfg)

    if not state["eligible"]:
        messages = {
            "disabled": "ফ্রি ট্রায়াল বর্তমানে বন্ধ আছে।",
            "already_used": "আপনি ইতিমধ্যে ফ্রি ট্রায়াল ব্যবহার করেছেন।",
            "kyc_required": "ফ্রি ট্রায়াল নিতে আগে KYC ভেরিফিকেশন সম্পন্ন করুন।",
            "already_pro": "আপনার প্রো সাবস্ক্রিপশন এখনও চালু আছে।",
        }
        return Response(
            {
                "error": state["reason"],
                "detail": messages.get(
                    state["reason"], "ফ্রি ট্রায়াল নেওয়া যায়নি।"
                ),
                **state,
            },
            status=400,
        )

    ends_at = timezone.now() + timedelta(days=cfg.days)

    # Conditional update, not save(): two taps (or two devices) both passed the
    # check above, and a read-modify-write would hand out two trials.
    # Filtering on pro_trial_used_at__isnull lets exactly one win.
    with transaction.atomic():
        claimed = User.objects.filter(
            pk=user.pk, pro_trial_used_at__isnull=True
        ).update(
            pro_trial_used_at=timezone.now(),
            is_pro=True,
            pro_validity=ends_at,
        )

    if not claimed:
        return Response(
            {
                "error": "already_used",
                "detail": "আপনি ইতিমধ্যে ফ্রি ট্রায়াল ব্যবহার করেছেন।",
            },
            status=400,
        )

    user.refresh_from_db(fields=["is_pro", "pro_validity", "pro_trial_used_at"])
    return Response(
        {
            "success": True,
            "detail": f"অভিনন্দন! আপনি {cfg.days} দিনের ফ্রি প্রো ট্রায়াল পেয়েছেন।",
            **_state(user, cfg),
        }
    )
