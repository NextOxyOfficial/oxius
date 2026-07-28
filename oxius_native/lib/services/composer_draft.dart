import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// What the create-post composer is holding, kept OUTSIDE the widget.
///
/// Picking media leaves the app: the gallery is another activity, and Android
/// is free to destroy ours while it is in front. Flutter then rebuilds the
/// composer with a fresh State — and everything picked before that moment is
/// gone. The screen showed one clip where the user had chosen two, published
/// it, and nothing anywhere reported a problem. That is exactly the shape of
/// "I uploaded 2 videos and 1 posted".
///
/// So the selection lives here instead:
///  * the statics survive an activity being recreated (same isolate),
///  * video paths are also written to disk, so they survive the process
///    itself being killed — the clips are real files, only the list was lost.
///
/// Images stay in memory only: they are base64 already, and parking megabytes
/// of them in SharedPreferences would cost more than it saves.
class ComposerDraft {
  ComposerDraft._();

  static const _videosKey = 'composer_draft_videos';

  static final List<String> images = [];
  static final List<Map<String, dynamic>> videos = [];
  static final List<String> hashtags = [];
  static String visibility = 'public';

  static bool get isEmpty =>
      images.isEmpty && videos.isEmpty && hashtags.isEmpty;

  /// Persist the video picks (small strings — paths and display names).
  static Future<void> saveVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (videos.isEmpty) {
        await prefs.remove(_videosKey);
        return;
      }
      await prefs.setStringList(
        _videosKey,
        videos.map((v) => jsonEncode(v)).toList(),
      );
    } catch (_) {
      // A draft is a convenience; never let it break the composer.
    }
  }

  /// Bring back video picks after a process death, dropping any whose file the
  /// system has since cleaned out of the cache.
  static Future<void> restoreVideos() async {
    if (videos.isNotEmpty) return; // the statics already survived
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_videosKey) ?? const [];
      for (final entry in raw) {
        final decoded = jsonDecode(entry);
        if (decoded is! Map) continue;
        final path = (decoded['path'] ?? '').toString();
        if (path.isEmpty || !File(path).existsSync()) continue;
        videos.add(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Ignore a malformed draft rather than block a new post.
    }
  }

  /// The post went out (or the user threw the draft away).
  static Future<void> clear() async {
    images.clear();
    videos.clear();
    hashtags.clear();
    visibility = 'public';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_videosKey);
    } catch (_) {}
  }
}
