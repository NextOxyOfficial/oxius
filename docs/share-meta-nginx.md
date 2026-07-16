# Share previews for bots (OG tags + Google structured data)

The frontend is a client-rendered SPA, so link scrapers see an empty shell.
`GET /api/share-meta/?u=<path>` (base/share_meta.py) returns bot-facing HTML
with the right OpenGraph/Twitter meta + JSON-LD for:

- `/business-network/posts/<slug|id>` → post text + first photo + author
- `/adsy-news/<slug|id>`             → NewsArticle (headline, image, dates)
- `/product-details/<slug|id>`       → Product (image, price offer, description)
- `/business-network/profile/<id>`   → ProfilePage (name, avatar, profession)
- anything else                      → site default card

## Activation (one-time nginx change, needs sudo)

In the adsyclub.com server block, ABOVE the SPA location:

```nginx
# Send link-preview crawlers to the Django share-meta renderer.
map $http_user_agent $is_share_bot {
    default 0;
    ~*(facebookexternalhit|facebot|twitterbot|whatsapp|telegrambot|linkedinbot|slackbot|discordbot|pinterest|googlebot|bingbot|applebot) 1;
}

server {
    ...
    location / {
        if ($is_share_bot) {
            rewrite ^ /api/share-meta/?u=$uri last;
        }
        # existing SPA config continues below
        ...
    }
}
```

Then `sudo nginx -t && sudo systemctl reload nginx`.

## Verify

```bash
curl -A "facebookexternalhit/1.1" https://adsyclub.com/adsy-news/<any-slug> | head -30
```

should print HTML containing `og:image` for that story. Also re-scrape a link
at https://developers.facebook.com/tools/debug/ and test rich results at
https://search.google.com/test/rich-results.

Note: `DEFAULT_IMAGE` points at `/static/logo-share.png` — drop a 1200x630
branded PNG there (or change the constant in base/share_meta.py).
