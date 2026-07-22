/// In-memory LRU cache of recent chat histories (1:1 rooms AND groups).
///
/// Opening a chat the user already visited renders INSTANTLY from this cache
/// (stale-while-revalidate): the cached messages paint first, the fresh fetch
/// then reconciles in the background — no spinner between chats.
///
/// Keys are namespaced by the caller (`room:id` / `group:id`) so the two
/// message shapes never collide. Deep copies go in and out so live message
/// maps (edited/deleted in place by the screens) can't alias cached state.
class ChatHistoryCache {
  ChatHistoryCache._();

  /// How many conversations stay warm. ~25 covers heavy switching without
  /// meaningful memory cost (text maps only — media stays on the network).
  static const int _maxConversations = 25;

  /// Recent tail per conversation — enough to fill the screen instantly;
  /// older pages load on scroll as usual.
  static const int _maxMessages = 60;

  static final Map<String, List<Map<String, dynamic>>> _store = {};
  // LRU order, most-recently-used LAST.
  static final List<String> _order = [];

  static List<Map<String, dynamic>>? get(String key) {
    final list = _store[key];
    if (list == null) return null;
    _touch(key);
    return [for (final m in list) Map<String, dynamic>.from(m)];
  }

  static void put(String key, List<Map<String, dynamic>> messages) {
    if (key.isEmpty) return;
    final start = messages.length > _maxMessages
        ? messages.length - _maxMessages
        : 0;
    _store[key] = [
      for (final m in messages.sublist(start)) Map<String, dynamic>.from(m)
    ];
    _touch(key);
    while (_order.length > _maxConversations) {
      _store.remove(_order.removeAt(0));
    }
  }

  static void invalidate(String key) {
    _store.remove(key);
    _order.remove(key);
  }

  /// Drop everything (logout).
  static void clearAll() {
    _store.clear();
    _order.clear();
  }

  static void _touch(String key) {
    _order.remove(key);
    _order.add(key);
  }
}
