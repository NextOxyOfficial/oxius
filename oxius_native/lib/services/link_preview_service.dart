import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
            print('LinkPreviewService non-2xx (${res.statusCode}) for $url via $fetchUri');
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

        final resolvedImage = _resolveAgainst(uri, image);
        final resolvedFavicon = _resolveAgainst(uri, favicon);

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
        print('LinkPreviewService failed for $url: $e');
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

    return const {
      'User-Agent': 'Mozilla/5.0',
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
    final v = value.trim();
    if (v.isEmpty) return null;
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
