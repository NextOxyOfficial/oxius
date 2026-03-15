"""
Management command to regenerate missing video thumbnails for BusinessNetworkMedia.

Usage:
    python manage.py regenerate_video_thumbnails          # Process all videos without thumbnails
    python manage.py regenerate_video_thumbnails --force   # Regenerate ALL video thumbnails (even existing)
    python manage.py regenerate_video_thumbnails --dry-run  # Show what would be processed without doing anything
"""
from django.core.management.base import BaseCommand
from business_network.models import BusinessNetworkMedia


class Command(BaseCommand):
    help = "Regenerate missing video thumbnails for BusinessNetworkMedia entries"

    def add_arguments(self, parser):
        parser.add_argument(
            "--force",
            action="store_true",
            help="Regenerate thumbnails even for videos that already have one",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Only show what would be processed, don't actually generate",
        )

    def handle(self, *args, **options):
        force = options["force"]
        dry_run = options["dry_run"]

        queryset = BusinessNetworkMedia.objects.filter(type="video").exclude(video="").exclude(video__isnull=True)

        if not force:
            queryset = queryset.filter(thumbnail__isnull=True) | queryset.filter(thumbnail="")
            # Deduplicate
            queryset = queryset.distinct()

        total = queryset.count()
        self.stdout.write(f"Found {total} video(s) to process.")

        if dry_run:
            for media in queryset:
                video_name = media.video.name if media.video else "N/A"
                thumb_name = media.thumbnail.name if media.thumbnail else "MISSING"
                self.stdout.write(f"  [DRY-RUN] id={media.id}  video={video_name}  thumbnail={thumb_name}")
            self.stdout.write(self.style.WARNING(f"Dry run complete. {total} video(s) would be processed."))
            return

        success = 0
        failed = 0

        for i, media in enumerate(queryset.iterator(), 1):
            video_name = media.video.name if media.video else "N/A"
            self.stdout.write(f"[{i}/{total}] Processing id={media.id}  video={video_name} ...")

            if force and media.thumbnail:
                # Clear existing thumbnail so ensure_thumbnail will regenerate
                media.thumbnail = None
                media.save(update_fields=["thumbnail"])

            try:
                media.ensure_thumbnail()
                # Reload from DB to check if thumbnail was saved
                media.refresh_from_db()
                if media.thumbnail:
                    self.stdout.write(self.style.SUCCESS(f"  -> OK: {media.thumbnail.name}"))
                    success += 1
                else:
                    self.stdout.write(self.style.ERROR(f"  -> FAILED: no thumbnail generated"))
                    failed += 1
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"  -> ERROR: {e}"))
                failed += 1

        self.stdout.write("")
        self.stdout.write(self.style.SUCCESS(f"Done! Success: {success}, Failed: {failed}, Total: {total}"))
