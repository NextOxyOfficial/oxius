// AdsyClub production telemetry & diagnostics.
//
// Design goals:
//   * One file, zero new pub dependencies.
//   * Release-build safe — no `print` spam, no debug-only behaviour leaking
//     into production.
//   * Crashlytics / Sentry / Firebase Performance compatible — call sites
//     emit structured events; external sinks plug in via static setters in
//     `main.dart` (e.g. `Telemetry.onError = FirebaseCrashlytics.instance.recordError`).
//   * Cheap: every emission is `O(1)`, ring buffer capped, no allocations
//     when sampling skips the event.
//
// Wiring overview:
//   * `Telemetry.installGlobalErrorHandlers()` — call from `main()` once.
//   * `Telemetry.trace('rides.create', () async {...})` — measure spans.
//   * `Telemetry.startSpan('rides.accept')` … `.stop()` — manual spans.
//   * `Telemetry.event('ws.reconnect', tags: {...})` — discrete event.
//   * `Telemetry.metric('api.latency_ms', 432, tags: {'endpoint':'/rides/'});`
//   * `TelemetryNavigatorObserver()` — drop into `MaterialApp.navigatorObservers`.
//
// Sinks (set from `main.dart` once Crashlytics is installed):
//   * `Telemetry.onError = (err, stack, ctx) => FirebaseCrashlytics.instance.recordError(err, stack, reason: ctx['reason']);`
//   * `Telemetry.onBreadcrumb` — receives every event / span / metric for
//     forwarding to a remote analytics backend.
//
// Slow-query / slow-API detection:
//   Spans automatically emit a `slow` breadcrumb when they exceed
//   `Telemetry.slowSpanThresholdMs` (default 1500ms). This is the cheapest
//   way to catch backend bottlenecks in the field.

import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Severity levels modelled on Crashlytics / Sentry conventions.
enum TelemetrySeverity { debug, info, warning, error, fatal }

/// Single breadcrumb emitted to sinks. Kept tiny so it can be cheaply
/// retained in a ring buffer for the most recent ~200 events.
class TelemetryBreadcrumb {
  TelemetryBreadcrumb({
    required this.category,
    required this.name,
    required this.severity,
    required this.timestamp,
    this.durationMs,
    this.tags,
    this.error,
    this.stackTrace,
  });

  final String category; // 'log' | 'span' | 'event' | 'metric' | 'error'
  final String name;
  final TelemetrySeverity severity;
  final DateTime timestamp;
  final int? durationMs;
  final Map<String, Object?>? tags;
  final Object? error;
  final StackTrace? stackTrace;

  Map<String, Object?> toJson() => {
        'category': category,
        'name': name,
        'severity': severity.name,
        'ts': timestamp.toIso8601String(),
        if (durationMs != null) 'duration_ms': durationMs,
        if (tags != null && tags!.isNotEmpty) 'tags': tags,
        if (error != null) 'error': error.toString(),
      };
}

/// Manual span. Returned by [Telemetry.startSpan]. `stop()` emits the
/// duration to the configured sinks.
class TelemetrySpan {
  TelemetrySpan._(this.name, this._tags) : _started = DateTime.now();

  final String name;
  final Map<String, Object?>? _tags;
  final DateTime _started;
  bool _stopped = false;

  /// Stop the span. Adds `success` + any extra tags to the emitted record.
  void stop({bool success = true, Map<String, Object?>? extra}) {
    if (_stopped) return;
    _stopped = true;
    final ms = DateTime.now().difference(_started).inMilliseconds;
    final tags = <String, Object?>{
      if (_tags != null) ..._tags!,
      if (extra != null) ...extra,
      'success': success,
    };
    Telemetry._emitSpan(name, ms, tags);
  }
}

/// Lightweight in-memory ring of recent breadcrumbs. Useful for attaching
/// to crash reports as additional context (Crashlytics `log()` calls or
/// Sentry breadcrumbs).
class _BreadcrumbRing {
  _BreadcrumbRing(this._capacity);

