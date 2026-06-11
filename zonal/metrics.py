"""Shared metric & commission engine for the zonal system.

Pure functions used by BOTH the API views and the invoice generator, so the
numbers are always identical no matter who computes them. Kept free of DRF /
request objects to avoid circular imports.
"""
from datetime import datetime, timedelta
from decimal import Decimal
from zoneinfo import ZoneInfo

from django.contrib.auth import get_user_model
from django.db.models import Count, Q, Sum
from django.utils import timezone

User = get_user_model()
DHAKA = ZoneInfo("Asia/Dhaka")

FEATURE_ORDER = [
    ("registration", "User Registration"),
    ("pro_subscription", "Pro Subscription"),
    ("microgig_post", "MicroGig Post"),
    ("eshop_order", "eShop Order"),
    ("mobile_recharge", "Mobile Recharge"),
    ("gold_sponsor", "Gold Sponsor"),
    ("rideshare_driver", "Rideshare Driver Commission"),
]


def month_range(year, month):
    """[start, end) aware datetimes for a calendar month in Dhaka time."""
    start = datetime(year, month, 1, tzinfo=DHAKA)
    if month == 12:
        end = datetime(year + 1, 1, 1, tzinfo=DHAKA)
    else:
        end = datetime(year, month + 1, 1, tzinfo=DHAKA)
    return start, end


def _sum(qs, field):
    return float(qs.aggregate(s=Sum(field))["s"] or 0)


def metric_querysets(city, start, end, upazila=None):
    """All feature querysets scoped to the zone city (and optionally one
    upazila) within [start, end)."""
    from base.models import Balance, MicroGigPost, Order
    from business_network.models import GoldSponsor
    from mobile_recharge.models import Recharge
    from rideshare.models import Ride

    def user_scope(prefix=""):
        q = Q(**{f"{prefix}city__iexact": city})
        if upazila:
            q &= Q(**{f"{prefix}upazila__iexact": upazila})
        return q

    regs = User.objects.filter(
        user_scope(), date_joined__gte=start, date_joined__lt=end
    )
    pro = Balance.objects.filter(
        user_scope("user__"), transaction_type="pro_subscription",
        completed=True, created_at__gte=start, created_at__lt=end,
    )
    gigs = MicroGigPost.objects.filter(
        user_scope("user__"), created_at__gte=start, created_at__lt=end
    ).exclude(gig_status="rejected")
    orders = Order.objects.filter(
        user_scope("user__"), created_at__gte=start, created_at__lt=end
    ).exclude(order_status="cancelled")
    recharges = Recharge.objects.filter(
        user_scope("user__"), status="completed",
        created_at__gte=start, created_at__lt=end,
    )
    gold = GoldSponsor.objects.filter(
        user_scope("user__"), amount_paid__gt=0,
        created_at__gte=start, created_at__lt=end,
    )
    rides = Ride.objects.filter(
        user_scope("assigned_driver__user__"), status="completed",
        completed_at__gte=start, completed_at__lt=end,
    )
    return {
        "registration": (regs, None),
        "pro_subscription": (pro, "amount"),
        "microgig_post": (gigs, "total_cost"),
        "eshop_order": (orders, "total"),
        "mobile_recharge": (recharges, "amount"),
        "gold_sponsor": (gold, "amount_paid"),
        "rideshare_driver": (rides, "platform_fee_amount"),
    }


def feature_data(querysets):
    data = {}
    for feature, (qs, amount_field) in querysets.items():
        data[feature] = {
            "count": qs.count(),
            "amount": _sum(qs, amount_field) if amount_field else 0.0,
        }
    return data


def calc_commissions(rates, data):
    """rates: {feature: (type, value)} -> (rows, total).
    percent -> value% of the feature's sales amount;
    flat    -> value ৳ x the feature's item count."""
    rows = []
    total = Decimal(0)
    for feature, label in FEATURE_ORDER:
        ctype, value = rates.get(feature, ("percent", Decimal(0)))
        d = data.get(feature, {"count": 0, "amount": 0.0})
        if ctype == "flat":
            earned = (Decimal(value) * d["count"]).quantize(Decimal("0.01"))
        else:
            earned = (
                Decimal(str(d["amount"])) * Decimal(value) / Decimal(100)
            ).quantize(Decimal("0.01"))
        total += earned
        rows.append({
            "feature": feature, "label": label, "type": ctype,
            "value": float(value), "count": d["count"],
            "base_amount": float(d["amount"]), "earned": float(earned),
        })
    return rows, total


def commission_for(city, rates, start, end, upazila=None):
    """Convenience: rows + Decimal total for a scope & window."""
    data = feature_data(metric_querysets(city, start, end, upazila=upazila))
    return calc_commissions(rates, data)


def subscription_analysis(city, upazila=None, lapsed_limit=30):
    """Pro-subscription snapshot of NOW: active / lapsed (not renewed) /
    expiring-soon + a short follow-up list of lapsed users."""
    now = timezone.now()
    soon = now + timedelta(days=7)
    base = User.objects.filter(city__iexact=city, pro_validity__isnull=False)
    if upazila:
        base = base.filter(upazila__iexact=upazila)
    active = base.filter(pro_validity__gte=now)
    lapsed = base.filter(pro_validity__lt=now)
    expiring = active.filter(pro_validity__lte=soon)
    lapsed_users = [
        {
            "name": (u.name or u.first_name or u.email or "—"),
            "phone": getattr(u, "phone", "") or "",
            "area": u.upazila or "",
            "expired_on": u.pro_validity.astimezone(DHAKA).strftime("%Y-%m-%d"),
            "auto_renew": bool(getattr(u, "auto_renew", False)),
        }
        for u in lapsed.order_by("-pro_validity")[:lapsed_limit]
    ]
    return {
        "ever_pro": base.count(),
        "active": active.count(),
        "lapsed": lapsed.count(),
        "expiring_soon": expiring.count(),
        "auto_renew_on": active.filter(auto_renew=True).count(),
        "lapsed_users": lapsed_users,
    }
