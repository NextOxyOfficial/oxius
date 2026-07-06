"""Recompress existing media (Cloudflare R2 in production, or local disk) so the
live app loads faster — WITHOUT changing any object keys, so every existing URL
keeps working.

What it does per image:
  * downscales anything larger than --max-dim on its longest side
  * re-encodes JPEG at --quality (progressive, optimized)
  * re-optimizes PNG; with --png-to-jpeg, opaque PNG photos are re-encoded as
    JPEG bytes written back to the SAME .png key (served with
    Content-Type: image/jpeg — browsers/apps render by content-type, so URLs
    stay valid). PNGs with transparency are always left as PNG.
  * only writes back when the new file is meaningfully smaller

Storage backend is auto-detected: if CLOUDFLARE_R2_MEDIA_ENABLED is on it talks
to R2 over the S3 API; otherwise it walks MEDIA_ROOT on local disk.

Examples
--------
  # See what WOULD change (nothing is written):
  python manage.py compress_media --dry-run

  # Safe default pass (keeps PNG as PNG):
  python manage.py compress_media

  # Aggressive pass — also converts opaque photo-PNGs to JPEG bytes:
  python manage.py compress_media --png-to-jpeg

  # Limit / scope while testing:
  python manage.py compress_media --dry-run --limit 50 --prefix sale_posts_images/
"""
from __future__ import annotations

import io
import os

from django.conf import settings
from django.core.management.base import BaseCommand

try:
    from PIL import Image, ImageOps
except ImportError:  # pragma: no cover
    Image = None

IMAGE_EXTS = {"jpg", "jpeg", "png"}
CACHE_CONTROL = "public, max-age=31536000, immutable"