  final int _capacity;
  final Queue<TelemetryBreadcrumb> _items = Queue();

  void add(TelemetryBreadcrumb crumb) {
    _items.add(crumb);
    while (_items.length > _capacity) {
      _items.removeFirst();
    }
  }

  List<TelemetryBreadcrumb> snapshot() => List.unmodifiable(_items);
}

/// Central telemetry facade. All static.
class Telemetry {
  Telemetry._();

  // ─────────── Configuration ───────────

  /// Master switch. When false, every static method short-circuits.
  /// Defaults to `true` in release builds. Can be flipped at runtime.
  static bool enabled = true;

  /// Cap on emitted log volume per second per call site. Anything beyond
  /// this is dropped silently to prevent runaway loops from spamming
  /// Crashlytics / log servers.
  static int maxEventsPerSecond = 50;

  /// Spans that take longer than this are tagged `slow: true` and emit a
  /// dedicated `'slow'` breadcrumb. Tune at runtime if you need to flush
  /// out backend bottlenecks.
  static int slowSpanThresholdMs = 1500;

  /// When true, debug-build logs are also mirrored to `dart:developer.log`
  /// so they show in the IDE. Always off in release.
  static bool mirrorToDeveloperLog = kDebugMode;

  // ─────────── Pluggable sinks ───────────

  /// Forward every breadcrumb. Wire to Crashlytics:
  /// ```dart
  /// Telemetry.onBreadcrumb = (c) =>
  ///   FirebaseCrashlytics.instance.log('${c.category}:${c.name} ${c.tags ?? ''}');
  /// ```
  static void Function(TelemetryBreadcrumb breadcrumb)? onBreadcrumb;

  /// Forward fatal/error reports. Wire to Crashlytics:
  /// ```dart
  /// Telemetry.onError = (err, stack, ctx) =>
  ///   FirebaseCrashlytics.instance.recordError(err, stack,
  ///     reason: ctx['reason'], fatal: ctx['fatal'] == true);
  /// ```
  static void Function(Object error, StackTrace? stack, Map<String, Object?> context)? onError;

  /// Forward numeric metrics for performance dashboards (Firebase
  /// Performance, Datadog, etc.).
  static void Function(String metric, num value, Map<String, Object?>? tags)? onMetric;

  // ─────────── Internal state ───────────

  static final _BreadcrumbRing _ring = _BreadcrumbRing(200);
  static final Map<String, _RateBucket> _buckets = {};

  /// Current user/session identifiers. Stamped on every event when set.
  /// Set once from `main.dart` after the user logs in.
  static String? userId;
  static String? sessionId;
  static final Map<String, Object?> _globalTags = {};

  static void setGlobalTag(String key, Object? value) {
    if (value == null) {
      _globalTags.remove(key);
    } else {
      _globalTags[key] = value;
    }
  }

  /// Snapshot of recent breadcrumbs — attach to manual crash reports.
  static List<TelemetryBreadcrumb> recentBreadcrumbs() => _ring.snapshot();

  // ─────────── Public API ───────────

