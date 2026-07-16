/// A compact, self-contained encoding for a "post shared into a chat".
///
/// The AdsyConnect message body is plain text, and the server-side link
/// preview for an adsyclub post only returns the generic site metadata (the
/// real per-post OpenGraph tags are served to bots only). So instead of
/// relying on a scrape, the sender embeds exactly what the card needs —
/// owner name, thumbnail, post url — and the recipient renders a minimal
/// Facebook-style attachment (thumbnail + owner name, no preview chrome).
///
/// Wire format is a single line, delimited by control chars so it never
/// collides with normal text or URLs:
///   `ADSYPOST | ownerName | thumbUrl | postUrl` (control-char separated)
class SharedPostMessage {
  static const String _prefix = 'ADSYPOST';
  static const String _sep = '';

  final String ownerName;
  final String thumbUrl;
  final String postUrl;

  const SharedPostMessage({
    required this.ownerName,
    required this.thumbUrl,
    required this.postUrl,
  });

  String encode() =>
      '$_prefix$_sep$ownerName$_sep$thumbUrl$_sep$postUrl';

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
      );
    }
    return _tryDecodeLegacy(content);
  }

  static final RegExp _urlLine =
      RegExp(r'^https?:\/\/\S+$', caseSensitive: false);

  /// Messages shared BEFORE the structured format existed look like:
  ///   `<Owner> on Business Network\n\n<description>\n\n<url>`
  /// Recognize them so old chats also render the standard preview card
  /// instead of a wall of title + description + raw URL.
  static SharedPostMessage? _tryDecodeLegacy(String content) {
    final text = content.trim();
    if (!text.contains(' on Business Network')) return null;
    final parts =
        text.split('\n\n').map((p) => p.trim()).where((p) => p.isNotEmpty);
    if (parts.length < 2) return null;
    final first = parts.first;
    final last = parts.last;
    if (!first.endsWith(' on Business Network')) return null;
    if (!_urlLine.hasMatch(last)) return null;
    final owner =
        first.substring(0, first.length - ' on Business Network'.length).trim();
    return SharedPostMessage(
      ownerName: owner.isEmpty ? first : owner,
      thumbUrl: '',
      postUrl: last,
    );
  }
}
