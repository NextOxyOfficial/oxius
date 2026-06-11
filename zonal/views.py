"""Zonal officer APIs — everything is scoped to the officer's own city.

GET    /api/zonal/me/                    -> office info + commission rates (or 403)
GET    /api/zonal/dashboard/             -> zone sales & leads report (?from=&to=)
GET    /api/zonal/notices/               -> active notices (global + this zone)
GET    /api/zonal/areas/                 -> upazila list of the zone city
GET    /api/zonal/notes/   POST          -> officer's Primary Notes
PATCH  /api/zonal/notes/<id>/  DELETE
GET    /api/zonal/managers/  POST        -> area managers (+ commission structure)
GET    /api/zonal/managers/<id>/  PATCH  DELETE
GET    /api/zonal/managers/<id>/report/  -> that area's sales + auto commissions
"""
from datetime import datetime, time, timedelta
from decimal import Decimal, InvalidOperation
from zoneinfo import ZoneInfo

from django.contrib.auth import get_user_model
from django.db.models import Count, Q, Sum
from django.db.models.functions import TruncDate
from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from . import metrics
from .metrics import (
    DHAKA,
    FEATURE_ORDER,
    feature_data as _feature_data,
    metric_querysets as _metric_querysets,
    subscription_analysis as _subscription_analysis,
)
from .models import (
    AreaManager,
    AreaManagerCommission,
    ZonalNote,
    ZonalNotice,
    ZoneFeatureCommission,
)

User = get_user_model()

NOT_OFFICER = {"detail": "এই অ্যাকাউন্টটি কোনো জোনাল অফিসের সাথে যুক্ত নয়।"}


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
                "type": c.commission_type,
                "value": float(c.value),
            }
            for c in office.commissions.all()
        ],
    }


def _parse_range(request):
    """from/to (Dhaka local dates) -> aware datetimes [start, end)."""
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


# ------------------------------------------------------------------ views --

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def zonal_me(request):
    office = _get_office(request)
    if not office:
        return Response(NOT_OFFICER, status=403)
    return Response(_office_payload(office))


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def zonal_dashboard(request):
    office = _get_office(request)
    if not office:
        return Response(NOT_OFFICER, status=403)

    d_from, d_to, start, end = _parse_range(request)
    city = office.city

    zone_users = User.objects.filter(city__iexact=city)
    querysets = _metric_querysets(city, start, end)
    data = _feature_data(querysets)

    # Per-area registration breakdown
    regs = querysets["registration"][0]
    reg_count = data["registration"]["count"]
    by_area = list(
        regs.exclude(upazila="")
        .values("upazila")
        .annotate(n=Count("id"))
        .order_by("-n")[:30]
    )
    no_area = reg_count - sum(a["n"] for a in by_area)

    # Rate-history aware AND net of area-manager cuts (each manager's share is
    # carved out of the zone's commission, not paid on top).
    commissions, net_total, gross_total, ded_total, mgr_detail = (
        metrics.zone_net_commission(office, start, end)
    )
    total_commission = float(net_total)

    # Daily series
    def _daily(qs, dt_field, amount_field):
        rows = (
            qs.annotate(d=TruncDate(dt_field, tzinfo=DHAKA))
            .values("d")
            .annotate(n=Count("id"), s=Sum(amount_field) if amount_field else Count("id"))
        )
        out = {}
        for r in rows:
            out[r["d"].isoformat()] = {
                "n": r["n"],
                "s": float(r["s"] or 0) if amount_field else 0.0,
            }
        return out

    reg_daily = _daily(querysets["registration"][0], "date_joined", None)
    pro_daily = _daily(querysets["pro_subscription"][0], "created_at", "amount")
    gig_daily = _daily(querysets["microgig_post"][0], "created_at", "total_cost")
    order_daily = _daily(querysets["eshop_order"][0], "created_at", "total")
    rec_daily = _daily(querysets["mobile_recharge"][0], "created_at", "amount")
    gold_daily = _daily(querysets["gold_sponsor"][0], "created_at", "amount_paid")
    ride_daily = _daily(querysets["rideshare_driver"][0], "completed_at", "platform_fee_amount")

    days = []
    d = d_to
    while d >= d_from and len(days) < 92:
        key = d.isoformat()
        days.append(
            {
                "date": key,
                "registrations": reg_daily.get(key, {"n": 0}).get("n", 0),
                "pro": pro_daily.get(key, {"n": 0, "s": 0}),
                "gigs": gig_daily.get(key, {"n": 0, "s": 0}),
                "orders": order_daily.get(key, {"n": 0, "s": 0}),
                "recharges": rec_daily.get(key, {"n": 0, "s": 0}),
                "gold": gold_daily.get(key, {"n": 0, "s": 0}),
                "rides": ride_daily.get(key, {"n": 0, "s": 0}),
            }
        )
        d -= timedelta(days=1)

    revenue = round(
        sum(data[f]["amount"] for f in (
            "pro_subscription", "microgig_post", "eshop_order",
            "mobile_recharge", "gold_sponsor", "rideshare_driver",
        )),
        2,
    )

    return Response(
        {
            "office": _office_payload(office),
            "range": {"from": d_from.isoformat(), "to": d_to.isoformat()},
            "totals": {
                "zone_users": zone_users.count(),
                "registrations": reg_count,
                "pro": data["pro_subscription"],
                "gigs": data["microgig_post"],
                "orders": data["eshop_order"],
                "recharges": data["mobile_recharge"],
                "gold": data["gold_sponsor"],
                "rides": data["rideshare_driver"],
                "revenue": revenue,
                "commission": total_commission,                 # NET (what zone gets)
                "commission_gross": float(gross_total),         # before manager cuts
                "commission_area_managers": float(ded_total),   # paid to area managers
            },
            "by_area": by_area
            + ([{"upazila": "(এলাকা দেওয়া নেই)", "n": no_area}] if no_area > 0 else []),
            "commissions": commissions,
            "area_manager_split": mgr_detail,
            "subscriptions": _subscription_analysis(city),
            "service_categories": metrics.service_category_breakdown(city),
            "days": days,
        }
    )


