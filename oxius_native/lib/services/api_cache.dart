// =============================================================================
// ApiCache — production-grade two-tier cache for GET endpoints.
//
// Designed for AdsyClub super-app: feed, profile, news, business network,
// classified, eshop, recharge history etc. Modeled after Facebook/Instagram
// "stale-while-revalidate" + in-flight request deduplication, Uber-style
// session-persisted state for ridesharing.
//
//   Layer 1 — In-memory LRU (instant, lost on restart)
//   Layer 2 — Disk (SharedPreferences-backed JSON, ~MB scale)
//   Layer 3 — Network (single in-flight per key, results fan out to all
//             concurrent callers via the same Future)
//
// Three read modes:
//   - getOrFetch():            cache-first, fall back to network
//   - getStream():             emits cached value immediately, then refetched
//                              value if stale (stale-while-revalidate)
//   - invalidate() / clear():  surgical or full eviction
//
// Designed to wrap existing http calls WITHOUT changing service signatures.
// Existing services keep using `http.get(...)`; new code paths can opt-in to
// `ApiCache.getOrFetch(...)` for instant-feeling reads.
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class _CacheEntry {
  final dynamic data;
  final int storedAt;

  _CacheEntry(this.data, this.storedAt);

  bool isFresherThan(Duration ttl) =>
      DateTime.now().millisecondsSinceEpoch - storedAt < ttl.inMilliseconds;

  Map<String, dynamic> toJson() => {'d': data, 't': storedAt};

  static _CacheEntry? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final t = raw['t'];
    if (t is! int) return null;
    return _CacheEntry(raw['d'], t);
  }
}

class ApiCache {
  // -----------------------------------------------------------------
  // Config
  // -----------------------------------------------------------------
  /// Soft cap on in-memory LRU entries. Each entry is a decoded JSON tree;
  /// keep this conservative so we don't pressure GC on low-memory phones.
  static const int _memoryCapacity = 256;

  /// Default freshness window: how long a value is considered "fresh enough"
  /// that we don't even kick off a background refresh.
  static const Duration defaultFreshTtl = Duration(minutes: 2);

  /// Default hard TTL: cache is returned to UI even when stale (for instant
  /// paint) but a background refetch is triggered.
  static const Duration defaultStaleTtl = Duration(hours: 6);

  /// Disk-cache key prefix in SharedPreferences.
  static const String _diskPrefix = 'apicache:v1:';

  // -----------------------------------------------------------------
  // State
  // -----------------------------------------------------------------
  static final Map<String, _CacheEntry> _memory =
      <String, _CacheEntry>{}; // LRU-ish (insertion order)
  static final Map<String, Future<dynamic>> _inflight =
      <String, Future<dynamic>>{};

  // -----------------------------------------------------------------
  // Public API
  // -----------------------------------------------------------------

  /// Returns a cached value if available within [freshTtl], otherwise calls
  /// [fetch] (deduplicated across concurrent callers) and stores the result.
  /// If the cache is stale (older than freshTtl but younger than staleTtl),
  /// the cached value is returned immediately and [fetch] runs in the
  /// background to refresh the cache.
  ///
  /// This is the "stale-while-revalidate" pattern used by Facebook/Instagram
  /// for instant feed paint.
  static Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetch, {
    Duration freshTtl = defaultFreshTtl,
    Duration staleTtl = defaultStaleTtl,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final mem = _memory[key];
      if (mem != null && mem.isFresherThan(freshTtl)) {
        return mem.data as T;
      }
      if (mem != null && mem.isFresherThan(staleTtl)) {
        // Stale-while-revalidate: kick off background refresh, return stale.
        unawaited(_refreshInBackground(key, fetch));
        return mem.data as T;
      }

      // Disk fallback when not in memory.
      final disk = await _readFromDisk(key);
      if (disk != null && disk.isFresherThan(staleTtl)) {
        _memory[key] = disk;
        _trimMemory();
        if (!disk.isFresherThan(freshTtl)) {
          unawaited(_refreshInBackground(key, fetch));
        }
        return disk.data as T;
      }
    }

