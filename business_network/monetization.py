"""Content monetization earnings — revenue-pool computation.

Pool model: each month a fixed admin-set pool (ContentMonetizationSettings.
monthly_pool_amount) is split among approved creators by their share of
engagement points. Fake engagement can only dilute the pool — total payout
never exceeds it — so the platform is safe even before fraud detection runs.

Valid-view rules applied here (anti-fraud layer 1):
  * views come from BusinessNetworkMediaView — already unique per
    (media, viewer) and self-view-proof at write time;
  * viewer accounts younger than `viewer_min_account_age_days` at the time
    of the view carry no points;
  * one viewer contributes at most `viewer_daily_view_cap` valid views per
    creator per day.
"""

from datetime import datetime, timedelta
from decimal import Decimal

from django.db.models import Count, F
from django.utils import timezone


def period_bounds(period):
    """'YYYY-MM' → (start, end) aware datetimes covering that month."""
    year, month = int(period[:4]), int(period[5:7])
    tz = timezone.get_current_timezone()
    start = datetime(year, month, 1)
    end = datetime(year + 1, 1, 1) if month == 12 else datetime(year, month + 1, 1)
    return (
        timezone.make_aware(start, tz),
        timezone.make_aware(end, tz),
    )


def current_period():
    now = timezone.localtime()
    return f"{now.year:04d}-{now.month:02d}"


def creator_points(user, start, end, conf):
    """Engagement points one creator earned inside [start, end)."""
    from .models import (
        BusinessNetworkFollowerModel,
        BusinessNetworkMedia,
        BusinessNetworkMediaView,
        BusinessNetworkPostComment,
        BusinessNetworkPostLike,
    )

    media_ids = list(
        BusinessNetworkMedia.objects.filter(
            business_network_posts__author=user
        )
        .values_list("id", flat=True)
        .distinct()
    )

    # Valid views: unique-per-viewer records, account-age gate, per-viewer
    # daily cap. The cap needs per-(viewer, day) counts, summed in Python.
    valid_views = 0
    top10_share = 0.0
    young_share = 0.0
    if media_ids:
        view_qs = (
            BusinessNetworkMediaView.objects.filter(
                media_id__in=media_ids,
                created_at__gte=start,
                created_at__lt=end,
            )
            .exclude(user=user)
            .filter(
                created_at__gte=F("user__date_joined")
                + timedelta(days=conf.viewer_min_account_age_days)
            )
        )
        per_viewer_day = view_qs.values("user_id", "created_at__date").annotate(
            n=Count("id")
        )
        cap = max(conf.viewer_daily_view_cap, 1)
        valid_views = sum(min(row["n"], cap) for row in per_viewer_day)

        # Fraud signals: viewer concentration + freshly-created viewer share.
        per_viewer = {}
        for row in per_viewer_day:
            per_viewer[row["user_id"]] = per_viewer.get(
                row["user_id"], 0
            ) + min(row["n"], cap)
        if valid_views > 0 and per_viewer:
            top10 = sum(sorted(per_viewer.values(), reverse=True)[:10])
            top10_share = top10 / valid_views
            young_views = (
                view_qs.filter(
                    user__date_joined__gte=end - timedelta(days=30)
                ).count()
            )
            young_share = min(young_views / valid_views, 1.0)

    likes = (
        BusinessNetworkPostLike.objects.filter(
            post__author=user, created_at__gte=start, created_at__lt=end
        )
        .exclude(user=user)
        .count()
    )
    comments = (
        BusinessNetworkPostComment.objects.filter(
            post__author=user, created_at__gte=start, created_at__lt=end
        )
        .exclude(author=user)
        .count()
    )
    followers_gained = BusinessNetworkFollowerModel.objects.filter(
        following=user, created_at__gte=start, created_at__lt=end
    ).count()

    total = (
        valid_views * conf.point_view
        + likes * conf.point_like
        + comments * conf.point_comment
        + followers_gained * conf.point_follower
    )
    return {
        "valid_views": valid_views,
        "likes": likes,
        "comments": comments,
        "followers_gained": followers_gained,
        "total_points": total,
        "top10_share": top10_share,
        "young_share": young_share,
    }


def fraud_score(points):
    """0–100 anomaly score from the period's signals. Thresholds only fire
    above a volume floor so small organic creators never get flagged."""
    views = points["valid_views"]
    engagement = points["likes"] + points["comments"]
    score = 0
    # A handful of viewers generating most of the volume.
    if views >= 200 and points["top10_share"] > 0.4:
        score += 35
    # Huge view volume with almost no likes/comments — bot cadence.
    if views >= 500 and engagement < views * 0.005:
        score += 35
    # Views dominated by accounts created within the last 30 days.
    if views >= 200 and points["young_share"] > 0.5:
        score += 30
    return min(score, 100)


