"""Ads system API — hybrid house-ads (AbnAdsPanel) + AdMob fallback.

GET  /api/bn/ads/serve/?placement=bn_feed&platform=app
    → one targeting-matched active panel ad, or {"fallback": "admob"}.

POST /api/bn/ads/track/   {"events": [{...}, ...]}
    → records AdEvents (max 50/batch). Drives ad counters + budget burn,
      viewer daily reward counters and the per-user interest profile.
"""
import random
from datetime import date, timedelta
from decimal import Decimal

from django.core.cache import cache
from django.db.models import F
from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from base.models import User

from .models import (
    AbnAdsPanel,
    AbnAdsPanelCategory,
    AdEvent,
    AdsSystemConfig,
    AdViewerDaily,
    UserAdProfile,
)

VALID_PLACEMENTS = {
    "bn_feed", "shorts_banner", "shorts_fullscreen", "app_open",
    "gigs_list", "sale_list", "news_list", "food_list", "classified_list",
    "web_feed", "web_banner",
}

VALID_EVENTS = {"impression", "click", "cta_click"}


def _user_age(user):
    dob = getattr(user, "date_of_birth", None) or getattr(user, "dob", None)
    if not dob:
        return None
    today = date.today()
    try:
        return today.year - dob.year - (
            (today.month, today.day) < (dob.month, dob.day)
        )
    except Exception:
        return None


def _user_gender(user):
    return (getattr(user, "gender", "") or "").strip().lower()


def _interest_weights(user):
    if not user or not user.is_authenticated:
        return {}
    profile = UserAdProfile.objects.filter(user=user).first()
    return profile.category_weights if profile else {}


@api_view(["GET"])
@permission_classes([AllowAny])
def serve_ad(request):
    placement = (request.query_params.get("placement") or "").strip()
    if placement not in VALID_PLACEMENTS:
        return Response({"fallback": "admob"})

    cfg = AdsSystemConfig.get()
    now = timezone.now()
    user = request.user if request.user.is_authenticated else None

    qs = AbnAdsPanel.objects.filter(status="active").select_related("category")
    candidates = []
    for ad in qs[:200]:
        # Placement: empty list = everywhere.
        if ad.placements and placement not in ad.placements:
            continue
        # Budget / view cap exhausted → auto-complete lazily.
        if ad.estimated_views and ad.views >= ad.estimated_views:
            AbnAdsPanel.objects.filter(pk=ad.pk).update(status="completed")
            continue
        if user is not None:
            # Gender targeting (only filters when the ad targets a subset
            # AND we actually know the viewer's gender).
            g = _user_gender(user)
            if g and not (ad.male and ad.female and ad.other):
                allowed = set()
                if ad.male:
                    allowed.add("male")
                if ad.female:
                    allowed.add("female")
                if ad.other:
                    allowed.add("other")
                if allowed and g not in allowed:
                    continue
            age = _user_age(user)
            if age is not None:
                if ad.min_age and age < ad.min_age:
                    continue
                if ad.max_age and age > ad.max_age:
                    continue
            # Daily frequency cap per user+ad.
            cap_key = f"adcap:{user.id}:{ad.pk}:{now.date().isoformat()}"
            if (cache.get(cap_key) or 0) >= cfg.daily_frequency_cap:
                continue
        candidates.append(ad)

    if not candidates:
        return Response({"fallback": "admob"})

    # Interest-weighted pick: the user's recent ad interests (impressions +
    # clicks per category, decayed nightly) bias which ad wins the slot.
    weights = _interest_weights(user)
    scored = []
    for ad in candidates:
        w = 1.0 + float(weights.get(str(ad.category_id), 0))
        # Under-served ads get a boost so budgets drain evenly.
        remaining = 1.0
        if ad.estimated_views:
            remaining += max(0.0, 1.0 - ad.views / ad.estimated_views)
        scored.append((ad, w * remaining))

    total = sum(s for _, s in scored)
    pick = random.uniform(0, total)
    chosen = scored[-1][0]
    acc = 0.0
    for ad, s in scored:
        acc += s
        if pick <= acc:
            chosen = ad
            break

    if user is not None:
        cap_key = f"adcap:{user.id}:{chosen.pk}:{now.date().isoformat()}"
        try:
            cache.set(cap_key, (cache.get(cap_key) or 0) + 1, 60 * 60 * 26)
        except Exception:
            pass

    request_ctx = {"request": request}
    images = []
    for m in chosen.media.all()[:4]:
        if m.image:
            url = m.image.url
            url = request.build_absolute_uri(url)
            if url.startswith("http://") and "localhost" not in url:
                url = url.replace("http://", "https://", 1)
            images.append(url)

    return Response({
        "source": "panel",
        "ad": {
            "id": chosen.pk,
            "title": chosen.title,
            "description": chosen.description,
            "images": images,
            "ad_type": chosen.ad_type,
            "ad_type_details": chosen.ad_type_details or "",
            "category": chosen.category_id,
            "category_name": getattr(chosen.category, "name", ""),
            "advertiser": (
                chosen.user.get_full_name() or chosen.user.username
            ) if chosen.user else "AdsyClub",
        },
    })


