const TTL_MS = 6 * 60 * 60 * 1000;

const cache = new Map();
const inflight = new Map();

export const useLinkPreview = () => {

  const urlRegex = /((?:https?:\/\/)?(?:www\.)?(?:localhost|(?:\d{1,3}\.){3}\d{1,3}|[A-Za-z0-9\-]+(?:\.[A-Za-z0-9\-]+)+)(?::\d{2,5})?(?:\/[\w\-._~%!$&'()*+,;=:@\/?#\[\]]*)?)/i;

  const stripTrailingPunctuation = (value) => {
    if (!value) return value;
    const trailing = ['.', ',', ';', ':', ')', ']', '}', '"', "'"];
    let v = value;
    while (v.length > 0) {
      const last = v[v.length - 1];
      if (!trailing.includes(last)) break;
      v = v.slice(0, -1);
    }
    return v;
  };

  const isLocalNetworkHost = (host) => {
    const h = (host || '').toLowerCase();
    if (h === 'localhost' || h === '127.0.0.1' || h === '0.0.0.0') return true;
    if (h.startsWith('10.')) return true;
    if (h.startsWith('192.168.')) return true;
    const m = /^172\.(\d{1,2})\./.exec(h);
    if (m) {
      const n = Number.parseInt(m[1] || '', 10);
      if (!Number.isNaN(n) && n >= 16 && n <= 31) return true;
    }
    return false;
  };

  const normalizeUrl = (raw) => {
    const value = (raw || '').trim();
    if (!value) return null;

    const stripped = stripTrailingPunctuation(value);
    if (!stripped) return null;

    if (stripped.startsWith('http://') || stripped.startsWith('https://')) return stripped;
    if (stripped.startsWith('mailto:') || stripped.startsWith('tel:')) return null;

    const host = stripped.split('/')[0];
    const scheme = isLocalNetworkHost(host) ? 'http' : 'https';
    return `${scheme}://${stripped}`;
  };

  const extractFirstUrl = (text) => {
    if (!text) return null;
    const match = urlRegex.exec(text);
    if (!match) return null;
    const raw = (match[1] || match[0] || '').trim();
    if (!raw) return null;
    return stripTrailingPunctuation(raw);
  };

  const extractTitle = (html) => {
    const m = /<title[^>]*>([\s\S]*?)<\/title>/i.exec(html);
    return m ? m[1] : null;
  };

  const extractAttr = (tag, attr) => {
    const re = new RegExp(`${attr.replace(/[.*+?^${}()|[\\]\\]/g, '\\$&')}\\s*=\\s*("([^"]*)"|'([^']*)'|([^\\s>]+))`, 'i');
    const m = re.exec(tag);
    if (!m) return null;
    return m[2] || m[3] || m[4] || null;
  };

  const extractMeta = (html, key, byProperty) => {
    const tags = html.match(/<meta\s+[^>]*>/gi) || [];
    const attr = byProperty ? 'property' : 'name';

    for (const tag of tags) {
      const name = extractAttr(tag, attr);
      if (!name) continue;
      if (name.toLowerCase() !== String(key).toLowerCase()) continue;

      const content = extractAttr(tag, 'content');
      if (content && content.trim()) return content;
    }

    if (!byProperty) {
      for (const tag of tags) {
        const name = extractAttr(tag, 'property');
        if (!name) continue;
        if (name.toLowerCase() !== String(key).toLowerCase()) continue;

        const content = extractAttr(tag, 'content');
        if (content && content.trim()) return content;
      }
    }

    return null;
  };

  const extractFavicon = (html) => {
    const tags = html.match(/<link\s+[^>]*>/gi) || [];
    for (const tag of tags) {
      const rel = (extractAttr(tag, 'rel') || '').toLowerCase();
      if (!rel) continue;
      if (!rel.includes('icon')) continue;

      const href = extractAttr(tag, 'href');
      if (href && href.trim()) return href;
    }
    return null;
  };

  const resolveAgainst = (baseUrl, maybeUrl) => {
    if (!maybeUrl) return null;
    const v = String(maybeUrl).trim();
    if (!v) return null;

    try {
      return new URL(v, baseUrl).toString();
    } catch (_) {
      return null;
    }
  };

  const clean = (value) => {
    if (value == null) return null;
    const v = String(value).trim();
    return v ? v : null;
  };

  const buildFetchUrls = (normalizedUrl) => {
    const base = normalizedUrl;

    try {
      const u = new URL(normalizedUrl);
      if (isLocalNetworkHost(u.hostname)) {
        return [base];
      }
    } catch (_) {
      return [base];
    }

    return [
      `https://api.allorigins.win/raw?url=${encodeURIComponent(base)}`,
      `https://r.jina.ai/${base}`,
    ];
  };

  const fetchHtml = async (url) => {
    return await $fetch(url, {
      responseType: 'text',
      timeout: 7000,
      headers: {
        Accept: 'text/html,application/xhtml+xml',
      },
    });
  };

  const getPreview = async (rawUrl) => {
    const normalized = normalizeUrl(rawUrl);
    if (!normalized) return null;

    const cached = cache.get(normalized);
    if (cached && Date.now() - cached.at < TTL_MS) {
      if (import.meta.dev && cached.data == null) {
      } else {
        return cached.data;
      }
    }

    const inFlightExisting = inflight.get(normalized);
    if (inFlightExisting) return inFlightExisting;

    const promise = (async () => {
      try {
        const fetchUrls = buildFetchUrls(normalized);

        for (const fetchUrl of fetchUrls) {
          try {
            const html = await fetchHtml(fetchUrl);
            if (!html || typeof html !== 'string') continue;

            const ogTitle = extractMeta(html, 'og:title', true);
            const ogDesc = extractMeta(html, 'og:description', true);
            const ogImage = extractMeta(html, 'og:image', true);
            const ogSite = extractMeta(html, 'og:site_name', true);

            const twTitle = extractMeta(html, 'twitter:title', false);
            const twDesc = extractMeta(html, 'twitter:description', false);
            const twImage = extractMeta(html, 'twitter:image', false);

            const title = ogTitle || twTitle || extractTitle(html);
            const description = ogDesc || twDesc || extractMeta(html, 'description', false);
            const image = ogImage || twImage;
            const favicon = extractFavicon(html);

            const resolvedImage = resolveAgainst(normalized, image);
            const resolvedFavicon = resolveAgainst(normalized, favicon);

            const data = {
              url: normalized,
              title: clean(title),
              description: clean(description),
              imageUrl: clean(resolvedImage),
              siteName: clean(ogSite) || (() => {
                try {
                  return new URL(normalized).hostname;
                } catch (_) {
                  return null;
                }
              })(),
              faviconUrl: clean(resolvedFavicon),
            };

            const hasAny =
              (data.title && data.title.trim()) ||
              (data.description && data.description.trim()) ||
              (data.imageUrl && data.imageUrl.trim());

            const finalData = hasAny ? data : null;
            cache.set(normalized, { at: Date.now(), data: finalData });
            return finalData;
          } catch (e) {
            if (import.meta.dev) {
              console.debug('Link preview fetch failed:', normalized, 'via', fetchUrl, e);
            }
          }
        }

        cache.set(normalized, { at: Date.now(), data: null });
        return null;
      } finally {
        inflight.delete(normalized);
      }
    })();

    inflight.set(normalized, promise);
    return promise;
  };

  return {
    extractFirstUrl,
    normalizeUrl,
    getPreview,
  };
};
