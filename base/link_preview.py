"""Server-side link-preview proxy.

The app used to fetch link metadata itself, which is unreliable: many sites
block non-browser user agents, time out, or (on web) fail CORS. Fetching from
the server with a real browser UA and parsing OpenGraph/Twitter/oEmbed tags is
far more dependable, so every URL a user posts or comments gets a preview.

GET /api/link-preview/?url=<url>  ->  {title, description, image, site_name, url}
"""
import re
from urllib.parse import urljoin, urlparse

import requests
from django.core.cache import cache
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

_CACHE_TTL = 60 * 60 * 6  # 6 hours
_TIMEOUT = 8
_MAX_HTML = 300_000
_UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
)


def _meta(html, key, by_property=True):
    attr = "property" if by_property else "name"
    # <meta property="og:title" content="...">  (either attribute order)
    for pat in (
        rf'<meta[^>]+{attr}=["\']{re.escape(key)}["\'][^>]+content=["\']([^"\']*)["\']',
        rf'<meta[^>]+content=["\']([^"\']*)["\'][^>]+{attr}=["\']{re.escape(key)}["\']',
    ):
        m = re.search(pat, html, re.IGNORECASE)
        if m:
            return m.group(1).strip()
    return None


def _title_tag(html):
    m = re.search(r"<title[^>]*>([\s\S]*?)</title>", html, re.IGNORECASE)
    return m.group(1).strip() if m else None


def _unescape(s):
    if not s or "&" not in s:
        return s
    s = (
        s.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")
        .replace("&quot;", '"').replace("&#39;", "'").replace("&#x27;", "'")
        .replace("&nbsp;", " ")
    )
    s = re.sub(r"&#(\d+);", lambda m: chr(int(m.group(1))), s)
    s = re.sub(r"&#x([0-9a-fA-F]+);", lambda m: chr(int(m.group(1), 16)), s)
    return s.strip()


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def link_preview(request):
    raw = (request.query_params.get("url") or "").strip()
    if not raw:
        return Response({"error": "url required"}, status=400)
    if not raw.startswith(("http://", "https://")):
        raw = "https://" + raw

    parsed = urlparse(raw)
    if parsed.scheme not in ("http", "https") or not parsed.netloc:
        return Response({"error": "invalid url"}, status=400)

    cache_key = f"linkprev:{raw}"
    cached = cache.get(cache_key)
    if cached is not None:
        return Response(cached)

    domain = parsed.netloc
    # A favicon we can always show, even when the page itself blocks scraping
    # (Cloudflare "Just a moment…", bot walls, etc.) — Google's favicon service.
    favicon = f"https://www.google.com/s2/favicons?domain={domain}&sz=128"

    title = description = image = None
    site_name = domain
    is_blocked = False
    try:
        resp = requests.get(
            raw,
            headers={"User-Agent": _UA, "Accept": "text/html,application/xhtml+xml"},
            timeout=_TIMEOUT,
            allow_redirects=True,
        )
        html = resp.text[:_MAX_HTML]

        title = (
            _meta(html, "og:title") or _meta(html, "twitter:title", False)
            or _title_tag(html)
        )
        description = (
            _meta(html, "og:description")
            or _meta(html, "twitter:description", False)
            or _meta(html, "description", False)
        )
        image = _meta(html, "og:image") or _meta(html, "twitter:image", False)
        site_name = _meta(html, "og:site_name") or domain

        # Detect an anti-bot interstitial or login wall so we don't show its
        # junk title (Facebook/Instagram serve "log in or sign up" pages to
        # non-browser fetches — that text is not the link's real preview).
        low = f"{title or ''} {description or ''}".lower()
        if any(m in low for m in (
            "just a moment", "attention required", "access denied",
            "are you a robot", "log in or sign up", "log into facebook",
            "log in to facebook", "you must log in",
            "content isn't available", "this page isn't available",
            "page not found", "login • instagram",
        )):
            is_blocked = True
            title = description = image = None

        if image:
            image = _unescape(image)
            if not image.startswith(("http://", "https://")):
                image = urljoin(raw, image)
    except Exception:
        is_blocked = True

    data = {
        "url": raw,
        "title": _unescape(title) if title else None,
        "description": _unescape(description) if description else None,
        "image": image,
        # Always present, so the app can render at least a compact link card.
        "site_name": _unescape(site_name) if site_name else domain,
        "favicon": favicon,
    }
    # Cache real results long; blocked/minimal ones only briefly (they may
    # start working, e.g. transient Cloudflare challenge).
    cache.set(cache_key, data, 60 * 10 if is_blocked else _CACHE_TTL)
    return Response(data)
