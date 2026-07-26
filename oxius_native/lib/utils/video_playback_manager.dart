import 'package:flutter/widgets.dart';

/// Single source of truth for "which video is allowed to make sound right now".
///
/// Every video surface in the app (feed media, shorts, video ads, chat clips)
/// used to own its playback independently, which produced three bugs the user
/// could hear:
///   * scrolling past a feed video left it playing off-screen,
///   * navigating to another page — or backgrounding the app — kept the audio
///     going,
///   * opening a short while another video was live played BOTH at once.
///
/// Rather than patching each widget, players register here and ask for the
/// floor. Granting it pauses everyone else, so overlapping audio is impossible
/// by construction. The manager also watches the app lifecycle itself, so a
/// widget that forgets to handle backgrounding still gets paused.
class VideoPlaybackManager with WidgetsBindingObserver {
  VideoPlaybackManager._() {
    WidgetsBinding.instance.addObserver(this);
  }

  static final VideoPlaybackManager instance = VideoPlaybackManager._();

  /// Registered pause callbacks, keyed by the owner token the caller passes in.
  final Map<Object, VoidCallback> _players = {};

  Object? _current;

  /// The player that currently holds the floor, if any.
  Object? get activeOwner => _current;

  /// Registers [owner]'s pause callback. Safe to call repeatedly.
  void register(Object owner, VoidCallback onPause) {
    _players[owner] = onPause;
  }

  /// Drops [owner]. Call from dispose() so a torn-down widget is never asked
  /// to pause (which would touch a disposed controller).
  void unregister(Object owner) {
    _players.remove(owner);
    if (identical(_current, owner)) _current = null;
  }

  /// Takes the audio floor for [owner], pausing every other registered player.
  /// Call this immediately BEFORE starting playback.
  void claim(Object owner) {
    if (!identical(_current, owner)) {
      _pauseAllExcept(owner);
      _current = owner;
    }
  }

  /// Gives up the floor if [owner] holds it. Does not pause anyone else.
  void release(Object owner) {
    if (identical(_current, owner)) _current = null;
  }

  /// Pauses every registered player. Used when leaving a screen or when the
  /// app stops being the foreground app.
  void pauseAll() {
    _pauseAllExcept(null);
    _current = null;
  }

  void _pauseAllExcept(Object? keep) {
    // Snapshot: a pause callback may unregister its owner (e.g. a widget that
    // disposes its controller), which would mutate the map mid-iteration.
    for (final entry in _players.entries.toList()) {
      if (keep != null && identical(entry.key, keep)) continue;
      try {
        entry.value();
      } catch (_) {
        // A disposed controller must not take the rest of the app down.
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `inactive` covers the iOS app-switcher and incoming calls; `paused` and
    // `hidden` cover backgrounding on both platforms.
    if (state != AppLifecycleState.resumed) {
      pauseAll();
    }
  }
}

/// Pauses all video whenever the route it wraps stops being the top route.
///
/// Attach [VideoRouteObserver.instance] to MaterialApp.navigatorObservers and
/// nothing can keep playing behind a pushed screen.
class VideoRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  VideoRouteObserver._();

  static final VideoRouteObserver instance = VideoRouteObserver._();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // Something new covered the screen — whatever was playing is now hidden.
    if (previousRoute != null) VideoPlaybackManager.instance.pauseAll();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    VideoPlaybackManager.instance.pauseAll();
  }
}
