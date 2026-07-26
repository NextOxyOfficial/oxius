"""Backfill: shrink already-uploaded BN videos to 720p.

New uploads are queued automatically; this covers everything from before.
Runs one at a time on purpose — the box has 4 cores and ~2 GB free, and a
parallel sweep would starve gunicorn while users are on the site.
"""

from django.core.management.base import BaseCommand
from django.db.models import Q

from business_network.models import BusinessNetworkMedia
from business_network.tasks import transcode_bn_video


class Command(BaseCommand):
    help = "Re-encode existing BN videos to 720p (skips ones already done)"

    def add_arguments(self, parser):
        parser.add_argument(
            "--limit", type=int, default=0,
            help="Only process N videos (0 = all). Useful for a cautious first run.",
        )
        parser.add_argument(
            "--async", action="store_true", dest="use_async",
            help="Queue through Celery instead of transcoding inline.",
        )

    def handle(self, *args, **opts):
        # video_original was added as a nullable field, so rows that predate it
        # hold NULL rather than "" — filtering on "" alone matched nothing.
        qs = (
            BusinessNetworkMedia.objects.filter(type="video")
            .exclude(video="")
            .exclude(video__isnull=True)
            .filter(Q(video_original="") | Q(video_original__isnull=True))
            .order_by("created_at")
        )
        limit = opts["limit"]
        if limit:
            qs = qs[:limit]

        total = qs.count() if not limit else len(list(qs))
        self.stdout.write(f"{total} video(s) to process")

        for i, media in enumerate(qs, 1):
            if opts["use_async"]:
                transcode_bn_video.delay(media.pk)
                self.stdout.write(f"[{i}/{total}] queued {media.pk}")
                continue
            result = transcode_bn_video(media.pk)
            self.stdout.write(f"[{i}/{total}] {media.pk}: {result}")

        self.stdout.write(self.style.SUCCESS("done"))