def creator_content_breakdown(user, start, end, conf, limit=10):
    """Per-post engagement + points inside [start, end) for the earnings
    page's "which content earned what" list, plus a daily-views series for
    the analytics chart. Uses the same account-age gate as creator_points
    (per-viewer daily cap skipped — display-level detail)."""
    from .models import (
        BusinessNetworkMediaView,
        BusinessNetworkPost,
        BusinessNetworkPostComment,
        BusinessNetworkPostLike,
    )

    view_qs = (
        BusinessNetworkMediaView.objects.filter(
            media__business_network_posts__author=user,
            created_at__gte=start,
            created_at__lt=end,
        )
        .exclude(user=user)
        .filter(
            created_at__gte=F("user__date_joined")
            + timedelta(days=conf.viewer_min_account_age_days)
        )
    )

    posts = {}

    def bucket(post_id):
        return posts.setdefault(
            post_id, {"views": 0, "likes": 0, "comments": 0}
        )

    for row in view_qs.values("media__business_network_posts__id").annotate(
        n=Count("id")
    ):
        pid = row["media__business_network_posts__id"]
        if pid:
            bucket(pid)["views"] += row["n"]

    for row in (
        BusinessNetworkPostLike.objects.filter(
            post__author=user, created_at__gte=start, created_at__lt=end
        )
        .exclude(user=user)
        .values("post_id")
        .annotate(n=Count("id"))
    ):
        bucket(row["post_id"])["likes"] += row["n"]

    for row in (
        BusinessNetworkPostComment.objects.filter(
            post__author=user, created_at__gte=start, created_at__lt=end
        )
        .exclude(author=user)
        .values("post_id")
        .annotate(n=Count("id"))
    ):
        bucket(row["post_id"])["comments"] += row["n"]

    for stats in posts.values():
        stats["points"] = (
            stats["views"] * conf.point_view
            + stats["likes"] * conf.point_like
            + stats["comments"] * conf.point_comment
        )

    top_ids = sorted(posts, key=lambda p: -posts[p]["points"])[:limit]
    top_content = []
    if top_ids:
        for post in BusinessNetworkPost.objects.filter(
            id__in=top_ids
        ).prefetch_related("media"):
            stats = posts[post.id]
            first_media = next(iter(post.media.all()), None)
            thumb = ""
            media_type = "image"
            if first_media is not None:
                media_type = first_media.type
                f = first_media.thumbnail or first_media.image
                if f:
                    thumb = f.url
            excerpt = (post.title or post.content or "").strip()[:80]
            top_content.append(
                {
                    "post_id": post.id,
                    "excerpt": excerpt,
                    "thumbnail": thumb,
                    "media_type": media_type,
                    **stats,
                }
            )
        top_content.sort(key=lambda c: -c["points"])

    daily_views = [
        {"date": str(row["created_at__date"]), "views": row["n"]}
        for row in view_qs.values("created_at__date")
        .annotate(n=Count("id"))
        .order_by("created_at__date")
    ]

    return {"top_content": top_content, "daily_views": daily_views}


def compute_period_earnings(period=None):
    """(Re)compute every approved creator's points + pool share for a month.

    Safe to run repeatedly (daily cron + after month close): rows already
    paid or forfeited are left untouched; everything else is refreshed.
    Returns a small summary dict for logging.
    """
    from .models import (
        ContentMonetizationApplication,
        ContentMonetizationSettings,
        CreatorMonthlyEarning,
    )

    period = period or current_period()
    start, end = period_bounds(period)
    conf = ContentMonetizationSettings.current()

    creators = [
        app.user
        for app in ContentMonetizationApplication.objects.filter(
            status="approved"
        ).select_related("user")
    ]

    results = {}
    for user in creators:
        results[user.pk] = (user, creator_points(user, start, end, conf))

    total_points = sum(p["total_points"] for _, p in results.values())
    pool = conf.monthly_pool_amount or Decimal("0")

    updated = 0
    for user, points in results.values():
        row, _created = CreatorMonthlyEarning.objects.get_or_create(
            user=user, period=period
        )
        if row.status in ("paid", "forfeited"):
            continue
        share = (
            (pool * Decimal(points["total_points"]) / Decimal(total_points))
            if total_points > 0
            else Decimal("0")
        )
        row.valid_views = points["valid_views"]
        row.likes = points["likes"]
        row.comments = points["comments"]
        row.followers_gained = points["followers_gained"]
        row.total_points = points["total_points"]
        row.amount = share.quantize(Decimal("0.01"))
        row.fraud_score = fraud_score(points)
        # Auto-hold suspicious rows for admin review; never auto-release a
        # row an admin already held or cleared.
        if row.fraud_score >= 50 and row.status == "accruing":
            row.status = "held"
            row.note = "Auto-flagged: anomalous view pattern"
        row.save(
            update_fields=[
                "valid_views",
                "likes",
                "comments",
                "followers_gained",
                "total_points",
                "amount",
                "fraud_score",
                "status",
                "note",
                "updated_at",
            ]
        )
        updated += 1

    return {
        "period": period,
        "creators": len(creators),
        "updated": updated,
        "total_points": total_points,
        "pool": str(pool),
    }
