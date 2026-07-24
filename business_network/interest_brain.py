"""Interest Brain — classifies each user into interest segments from their
real activity (posts/videos they view, like, save, comment on, hide or
report, ads they click, creators they engage with) so ad serving can match
ads to the people most likely to care.

Design (all in-process, no extra infra):

1. A fixed INTEREST_TAXONOMY of segments, each with Bangla + English
   keywords. Content is classified by keyword hits — cheap, transparent,
   and easy to tune from one place.
2. `build_profile(user)` sweeps the user's last 30 days of activity,
   classifies every piece of content they touched, and weights it by how
   strong the signal is (save > comment > like > watch > feed view;
   hide/report are negative). Scores are normalized to 0–100.
3. Results land on UserAdProfile: `interest_scores` (per-segment 0–100),
   `segments` (top segments + activity level), `gender_affinity` (share of
   engagement on male vs female creators' content).
4. serve_ad() classifies each ad's text the same way (cached) and boosts
   ads whose segments overlap the viewer's — on top of the existing
   ad-category weights, frequency caps and targeting filters.

Run nightly via `build_interest_profiles` (celery beat).
"""
import logging
from datetime import timedelta

from django.core.cache import cache
from django.utils import timezone

logger = logging.getLogger(__name__)

# ── Interest taxonomy ────────────────────────────────────────────────────
# segment -> keywords (lowercase; Bangla matched as substrings, English as
# substrings too — good enough at this scale and language mix).
INTEREST_TAXONOMY = {
    "fashion": [
        "fashion", "dress", "saree", "শাড়ি", "পাঞ্জাবি", "জামা", "পোশাক",
        "ফ্যাশন", "clothing", "outfit", "কালেকশন", "eid collection", "টি-শার্ট",
        "tshirt", "shoe", "জুতা", "bag", "ব্যাগ",
    ],
    "beauty": [
        "beauty", "makeup", "মেকআপ", "রূপচর্চা", "skincare", "স্কিন", "cosmetic",
        "কসমেটিক", "parlour", "পার্লার", "hair", "চুল",
    ],
    "food": [
        "food", "খাবার", "রেসিপি", "recipe", "restaurant", "রেস্টুরেন্ট", "বিরিয়ানি",
        "biryani", "cake", "কেক", "delivery", "ডেলিভারি", "ফুড", "রান্না", "cooking",
        "মিষ্টি", "pizza", "burger",
    ],
    "tech": [
        "tech", "টেক", "mobile", "মোবাইল", "phone", "ফোন", "laptop", "ল্যাপটপ",
        "computer", "কম্পিউটার", "gadget", "গ্যাজেট", "app", "অ্যাপ", "software",
        "ai", "internet", "ইন্টারনেট", "gaming", "গেম",
    ],
    "business": [
        "business", "ব্যবসা", "উদ্যোক্তা", "entrepreneur", "startup", "স্টার্টআপ",
        "marketing", "মার্কেটিং", "invest", "বিনিয়োগ", "shop", "দোকান", "wholesale",
        "পাইকারি", "ecommerce", "ই-কমার্স",
    ],
    "jobs_education": [
        "job", "চাকরি", "নিয়োগ", "career", "ক্যারিয়ার", "admission", "ভর্তি",
        "exam", "পরীক্ষা", "study", "পড়াশোনা", "course", "কোর্স", "training",
        "প্রশিক্ষণ", "scholarship", "বৃত্তি", "university", "বিশ্ববিদ্যালয়", "bcs",
        "freelancing", "ফ্রিল্যান্সিং", "skill", "দক্ষতা",
    ],
    "entertainment": [
        "funny", "মজার", "হাসি", "comedy", "কমেডি", "natok", "নাটক", "movie",
        "মুভি", "সিনেমা", "গান", "song", "music", "মিউজিক", "dance", "নাচ",
        "celebrity", "তারকা", "entertainment", "বিনোদন", "vlog", "ভ্লগ",
    ],
    "sports": [
        "cricket", "ক্রিকেট", "football", "ফুটবল", "খেলা", "sports", "স্পোর্টস",
        "match", "ম্যাচ", "world cup", "বিশ্বকাপ", "gym", "জিম", "fitness",
        "ফিটনেস",
    ],
    "health": [
        "health", "স্বাস্থ্য", "doctor", "ডাক্তার", "hospital", "হাসপাতাল",
        "medicine", "ওষুধ", "চিকিৎসা", "treatment", "diabetes", "ডায়াবেটিস",
        "mental health", "মানসিক",
    ],
    "travel": [
        "travel", "ভ্রমণ", "tour", "ট্যুর", "trip", "ট্রিপ", "resort", "রিসোর্ট",
        "hotel", "হোটেল", "cox", "কক্সবাজার", "সাজেক", "sylhet", "সিলেট",
        "বান্দরবান", "visa", "ভিসা", "flight", "ফ্লাইট",
    ],
    "religion": [
        "islam", "ইসলাম", "নামাজ", "কুরআন", "quran", "hadith", "হাদিস", "দোয়া",
        "রমজান", "ঈদ", "হজ", "waz", "ওয়াজ", "মসজিদ",
    ],
    "agriculture": [
        "কৃষি", "agriculture", "farming", "খামার", "ফসল", "crop", "গরু", "cattle",
        "মাছ চাষ", "fish farm", "পোল্ট্রি", "poultry", "সবজি",
    ],
    "vehicles_property": [
        "car", "গাড়ি", "bike", "বাইক", "মোটরসাইকেল", "motorcycle", "land",
        "জমি", "flat", "ফ্ল্যাট", "প্লট", "property", "প্রপার্টি", "rent", "ভাড়া",
        "real estate",
    ],
    "finance": [
        "loan", "লোন", "ঋণ", "bank", "ব্যাংক", "savings", "সঞ্চয়", "bkash",
        "বিকাশ", "nagad", "নগদ", "mobile banking", "insurance", "বীমা", "dps",
        "recharge", "রিচার্জ",
    ],
}