@api_view(["POST"])
@permission_classes([AllowAny])
def track_ad_events(request):
    events = request.data.get("events") or []
    if not isinstance(events, list):
        return Response({"error": "events must be a list"}, status=400)
    events = events[:50]

    cfg = AdsSystemConfig.get()
    user = request.user if request.user.is_authenticated else None
    today = timezone.localdate()

    created = 0
    viewer_views = 0
    interest_bumps = {}  # category_id -> weight delta

    for ev in events:
        if not isinstance(ev, dict):
            continue
        event_type = (ev.get("event_type") or "").strip()
        if event_type not in VALID_EVENTS:
            continue
        source = "admob" if (ev.get("source") == "admob") else "panel"
        placement = (ev.get("placement") or "").strip()[:30]
        platform = (ev.get("platform") or "app").strip()[:10]

        ad = None
        if source == "panel":
            ad_id = str(ev.get("ad") or "").strip()
            if ad_id:
                ad = AbnAdsPanel.objects.filter(pk=ad_id).first()
            if ad is None:
                continue

        creator = None
        creator_id = str(ev.get("creator") or "").strip()
        if creator_id:
            creator = User.objects.filter(id=creator_id).first()

        category = ad.category if ad else None

        AdEvent.objects.create(
            ad=ad,
            source=source,
            event_type=event_type,
            placement=placement,
            platform=platform,
            user=user,
            creator=creator,
            category=category,
        )
        created += 1

        # Panel counters + budget burn (CPV per impression).
        if ad is not None:
            if event_type == "impression":
                AbnAdsPanel.objects.filter(pk=ad.pk).update(
                    views=F("views") + 1,
                    spent=F("spent") + Decimal(str(cfg.cpv_rate)),
                )
                if ad.estimated_views and ad.views + 1 >= ad.estimated_views:
                    AbnAdsPanel.objects.filter(pk=ad.pk).update(
                        status="completed"
                    )
            else:
                AbnAdsPanel.objects.filter(pk=ad.pk).update(
                    clicks=F("clicks") + 1
                )

        # Viewer reward counter — every tracked impression counts, both
        # AdMob and panel (the user asked to reward total ad exposure).
        if user is not None and event_type == "impression":
            viewer_views += 1

        # Interest profile: impressions nudge, clicks push hard.
        if user is not None and category is not None:
            delta = 1.0 if event_type == "impression" else 4.0
            key = str(category.pk)
            interest_bumps[key] = interest_bumps.get(key, 0.0) + delta

    if user is not None and viewer_views and cfg.viewer_reward_enabled:
        row, _ = AdViewerDaily.objects.get_or_create(user=user, date=today)
        AdViewerDaily.objects.filter(pk=row.pk).update(
            views=F("views") + viewer_views
        )

    if user is not None and interest_bumps:
        profile, _ = UserAdProfile.objects.get_or_create(user=user)
        weights = dict(profile.category_weights or {})
        for key, delta in interest_bumps.items():
            weights[key] = round(float(weights.get(key, 0.0)) + delta, 2)
        profile.category_weights = weights
        profile.save(update_fields=["category_weights", "updated_at"])

    return Response({"recorded": created})
