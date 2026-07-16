import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';

class LinkPreviewData {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;
  final String? faviconUrl;

  const LinkPreviewData({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
    this.faviconUrl,
  });
}

class LinkPreviewService {
  static const Duration _timeout = Duration(seconds: 7);
  static const Duration _ttl = Duration(hours: 6);

  static const String _webCorsProxyBase = 'https://api.allorigins.win/raw';
  static const String _webCorsProxyFallbackBase = 'https://r.jina.ai';

  static final Map<String, _CacheEntry> _cache = {};
  static final Map<String, Future<LinkPreviewData?>> _inflight = {};

  static Future<LinkPreviewData?> getPreview(String rawUrl) {
    final normalized = _normalizeUrl(rawUrl);
    if (normalized == null) return Future.value(null);

    final cached = _cache[normalized];
    if (cached != null && DateTime.now().difference(cached.at) < _ttl) {
      if (kDebugMode && cached.data == null) {
      } else {
      return Future.value(cached.data);
      }
    }

    final existing = _inflight[normalized];
    if (existing != null) return existing;

    final future = _fetch(normalized).whenComplete(() {
      _inflight.remove(normalized);
    });

    _inflight[normalized] = future;
    return future;
  }

  static Future<LinkPreviewData?> _fetch(String url) async {
    // Prefer the server-side proxy — it uses a real browser UA, follows
    // redirects, and isn't subject to CORS, so it reliably previews sites the
    // client can't fetch (news portals, shops, etc.).
    final server = await _fetchFromServer(url);
    if (server != null) {
      _cache[url] = _CacheEntry(server, DateTime.now());
      return server;
    }
    return _fetchClientSide(url);
  }

  static Future<LinkPreviewData?> _fetchFromServer(String url) async {
    try {
      final headers = await ApiService.getHeaders();
      final res = await http
          .get(
            Uri.parse(
                '${ApiService.baseUrl}/link-preview/?url=${Uri.encodeQueryComponent(url)}'),
            headers: headers,
          )
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final title = (data['title'] ?? '').toString();
      final desc = (data['description'] ?? '').toString();
      final image = (data['image'] ?? '').toString();
      if (title.isEmpty && desc.isEmpty && image.isEmpty) return null;
      return LinkPreviewData(
        url: url,
        title: title.isEmpty ? null : title,
        description: desc.isEmpty ? null : desc,
        imageUrl: image.isEmpty ? null : image,
        siteName: (data['site_name'] ?? '').toString().isEmpty
            ? Uri.parse(url).host
            : data['site_name'].toString(),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('server link-preview failed: $e');
      return null;
    }
  }

  static Future<LinkPreviewData?> _fetchClientSide(String url) async {
    try {
      final uri = Uri.parse(url);
      final headers = _buildHeaders();

      for (final fetchUri in _buildFetchUris(uri)) {
        final res = await http
            .get(
              fetchUri,
              headers: headers,
            )
            .timeout(_timeout);

        if (res.statusCode < 200 || res.statusCode >= 300) {
          if (kDebugMode) {
            debugPrint('LinkPreviewService non-2xx (${res.statusCode}) for $url via $fetchUri');
          }
          continue;
        }

        var html = res.body;
        if (html.length > 250000) {
          html = html.substring(0, 250000);
        }

        final ogTitle = _extractMeta(html, key: 'og:title', byProperty: true);
        final ogDesc = _extractMeta(html, key: 'og:description', byProperty: true);
        final ogImage = _extractMeta(html, key: 'og:image', byProperty: true);
        final ogSite = _extractMeta(html, key: 'og:site_name', byProperty: true);

        final twTitle = _extractMeta(html, key: 'twitter:title', byProperty: false);
        final twDesc = _extractMeta(html, key: 'twitter:description', byProperty: false);
        final twImage = _extractMeta(html, key: 'twitter:image', byProperty: false);

        final title = ogTitle ?? twTitle ?? _extractTitle(html);
        final description = ogDesc ?? twDesc ?? _extractMeta(html, key: 'description', byProperty: false);
        final image = ogImage ?? twImage;
        final favicon = _extractFavicon(html);

        // Unescape BEFORE resolving: Uri.parse on an entity-encoded URL
        // ("...?w=1200&amp;sig=x") mangles the query keys.
        final resolvedImage =
            _resolveAgainst(uri, image == null ? null : _htmlUnescape(image));
        final resolvedFavicon = _resolveAgainst(
            uri, favicon == null ? null : _htmlUnescape(favicon));

        final data = LinkPreviewData(
          url: url,
          title: _clean(title),
          description: _clean(description),
          imageUrl: _clean(resolvedImage),
          siteName: _clean(ogSite) ?? uri.host,
          faviconUrl: _clean(resolvedFavicon),
        );

        final hasAny = (data.title != null && data.title!.trim().isNotEmpty) ||
            (data.description != null && data.description!.trim().isNotEmpty) ||
            (data.imageUrl != null && data.imageUrl!.trim().isNotEmpty);

        final finalData = hasAny ? data : null;
        _cache[url] = _CacheEntry(finalData, DateTime.now());
        return finalData;
      }

      _cache[url] = _CacheEntry(null, DateTime.now());
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LinkPreviewService failed for $url: $e');
      }
      _cache[url] = _CacheEntry(null, DateTime.now());
      return null;
    }
  }