# Signal weights: how strongly each action says "this user cares".
W_FEED_VIEW = 0.5
W_VIDEO_WATCH = 1.5
W_LIKE = 3.0
W_VIDEO_LIKE = 3.0
W_COMMENT = 4.0
W_SAVE = 5.0
W_AD_IMPRESSION = 0.5
W_AD_CLICK = 4.0
W_HIDE = -6.0
W_REPORT = -8.0

LOOKBACK_DAYS = 30
# Per-signal row caps keep one hyperactive user from stalling the nightly job.
ROW_CAP = 500

# ── Soft mood/tone word lists (NOT a clinical assessment — a light content
# tone signal so serving/feed can soften experiences for low-tone users). ──
POSITIVE_WORDS = (
    "আলহামদুলিল্লাহ", "খুশি", "ভালো লাগ", "সুন্দর", "মজা", "ধন্যবাদ",
    "শুকরিয়া", "অভিনন্দন", "happy", "great", "love", "awesome", "excited",
    "blessed", "alhamdulillah",
)
NEGATIVE_WORDS = (
    "কষ্ট", "দুঃখ", "হতাশ", "একা", "মন খারাপ", "ক্লান্ত", "বিষণ্ণ",
    "কান্না", "যন্ত্রণা", "sad", "depressed", "alone", "tired", "pain",
    "hurt", "hopeless",
)


def classify_text(text):
    """Return {segment: hit_count} for a blob of content text."""
    if not text:
        return {}
    t = text.lower()
    hits = {}
    for segment, keywords in INTEREST_TAXONOMY.items():
        n = sum(1 for kw in keywords if kw in t)
        if n:
            hits[segment] = n
    return hits


def _post_text(post):
    if post is None:
        return ""
    parts = [post.title or "", post.content or ""]
    try:
        parts.extend(t.tag for t in post.tags.all()[:10])
    except Exception:
        pass
    return " ".join(parts)


