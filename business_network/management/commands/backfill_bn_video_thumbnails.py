"""Generate the missing poster frames for Business Network videos.

Thumbnail generation had always gone through `media.video.path`, which this
project's storage backend refuses, so NOT ONE video in the database had a
thumbnail — and a video shown as a grid tile (any post with more than one
media item) rendered as a blank box. This fills in the backlog; new uploads
queue the same work on commit.

    python manage.py backfill_bn_video_thumbnails             # missing only
    python manage.py backfill_bn_video_thumbnails --limit 50
    python manage.py backfill_bn_video_thumbnails --force     # redo all
    python manage.py backfill_bn_video_thumbnails --dry-run
"""
from django.core.management.base import BaseCommand
from django.db.models import Q

from business_network.models import BusinessNetworkMedia
from business_network.tasks import make_video_thumbnail


class Command(BaseCommand):
    help = "Generate poster frames for BN videos that have none."

    def add_arguments(self, parser):
        parser.add_argument("--limit", type=int, default=0)
        parser.add_argument("--force", action="store_true")
        parser.add_argument("--dry-run", action="store_true")

    def handle(self, *args, **opts):
        qs = BusinessNetworkMedia.objects.filter(type="video").exclude(
            Q(video="") | Q(video__isnull=True)
        )
        if not opts["force"]:
            # Nullable field → legacy rows are NULL, not "". Both mean "none".
            qs = qs.filter(Q(thumbnail="") | Q(thumbnail__isnull=True))
        qs = qs.order_by("-created_at")
        if opts["limit"]:
            qs = qs[: opts["limit"]]

        total = qs.count()
        self.stdout.write(f"{total} video(s) to process")
        if opts["dry_run"]:
            for m in qs:
                self.stdout.write(f"  would process {m.pk} {m.video.name}")
            return

        done = failed = 0
        for media in qs:
            try:
                ok = make_video_thumbnail(media, force=opts["force"])
            except Exception as exc:      # one bad file must not stop the run
                ok = False
                self.stderr.write(f"  {media.pk}: {exc}")
            if ok:
                done += 1
                self.stdout.write(f"  ok {media.pk} -> {media.thumbnail.name}")
            else:
                failed += 1
                self.stdout.write(f"  skip {media.pk}")

        self.stdout.write(self.style.SUCCESS(f"done: {done} generated, {failed} skipped"))