  /// Install Flutter + zone error handlers so uncaught exceptions are
  /// routed through [recordError]. Call ONCE from `main()`, before
  /// `runApp` if possible.
  ///
  /// To wrap `runApp` in an error-capturing zone, use
  /// [runAppWithTelemetry] below instead.
  static void installGlobalErrorHandlers() {
    FlutterError.onError = (FlutterErrorDetails details) {
      // Always pass through to default so DebugPaint / red screen still
      // shows up in debug mode.
      FlutterError.presentError(details);
      recordError(
        details.exception,
        details.stack,
        reason: details.context?.toDescription() ?? 'FlutterError',
        fatal: false,
      );
    };

    // Catch errors from the platform side (e.g. Method channel exceptions
    // bubbling out of native plugins).
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      recordError(error, stack, reason: 'PlatformDispatcher', fatal: true);
      return true; // mark as handled — don't terminate the isolate
    };
  }

  /// Wrap the whole app inside an error-capturing zone. Use from `main()`:
  /// ```dart
  /// void main() => Telemetry.runAppWithTelemetry(() => runApp(MyApp()));
  /// ```
  static void runAppWithTelemetry(void Function() body) {
    installGlobalErrorHandlers();
    runZonedGuarded(body, (Object error, StackTrace stack) {
      recordError(error, stack, reason: 'unhandled-zone', fatal: true);
    });
  }

  /// Structured log. Free-form `message` + optional structured `tags`.
  static void log(
    String message, {
    TelemetrySeverity severity = TelemetrySeverity.info,
    Map<String, Object?>? tags,
  }) {
    if (!enabled) return;
    if (!_rateAllow('log:$message')) return;
    final crumb = TelemetryBreadcrumb(
      category: 'log',
      name: message,
      severity: severity,
      timestamp: DateTime.now(),
      tags: _mergeTags(tags),
    );
    _dispatch(crumb);
  }

  /// Discrete named event (no duration). Use for things like
  /// `'fcm.received'`, `'ws.reconnect'`, `'call.declined'`.
  static void event(
    String name, {
    Map<String, Object?>? tags,
    TelemetrySeverity severity = TelemetrySeverity.info,
  }) {
    if (!enabled) return;
    if (!_rateAllow('event:$name')) return;
    _dispatch(TelemetryBreadcrumb(
      category: 'event',
      name: name,
      severity: severity,
      timestamp: DateTime.now(),
      tags: _mergeTags(tags),
    ));
  }

  /// Record a numeric metric — API latency, frame time, queue depth, etc.
  static void metric(
    String name,
    num value, {
    Map<String, Object?>? tags,
  }) {
    if (!enabled) return;
    final merged = _mergeTags(tags);
    onMetric?.call(name, value, merged);
    _dispatch(TelemetryBreadcrumb(
      category: 'metric',
      name: name,
      severity: TelemetrySeverity.info,
      timestamp: DateTime.now(),
      tags: {...?merged, 'value': value},
    ));
  }

  /// Manually start a span. Always pair with [TelemetrySpan.stop].
  /// Prefer [trace] when wrapping a single async block.
  static TelemetrySpan startSpan(String name, {Map<String, Object?>? tags}) =>
      TelemetrySpan._(name, tags);

  /// Wrap an async block; emits a span with duration + success flag.
  /// On error, the span is marked failed AND [recordError] is called.
  static Future<T> trace<T>(
    String name,
    FutureOr<T> Function() body, {
    Map<String, Object?>? tags,
  }) async {
    final span = startSpan(name, tags: tags);
    try {
      final result = await body();
      span.stop(success: true);
      return result;
    } catch (e, stack) {
      span.stop(success: false, extra: {'error_type': e.runtimeType.toString()});
      recordError(e, stack, reason: 'span:$name', fatal: false);
      rethrow;
    }
  }

  /// Record an error / exception. Forwards to [onError] if wired.
  /// `fatal: true` causes Crashlytics to treat it as a crash.
  static void recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Map<String, Object?>? tags,
  }) {
    if (!enabled) return;
    final merged = _mergeTags({
      if (reason != null) 'reason': reason,
      'fatal': fatal,
      ...?tags,
    });
    final crumb = TelemetryBreadcrumb(
      category: 'error',
      name: reason ?? error.runtimeType.toString(),
      severity: fatal ? TelemetrySeverity.fatal : TelemetrySeverity.error,
      timestamp: DateTime.now(),
      tags: merged,
      error: error,
      stackTrace: stack,
    );
    _dispatch(crumb);
    try {
      onError?.call(error, stack, merged ?? const {});
    } catch (_) {
      // Never let a faulty sink crash the app.
    }
  }

  // ─────────── Internal ───────────

  static void _emitSpan(String name, int durationMs, Map<String, Object?> tags) {
    if (!enabled) return;
    final slow = durationMs >= slowSpanThresholdMs;
    final merged = _mergeTags({
      ...tags,
      if (slow) 'slow': true,
    });
    final crumb = TelemetryBreadcrumb(
      category: 'span',
      name: name,
      severity: slow ? TelemetrySeverity.warning : TelemetrySeverity.info,
      timestamp: DateTime.now(),
      durationMs: durationMs,
      tags: merged,
    );
    _dispatch(crumb);
    onMetric?.call('span.$name.ms', durationMs, merged);
  }

  static Map<String, Object?>? _mergeTags(Map<String, Object?>? tags) {
    if (_globalTags.isEmpty && (tags == null || tags.isEmpty)) {
      if (userId == null && sessionId == null) return null;
    }
    return <String, Object?>{
      ..._globalTags,
      if (userId != null) 'user_id': userId,
      if (sessionId != null) 'session_id': sessionId,
      ...?tags,
    };
  }

  static void _dispatch(TelemetryBreadcrumb crumb) {
    _ring.add(crumb);
    if (mirrorToDeveloperLog && !kReleaseMode) {
      developer.log(
        '[${crumb.severity.name}] ${crumb.category}:${crumb.name}'
        '${crumb.durationMs != null ? ' (${crumb.durationMs}ms)' : ''}'
        '${crumb.tags != null && crumb.tags!.isNotEmpty ? ' ${crumb.tags}' : ''}',
        name: 'telemetry',
        error: crumb.error,
        stackTrace: crumb.stackTrace,
      );
    }
    try {
      onBreadcrumb?.call(crumb);
    } catch (_) {
      // A misbehaving sink should not blow up the producer.
    }
  }

  static bool _rateAllow(String key) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final bucket = _buckets.putIfAbsent(key, () => _RateBucket());
    if (bucket.second != now) {
      bucket.second = now;
      bucket.count = 0;
    }
    bucket.count += 1;
    return bucket.count <= maxEventsPerSecond;
  }
}