class Command(BaseCommand):
    help = "Recompress existing media (R2 or local) in place to speed up the app."

    def add_arguments(self, parser):
        parser.add_argument("--dry-run", action="store_true",
                            help="Report savings but write nothing.")
        parser.add_argument("--min-kb", type=int, default=120,
                            help="Skip files smaller than this (default 120).")
        parser.add_argument("--max-dim", type=int, default=1600,
                            help="Cap the longest side to this many px (default 1600).")
        parser.add_argument("--quality", type=int, default=72,
                            help="JPEG quality 1-95 (default 72).")
        parser.add_argument("--png-to-jpeg", action="store_true",
                            help="Re-encode opaque PNG photos as JPEG (same key).")
        parser.add_argument("--limit", type=int, default=0,
                            help="Process at most N images (0 = all).")
        parser.add_argument("--prefix", default="",
                            help="Only process keys/paths under this prefix.")
        parser.add_argument("--min-gain", type=float, default=0.05,
                            help="Only rewrite if it shrinks by at least this "
                                 "fraction (default 0.05 = 5%%).")

    # ── backend selection ───────────────────────────────────────────────────
    def handle(self, *args, **opts):
        if Image is None:
            self.stderr.write(self.style.ERROR("Pillow is not installed."))
            return

        self.opts = opts
        self.dry = opts["dry_run"]
        self.min_bytes = opts["min_kb"] * 1024
        self.is_r2 = bool(getattr(settings, "CLOUDFLARE_R2_MEDIA_ENABLED", False))

        backend = "Cloudflare R2" if self.is_r2 else f"local disk ({settings.MEDIA_ROOT})"
        mode = "DRY RUN (no writes)" if self.dry else "LIVE (writing changes)"
        self.stdout.write(self.style.WARNING(
            f"Media compression - backend: {backend} - {mode}"))
        if opts["png_to_jpeg"]:
            self.stdout.write("  png-to-jpeg: ON (opaque PNGs become JPEG bytes)")

        if self.is_r2:
            self._init_r2()
            entries = self._iter_r2(opts["prefix"])
        else:
            entries = self._iter_local(opts["prefix"])

        seen = touched = 0
        total_old = total_new = 0
        limit = opts["limit"]

        for key, size in entries:
            ext = key.rsplit(".", 1)[-1].lower() if "." in key else ""
            if ext not in IMAGE_EXTS:
                continue
            if size < self.min_bytes:
                continue
            seen += 1
            try:
                result = self._process(key, size)
            except Exception as e:  # never let one bad file stop the run
                self.stderr.write(f"  ! {key}: {e}")
                continue
            if result:
                old, new = result
                total_old += old
                total_new += new
                touched += 1
                pct = (100 * new // old) if old else 100
                self.stdout.write(
                    f"  {'[dry]' if self.dry else '[ok]'} {old // 1024:5}KB -> "
                    f"{new // 1024:5}KB ({pct:3}%)  {key}")
            if limit and touched >= limit:
                break

        saved = total_old - total_new
        self.stdout.write(self.style.SUCCESS(
            f"\nScanned {seen} eligible image(s); "
            f"{'would compress' if self.dry else 'compressed'} {touched}.\n"
            f"Total: {total_old // 1024}KB -> {total_new // 1024}KB "
            f"({saved // 1024}KB saved"
            f"{f', {100 * saved // total_old}%' if total_old else ''})."))
        if self.dry:
            self.stdout.write("Re-run without --dry-run to apply.")
        elif self.is_r2 and touched:
            self.stdout.write(
                "Tip: purge the Cloudflare cache for media.adsyclub.com so the "
                "edge serves the smaller files immediately.")

    # ── R2 backend ──────────────────────────────────────────────────────────
    def _init_r2(self):
        import boto3
        from botocore.config import Config

        self.bucket = settings.AWS_STORAGE_BUCKET_NAME
        self.s3 = boto3.client(
            "s3",
            endpoint_url=settings.AWS_S3_ENDPOINT_URL,
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
            region_name=getattr(settings, "AWS_S3_REGION_NAME", "auto"),
            config=Config(signature_version="s3v4"),
        )

    def _iter_r2(self, prefix):
        paginator = self.s3.get_paginator("list_objects_v2")
        for page in paginator.paginate(Bucket=self.bucket, Prefix=prefix or ""):
            for obj in page.get("Contents", []):
                yield obj["Key"], obj["Size"]

    def _read_r2(self, key):
        return self.s3.get_object(Bucket=self.bucket, Key=key)["Body"].read()

    def _write_r2(self, key, data, content_type):
        self.s3.put_object(
            Bucket=self.bucket, Key=key, Body=data,
            ContentType=content_type, CacheControl=CACHE_CONTROL)

    # ── local backend ───────────────────────────────────────────────────────
    def _iter_local(self, prefix):
        root = settings.MEDIA_ROOT
        for dirpath, _dirs, files in os.walk(root):
            for name in files:
                full = os.path.join(dirpath, name)
                key = os.path.relpath(full, root).replace(os.sep, "/")
                if prefix and not key.startswith(prefix):
                    continue
                try:
                    yield key, os.path.getsize(full)
                except OSError:
                    continue

    def _read_local(self, key):
        with open(os.path.join(settings.MEDIA_ROOT, key), "rb") as f:
            return f.read()

    def _write_local(self, key, data, content_type):
        with open(os.path.join(settings.MEDIA_ROOT, key), "wb") as f:
            f.write(data)

    # ── core ────────────────────────────────────────────────────────────────
    def _process(self, key, size):
        data = self._read_r2(key) if self.is_r2 else self._read_local(key)
        ext = key.rsplit(".", 1)[-1].lower()
        new_data, content_type = self._recompress(data, ext)
        if new_data is None:
            return None
        old = len(data)
        new = len(new_data)
        if new >= old * (1 - self.opts["min_gain"]):
            return None  # not worth the churn
        if not self.dry:
            if self.is_r2:
                self._write_r2(key, new_data, content_type)
            else:
                self._write_local(key, new_data, content_type)
        return old, new

    def _recompress(self, data, ext):
        im = Image.open(io.BytesIO(data))

        # Skip animated images (multi-frame GIF/PNG) — recompress would flatten.
        if getattr(im, "is_animated", False):
            return None, None

        im = ImageOps.exif_transpose(im)  # bake orientation, drop EXIF bloat
        max_dim = self.opts["max_dim"]
        if max(im.size) > max_dim:
            im.thumbnail((max_dim, max_dim), Image.LANCZOS)

        out = io.BytesIO()
        has_alpha = im.mode in ("RGBA", "LA") or (
            im.mode == "P" and "transparency" in im.info)

        if ext in ("jpg", "jpeg"):
            im.convert("RGB").save(
                out, "JPEG", quality=self.opts["quality"],
                optimize=True, progressive=True)
            return out.getvalue(), "image/jpeg"

        # PNG
        if self.opts["png_to_jpeg"] and not has_alpha:
            # Opaque PNG (usually a photo/banner) → JPEG bytes, same .png key.
            im.convert("RGB").save(
                out, "JPEG", quality=max(self.opts["quality"], 80),
                optimize=True, progressive=True)
            return out.getvalue(), "image/jpeg"

        if im.mode == "P":
            im = im.convert("RGBA" if has_alpha else "RGB")
        im.save(out, "PNG", optimize=True)
        return out.getvalue(), "image/png"
