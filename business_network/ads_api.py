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
    "bn_feed", "shorts_banner", "shorts_fullscreen", "shorts_reel",
    "app_open", "gigs_list", "sale_list", "news_list", "food_list",
    "classified_list", "web_feed", "web_banner",
}

VALID_EVENTS = {"impression", "click", "cta_click", "skip"}

# Anti-fraud ceilings (per user per day, cache-enforced).
MAX_DAILY_EVENTS_PER_USER = 600


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


def _ad_profile(user):
    if not user or not user.is_authenticated:
        return None
    return UserAdProfile.objects.filter(user=user).first()


@api_view(["GET"])
@permission_classes([AllowAny])
def serve_ad(request):
    placement = (request.query_params.get("placement") or "").strip()
    if placement not in VALID_PLACEMENTS:
        return Response({"fallback": "admob"})

    cfg = AdsSystemConfig.get()
    now = timezone.now()
    today = timezone.localdate().isoformat()
    user = request.user if request.user.is_authenticated else None

    # The shorts reel only carries boosted posts; other placements carry
    # image/video creatives.
    want_boost = placement == "shorts_reel"

    qs = AbnAdsPanel.objects.filter(status="active").select_related(
        "category", "boosted_post__author"
    )
    candidates = []
    for ad in qs[:200]:
        if want_boost != (ad.format == "boost"):
            continue
        if want_boost and ad.boosted_post_id is None:
            continue
        # Placement: empty list = everywhere.
        if not want_boost and ad.placements and placement not in ad.placements:
            continue
        # Budget / view cap exhausted → auto-complete lazily.
        if ad.estimated_views and ad.views >= ad.estimated_views:
            AbnAdsPanel.objects.filter(pk=ad.pk).update(status="completed")
            continue
        # Scheduling window.
        if ad.start_at and now < ad.start_at:
            continue
        if ad.end_at and now > ad.end_at:
            continue
        # Daily pacing: stop for today once the daily budget is burned.
        if ad.daily_budget:
            spent_today = Decimal(str(cache.get(f"adspend:{ad.pk}:{today}") or 0))
            if spent_today >= ad.daily_budget:
                continue
        # Location targeting: only serve to users we KNOW are in a target
        # area (unknown location never matches a targeted ad).
        if ad.target_locations:
            locs = {str(l).strip().lower() for l in ad.target_locations}
            user_locs = set()
            if user is not None:
                for attr in ("city", "upazila", "state"):
                    v = (getattr(user, attr, "") or "").strip().lower()
                    if v:
                        user_locs.add(v)
            if not (locs & user_locs):
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

    # Interest-weighted pick: ad-category weights (impressions + clicks,
    # decayed nightly) + the Interest Brain's content segments bias which
    # ad wins the slot.
    from .interest_brain import classify_ad

    profile = _ad_profile(user)
    weights = (profile.category_weights or {}) if profile else {}
    iscores = (profile.interest_scores or {}) if profile else {}
    gaff = (profile.gender_affinity or {}) if profile else {}
    scored = []
    for ad in candidates:
        w = 1.0 + float(weights.get(str(ad.category_id), 0))
        # Interest Brain: an ad whose content segments match the viewer's
        # interests serves up to 2.5x more often.
        if iscores:
            tags = classify_ad(ad)
            if tags:
                overlap = max((iscores.get(t, 0) for t in tags), default=0)
                w *= 1.0 + (float(overlap) / 100.0) * 1.5
        # Boosted posts: nudge toward creators of the gender this viewer
        # actually engages with (±50%).
        if gaff and ad.format == "boost" and ad.boosted_post is not None:
            author = ad.boosted_post.author
            ag = (getattr(author, "gender", "") or "").strip().lower()
            if ag in ("male", "female"):
                w *= 1.0 + (float(gaff.get(ag, 50)) - 50.0) / 100.0
        # Under-served ads get a boost so budgets drain evenly.
        remaining = 1.0
        if ad.estimated_views:
            remaining += max(0.0, 1.0 - ad.views / ad.estimated_views)
        # Ad-quality signal: after enough data, a strong CTR earns more
        # serving, a dead CTR earns less (Facebook relevance-score lite).
        quality = 1.0
        if ad.views >= 20:
            ctr = ad.clicks / ad.views
            quality = max(0.5, min(1.0 + ctr * 20.0, 2.5))
        scored.append((ad, w * remaining * quality))

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

    def _abs(url):
        url = request.build_absolute_uri(url)
        if url.startswith("http://") and "localhost" not in url:
            url = url.replace("http://", "https://", 1)
        return url

    images = []
    video_url = ""
    for m in chosen.media.all()[:4]:
        if m.image:
            images.append(_abs(m.image.url))
        if m.video and not video_url:
            video_url = _abs(m.video.url)

    payload = {
        "id": chosen.pk,
        "title": chosen.title,
        "description": chosen.description,
        "format": chosen.format,
        "images": images,
        "video_url": video_url,
        "companion_banner": (
            _abs(chosen.companion_banner.url) if chosen.companion_banner else ""
        ),
        "ad_type": chosen.ad_type,
        "ad_type_details": chosen.ad_type_details or "",
        "category": chosen.category_id,
        "category_name": getattr(chosen.category, "name", ""),
        "advertiser": (
            chosen.user.get_full_name() or chosen.user.username
        ) if chosen.user else "AdsyClub",
        # Owner identity so the app can render a real avatar and navigate
        # to the advertiser's BN profile from any ad surface.
        "advertiser_id": str(chosen.user.id) if chosen.user else "",
        "advertiser_image": (
            _abs(chosen.user.image.url)
            if chosen.user is not None and getattr(chosen.user, "image", None)
            else ""
        ),
    }

    # Boosted post: ship everything the shorts reel needs to play it inline.
    if chosen.format == "boost" and chosen.boosted_post:
        post = chosen.boosted_post
        boost_video = ""
        boost_thumb = ""
        for m in post.media.all():
            if getattr(m, "type", "") == "video" and m.video:
                boost_video = _abs(m.video.url)
                if m.thumbnail:
                    boost_thumb = _abs(m.thumbnail.url)
                break
        author = post.author
        payload["boosted_post"] = {
            "id": post.pk,
            "video_url": boost_video,
            "thumbnail": boost_thumb,
            "content": post.content or "",
            "author_id": str(author.id) if author else "",
            "author_name": (
                author.get_full_name() or author.username
            ) if author else "",
            "author_avatar": _abs(author.image.url)
            if author is not None and getattr(author, "image", None)
            else "",
        }
        if not boost_video:
            # A boost without a playable video can't run in the reel.
            return Response({"fallback": "admob"})

    return Response({"source": "panel", "ad": payload})


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

    # Anti-fraud ceiling: one user can't pump unlimited events in a day.
    if user is not None:
        daily_key = f"adevents:{user.id}:{today.isoformat()}"
        daily_count = cache.get(daily_key) or 0
        if daily_count >= MAX_DAILY_EVENTS_PER_USER:
            return Response({"recorded": 0, "capped": True})
        cache.set(daily_key, daily_count + len(events), 60 * 60 * 26)

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

        # Panel counters + budget burn (CPV per billable impression). A
        # per-user+ad daily dedupe cap keeps repeat exposure from burning
        # budget beyond the frequency cap.
        if ad is not None:
            if event_type == "impression":
                billable = True
                if user is not None:
                    dedupe_key = (
                        f"adbill:{user.id}:{ad.pk}:{today.isoformat()}"
                    )
                    seen = cache.get(dedupe_key) or 0
                    if seen >= cfg.daily_frequency_cap:
                        billable = False
                    else:
                        cache.set(dedupe_key, seen + 1, 60 * 60 * 26)
                if billable:
                    AbnAdsPanel.objects.filter(pk=ad.pk).update(
                        views=F("views") + 1,
                        spent=F("spent") + Decimal(str(cfg.cpv_rate)),
                    )
                    # Daily pacing counter (serve stops at daily_budget).
                    spend_key = f"adspend:{ad.pk}:{today.isoformat()}"
                    prev = Decimal(str(cache.get(spend_key) or 0))
                    cache.set(
                        spend_key,
                        str(prev + Decimal(str(cfg.cpv_rate))),
                        60 * 60 * 26,
                    )
                    if ad.estimated_views and ad.views + 1 >= ad.estimated_views:
                        AbnAdsPanel.objects.filter(pk=ad.pk).update(
                            status="completed"
                        )
            elif event_type in ("click", "cta_click"):
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


