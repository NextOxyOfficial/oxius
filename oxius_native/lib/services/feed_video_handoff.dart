/// Where a feed video had reached when the viewer tapped through to shorts.
///
/// The feed autoplays a short inline. Tapping it opened the shorts viewer,
/// which fetched the video and started it from zero — so a clip watched
/// halfway restarted, and the viewer had to sit through what they had just
/// seen. This carries the inline player's position across that navigation.
///
/// Deliberately a read-and-clear store, not a cache: the position belongs to
/// one handoff. Scrolling back to the same short later starts from the top,
/// which is what you want — otherwise a video you finished would reopen at
/// its final frame forever.
library;

import 'package:flutter/foundation.dart';

class FeedVideoHandoff {
  FeedVideoHandoff._();

  static final Map<String, Duration> _positions = {};

  /// Called by the inline feed player at the moment of the tap.
  static void remember(String? url, Duration? position) {
    if (url == null || url.isEmpty || position == null) return;
    // Under a second in is indistinguishable from the start, and resuming a
    // nearly-finished clip would open on its last frame — treat both as "play
    // from the beginning" and store nothing.
    if (position < const Duration(seconds: 1)) return;
    _positions[url] = position;
  }

  /// Consumed once by the shorts player. Returns null when there is nothing
  /// to resume, which is the normal case for every video except the one just
  /// tapped.
  static Duration? take(String? url) {
    if (url == null || url.isEmpty) return null;
    final at = _positions.remove(url);
    if (at != null) {
      debugPrint('FeedVideoHandoff: resuming $url at $at');
    }
    return at;
  }

  @visibleForTesting
  static void clear() => _positions.clear();
}
