/// A compact, self-contained encoding for a "post shared into a chat".
///
/// The AdsyConnect message body is plain text, and the server-side link
/// preview for an adsyclub post only returns the generic site metadata (the
/// real per-post OpenGraph tags are served to bots only). So instead of
/// relying on a scrape, the sender embeds exactly what the card needs and the
/// recipient renders a minimal Facebook-style attachment: thumbnail + the
/// post author's name + a short caption (NOT a generic "Business Network").
///
/// Wire format is one line, control-char delimited so it never collides with
/// normal text/URLs. Fields are positional; trailing ones are optional so old
/// 4-token messages still decode:
///   ADSYPOST | ownerName | thumbUrl | postUrl | authorName | caption
class SharedPostMessage {
  static const String _prefix = 'ADSYPOST';
  static const String _sep = '';

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
  String get displayName =>
      authorName.isNotEmpty ? authorName : ownerName;

  String encode() => [
        _prefix,
        ownerName,
        thumbUrl,
        postUrl,
        authorName,
        // Strip control chars/newlines from the caption so it stays one token.
        caption.replaceAll(_sep, ' ').replaceAll('\n', ' ').trim(),
      ].join(_sep);

  static bool isShared(String content) => content.startsWith('$_prefix$_sep');

  /// Returns null when [content] isn't a shared-post message.
  static SharedPostMessage? tryDecode(String content) {
    if (isShared(content)) {
      final parts = content.split(_sep);
      // parts[0] == 'ADSYPOST'
      return SharedPostMessage(
        ownerName: parts.length > 1 ? parts[1] : '',
        thumbUrl: parts.length > 2 ? parts[2] : '',
        postUrl: parts.length > 3 ? parts[3] : '',
        authorName: parts.length > 4 ? parts[4] : '',
        caption: parts.length > 5 ? parts[5] : '',
      );
    }
    return _tryDecodeLegacy(content);
  }

  static final RegExp _urlLine =
      RegExp(r'^https?:\/\/\S+$', caseSensitive: false);

  /// Messages shared BEFORE the structured format existed look like:
  ///   `<Owner> on Business Network\n\n<description>\n\n<url>`
  /// Recognize them so old chats also render the standard preview card.
  static SharedPostMessage? _tryDecodeLegacy(String content) {
    final text = content.trim();
    if (!text.contains(' on Business Network')) return null;
    final parts =
        text.split('\n\n').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.length < 2) return null;
    final first = parts.first;
    final last = parts.last;
    if (!first.endsWith(' on Business Network')) return null;
    if (!_urlLine.hasMatch(last)) return null;
    final owner =
        first.substring(0, first.length - ' on Business Network'.length).trim();
    // Middle paragraph (if any) is the caption.
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
