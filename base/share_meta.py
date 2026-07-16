"""Crawler-facing share previews.

The adsyclub.com frontend is a client-rendered SPA (`ssr: false`), so link
scrapers (Facebook, WhatsApp, Telegram, Twitter, Google) receive an empty HTML
shell — every shared link previews as the same generic card and Google indexes
nothing meaningful.

This view returns a small server-rendered HTML page carrying the RIGHT
OpenGraph/Twitter meta + JSON-LD structured data for whatever the shared URL
points at: a Business Network post, a news story, a product, or a profile.

It is meant to be served ONLY to bots via an nginx user-agent rule (humans keep
getting the SPA) — see docs/share-meta-nginx.md. It also works directly:
GET /api/share-meta/?u=/business-network/posts/<slug>
"""
import json
import re

from django.http import HttpResponse
from django.utils.html import escape

SITE = "https://adsyclub.com"
SITE_NAME = "AdsyClub"
DEFAULT_IMAGE = f"{SITE}/static/logo-share.png"
DEFAULT_DESC = (
    "AdsyClub — বাংলাদেশের নিজস্ব সোশ্যাল বিজনেস প্ল্যাটফর্ম। পোস্ট, নিউজ, "
    "মাইক্রো গিগ, ই-শপ ও আরও অনেক কিছু।"
)


def _abs_media(url):
    if not url:
        return DEFAULT_IMAGE
    url = str(url)
    if url.startswith("http"):
        return url
    return f"{SITE}{url if url.startswith('/') else '/' + url}"


def _strip_html(text, limit=200):
    text = re.sub(r"<[^>]+>", " ", text or "")
    text = re.sub(r"\s+", " ", text).strip()
    return (text[: limit - 1] + "…") if len(text) > limit else text


def _bn_post(ident):
    from business_network.models import BusinessNetworkPost

    post = (
        BusinessNetworkPost.objects.filter(slug=ident).first()
        or (BusinessNetworkPost.objects.filter(id=ident).first()
            if ident.isdigit() else None)
    )
    if post is None or post.is_banned or post.visibility != "public":
        return None
    author = getattr(post.author, "name", "") or "AdsyClub Member"
    media = post.media.filter(type="image").first()
    image = _abs_media(getattr(getattr(media, "image", None), "url", None))
    desc = _strip_html(post.content) or f"{author} এর পোস্ট — AdsyClub Business Network"
    return {
        "title": f"{author} — Business Network",
        "description": desc,
        "image": image,
        "type": "article",
        "jsonld": {
            "@context": "https://schema.org",
            "@type": "SocialMediaPosting",
            "headline": desc[:110],
            "author": {"@type": "Person", "name": author},
            "datePublished": post.created_at.isoformat(),
            "image": image,
        },
    }


def _news(ident):
    from news.models import NewsPost

    story = (
        NewsPost.objects.filter(slug=ident).first()
        or NewsPost.objects.filter(id=ident).first()
    )
    if story is None:
        return None
    image = _abs_media(getattr(story.image, "url", None))
    desc = _strip_html(story.content)
    return {
        "title": story.title,
        "description": desc,
        "image": image,
        "type": "article",
        "jsonld": {
            "@context": "https://schema.org",
            "@type": "NewsArticle",
            "headline": story.title,
            "image": [image],
            "datePublished": story.created_at.isoformat(),
            "dateModified": story.updated_at.isoformat(),
            "publisher": {"@type": "Organization", "name": SITE_NAME},
        },
    }


def _product(ident):
    from base.models import Product

    product = (
        Product.objects.filter(slug=ident).first()
        or Product.objects.filter(id=ident).first()
    )
    if product is None:
        return None
    media = product.image.first()
    image = _abs_media(getattr(getattr(media, "image", None), "url", None))
    desc = _strip_html(product.short_description or product.description)
    price = getattr(product, "sale_price", None) or getattr(
        product, "regular_price", None
    )
    jsonld = {
        "@context": "https://schema.org",
        "@type": "Product",
        "name": product.name,
        "image": [image],
        "description": desc,
    }
    if price:
        jsonld["offers"] = {
            "@type": "Offer",
            "priceCurrency": "BDT",
            "price": str(price),
            "availability": "https://schema.org/InStock",
        }
    return {
        "title": product.name,
        "description": desc or f"{product.name} — AdsyClub eShop",
        "image": image,
        "type": "product",
        "jsonld": jsonld,
    }


def _profile(ident):
    from django.contrib.auth import get_user_model

    User = get_user_model()
    user = User.objects.filter(id=ident).first()
    if user is None:
        return None
    name = getattr(user, "name", "") or user.username or "AdsyClub Member"
    image = _abs_media(getattr(getattr(user, "image", None), "url", None))
    profession = getattr(user, "profession", "") or ""
    desc = (
        f"{name} — {profession} | AdsyClub Business Network profile"
        if profession
        else f"{name} — AdsyClub Business Network profile"
    )
    return {
        "title": name,
        "description": desc,
        "image": image,
        "type": "profile",
        "jsonld": {
            "@context": "https://schema.org",
            "@type": "ProfilePage",
            "mainEntity": {"@type": "Person", "name": name, "image": image},
        },
    }


# URL-path → resolver. Order matters: first match wins.
_ROUTES = [
    (re.compile(r"^/business-network/posts/([^/?#]+)"), _bn_post),
    (re.compile(r"^/adsy-news/([^/?#]+)"), _news),
    (re.compile(r"^/product-details/([^/?#]+)"), _product),
    (re.compile(r"^/business-network/profile/([^/?#]+)"), _profile),
]

_TEMPLATE = """<!DOCTYPE html>
<html lang="bn">
<head>
<meta charset="utf-8">
<title>{title} | {site}</title>
<link rel="canonical" href="{url}">
<meta name="description" content="{description}">
<meta property="og:site_name" content="{site}">
<meta property="og:type" content="{type}">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{description}">
<meta property="og:image" content="{image}">
<meta property="og:url" content="{url}">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="{title}">
<meta name="twitter:description" content="{description}">
<meta name="twitter:image" content="{image}">
<script type="application/ld+json">{jsonld}</script>
</head>
<body>
<h1>{title}</h1>
<p>{description}</p>
<img src="{image}" alt="{title}">
<a href="{url}">{url}</a>
</body>
</html>"""


def share_meta(request):
    """GET /api/share-meta/?u=<original request path>."""
    path = request.GET.get("u") or "/"
    # Guard against absolute URLs being passed in.
    path = re.sub(r"^https?://[^/]+", "", path)

    meta = None
    for pattern, resolver in _ROUTES:
        m = pattern.match(path)
        if m:
            try:
                meta = resolver(m.group(1))
            except Exception:
                meta = None
            break

    if meta is None:
        meta = {
            "title": SITE_NAME,
            "description": DEFAULT_DESC,
            "image": DEFAULT_IMAGE,
            "type": "website",
            "jsonld": {
                "@context": "https://schema.org",
                "@type": "WebSite",
                "name": SITE_NAME,
                "url": SITE,
            },
        }

    html = _TEMPLATE.format(
        site=SITE_NAME,
        url=escape(f"{SITE}{path}"),
        title=escape(meta["title"]),
        description=escape(meta["description"]),
        image=escape(meta["image"]),
        type=meta["type"],
        jsonld=json.dumps(meta["jsonld"], ensure_ascii=False),
    )
    return HttpResponse(html, content_type="text/html; charset=utf-8")