  static List<Uri> _buildFetchUris(Uri original) {
    if (!kIsWeb || _isLocalNetworkHost(original.host)) {
      return [original];
    }

    final primary = Uri.parse(_webCorsProxyBase).replace(queryParameters: {
      'url': original.toString(),
    });

    final fallback = Uri.parse('$_webCorsProxyFallbackBase/${original.toString()}');

    return [primary, fallback];
  }

  static bool _isLocalNetworkHost(String host) {
    final h = host.toLowerCase();
    if (h == 'localhost' || h == '127.0.0.1' || h == '0.0.0.0') return true;
    if (h.startsWith('10.')) return true;
    if (h.startsWith('192.168.')) return true;
    final m = RegExp(r'^172\.(\d{1,2})\.').firstMatch(h);
    if (m != null) {
      final n = int.tryParse(m.group(1) ?? '');
      if (n != null && n >= 16 && n <= 31) return true;
    }
    return false;
  }

  static Map<String, String> _buildHeaders() {
    if (kIsWeb) {
      return const {
        'Accept': 'text/html,application/xhtml+xml',
      };
    }

    // A real browser UA — many sites refuse bare 'Mozilla/5.0' or serve a
    // page without OpenGraph tags to unknown agents.
    return const {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) '
              'Chrome/124.0.0.0 Mobile Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml',
    };
  }

  static String? _normalizeUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final stripped = _stripTrailingPunctuation(value);
    if (stripped.isEmpty) return null;

    if (stripped.startsWith('http://') || stripped.startsWith('https://')) {
      return stripped;
    }

    if (stripped.startsWith('mailto:') || stripped.startsWith('tel:')) {
      return null;
    }

    return 'https://$stripped';
  }

  static String _stripTrailingPunctuation(String url) {
    const trailing = ['.', ',', ';', ':', ')', ']', '}', '"', "'"];
    var value = url;
    while (value.isNotEmpty) {
      final last = value[value.length - 1];
      if (!trailing.contains(last)) break;
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  static String? _resolveAgainst(Uri base, String? maybeUrl) {
    if (maybeUrl == null) return null;
    final value = maybeUrl.trim();
    if (value.isEmpty) return null;

    try {
      final uri = Uri.parse(value);
      if (uri.hasScheme) return uri.toString();
      return base.resolveUri(uri).toString();
    } catch (_) {
      return null;
    }
  }

  static String? _clean(String? value) {
    if (value == null) return null;
    final v = _htmlUnescape(value.trim());
    if (v.isEmpty) return null;
    return v;
  }

  /// Decode the HTML entities that appear inside meta-tag attributes. og:image
  /// URLs routinely carry `&amp;` in their query strings (signed CDN URLs);
  /// passing the raw value to Image.network 4xx-es and the preview silently
  /// loses its image while title/description still show.
  static String _htmlUnescape(String value) {
    if (!value.contains('&')) return value;
    var v = value
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&nbsp;', ' ');
    // Numeric entities (&#1234; / &#xA0;).
    v = v.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final code = int.tryParse(m.group(1)!);
      return code == null ? m.group(0)! : String.fromCharCode(code);
    });
    v = v.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
      final code = int.tryParse(m.group(1)!, radix: 16);
      return code == null ? m.group(0)! : String.fromCharCode(code);
    });
    return v;
  }

  static String? _extractTitle(String html) {
    final m = RegExp(r'<title[^>]*>([\s\S]*?)<\/title>', caseSensitive: false).firstMatch(html);
    if (m == null) return null;
    return m.group(1);
  }

  static String? _extractMeta(
    String html, {
    required String key,
    required bool byProperty,
  }) {
    final metaTags = RegExp(r'<meta\s+[^>]*>', caseSensitive: false).allMatches(html);

    for (final m in metaTags) {
      final tag = m.group(0) ?? '';
      final name = _extractAttr(tag, byProperty ? 'property' : 'name');
      if (name == null) continue;
      if (name.toLowerCase() != key.toLowerCase()) continue;

      final content = _extractAttr(tag, 'content');
      if (content != null && content.trim().isNotEmpty) {
        return content;
      }
    }

    if (!byProperty) {
      final metaTags2 = RegExp(r'<meta\s+[^>]*>', caseSensitive: false).allMatches(html);
      for (final m in metaTags2) {
        final tag = m.group(0) ?? '';
        final name = _extractAttr(tag, 'property');
        if (name == null) continue;
        if (name.toLowerCase() != key.toLowerCase()) continue;

        final content = _extractAttr(tag, 'content');
        if (content != null && content.trim().isNotEmpty) {
          return content;
        }
      }
    }

    return null;
  }

  static String? _extractFavicon(String html) {
    final linkTags = RegExp(r'<link\s+[^>]*>', caseSensitive: false).allMatches(html);
    for (final m in linkTags) {
      final tag = m.group(0) ?? '';
      final rel = _extractAttr(tag, 'rel')?.toLowerCase();
      if (rel == null) continue;

      if (rel.contains('icon')) {
        final href = _extractAttr(tag, 'href');
        if (href != null && href.trim().isNotEmpty) return href;
      }
    }
    return null;
  }

  static String? _extractAttr(String tag, String attr) {
    final m = RegExp(
      '${RegExp.escape(attr)}\\s*=\\s*("([^"]*)"|\'([^\']*)\'|([^\\s>]+))',
      caseSensitive: false,
    ).firstMatch(tag);

    if (m == null) return null;
    return m.group(2) ?? m.group(3) ?? m.group(4);
  }
}

class _CacheEntry {
  final LinkPreviewData? data;
  final DateTime at;

  _CacheEntry(this.data, this.at);
}
