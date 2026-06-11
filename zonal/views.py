"""Zonal officer APIs — everything is scoped to the officer's own city.

GET /api/zonal/me/         -> office info + commission rates (or 403)
GET /api/zonal/dashboard/  -> sales & leads report for the zone
                              ?from=YYYY-MM-DD&to=YYYY-MM-DD (default: last 30 days)
"""
from datetime import datetime, time, timedelta
from decimal import Decimal
from zoneinfo import ZoneInfo

from django.contrib.auth import get_user_model
from django.db.models import Count, Sum
from django.db.models.functions import TruncDate
from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

User = get_user_model()
DHAKA = ZoneInfo("Asia/Dhaka")


def _get_office(request):
    office = getattr(request.user, "zonal_office", None)
    if office and office.is_active:
        return office
    return None


def _office_payload(office):
    return {
        "name": office.name,
        "city": office.city,
        "officer": getattr(office.user, "name", "") or office.user.email,
        "commissions": [
            {
                "feature": c.feature,
                "label": c.get_feature_display(),
                "percent": float(c.percent),
            }
            for c in office.commissions.all()
        ],
    }


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def zonal_me(request):
    office = _get_office(request)
    if not office:
        return Response(
            {"detail": "এই অ্যাকাউন্টটি কোনো জোনাল অফিসের সাথে যুক্ত নয়।"},
            status=403,
        )
    return Response(_office_payload(office))


def _parse_range(request):
    """from/to (Dhaka local dates) -> aware UTC datetimes [start, end)."""
    today_local = timezone.now().astimezone(DHAKA).date()
    default_from = today_local - timedelta(days=29)

    def _d(name, fallback):
        raw = (request.query_params.get(name) or "").strip()
        try:
            return datetime.strptime(raw, "%Y-%m-%d").date()
        except ValueError:
            return fallback

    d_from = _d("from", default_from)
    d_to = _d("to", today_local)
    if d_from > d_to:
        d_from, d_to = d_to, d_from
    start = datetime.combine(d_from, time.min, tzinfo=DHAKA)
    end = datetime.combine(d_to + timedelta(days=1), time.min, tzinfo=DHAKA)
    return d_from, d_to, start, end


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def zonal_dashboard(request):
    office = _get_office(request)
    if not office:
        return Response(
            {"detail": "এই অ্যাকাউন্টটি কোনো জোনাল অফিসের সাথে যুক্ত নয়।"},
            status=403,
        )

    from base.models import Balance, MicroGigPost, Order
    from mobile_recharge.models import Recharge

    d_from, d_to, start, end = _parse_range(request)
    city = office.city

    zone_users = User.objects.filter(city__iexact=city)

    # ---- Leads: registrations in range + per-area breakdown -------------
    regs = zone_users.filter(date_joined__gte=start, date_joined__lt=end)
    reg_count = regs.count()
    by_area = list(
        regs.exclude(upazila="")
        .values("upazila")
        .annotate(n=Count("id"))
        .order_by("-n")[:30]
    )
    no_area = reg_count - sum(a["n"] for a in by_area)
    reg_daily = {
        r["d"].isoformat(): r["n"]
        for r in regs.annotate(d=TruncDate("date_joined", tzinfo=DHAKA))
        .values("d")
        .annotate(n=Count("id"))
    }

    # ---- Sales metrics (all scoped to users whose city = zone city) ----
    def _sum(qs, field):
        return float(qs.aggregate(s=Sum(field))["s"] or 0)

    pro_qs = Balance.objects.filter(
        transaction_type="pro_subscription",
        completed=True,
        user__city__iexact=city,
        created_at__gte=start,
        created_at__lt=end,
    )
    pro = {"count": pro_qs.count(), "amount": _sum(pro_qs, "amount")}

    gig_qs = MicroGigPost.objects.filter(
        user__city__iexact=city,
        created_at__gte=start,
        created_at__lt=end,
    ).exclude(gig_status="rejected")
    gigs = {"count": gig_qs.count(), "amount": _sum(gig_qs, "total_cost")}

    order_qs = Order.objects.filter(
        user__city__iexact=city,
        created_at__gte=start,
        created_at__lt=end,
    ).exclude(order_status="cancelled")
    orders = {"count": order_qs.count(), "amount": _sum(order_qs, "total")}

    rec_qs = Recharge.objects.filter(
        user__city__iexact=city,
        status="completed",
        created_at__gte=start,
        created_at__lt=end,
    )
    recharges = {"count": rec_qs.count(), "amount": _sum(rec_qs, "amount")}

    # ---- Commission: rate% x feature revenue in the zone ---------------
    rates = {c.feature: c.percent for c in office.commissions.all()}
    feature_amounts = {
        "registration": Decimal(0),  # leads have no monetary base
        "pro_subscription": Decimal(str(pro["amount"])),
        "microgig_post": Decimal(str(gigs["amount"])),
        "eshop_order": Decimal(str(orders["amount"])),
        "mobile_recharge": Decimal(str(recharges["amount"])),
    }
    commissions = []
    total_commission = Decimal(0)
    for feature, label in [
        ("registration", "User Registration"),
        ("pro_subscription", "Pro Subscription"),
        ("microgig_post", "MicroGig Post"),
        ("eshop_order", "eShop Order"),
        ("mobile_recharge", "Mobile Recharge"),
    ]:
        pct = rates.get(feature, Decimal(0))
        earned = (feature_amounts[feature] * pct / Decimal(100)).quantize(
            Decimal("0.01")
        )
        total_commission += earned
        commissions.append(
            {
                "feature": feature,
                "label": label,
                "percent": float(pct),
                "base_amount": float(feature_amounts[feature]),
                "earned": float(earned),
            }
        )

    # ---- Daily activity series (for the day-by-day table) --------------
    def _daily(qs, dt_field, amount_field):
        rows = (
            qs.annotate(d=TruncDate(dt_field, tzinfo=DHAKA))
            .values("d")
            .annotate(n=Count("id"), s=Sum(amount_field))
        )
        return {r["d"].isoformat(): {"n": r["n"], "s": float(r["s"] or 0)} for r in rows}

    pro_daily = _daily(pro_qs, "created_at", "amount")
    gig_daily = _daily(gig_qs, "created_at", "total_cost")
    order_daily = _daily(order_qs, "created_at", "total")
    rec_daily = _daily(rec_qs, "created_at", "amount")

    days = []
    d = d_to
    while d >= d_from and len(days) < 92:
        key = d.isoformat()
        days.append(
            {
                "date": key,
                "registrations": reg_daily.get(key, 0),
                "pro": pro_daily.get(key, {"n": 0, "s": 0}),
                "gigs": gig_daily.get(key, {"n": 0, "s": 0}),
                "orders": order_daily.get(key, {"n": 0, "s": 0}),
                "recharges": rec_daily.get(key, {"n": 0, "s": 0}),
            }
        )
        d -= timedelta(days=1)

    return Response(
        {
            "office": _office_payload(office),
            "range": {"from": d_from.isoformat(), "to": d_to.isoformat()},
            "totals": {
                "zone_users": zone_users.count(),
                "registrations": reg_count,
                "pro": pro,
                "gigs": gigs,
                "orders": orders,
                "recharges": recharges,
                "revenue": round(
                    pro["amount"] + gigs["amount"] + orders["amount"] + recharges["amount"], 2
                ),
                "commission": float(total_commission),
            },
            "by_area": by_area + ([{"upazila": "(এলাকা দেওয়া নেই)", "n": no_area}] if no_area > 0 else []),
            "commissions": commissions,
            "days": days,
        }
    )
