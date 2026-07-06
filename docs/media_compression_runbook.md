# Speeding up media on production (Cloudflare R2)

Production serves user media from a Cloudflare R2 bucket on
`https://media.adsyclub.com/…`. Photos uploaded before app-side compression was
added are large and slow the app down. This runbook shrinks them **in place**
(same object keys → every existing URL keeps working) and lists the Cloudflare
dashboard switches that give extra, zero-code wins.

## A. Re-compress existing files (run once on the server)

A management command, `compress_media`, walks the R2 bucket, downscales +
re-encodes each image, and writes the smaller version back to the **same key**.
It auto-detects R2 from `CLOUDFLARE_R2_MEDIA_ENABLED`; on a dev box with local
media it compresses `MEDIA_ROOT` instead.

```bash
cd /home/django/adsyclub
source /home/django/venv/bin/activate
git pull origin main            # gets the command

# 1) See what WOULD change — writes nothing:
python manage.py compress_media --dry-run --png-to-jpeg

# 2) Apply it:
python manage.py compress_media --png-to-jpeg
```

Flags:

| Flag | Default | Meaning |
|------|---------|---------|
| `--dry-run` | off | Report savings, write nothing. |
| `--png-to-jpeg` | off | Re-encode **opaque** photo-PNGs as JPEG bytes on the same `.png` key (served as `image/jpeg`). Biggest win for photos saved as PNG. PNGs with transparency (logos) are never touched this way. |
| `--min-kb` | 120 | Skip files already smaller than this. |
| `--max-dim` | 1600 | Cap the longest side to this many pixels. |
| `--quality` | 72 | JPEG quality. |
| `--prefix p/` | — | Only process keys under a prefix (e.g. `sale_posts_images/`). |
| `--limit N` | 0 | Stop after N images (handy for a first cautious pass). |

Safe by design: it never renames/deletes objects, skips animated images, keeps
transparency, only rewrites when the file actually shrinks (≥5 %), and continues
past any single bad file. Newly written objects get
`Cache-Control: public, max-age=31536000, immutable`.

Cautious first run:

```bash
python manage.py compress_media --png-to-jpeg --limit 30
# spot-check a few images in the app, then run the full pass.
```

After the full run, **purge the Cloudflare cache** for `media.adsyclub.com`
(Dashboard → Caching → Configuration → Purge Everything, or purge by hostname)
so the edge serves the smaller files immediately instead of the cached originals.

## B. Cloudflare dashboard wins (no re-upload, apply to everything)

1. **Polish** (Speed → Optimization → Image Optimization, needs Pro): set to
   **Lossy** and enable **WebP** — Cloudflare then recompresses and serves WebP
   at the edge automatically for every image.
2. **Brotli** (Speed → Optimization → Content Optimization): ON — smaller
   HTML/JS/CSS for the Nuxt frontend.
3. **Caching for `media.adsyclub.com`**: a Cache Rule with **Eligible for cache
   = Edge TTL a month+**. R2 custom domains are cacheable; long TTL means images
   are served from the nearest edge, not fetched from R2 each time.
4. **Tiered Cache** (Caching → Tiered Cache): ON — fewer origin fetches.

## C. Keep it from happening again

New uploads from the app are already compressed client-side (the Flutter
`ImageCompressor`, ~80 KB target, wired into every upload screen). So this
backfill only needs to run once; re-run it occasionally if a batch of large
files gets in through the admin.