@api_view(["POST"])
def upload_ad_video(request):
    """Multipart video upload for VIDEO-format ads (base64 would be too
    heavy). Returns the media id to reference from the create call."""
    if not request.user.is_authenticated:
        return Response({"error": "auth required"}, status=401)
    f = request.FILES.get("video")
    if f is None:
        return Response({"error": "video file required"}, status=400)
    if f.size > 60 * 1024 * 1024:
        return Response({"error": "video too large (max 60MB)"}, status=400)
    from .models import AbnAdsPanelMedia

    media = AbnAdsPanelMedia.objects.create(video=f)
    return Response({"media_id": media.pk}, status=201)


@api_view(["GET"])
def my_ad_stats(request):
    """Advertiser dashboard: daily views/clicks series for the caller's ads
    (last `days`, default 14) + lifetime totals per ad."""
    if not request.user.is_authenticated:
        return Response({"error": "auth required"}, status=401)
    from datetime import timedelta

    from django.db.models import Count, Q

    days = min(int(request.query_params.get("days") or 14), 60)
    since = timezone.localdate() - timedelta(days=days - 1)

    my_ads = AbnAdsPanel.objects.filter(user=request.user)
    daily = (
        AdEvent.objects.filter(
            ad__in=my_ads, created_at__date__gte=since, source="panel"
        )
        .values("created_at__date")
        .annotate(
            views=Count("id", filter=Q(event_type="impression")),
            clicks=Count(
                "id", filter=Q(event_type__in=["click", "cta_click"])
            ),
        )
        .order_by("created_at__date")
    )
    return Response({
        "daily": [
            {
                "date": str(row["created_at__date"]),
                "views": row["views"],
                "clicks": row["clicks"],
            }
            for row in daily
        ],
        "ads": [
            {
                "id": ad.pk,
                "title": ad.title,
                "status": ad.status,
                "views": ad.views,
                "clicks": ad.clicks,
                "spent": str(ad.spent),
                "budget": str(ad.budget),
            }
            for ad in my_ads.order_by("-created_at")[:50]
        ],
    })