class _RateBucket {
  int second = 0;
  int count = 0;
}

/// Drop into `MaterialApp.navigatorObservers` to record screen navigation.
/// Each push / pop / replace emits a `nav.*` event and a span around the
/// route's lifetime. Stacks duplicates intentionally — caller can dedup.
class TelemetryNavigatorObserver extends NavigatorObserver {
  TelemetryNavigatorObserver({this.category = 'nav'});

  final String category;
  final Map<Route<dynamic>, DateTime> _opened = {};

  String _name(Route<dynamic>? route) {
    if (route == null) return 'unknown';
    final settings = route.settings;
    return settings.name ?? route.runtimeType.toString();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _opened[route] = DateTime.now();
    Telemetry.event('$category.push', tags: {
      'to': _name(route),
      'from': _name(previousRoute),
    });
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    final opened = _opened.remove(route);
    Telemetry.event('$category.pop', tags: {
      'route': _name(route),
      if (opened != null)
        'visible_ms': DateTime.now().difference(opened).inMilliseconds,
    });
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) _opened.remove(oldRoute);
    if (newRoute != null) _opened[newRoute] = DateTime.now();
    Telemetry.event('$category.replace', tags: {
      'to': _name(newRoute),
      'from': _name(oldRoute),
    });
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _opened.remove(route);
    Telemetry.event('$category.remove', tags: {'route': _name(route)});
  }
}

/// Tracks `WidgetsBindingObserver.didChangeAppLifecycleState` so foreground
/// / background transitions land in the breadcrumb stream. Attach once
/// (e.g. from `MyApp.initState`):
///
/// ```dart
/// WidgetsBinding.instance.addObserver(TelemetryLifecycleObserver());
/// ```
class TelemetryLifecycleObserver with WidgetsBindingObserver {
  AppLifecycleState? _last;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_last == state) return;
    _last = state;
    Telemetry.event('app.lifecycle', tags: {'state': state.name});
  }
}
