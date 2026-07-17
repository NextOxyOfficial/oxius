import 'dart:convert';

/// A compact, self-contained encoding for a "post shared into a chat".
///
/// The AdsyConnect message body is plain text, and the server-side link
/// preview for an adsyclub post only returns the generic site metadata (the
/// real per-post OpenGraph tags are served to bots only). So the sender embeds
/// exactly what the card needs and the recipient renders a minimal card:
/// thumbnail + the post author's name + a short caption.
///
/// ENCODING: `ADSYPOST::<base64(utf8(json))>`.
/// The original format used a raw control char (U+0001) as a field delimiter.
/// That turned out fragile — it got stripped/normalised in transit (some
/// messages arrived with all fields concatenated and no delimiter), which
/// showed garbage like a lone "P"/"0" on the card. base64 is pure ASCII with
/// no delimiter, so it survives JSON, the DB and every app layer intact.
///
/// [tryDecode] still understands the two older formats (control-char and the
/// pre-format "X on Business Network" text) so old chats keep working.
class SharedPostMessage {
  static const String _prefix = 'ADSYPOST';
  static const String _jsonMarker = 'ADSYPOST::';
  static const String _legacySep = '';

  /// The bold headline for the card. For posts this is the author's name.
  final String ownerName;
  final String thumbUrl;
  final String postUrl;

  /// Explicit author name (falls back to [ownerName] when absent).
  final String authorName;

  /// Short post caption/content shown under the name.
  final String caption;

  const SharedPostMessage({
    required this.ownerName,
    required this.thumbUrl,
    required this.postUrl,
    this.authorName = '',
    this.caption = '',
  });

  /// The name to show bold on the card.
  String get displayName => authorName.isNotEmpty ? authorName : ownerName;

  String encode() {
    final json = jsonEncode({
      'n': ownerName,
      't': thumbUrl,
      'u': postUrl,
      'a': authorName,
      'c': _clean(caption),
    });
    return '$_jsonMarker${base64.encode(utf8.encode(json))}';
  }

  static bool isShared(String content) => content.startsWith(_prefix);

  /// Returns null when [content] isn't a shared-post message.
  static SharedPostMessage? tryDecode(String content) {
    // 1) Current robust format: ADSYPOST::<base64 json>
    if (content.startsWith(_jsonMarker)) {
      try {
        final raw = content.substring(_jsonMarker.length).trim();
        final map = jsonDecode(utf8.decode(base64.decode(raw)))
            as Map<String, dynamic>;
        return SharedPostMessage(
          ownerName: (map['n'] ?? '').toString(),
          thumbUrl: (map['t'] ?? '').toString(),
          postUrl: (map['u'] ?? '').toString(),
          authorName: (map['a'] ?? '').toString(),
          caption: (map['c'] ?? '').toString(),
        );
      } catch (_) {
        // Fall through to salvage below.
      }
    }

    // 2) Old control-char format: ADSYPOST<sep>owner<sep>thumb<sep>url[...]
    if (content.startsWith('$_prefix$_legacySep')) {
      final parts = content.split(_legacySep);
      return SharedPostMessage(
        ownerName: parts.length > 1 ? parts[1] : '',
        thumbUrl: parts.length > 2 ? parts[2] : '',
        postUrl: parts.length > 3 ? parts[3] : '',
        authorName: parts.length > 4 ? parts[4] : '',
        caption: parts.length > 5 ? parts[5] : '',
      );
    }

    // 3) Any other ADSYPOST-prefixed blob whose delimiters were stripped in
    //    transit — salvage the URLs so it still renders a tappable card.
    if (content.startsWith(_prefix)) {
      final urls = _urlAnywhere
          .allMatches(content)
          .map((m) => m.group(0)!)
          .toList();
      if (urls.isNotEmpty) {
        final thumb = urls.firstWhere(
          (u) => u.contains('/media.') || u.contains('media.adsyclub'),
          orElse: () => '',
        );
        final post = urls.lastWhere(
          (u) => !u.contains('media.'),
          orElse: () => urls.last,
        );
        return SharedPostMessage(
          ownerName: 'পোস্ট',
          thumbUrl: thumb,
          postUrl: post,
        );
      }
      return const SharedPostMessage(
          ownerName: 'পোস্ট', thumbUrl: '', postUrl: '');
    }

    return _tryDecodeLegacy(content);
  }

  static final RegExp _urlAnywhere =
      RegExp(r'https?:\/\/[^\s]+', caseSensitive: false);
  static final RegExp _urlLine =
      RegExp(r'^https?:\/\/\S+$', caseSensitive: false);

  static String _clean(String s) =>
      s.replaceAll(_legacySep, ' ').replaceAll('\n', ' ').trim();

  /// Messages shared BEFORE the structured format existed look like:
  ///   `<Owner> on Business Network\n\n<description>\n\n<url>`
  static SharedPostMessage? _tryDecodeLegacy(String content) {
    final text = content.trim();
    if (!text.contains(' on Business Network')) return null;
    final parts = text
        .split('\n\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length < 2) return null;
    final first = parts.first;
    final last = parts.last;
    if (!first.endsWith(' on Business Network')) return null;
    if (!_urlLine.hasMatch(last)) return null;
    final owner =
        first.substring(0, first.length - ' on Business Network'.length).trim();
    final caption = parts.length > 2 ? parts[1] : '';
    return SharedPostMessage(
      ownerName: owner.isEmpty ? first : owner,
      thumbUrl: '',
      postUrl: last,
      authorName: owner,
      caption: caption,
    );
  }
}