# --------------------------------------------------------------- notices --

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def zonal_notices(request):
    office = _get_office(request)
    if not office:
        return Response(NOT_OFFICER, status=403)
    notices = ZonalNotice.objects.filter(is_active=True).filter(
        Q(office__isnull=True) | Q(office=office)
    )[:20]
    return Response(
        [
            {
                "id": n.id,
                "title": n.title,
                "body": n.body,
                "image": (n.image.url if n.image else None),
                "created_at": n.created_at.astimezone(DHAKA).strftime("%Y-%m-%d"),
            }
            for n in notices
        ]
    )


# ----------------------------------------------------------------- notes --

@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def zonal_notes(request):
    office = _get_office(request)
    if not office:
        return Response(NOT_OFFICER, status=403)

    if request.method == "POST":
        title = (request.data.get("title") or "").strip()
        body = (request.data.get("body") or "").strip()
        if not title:
            return Response({"detail": "নোটের শিরোনাম লিখুন।"}, status=400)
        note = ZonalNote.objects.create(office=office, title=title, body=body)
        return Response(_note_payload(note), status=201)

    return Response(
        [_note_payload(n) for n in office.notes.all()[:200]]
    )


def _note_payload(n):
    return {
        "id": n.id,
        "title": n.title,
        "body": n.body,
        "created_at": n.created_at.astimezone(DHAKA).strftime("%Y-%m-%d %H:%M"),
        "updated_at": n.updated_at.astimezone(DHAKA).strftime("%Y-%m-%d %H:%M"),
    }