@api_view(["GET"])
def my_reward_status(request):
    """Viewer reward progress for TODAY — powers the app's reward meter."""
    if not request.user.is_authenticated:
        return Response({"error": "auth required"}, status=401)
    cfg = AdsSystemConfig.get()
    today = timezone.localdate()
    row = AdViewerDaily.objects.filter(user=request.user, date=today).first()
    views = row.views if row else 0
    per = max(1, cfg.views_per_diamond)
    earned = min(views // per, cfg.max_daily_diamonds)
    return Response({
        "enabled": cfg.viewer_reward_enabled,
        "today_views": views,
        "views_per_diamond": per,
        "max_daily_diamonds": cfg.max_daily_diamonds,
        "diamonds_earned_today": earned,
        "views_to_next": 0 if earned >= cfg.max_daily_diamonds
        else per - (views % per),
    })


@api_view(["POST"])
def toggle_my_ad(request, ad_id):
    """Advertiser stop/resume for their OWN ad (status is otherwise
    server-controlled). review/rejected/completed ads can't be toggled."""
    if not request.user.is_authenticated:
        return Response({"error": "auth required"}, status=401)
    ad = AbnAdsPanel.objects.filter(pk=ad_id, user=request.user).first()
    if ad is None:
        return Response({"error": "not found"}, status=404)
    if ad.status == "active":
        ad.status = "stoped"
    elif ad.status == "stoped":
        ad.status = "active"
    else:
        return Response(
            {"error": f"cannot toggle from {ad.status}"}, status=400
        )
    ad.save(update_fields=["status"])
    return Response({"status": ad.status})
