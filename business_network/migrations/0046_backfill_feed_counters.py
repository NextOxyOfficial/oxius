from django.db import migrations
from django.db.models import Count, Max


def backfill_counters(apps, schema_editor):
    """Populate the denormalized engagement counters from existing rows so the
    new feed ranking has accurate data on day one. From here on the signals in
    business_network/signals.py keep them in sync."""
    BusinessNetworkPost = apps.get_model("business_network", "BusinessNetworkPost")

    posts = BusinessNetworkPost.objects.annotate(
        _lc=Count("post_likes", distinct=True),
        _cc=Count("post_comments", distinct=True),
        _sc=Count("saved_by", distinct=True),
        _last_like=Max("post_likes__created_at"),
        _last_comment=Max("post_comments__created_at"),
    )

    to_update = []
    for p in posts.iterator(chunk_size=500):
        p.like_count = p._lc or 0
        p.comment_count = p._cc or 0
        p.save_count = p._sc or 0
        candidates = [d for d in (p._last_like, p._last_comment) if d]
        p.last_activity_at = max(candidates) if candidates else p.created_at
        to_update.append(p)
        if len(to_update) >= 500:
            BusinessNetworkPost.objects.bulk_update(
                to_update,
                ["like_count", "comment_count", "save_count", "last_activity_at"],
            )
            to_update = []
    if to_update:
        BusinessNetworkPost.objects.bulk_update(
            to_update,
            ["like_count", "comment_count", "save_count", "last_activity_at"],
        )


def noop(apps, schema_editor):
    pass


class Migration(migrations.Migration):

    dependencies = [
        ("business_network", "0045_businessnetworkpost_comment_count_and_more"),
    ]

    operations = [
        migrations.RunPython(backfill_counters, noop),
    ]
