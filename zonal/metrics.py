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
    """Convenience: rows + Decimal total for a scope & window (flat current
    rate — kept for callers that don't need rate history)."""
    data = feature_data(metric_querysets(city, start, end, upazila=upazila))
    return calc_commissions(rates, data)


# ---- effective-dated (rate-history aware) commission --------------------

def _feature_count_amount(feature, city, start, end, upazila=None):
    """(count, amount) for ONE feature within a sub-window."""
    qs, field = metric_querysets(city, start, end, upazila=upazila)[feature]
    return qs.count(), (_sum(qs, field) if field else 0.0)


def _rate_at(changes, t):
    """The change effective at time t = latest change with effective_from<=t."""
    eff = None
    for c in changes:  # changes sorted ascending by effective_from
        if c.effective_from <= t:
            eff = c
        else:
            break
    return eff


def _segments(changes, start, end):
    """Split [start,end) at rate-change points inside it -> [(s,e,change)]."""
    pts = sorted({start, end} | {
        c.effective_from for c in changes if start < c.effective_from < end
    })
    segs = []
    for i in range(len(pts) - 1):
        s, e = pts[i], pts[i + 1]
        segs.append((s, e, _rate_at(changes, s)))
    return segs


def commission_from_changes(city, changes_by_feature, start, end, upazila=None):
    """Commission where each sale is credited at the rate effective WHEN it
    happened — so raising a rate today never re-prices past sales.

    changes_by_feature: {feature: [ZoneRateChange-like sorted by effective_from]}
    """
    rows = []
    total = Decimal(0)
    for feature, label in FEATURE_ORDER:
        changes = changes_by_feature.get(feature, [])
        segs = _segments(changes, start, end) if changes else [(start, end, None)]
        cnt_total, amt_total = 0, 0.0
        earned = Decimal(0)
        for s, e, eff in segs:
            cnt, amt = _feature_count_amount(feature, city, s, e, upazila)
            cnt_total += cnt
            amt_total += amt
            if eff is None:
                continue
            if eff.commission_type == "flat":
                earned += Decimal(eff.value) * cnt
            else:
                earned += Decimal(str(amt)) * Decimal(eff.value) / Decimal(100)
        earned = earned.quantize(Decimal("0.01"))
        total += earned
        # Display "current rate" = rate effective at the window end.
        cur = _rate_at(changes, end) if changes else None
        ctype = cur.commission_type if cur else "percent"
        cval = float(cur.value) if cur else 0.0
        rows.append({
            "feature": feature, "label": label, "type": ctype, "value": cval,
            "count": cnt_total, "base_amount": amt_total, "earned": float(earned),
        })
    return rows, total


def _changes_by_feature(change_qs):
    out = {}
    for c in change_qs.order_by("effective_from"):
        out.setdefault(c.feature, []).append(c)
    return out


def commission_for_office(office, start, end):
    return commission_from_changes(
        office.city, _changes_by_feature(office.rate_changes.all()), start, end
    )


def commission_for_manager(office, manager, start, end):
    return commission_from_changes(
        office.city, _changes_by_feature(manager.rate_changes.all()),
        start, end, upazila=manager.area,
    )


def zone_net_commission(office, start, end):
    """Zone officer's NET commission: the zone's gross commission MINUS each
    area manager's share (the manager's cut is carved OUT of the zone's, not
    paid on top). Per area the deduction is capped at what the zone earned from
    THAT area, so a high manager rate in one area can't eat the zone's
    earnings elsewhere.

    Returns (rows, net_total, gross_total, deduction_total, managers_detail).
    Each row carries gross / area_manager_deduction / earned(=net) per feature.
    """
    zone_changes = _changes_by_feature(office.rate_changes.all())
    gross_rows, gross_total = commission_from_changes(office.city, zone_changes, start, end)
    gross_by_feature = {r["feature"]: Decimal(str(r["earned"])) for r in gross_rows}

    deduction_by_feature = {f: Decimal(0) for f, _ in FEATURE_ORDER}
    managers_detail = []
    for mgr in office.area_managers.filter(is_active=True):
        mgr_rows, mgr_total = commission_for_manager(office, mgr, start, end)
        # What the zone earns from this manager's area at the ZONE's own rate —
        # the manager's cut can't exceed this.
        zone_area_rows, _zt = commission_from_changes(
            office.city, zone_changes, start, end, upazila=mgr.area
        )
        zone_area_by_feature = {
            r["feature"]: Decimal(str(r["earned"])) for r in zone_area_rows
        }
        mgr_from_zone = Decimal(0)
        for r in mgr_rows:
            f = r["feature"]
            ded = min(Decimal(str(r["earned"])), zone_area_by_feature.get(f, Decimal(0)))
            deduction_by_feature[f] += ded
            mgr_from_zone += ded
        managers_detail.append({
            "name": mgr.name, "area": mgr.area,
            "earned": float(mgr_total), "from_zone": float(mgr_from_zone),
        })

    net_rows, net_total, deduction_total = [], Decimal(0), Decimal(0)
    for r in gross_rows:
        f = r["feature"]
        gross = gross_by_feature[f]
        ded = deduction_by_feature.get(f, Decimal(0))
        net = gross - ded
        if net < 0:
            net = Decimal(0)
        net_total += net
        deduction_total += ded
        nr = dict(r)
        nr["gross"] = float(gross)
        nr["area_manager_deduction"] = float(ded)
        nr["earned"] = float(net)
        net_rows.append(nr)
    return net_rows, net_total, gross_total, deduction_total, managers_detail


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