def classify_ad(ad):
    """Segments for an ad creative, cached — serve calls this per request."""
    key = f"adtags:{ad.pk}"
    tags = cache.get(key)
    if tags is None:
        text = f"{ad.title} {ad.description}"
        if ad.boosted_post_id:
            try:
                text += " " + _post_text(ad.boosted_post)
            except Exception:
                pass
        tags = list(classify_text(text).keys())
        cache.set(key, tags, 60 * 60 * 6)
    return tags


def build_profile(user):
    """Classify one user from their recent activity. Returns the profile
    dict that lands on UserAdProfile (also saves it)."""
    from .models import (
        AdEvent,
        BusinessNetworkMediaLike,
        BusinessNetworkMediaView,
        BusinessNetworkPostComment,
        BusinessNetworkPostLike,
        HiddenPost,
        PostReport,
        PostSeen,
        UserAdProfile,
        UserSavedPosts,
    )

    since = timezone.now() - timedelta(days=LOOKBACK_DAYS)
    scores = {}
    gender_units = {"male": 0.0, "female": 0.0}
    total_signal = 0.0
    video_signal = 0.0

    def bump(text, weight, author=None):
        nonlocal total_signal
        hits = classify_text(text)
        for seg, n in hits.items():
            scores[seg] = scores.get(seg, 0.0) + weight * min(n, 3)
        if weight > 0:
            total_signal += weight
            if author is not None:
                g = (author.gender or "").strip().lower()
                if g in gender_units:
                    gender_units[g] += weight

    # Feed views (weak but plentiful)
    for seen in (
        PostSeen.objects.filter(user=user, last_seen_at__gte=since)
        .select_related("post", "post__author")
        .prefetch_related("post__tags")[:ROW_CAP]
    ):
        bump(_post_text(seen.post), W_FEED_VIEW, seen.post.author)

    # Post likes / comments / saves
    for like in (
        BusinessNetworkPostLike.objects.filter(user=user, created_at__gte=since)
        .select_related("post", "post__author")
        .prefetch_related("post__tags")[:ROW_CAP]
    ):
        bump(_post_text(like.post), W_LIKE, like.post.author)

    for cm in (
        BusinessNetworkPostComment.objects.filter(
            author=user, created_at__gte=since
        )
        .select_related("post", "post__author")
        .prefetch_related("post__tags")[:ROW_CAP]
    ):
        bump(_post_text(cm.post) + " " + (cm.content or ""), W_COMMENT,
             cm.post.author)

    for sv in (
        UserSavedPosts.objects.filter(user=user, created_at__gte=since)
        .select_related("post", "post__author")
        .prefetch_related("post__tags")[:ROW_CAP]
    ):
        bump(_post_text(sv.post), W_SAVE, sv.post.author)

    # Video watches + likes (what kind of videos they actually watch)
    for mv in (
        BusinessNetworkMediaView.objects.filter(user=user, created_at__gte=since)
        .select_related("media")[:ROW_CAP]
    ):
        post = mv.media.business_network_posts.select_related("author").first()
        if post is not None:
            bump(_post_text(post), W_VIDEO_WATCH, post.author)
            video_signal += W_VIDEO_WATCH

    for ml in (
        BusinessNetworkMediaLike.objects.filter(user=user, created_at__gte=since)
        .select_related("media")[:ROW_CAP]
    ):
        post = ml.media.business_network_posts.select_related("author").first()
        if post is not None:
            bump(_post_text(post), W_VIDEO_LIKE, post.author)
            video_signal += W_VIDEO_LIKE

    # Negative signals: content they hide or report
    for h in (
        HiddenPost.objects.filter(user=user, created_at__gte=since)
        .select_related("post")[:ROW_CAP]
    ):
        bump(_post_text(h.post), W_HIDE)

    for r in (
        PostReport.objects.filter(user=user, created_at__gte=since)
        .select_related("post")[:ROW_CAP]
    ):
        bump(_post_text(r.post), W_REPORT)

    # Ad interactions (clicks are the strongest purchase-intent signal)
    for ev in (
        AdEvent.objects.filter(
            user=user, created_at__gte=since, source="panel", ad__isnull=False
        ).select_related("ad")[:ROW_CAP]
    ):
        w = W_AD_CLICK if ev.event_type in ("click", "cta_click") else W_AD_IMPRESSION
        bump(f"{ev.ad.title} {ev.ad.description}", w)

    # ── Normalize to 0–100 ──
    positives = {k: v for k, v in scores.items() if v > 0}
    top = max(positives.values()) if positives else 0.0
    interest_scores = {}
    if top > 0:
        for seg, v in scores.items():
            norm = max(0.0, v) / top * 100.0
            if norm >= 5:
                interest_scores[seg] = round(norm, 1)

    # ── Soft mood/tone from the user's OWN recent words (posts+comments).
    # A gentle product signal only — never a diagnosis, never shown to the
    # user, never sold to advertisers as a targeting option. ──
    from .models import BusinessNetworkPost

    own_texts = []
    for p in BusinessNetworkPost.objects.filter(
        author=user, created_at__gte=since
    )[:100]:
        own_texts.append(f"{p.title or ''} {p.content or ''}")
    for own_cm in BusinessNetworkPostComment.objects.filter(
        author=user, created_at__gte=since
    )[:200]:
        own_texts.append(own_cm.content or "")
    blob = " ".join(own_texts).lower()
    pos_hits = sum(blob.count(w) for w in POSITIVE_WORDS)
    neg_hits = sum(blob.count(w) for w in NEGATIVE_WORDS)

    # ── Segments: top interests + activity level + heavy-video flag ──
    ranked = sorted(interest_scores.items(), key=lambda x: -x[1])
    segments = [seg for seg, _ in ranked[:3]]
    if pos_hits + neg_hits >= 3:
        if neg_hits > pos_hits * 2:
            segments.append("mood_low")
        elif pos_hits > neg_hits:
            segments.append("mood_positive")
    if total_signal >= 150:
        segments.append("high_activity")
    elif total_signal >= 40:
        segments.append("medium_activity")
    else:
        segments.append("low_activity")
    if video_signal >= total_signal * 0.4 and video_signal > 0:
        segments.append("video_lover")

    # ── Gender affinity (share of engagement on male/female creators) ──
    g_total = gender_units["male"] + gender_units["female"]
    gender_affinity = {}
    if g_total > 0:
        gender_affinity = {
            "male": round(gender_units["male"] / g_total * 100),
            "female": round(gender_units["female"] / g_total * 100),
        }

    profile, _ = UserAdProfile.objects.get_or_create(user=user)
    profile.interest_scores = interest_scores
    profile.segments = segments
    profile.gender_affinity = gender_affinity
    profile.brain_built_at = timezone.now()
    profile.save(
        update_fields=[
            "interest_scores", "segments", "gender_affinity",
            "brain_built_at", "updated_at",
        ]
    )
    return {
        "interest_scores": interest_scores,
        "segments": segments,
        "gender_affinity": gender_affinity,
    }


def active_user_ids(days=LOOKBACK_DAYS):
    """Users worth profiling: anyone with BN activity in the window."""
    from .models import (
        BusinessNetworkMediaView,
        BusinessNetworkPostLike,
        PostSeen,
    )

    since = timezone.now() - timedelta(days=days)
    ids = set()
    ids.update(
        PostSeen.objects.filter(last_seen_at__gte=since)
        .values_list("user_id", flat=True).distinct()
    )
    ids.update(
        BusinessNetworkPostLike.objects.filter(created_at__gte=since)
        .values_list("user_id", flat=True).distinct()
    )
    ids.update(
        BusinessNetworkMediaView.objects.filter(created_at__gte=since)
        .values_list("user_id", flat=True).distinct()
    )
    return ids