@api_view(["PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def zonal_note_detail(request, note_id):
    office = _get_office(request)
    if not office:
        return Response(NOT_OFFICER, status=403)
    note = office.notes.filter(id=note_id).first()
    if not note:
        return Response({"detail": "নোটটি পাওয়া যায়নি।"}, status=404)

    if request.method == "DELETE":
        note.delete()
        return Response(status=204)

    title = (request.data.get("title") or "").strip()
    body = request.data.get("body")
    if title:
        note.title = title
    if body is not None:
        note.body = str(body).strip()
    note.save()
    return Response(_note_payload(note))


# ----------------------------------------------------------------- areas --

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def zonal_areas(request):
    """Upazila list of the zone's city — for the area-manager form."""
    office = _get_office(request)
    if not office:
        return Response(NOT_OFFICER, status=403)
    try:
        from cities.models import Upazila

        names = list(
            Upazila.objects.filter(city__name_eng__iexact=office.city)
            .order_by("name_eng")
            .values_list("name_eng", flat=True)
        )
        # Dedupe, keep order
        seen, out = set(), []
        for n in names:
            k = (n or "").strip()
            if k and k.lower() not in seen:
                seen.add(k.lower())
                out.append(k)
        return Response(out)
    except Exception:
        return Response([])


# -------------------------------------------------------------- managers --

def _parse_commissions(raw):
    """[{feature, type, value}] -> {feature: (type, Decimal)} with validation."""
    valid_features = {f for f, _ in ZoneFeatureCommission.FEATURES}
    out = {}
    if not isinstance(raw, list):
        return out
    for item in raw:
        if not isinstance(item, dict):
            continue
        feature = str(item.get("feature") or "").strip()
        if feature not in valid_features:
            continue
        ctype = str(item.get("type") or "percent").strip()
        if ctype not in ("percent", "flat"):
            ctype = "percent"
        try:
            value = Decimal(str(item.get("value") or 0))
        except (InvalidOperation, ValueError):
            value = Decimal(0)
        if value < 0:
            value = Decimal(0)
        if ctype == "percent" and value > 100:
            value = Decimal(100)
        out[feature] = (ctype, value)
    return out


MANAGER_PAYOUT_FIELDS = (
    "payout_method", "payout_account_name", "payout_account_number",
    "payout_bank_name", "payout_bank_branch",
)


def _manager_payload(m):
    data = {
        "id": m.id,
        "name": m.name,
        "phone": m.phone,
        "area": m.area,
        "is_active": m.is_active,
        "created_at": m.created_at.astimezone(DHAKA).strftime("%Y-%m-%d"),
        "commissions": [
            {
                "feature": c.feature,
                "label": c.get_feature_display(),
                "type": c.commission_type,
                "value": float(c.value),
            }
            for c in m.commissions.all()
        ],
    }
    for f in MANAGER_PAYOUT_FIELDS:
        data[f] = getattr(m, f, "") or ""
    return data


def _save_manager_payout(manager, src):
    valid_methods = {"", "bkash", "nagad", "rocket", "bank"}
    changed = []
    for f in MANAGER_PAYOUT_FIELDS:
        if f in src:
            value = str(src.get(f) or "").strip()
            if f == "payout_method" and value not in valid_methods:
                continue
            setattr(manager, f, value[:120])
            changed.append(f)
    if changed:
        manager.save(update_fields=changed)


def _save_manager_commissions(manager, parsed):
    for feature, _label in FEATURE_ORDER:
        ctype, value = parsed.get(feature, ("percent", Decimal(0)))
        AreaManagerCommission.objects.update_or_create(
            manager=manager,
            feature=feature,
            defaults={"commission_type": ctype, "value": value},
        )


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def zonal_managers(request):
    office = _get_office(request)
    if not office:
        return Response(NOT_OFFICER, status=403)

    if request.method == "POST":
        name = (request.data.get("name") or "").strip()
        area = (request.data.get("area") or "").strip()
        phone = (request.data.get("phone") or "").strip()
        if not name or not area:
            return Response(
                {"detail": "ম্যানেজারের নাম ও এলাকা — দুটোই লাগবে।"}, status=400
            )
        if office.area_managers.filter(name__iexact=name, area__iexact=area).exists():
            return Response(
                {"detail": "এই এলাকায় একই নামের ম্যানেজার ইতিমধ্যে আছে।"}, status=400
            )
        manager = AreaManager.objects.create(
            office=office, name=name, area=area, phone=phone
        )
        _save_manager_commissions(
            manager, _parse_commissions(request.data.get("commissions"))
        )
        _save_manager_payout(manager, request.data)
        return Response(_manager_payload(manager), status=201)

    return Response(
        [_manager_payload(m) for m in office.area_managers.all()]
    )


@api_view(["GET", "PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def zonal_manager_detail(request, manager_id):
    office = _get_office(request)
    if not office:
        return Response(NOT_OFFICER, status=403)
    manager = office.area_managers.filter(id=manager_id).first()
    if not manager:
        return Response({"detail": "ম্যানেজার পাওয়া যায়নি।"}, status=404)

    if request.method == "DELETE":
        manager.delete()
        return Response(status=204)

    if request.method == "PATCH":
        for field in ("name", "phone", "area"):
            val = request.data.get(field)
            if val is not None and str(val).strip():
                setattr(manager, field, str(val).strip())
        if request.data.get("is_active") is not None:
            manager.is_active = bool(request.data.get("is_active"))
        manager.save()
        if request.data.get("commissions") is not None:
            _save_manager_commissions(
                manager, _parse_commissions(request.data.get("commissions"))
            )
        _save_manager_payout(manager, request.data)
        return Response(_manager_payload(manager))

    return Response(_manager_payload(manager))


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def zonal_manager_report(request, manager_id):
    """The manager's profile: their area's sales + auto-computed commissions
    per their own structure. Same engine as the zone dashboard, narrowed to
    the manager's upazila."""
    office = _get_office(request)
    if not office:
        return Response(NOT_OFFICER, status=403)
    manager = office.area_managers.filter(id=manager_id).first()
    if not manager:
        return Response({"detail": "ম্যানেজার পাওয়া যায়নি।"}, status=404)

    d_from, d_to, start, end = _parse_range(request)
    querysets = _metric_querysets(office.city, start, end, upazila=manager.area)
    data = _feature_data(querysets)

    # Rate-history aware (scoped to the manager's area).
    commissions, total_commission = metrics.commission_for_manager(
        office, manager, start, end
    )
    total_commission = float(total_commission)

    revenue = round(
        sum(data[f]["amount"] for f in (
            "pro_subscription", "microgig_post", "eshop_order",
            "mobile_recharge", "gold_sponsor", "rideshare_driver",
        )),
        2,
    )

    return Response(
        {
            "manager": _manager_payload(manager),
            "range": {"from": d_from.isoformat(), "to": d_to.isoformat()},
            "totals": {
                "area_users": User.objects.filter(
                    city__iexact=office.city, upazila__iexact=manager.area
                ).count(),
                "registrations": data["registration"]["count"],
                "pro": data["pro_subscription"],
                "gigs": data["microgig_post"],
                "orders": data["eshop_order"],
                "recharges": data["mobile_recharge"],
                "gold": data["gold_sponsor"],
                "rides": data["rideshare_driver"],
                "revenue": revenue,
                "commission": total_commission,
            },
            "commissions": commissions,
            "subscriptions": _subscription_analysis(office.city, upazila=manager.area),
            "service_categories": metrics.service_category_breakdown(
                office.city, upazila=manager.area
            ),
        }
    )


# -------------------------------------------------------------- settings --

PAYOUT_FIELDS = (
    "contact_phone", "office_address", "nid_number", "payout_method",
    "payout_account_name", "payout_account_number", "payout_bank_name",
    "payout_bank_branch", "payout_routing_number",
)


def _settings_payload(office):
    user = office.user
    photo = None
    try:
        if getattr(user, "image", None):
            photo = user.image.url
    except Exception:
        photo = None
    data = {
        "office_name": office.name,
        "city": office.city,
        "officer_name": getattr(user, "name", "") or f"{user.first_name} {user.last_name}".strip(),
        "officer_email": user.email,
        "officer_phone": getattr(user, "phone", "") or "",
        "officer_photo": photo,
        "joined": office.created_at.astimezone(DHAKA).strftime("%Y-%m-%d"),
    }
    for f in PAYOUT_FIELDS:
        data[f] = getattr(office, f, "") or ""
    return data


@api_view(["GET", "PATCH"])
@permission_classes([IsAuthenticated])
def zonal_settings(request):
    office = _get_office(request)
    if not office:
        return Response(NOT_OFFICER, status=403)

    if request.method == "PATCH":
        valid_methods = {"", "bkash", "nagad", "rocket", "bank"}
        changed = []
        for f in PAYOUT_FIELDS:
            if f in request.data:
                value = str(request.data.get(f) or "").strip()
                if f == "payout_method" and value not in valid_methods:
                    continue
                setattr(office, f, value[:255])
                changed.append(f)
        if changed:
            office.save(update_fields=changed)
    return Response(_settings_payload(office))


# -------------------------------------------------------------- payments --

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def zonal_payments(request):
    office = _get_office(request)
    if not office:
        return Response(NOT_OFFICER, status=403)

    payments = office.payments.all()[:200]
    from django.db.models import Sum as _S
    paid_total = float(
        office.payments.filter(status="paid").aggregate(s=_S("amount"))["s"] or 0
    )
    pending_total = float(
        office.payments.filter(status="pending").aggregate(s=_S("amount"))["s"] or 0
    )
    return Response(
        {
            "totals": {"paid": paid_total, "pending": pending_total},
            "payments": [
                {
                    "id": p.id,
                    "amount": float(p.amount),
                    "method": p.method,
                    "trx_id": p.trx_id,
                    "status": p.status,
                    "note": p.note,
                    "period_from": p.period_from.isoformat() if p.period_from else None,
                    "period_to": p.period_to.isoformat() if p.period_to else None,
                    "paid_at": p.paid_at.astimezone(DHAKA).strftime("%Y-%m-%d"),
                }
                for p in payments
            ],
        }
    )


# ----------------------------------------------------- earnings & invoices --

def _current_month_bounds():
    now_local = timezone.now().astimezone(DHAKA)
    return metrics.month_range(now_local.year, now_local.month)


def _balance_summary(invoices_qs, live_rows, live_total):
    """Balance figures from finalized invoices + this month's live (not yet
    invoiced) commission. The CURRENT month is represented only by the live
    figure, so any current-month invoice row (e.g. from a --current preview) is
    excluded from the invoice aggregates to avoid double counting."""
    from django.db.models import Sum as _S
    now_local = timezone.now().astimezone(DHAKA)
    finalized = invoices_qs.exclude(
        period_year=now_local.year, period_month=now_local.month
    )
    lifetime_invoiced = float(finalized.aggregate(s=_S("amount"))["s"] or 0)
    paid = float(finalized.filter(status="paid").aggregate(s=_S("amount"))["s"] or 0)
    payable = float(finalized.filter(status="unpaid").aggregate(s=_S("amount"))["s"] or 0)
    return {
        "payable_now": round(payable, 2),          # finalized past months, awaiting payout
        "this_month": float(live_total),           # accruing, not yet invoiced
        "lifetime_earned": round(lifetime_invoiced + float(live_total), 2),
        "total_paid": round(paid, 2),
        "this_month_rows": live_rows,
    }


def _invoice_payload(inv):
    return {
        "id": inv.id,
        "period": inv.period_label,
        "amount": float(inv.amount),
        "status": inv.status,
        "breakdown": inv.breakdown or [],
        "pay_method": inv.pay_method,
        "pay_trx_id": inv.pay_trx_id,
        "pay_note": inv.pay_note,
        "paid_at": inv.paid_at.astimezone(DHAKA).strftime("%Y-%m-%d") if inv.paid_at else None,
        "generated_at": inv.generated_at.astimezone(DHAKA).strftime("%Y-%m-%d"),
    }


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def zonal_balance(request):
    office = _get_office(request)
    if not office:
        return Response(NOT_OFFICER, status=403)
    start, end = _current_month_bounds()
    rows, net_total, _g, _d, _m = metrics.zone_net_commission(office, start, end)
    return Response(_balance_summary(office.invoices.all(), rows, net_total))


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def zonal_invoices(request):
    office = _get_office(request)
    if not office:
        return Response(NOT_OFFICER, status=403)
    return Response([_invoice_payload(i) for i in office.invoices.all()[:120]])


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def zonal_manager_balance(request, manager_id):
    office = _get_office(request)
    if not office:
        return Response(NOT_OFFICER, status=403)
    manager = office.area_managers.filter(id=manager_id).first()
    if not manager:
        return Response({"detail": "ম্যানেজার পাওয়া যায়নি।"}, status=404)
    start, end = _current_month_bounds()
    rows, total = metrics.commission_for_manager(office, manager, start, end)
    return Response(
        {
            "balance": _balance_summary(manager.invoices.all(), rows, total),
            "invoices": [_invoice_payload(i) for i in manager.invoices.all()[:120]],
        }
    )