    // Network — dedupe concurrent callers.
    return _fetchAndStore<T>(key, fetch);
  }

  /// Stale-while-revalidate as a Stream. Useful in StreamBuilder-driven
  /// screens: emits cached value (if any) immediately, then the fresh
  /// network value once it arrives.
  static Stream<T> getStream<T>(
    String key,
    Future<T> Function() fetch, {
    Duration freshTtl = defaultFreshTtl,
    Duration staleTtl = defaultStaleTtl,
  }) async* {
    final mem = _memory[key];
    if (mem != null && mem.isFresherThan(staleTtl)) {
      yield mem.data as T;
      if (mem.isFresherThan(freshTtl)) return;
    } else {
      final disk = await _readFromDisk(key);
      if (disk != null && disk.isFresherThan(staleTtl)) {
        _memory[key] = disk;
        _trimMemory();
        yield disk.data as T;
        if (disk.isFresherThan(freshTtl)) return;
      }
    }
    final fresh = await _fetchAndStore<T>(key, fetch);
    yield fresh;
  }

  /// Peek at the cached value without triggering a fetch. Returns null on miss.
  static T? peek<T>(String key) {
    final mem = _memory[key];
    if (mem == null) return null;
    final d = mem.data;
    return d is T ? d : null;
  }

  /// Write a value into the cache directly (e.g. after a POST that returns
  /// the new server state — keeps reads instant after a mutation).
  static Future<void> put(String key, dynamic value) async {
    final entry = _CacheEntry(value, DateTime.now().millisecondsSinceEpoch);
    _memory[key] = entry;
    _trimMemory();
    await _writeToDisk(key, entry);
  }

  /// Drop a single key from both memory + disk.
  static Future<void> invalidate(String key) async {
    _memory.remove(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_diskPrefix + key);
    } catch (_) {}
  }

  /// Drop every key starting with [prefix]. Use for category-level
  /// invalidation, e.g. invalidatePrefix('feed:') after a new post.
  static Future<void> invalidatePrefix(String prefix) async {
    _memory.removeWhere((k, _) => k.startsWith(prefix));
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullPrefix = _diskPrefix + prefix;
      final keys =
          prefs.getKeys().where((k) => k.startsWith(fullPrefix)).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }

  /// Wipe the entire cache. Call on logout.
  static Future<void> clear() async {
    _memory.clear();
    _inflight.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys =
          prefs.getKeys().where((k) => k.startsWith(_diskPrefix)).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }

  // -----------------------------------------------------------------
  // Internals
  // -----------------------------------------------------------------

  static Future<T> _fetchAndStore<T>(
    String key,
    Future<T> Function() fetch,
  ) async {
    final existing = _inflight[key];
    if (existing != null) {
      // Already fetching for another caller — share the result.
      return existing as Future<T>;
    }
    final future = fetch();
    _inflight[key] = future;
    try {
      final value = await future;
      final entry = _CacheEntry(value, DateTime.now().millisecondsSinceEpoch);
      _memory[key] = entry;
      _trimMemory();
      // Disk write is fire-and-forget so it never blocks the UI path.
      unawaited(_writeToDisk(key, entry));
      return value;
    } finally {
      _inflight.remove(key);
    }
  }

  static Future<void> _refreshInBackground<T>(
    String key,
    Future<T> Function() fetch,
  ) async {
    if (_inflight.containsKey(key)) return; // already refreshing
    try {
      await _fetchAndStore<T>(key, fetch);
    } catch (_) {
      // Background refresh failures are swallowed; the stale value is still
      // displayed and the next foreground call will retry.
    }
  }

  static void _trimMemory() {
    while (_memory.length > _memoryCapacity) {
      final first = _memory.keys.first;
      _memory.remove(first);
    }
  }

  static Future<_CacheEntry?> _readFromDisk(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_diskPrefix + key);
      if (raw == null) return null;
      final decoded = json.decode(raw);
      return _CacheEntry.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeToDisk(String key, _CacheEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(entry.toJson());
      // Cap individual entry size at 1 MB to keep SharedPreferences healthy.
      if (encoded.length > 1024 * 1024) return;
      await prefs.setString(_diskPrefix + key, encoded);
    } catch (_) {
      // Disk-cache failures are non-fatal; memory cache still serves reads.
    }
  }
}
