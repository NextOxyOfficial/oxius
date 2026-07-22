import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/user_suggestions_service.dart';
import 'adsy_connect_chat_interface.dart';
import 'create_group_screen.dart';
import 'group_chat_screen.dart';
import 'inbox_screen.dart' show NewChatModal;
import '../services/adsyconnect_realtime_service.dart';
import '../services/adsyconnect_service.dart';
import '../services/fcm_service.dart';
import '../services/deep_link_service.dart';
import '../widgets/chat_list_skeleton.dart';
import '../config/app_config.dart';
import '../utils/network_error_handler.dart';
import '../utils/shared_post_message.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';
import 'package:oxius_native/widgets/common/adsy_chat_icon.dart';
import 'package:oxius_native/widgets/common/adsy_back_to_top.dart';
import 'package:oxius_native/widgets/common/adsy_sheet.dart';
import 'package:oxius_native/widgets/common/adsy_pro_badge.dart';
import 'package:oxius_native/widgets/common/adsy_dialog.dart';
import '../utils/adsy_ios_scale.dart';

/// Chat-list buckets. Spam is hidden from every tab except its own so junk
/// never clutters real conversations.
enum _ChatTab { all, mutual, groups, nonFollowers, spam }

class AdsyConnectScreen extends StatefulWidget {
  const AdsyConnectScreen({super.key, this.initialChatId, this.initialGroupId});

  final String? initialChatId;
  // Push-tap deep link: open this GROUP chat immediately.
  final String? initialGroupId;

  @override
  State<AdsyConnectScreen> createState() => _AdsyConnectScreenState();
}

class _AdsyConnectScreenState extends State<AdsyConnectScreen> {
  bool _isLoadingChats = true;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _chatConversations = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _didOpenInitialChat = false;
  Timer? _pollingTimer;
  Timer? _onlineStatusTimer;
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;
  OverlayEntry? _activeChatOverlay;
  String? _activeOverlayChatroomId;

  static const Set<String> _rootRoutesAllowedFromChatOverlay = {
    '/',
    '/business-network',
    '/business-network/profile',
    '/login',
    '/inbox',
    '/settings',
    '/deposit-withdraw',
    '/mobile-recharge',
    '/micro-gigs',
    '/mindforce',
  };

  final TextEditingController _chatSearchController = TextEditingController();
  final ScrollController _listScrollController = ScrollController();
  String _chatSearchQuery = '';
  // Header search: collapsed to an icon; expands elastically on tap.
  bool _chatSearchOpen = false;
  _ChatTab _activeChatTab = _ChatTab.all;
  List<Map<String, dynamic>> _groups = [];
  bool _loadingGroups = false;
  bool _groupsLoadedOnce = false;

  static const int _pageSize = 20;

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase().trim();
      return v == 'true' || v == '1' || v == 'yes';
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadChats();
    // Groups show inline in the main list, so load them up front too.
    unawaited(_loadGroups());
    // Push-tap deep link: open the target chat IMMEDIATELY (single-room
    // fetch) instead of waiting for the full chat list to load first.
    if ((widget.initialChatId ?? '').isNotEmpty) {
      unawaited(_openInitialChatIfNeeded());
    }
    if ((widget.initialGroupId ?? '').isNotEmpty) {
      unawaited(_openInitialGroupIfNeeded());
    }
    unawaited(AdsyConnectRealtimeService.instance.connect());
    _realtimeSubscription = AdsyConnectRealtimeService.instance.events.listen(
      _handleRealtimeEvent,
    );
    _startRealTimePolling();
    _startOnlineStatusPolling();
    _chatSearchController.addListener(_onChatSearchChanged);

    // Let FCMService close our full-screen chat overlay before it pushes a
    // CallScreen. The chat overlay is inserted into the root Overlay (above the
    // root Navigator), so without this the CallScreen would be hidden behind it
    // and the user could hear the ringtone without seeing the accept UI.
    FCMService.dismissBlockingChatOverlay = _dismissChatOverlayForIncomingCall;
  }

  void _dismissChatOverlayForIncomingCall() {
    if (!mounted || _activeChatOverlay == null) return;
    _removeActiveChatOverlay(refreshAfterClose: false);
  }

  void _handleRealtimeEvent(Map<String, dynamic> event) {
    final type = event['type']?.toString();
    if (type == null || !mounted) {
      return;
    }

    if (type == 'user_online_status') {
      final userId = event['user_id']?.toString();
      if (userId == null || userId.isEmpty) {
        return;
      }

      final index = _chatConversations.indexWhere(
        (chat) => (chat['userId'] ?? '').toString() == userId,
      );
      if (index == -1) {
        return;
      }

      setState(() {
        _chatConversations[index]['isOnline'] = _parseBool(event['is_online']);
      });
      return;
    }

    if (type == 'new_message' || type == 'message_read') {
      if (type == 'new_message') {
        // Instant UI update from the socket payload itself; the background
        // re-fetch below then reconciles with authoritative server data.
        _applyIncomingMessageToList(event['message']);
      }
      unawaited(_refreshChatsInBackground());
      return;
    }

    if (type == 'group_message') {
      _applyIncomingGroupMessage(event['message']);
      return;
    }

    if (type == 'group_updated') {
      unawaited(_loadGroups());
    }
  }

  /// Instantly reflect an incoming GROUP message on the list — preview,
  /// time and unread badge — without waiting for a reload.
  void _applyIncomingGroupMessage(dynamic message) {
    if (message is! Map) return;
    final groupId = (message['group'] ?? '').toString();
    if (groupId.isEmpty) return;

    final index =
        _groups.indexWhere((g) => (g['id'] ?? '').toString() == groupId);
    if (index == -1) {
      // Unknown group (just added?) — the full reload brings it in.
      unawaited(_loadGroups());
      return;
    }

    final sender = message['sender'] is Map
        ? Map<String, dynamic>.from(message['sender'] as Map)
        : <String, dynamic>{};
    final senderId = (sender['id'] ?? '').toString();
    final myId = AuthService.currentUser?.id.toString() ?? '';
    final senderName = _getFullName(sender);

    var preview = (message['content'] ?? '').toString();
    if (SharedPostMessage.tryDecode(preview) != null) {
      preview = '📎 একটি পোস্ট';
    } else {
      preview = _formatReplyPreview(preview) ?? preview;
    }
    switch ((message['message_type'] ?? 'text').toString()) {
      case 'voice':
        preview = '🎤 Voice message';
      case 'image':
        preview = '📷 Photo';
      case 'video':
        preview = '🎥 Video';
      case 'document':
        preview = '📄 Document';
    }

    setState(() {
      final g = Map<String, dynamic>.from(_groups[index]);
      g['last_message_preview'] =
          senderName.isNotEmpty ? '$senderName: $preview' : preview;
      g['last_message_at'] = (message['created_at'] ?? '').toString();
      if (senderId.isNotEmpty && senderId != myId) {
        g['unread_count'] = ((g['unread_count'] as num?) ?? 0).toInt() + 1;
      }
      _groups
        ..removeAt(index)
        ..insert(0, g);
    });
  }

  /// Instantly reflect an incoming message on the chat list — preview, time,
  /// unread badge and position (move to top) — without waiting for the
  /// background page-1 re-fetch.
  void _applyIncomingMessageToList(dynamic message) {
    if (message is! Map) return;
    final roomId = (message['chatroom'] ?? '').toString();
    if (roomId.isEmpty) return;

    final rawPreview =
        (message['display_content'] ?? message['content'] ?? '').toString();
    // Same sanitization as _parseChatRooms — the socket payload carries the
    // RAW content, so reply markers / shared-post JSON leaked into the list.
    String preview = rawPreview;
    if (SharedPostMessage.tryDecode(rawPreview) != null) {
      preview = '📎 একটি পোস্ট শেয়ার করা হয়েছে';
    } else {
      preview = _formatReplyPreview(rawPreview) ?? rawPreview;
    }
    final createdAt =
        DateTime.tryParse((message['created_at'] ?? '').toString()) ??
            DateTime.now();
    final sender = message['sender'] is Map
        ? Map<String, dynamic>.from(message['sender'] as Map)
        : <String, dynamic>{};
    final senderId = (sender['id'] ?? '').toString();

    final index = _chatConversations
        .indexWhere((c) => (c['id'] ?? '').toString() == roomId);

    if (index == -1) {
      // Room not in the loaded list (deep page / brand-new). Build a minimal
      // entry from the socket payload so the chat surfaces at the top NOW —
      // the background page-1 refresh then reconciles authoritative data.
      final myId = AuthService.currentUser?.id.toString() ?? '';
      final fromPeer = senderId.isNotEmpty && senderId != myId;
      if (!fromPeer) return; // own echo for an unloaded room — refresh covers it
      setState(() {
        _chatConversations.insert(0, <String, dynamic>{
          'id': roomId,
          'userId': senderId,
          'userName': _getFullName(sender),
          'userAvatar': sender['avatar'],
          'profession': sender['profession'] ?? '',
          'lastMessage': preview.isNotEmpty ? preview : 'নতুন মেসেজ',
          'timestamp': createdAt,
          'unreadCount': 1,
          'isOnline': true,
          'isTyping': false,
          'isVerified':
              sender['kyc'] == true || sender['is_verified'] == true,
          'isPro': sender['is_pro'] == true,
          'isGroup': message['is_group'] == true,
        });
      });
      return;
    }

    final isFromPeer = senderId.isNotEmpty &&
        senderId == (_chatConversations[index]['userId'] ?? '').toString();

    setState(() {
      final chat = _chatConversations.removeAt(index);
      if (preview.isNotEmpty) {
        chat['lastMessage'] = preview;
      }
      chat['timestamp'] = createdAt;
      if (isFromPeer) {
        chat['unreadCount'] = ((chat['unreadCount'] as num?) ?? 0).toInt() + 1;
      }
      _chatConversations.insert(0, chat);
    });
  }

  void _onChatSearchChanged() {
    final next = _chatSearchController.text;
    if (next == _chatSearchQuery) return;
    if (!mounted) return;
    setState(() {
      _chatSearchQuery = next;
    });
    _schedulePeopleSearch(next);
  }

  // ── Smart search: also surface OTHER users (people you haven't chatted
  // with yet) under the matched conversations, social-media style. ──

  Timer? _peopleDebounce;
  List<Map<String, dynamic>> _peopleResults = [];
  bool _peopleSearching = false;
  // People-section filter: 'all' | 'following' | 'new'.
  String _peopleFilter = 'all';

  void _schedulePeopleSearch(String query) {
    _peopleDebounce?.cancel();
    final q = query.trim();
    if (q.length < 2) {
      if (_peopleResults.isNotEmpty || _peopleSearching) {
        setState(() {
          _peopleResults = [];
          _peopleSearching = false;
        });
      }
      return;
    }
    setState(() => _peopleSearching = true);
    _peopleDebounce = Timer(const Duration(milliseconds: 450), () {
      _searchPeople(q);
    });
  }

  Future<void> _searchPeople(String query) async {
    try {
      final token = await AuthService.getValidToken();
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final uri =
          Uri.parse('${ApiService.baseUrl}/bn/users/search/').replace(
        queryParameters: {
          'q': query,
          'page_size': '10',
          'exclude_self': '1',
        },
      );
      final response = await http.get(uri, headers: headers);
      if (!mounted) return;
      // Stale response (query changed while in flight) — drop it.
      if (query != _chatSearchQuery.trim()) return;

      final results = <Map<String, dynamic>>[];
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Users already present in the chat list stay in the চ্যাট section.
        final knownIds = _chatConversations
            .map((c) => (c['userId'] ?? '').toString())
            .toSet();
        if (data['results'] is List) {
          for (final item in data['results']) {
            if (item is! Map) continue;
            final user = Map<String, dynamic>.from(item);
            final id = user['id']?.toString() ?? '';
            if (id.isEmpty || knownIds.contains(id)) continue;
            results.add(user);
          }
        }
      }
      setState(() {
        _peopleResults = results;
        _peopleSearching = false;
      });
    } catch (e) {
      debugPrint('People search failed: $e');
      if (mounted) setState(() => _peopleSearching = false);
    }
  }

  /// Start (or resume) a 1:1 chat with a user found via smart search.
  Future<void> _startChatWithUser(Map<String, dynamic> user) async {
    try {
      final chatroom = await AdsyConnectService.getOrCreateChatRoom(
        user['id'].toString(),
      );
      if (!mounted) return;
      final name = (user['first_name'] != null && user['last_name'] != null)
          ? '${user['first_name']} ${user['last_name']}'.trim()
          : (user['username'] ?? 'User').toString();
      await _openChat(<String, dynamic>{
        'id': chatroom['id'].toString(),
        'userId': user['id'].toString(),
        'userName': name,
        'userAvatar': user['profile_picture'] ?? user['image'],
        'profession': user['profession'],
        'isOnline': false,
        'unreadCount': 0,
      });
    } catch (e) {
      if (!mounted) return;
      final message = e is AdsyChatException
          ? e.message
          : 'চ্যাট খোলা যায়নি, একটু পরে আবার চেষ্টা করুন।';
      AdsyToast.error(context, message);
    }
  }

  void _startOnlineStatusPolling() {
    _onlineStatusTimer?.cancel();
    _onlineStatusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshOnlineStatuses();
    });
  }

  Future<void> _refreshOnlineStatuses() async {
    try {
      if (!mounted) return;
      if (_chatConversations.isEmpty) return;

      final userIds = _chatConversations
          .map((c) => (c['userId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (userIds.isEmpty) return;

      final statuses = await AdsyConnectService.getOnlineStatusList(userIds);
      if (!mounted) return;
      if (statuses.isEmpty) return;

      final Map<String, Map<String, dynamic>> statusByUserId = {};
      for (final item in statuses) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final id = (map['user_id'] ??
                  map['userId'] ??
                  map['id'] ??
                  (map['user'] is Map ? map['user']['id'] : null))
              ?.toString();
          if (id != null && id.isNotEmpty) {
            statusByUserId[id] = map;
          }
        }
      }

      if (statusByUserId.isEmpty) return;

      setState(() {
        for (var i = 0; i < _chatConversations.length; i++) {
          final uid = (_chatConversations[i]['userId'] ?? '').toString();
          final status = statusByUserId[uid];
          if (status == null) continue;

          final isOnline =
              _parseBool(status['is_online'] ?? status['isOnline']);
          _chatConversations[i]['isOnline'] = isOnline;
        }
      });
    } catch (_) {}
  }

  void _startRealTimePolling() {
    // WebSocket is the primary realtime path; polling stays as a recovery fallback.
    _pollingTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (mounted) {
        _refreshChatsInBackground();
      }
    });
  }

  Future<void> _refreshChatsInBackground() async {
    try {
      final chatRooms =
          await AdsyConnectService.getChatRooms(page: 1, pageSize: _pageSize);

      if (mounted) {
        setState(() {
          // Only update the first page to refresh unread counts
          final newChats = _parseChatRooms(chatRooms);

          // Update existing chats with new data
          for (var newChat in newChats) {
            final index =
                _chatConversations.indexWhere((c) => c['id'] == newChat['id']);
            if (index != -1) {
              final existingOnline = _chatConversations[index]['isOnline'];
              _chatConversations[index] = newChat;
              if (existingOnline != null) {
                _chatConversations[index]['isOnline'] = existingOnline;
              }
            } else {
              // New chat arrived, add it to the top
              _chatConversations.insert(0, newChat);
            }
          }

          // Re-order by most recent activity so a conversation that just
          // received a message jumps to the top in real time, instead of
          // staying put until the screen is reloaded. (The in-place merge
          // above keeps each chat at its old position otherwise.)
          _chatConversations.sort((a, b) {
            final ta = a['timestamp'];
            final tb = b['timestamp'];
            final da =
                ta is DateTime ? ta : DateTime.fromMillisecondsSinceEpoch(0);
            final db =
                tb is DateTime ? tb : DateTime.fromMillisecondsSinceEpoch(0);
            return db.compareTo(da);
          });
        });
      }
    } catch (e) {
      debugPrint('🔴 Error refreshing chats in background: $e');
      // Silent fail - don't show error to user
    }
  }

  @override
  void dispose() {
    // Only clear the hook if it still points at this State instance, so a newer
    // AdsyConnectScreen that registered after us isn't accidentally unhooked.
    if (FCMService.dismissBlockingChatOverlay ==
        _dismissChatOverlayForIncomingCall) {
      FCMService.dismissBlockingChatOverlay = null;
    }
    _pollingTimer?.cancel();
    _onlineStatusTimer?.cancel();
    _realtimeSubscription?.cancel();
    _removeActiveChatOverlay(refreshAfterClose: false);
    _peopleDebounce?.cancel();
    _chatSearchController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  bool _matchesTab(Map<String, dynamic> chat) {
    final isSpam = chat['isSpam'] == true;
    switch (_activeChatTab) {
      case _ChatTab.all:
        return !isSpam;
      case _ChatTab.mutual:
        return !isSpam && chat['isMutual'] == true;
      case _ChatTab.groups:
        return chat['isGroup'] == true;
      case _ChatTab.nonFollowers:
        return !isSpam && chat['theyFollowMe'] != true;
      case _ChatTab.spam:
        return isSpam;
    }
  }

  int _tabCount(_ChatTab tab) {
    if (tab == _ChatTab.groups) return _groups.length;
    final prev = _activeChatTab;
    _activeChatTab = tab;
    final n = _chatConversations.where(_matchesTab).length;
    _activeChatTab = prev;
    return n;
  }

  Future<void> _loadGroups() async {
    setState(() => _loadingGroups = true);
    final gs = await AdsyConnectService.getGroups();
    if (!mounted) return;
    setState(() {
      _groups = gs
          .map<Map<String, dynamic>>((g) => Map<String, dynamic>.from(g))
          .toList();
      _loadingGroups = false;
      _groupsLoadedOnce = true;
    });
  }

  Future<void> _openCreateGroup() async {
    final created = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );
    if (created != null && mounted) {
      setState(() => _activeChatTab = _ChatTab.groups);
      await _loadGroups();
    }
  }

  Future<void> _openGroup(Map<String, dynamic> group) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GroupChatScreen(group: group)),
    );
    if (mounted) _loadGroups();
  }

  List<Map<String, dynamic>> get _filteredChats {
    final q = _chatSearchQuery.trim().toLowerCase();
    final list = _chatConversations.where((chat) {
      if (!_matchesTab(chat)) return false;
      if (q.isEmpty) return true;
      final name = (chat['userName'] ?? '').toString().toLowerCase();
      final msg = (chat['lastMessage'] ?? '').toString().toLowerCase();
      // Only REAL text messages count as message matches — call logs,
      // shared-post placeholders etc. produce noise (e.g. searching "call"
      // matching every "Video call · 02:13" row).
      return name.contains(q) ||
          (_searchableMessage(msg) && msg.contains(q));
    }).toList();

    // The main (সব) tab shows GROUPS inline with 1:1 chats, sorted together
    // by recency — a group shouldn't hide inside its own tab only.
    if (_activeChatTab == _ChatTab.all && _groups.isNotEmpty) {
      for (final g in _groups) {
        final name = (g['name'] ?? '').toString();
        final preview = (g['last_message_preview'] ?? '').toString();
        if (q.isNotEmpty &&
            !name.toLowerCase().contains(q) &&
            !preview.toLowerCase().contains(q)) {
          continue;
        }
        list.add({
          'isGroup': true,
          '_group': g,
          'userName': name,
          'lastMessage': preview,
          'timestamp':
              DateTime.tryParse((g['last_message_at'] ?? '').toString()) ??
                  DateTime.now(),
        });
      }
      list.sort((a, b) {
        final ta = a['timestamp'];
        final tb = b['timestamp'];
        if (ta is! DateTime || tb is! DateTime) return 0;
        return tb.compareTo(ta);
      });
    }
    return list;
  }

  Future<void> _loadChats({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoadingChats = true;
        _currentPage = 1;
      });
    } else {
      // Prevent multiple simultaneous loads
      if (_isLoadingMore || !_hasMore) return;
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final pageToLoad = loadMore ? _currentPage + 1 : 1;
      debugPrint('🔵 Loading chat rooms, page: $pageToLoad');
      final chatRooms = await AdsyConnectService.getChatRooms(
          page: pageToLoad, pageSize: _pageSize);
      debugPrint('🟢 Loaded ${chatRooms.length} chat rooms');

      if (mounted) {
        final newChats = _parseChatRooms(chatRooms);

        setState(() {
          if (loadMore) {
            // Get existing chat IDs to prevent duplicates
            final existingIds = _chatConversations.map((c) => c['id']).toSet();

            // Only add chats that don't already exist
            final uniqueNewChats = newChats
                .where((chat) => !existingIds.contains(chat['id']))
                .toList();

            debugPrint(
                '📊 Adding ${uniqueNewChats.length} unique chats (filtered ${newChats.length - uniqueNewChats.length} duplicates)');
            _chatConversations.addAll(uniqueNewChats);

            // Move to the page we just successfully loaded
            _currentPage = pageToLoad;
          } else {
            _chatConversations = newChats;
            _currentPage = 1;
          }

          _isLoadingChats = false;
          _isLoadingMore = false;
          _hasMore = chatRooms.length >= _pageSize;
        });

        if (!loadMore) {
          _refreshOnlineStatuses();
          unawaited(_openInitialChatIfNeeded());
        }
      }
    } catch (e) {
      debugPrint('🔴 Error loading chats: $e');
      if (mounted) {
        setState(() {
          _isLoadingChats = false;
          _isLoadingMore = false;
        });

        final customMessage = NetworkErrorHandler.isNetworkError(e)
            ? null
            : (loadMore ? 'Failed to load more chats' : 'Failed to load chats');

        NetworkErrorHandler.showErrorSnackbar(
          context,
          e,
          customMessage: customMessage,
          onRetry: () => _loadChats(loadMore: loadMore),
        );
      }
    }
  }

  /// Reply messages are stored as a single string in this format:
  ///   `↩️ (uuid) Sender: quoted preview\n\nActual message`
  /// Older messages were saved with a mojibaked `â†©ï¸` prefix (UTF-8 bytes
  /// mis-decoded as Latin-1), which previously leaked the raw `(uuid)` header
  /// into the chat list. Returns a clean `↩️ <actual message>` preview, or
  /// null when [content] is not a reply.
  String? _formatReplyPreview(String content) {
    final text = content.trimLeft();
    const correctPrefix = '↩️';
    const legacyPrefix = 'â†©ï¸';

    final String prefix;
    if (text.startsWith(correctPrefix)) {
      prefix = correctPrefix;
    } else if (text.startsWith(legacyPrefix)) {
      prefix = legacyPrefix;
    } else {
      return null;
    }

    // The actual message sits after the blank-line separator.
    final parts = text.split('\n\n');
    if (parts.length >= 2) {
      final actualText = parts.sublist(1).join('\n\n').trim();
      if (actualText.isNotEmpty) return '↩️ $actualText';
    }

    // No body — strip the "(uuid) Sender:" header and show whatever remains.
    var rest = text.substring(prefix.length).trim();
    if (rest.startsWith('(')) {
      final end = rest.indexOf(')');
      if (end != -1) rest = rest.substring(end + 1).trim();
    }
    final colon = rest.indexOf(':');
    if (colon != -1) rest = rest.substring(colon + 1).trim();
    return rest.isNotEmpty ? '↩️ $rest' : '↩️ Reply';
  }

  List<Map<String, dynamic>> _parseChatRooms(List<dynamic> chatRooms) {
    return chatRooms.map((room) {
      final otherUser = room['other_user'] ?? {};
      final lastMessage = room['last_message'];

      // Check if last message is deleted
      final isDeleted = lastMessage?['is_deleted'] == true;
      final messageContent = lastMessage?['content']?.toString() ??
          room['last_message_preview']?.toString() ??
          '';

      // Show "Message removed" if deleted OR if content says "Message deleted"
      String displayMessage;
      if (isDeleted || messageContent == 'Message deleted') {
        displayMessage = 'Message removed';
      } else if (messageContent.isEmpty) {
        displayMessage = 'No messages yet';
      } else if (SharedPostMessage.tryDecode(messageContent) != null) {
        // Never leak the raw shared-post payload into the list preview.
        displayMessage = '📎 একটি পোস্ট শেয়ার করা হয়েছে';
      } else {
        displayMessage = _formatReplyPreview(messageContent) ?? messageContent;
      }

      return {
        'id': room['id'],
        'userId': otherUser['id']?.toString() ?? '',
        'userName': _getFullName(otherUser),
        'userAvatar': otherUser['avatar'],
        'profession': otherUser['profession'] ?? '',
        'lastMessage': displayMessage,
        'timestamp': lastMessage?['created_at'] != null
            ? DateTime.parse(lastMessage['created_at'])
            : DateTime.parse(
                room['last_message_at'] ?? DateTime.now().toIso8601String()),
        'unreadCount': room['unread_count'] ?? 0,
        'isOnline': _parseBool(otherUser['is_online'] ?? otherUser['isOnline']),
        'isTyping': false,
        // Backend sends kyc (verified) + is_pro on chat counterparts.
        'isVerified':
            otherUser['kyc'] == true || otherUser['is_verified'] == true,
        'isPro': otherUser['is_pro'] == true,
        // Deleted (deactivated) / suspended account flags — the tile labels
        // the name and the profile link is disabled.
        'isDeleted': otherUser['is_active'] == false,
        'isSuspended': otherUser['is_suspended'] == true,
        'isMuted': room['is_muted'] == true,
        'isArchived': room['is_archived'] == true,
        'isMutual': room['is_mutual'] == true,
        'iFollowThem': room['i_follow_them'] == true,
        'theyFollowMe': room['they_follow_me'] == true,
        'isSpam': room['is_spam'] == true,
        'isGroup': room['is_group'] == true,
      };
    }).toList();
  }

  String _getFullName(Map<String, dynamic> user) {
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final username = user['username'] ?? 'User';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    }
    return username;
  }

  Future<void> _refreshChats() async {
    // Prefer a silent background refresh so we don't flash the skeleton or
    // briefly empty the list right after returning from a chat — that empty
    // frame can swallow the first tap on the list.
    if (_chatConversations.isNotEmpty) {
      await _refreshChatsInBackground();
      return;
    }
    await _loadChats();
  }

  void _loadMoreChats() {
    if (!_isLoadingChats && _hasMore) {
      _loadChats(loadMore: true);
    }
  }

  Future<void> _openChat(Map<String, dynamic> chat) async {
    final chatroomId = chat['id']?.toString();
    if (chatroomId == null || chatroomId.isEmpty) return;
    // Already showing this exact chat — nothing to do.
    if (_activeOverlayChatroomId == chatroomId) return;

    // Optimistic: clear the unread badge instantly — no reload needed.
    if ((chat['unreadCount'] ?? 0) != 0 && mounted) {
      setState(() => chat['unreadCount'] = 0);
    }

    // Open the chat overlay immediately so the tap always feels responsive.
    // Previously we awaited markChatroomAsRead() here while holding an
    // open-guard; a slow/hung request left that guard stuck, so further taps
    // were silently ignored until the screen was rebuilt by switching tabs.
    _showChatOverlay(<String, dynamic>{
      ...chat,
      'id': chatroomId,
      'userId': chat['userId']?.toString() ?? '',
      'userName': chat['userName']?.toString() ?? 'Unknown',
    });

    // Mark as read in the background — never block the tap on a network call.
    unawaited(
      AdsyConnectService.markChatroomAsRead(chatroomId).catchError((e) {
        debugPrint('Error marking chatroom as read: $e');
      }),
    );
  }

  void _showChatOverlay(Map<String, dynamic> chat) {
    final chatroomId = chat['id']?.toString() ?? '';
    if (chatroomId.isEmpty) return;
    if (_activeChatOverlay != null && _activeOverlayChatroomId == chatroomId) {
      return;
    }

    _removeActiveChatOverlay(refreshAfterClose: false);

    final overlay = Overlay.of(context, rootOverlay: true);
    final entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: Material(
          color: const Color(0xFFF8FAFC),
          child: ScaffoldMessenger(
            child: Navigator(
              onGenerateRoute: (settings) {
                final chatRouteName =
                    AdsyConnectChatInterface.routeNameFor(chatroomId);
                if (settings.name == Navigator.defaultRouteName ||
                    settings.name == chatRouteName) {
                  return MaterialPageRoute<void>(
                    settings: RouteSettings(name: chatRouteName),
                    builder: (_) => AdsyConnectChatInterface(
                      key: ValueKey('adsy_chat_overlay_$chatroomId'),
                      chatroomId: chatroomId,
                      userId: chat['userId']?.toString() ?? '',
                      userName: chat['userName']?.toString() ?? 'Unknown',
                      userAvatar: chat['userAvatar']?.toString(),
                      profession: chat['profession']?.toString(),
                      isOnline: _parseBool(chat['isOnline']),
                      isVerified: _parseBool(chat['isVerified']),
                      isPro: _parseBool(chat['isPro']),
                      onClose: _closeActiveChatOverlay,
                    ),
                  );
                }

                if (_rootRoutesAllowedFromChatOverlay.contains(settings.name)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _removeActiveChatOverlay(refreshAfterClose: false);
                    final rootNavigator = FCMService.navigatorKey.currentState;
                    final routeName = settings.name ?? '/';
                    if (rootNavigator == null) return;

                    if (routeName == '/' || routeName == '/business-network') {
                      rootNavigator.pushNamedAndRemoveUntil(
                        routeName,
                        (route) => route.isFirst,
                        arguments: settings.arguments,
                      );
                    } else {
                      rootNavigator.pushNamed(
                        routeName,
                        arguments: settings.arguments,
                      );
                    }
                  });

                  return MaterialPageRoute<void>(
                    builder: (_) => const SizedBox.shrink(),
                  );
                }

                return MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Page not found')),
                    body: Center(
                      child: Text(
                        'Unknown chat route: ${settings.name ?? ''}',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    _activeOverlayChatroomId = chatroomId;
    _activeChatOverlay = entry;
    overlay.insert(entry);

    // While this chat overlay is up, internal link taps inside it must close
    // it first (it sits above the root navigator) so the destination shows on
    // top instead of hiding behind the chat.
    DeepLinkService.dismissTransientOverlay = () {
      _removeActiveChatOverlay(refreshAfterClose: false);
    };
  }

  void _closeActiveChatOverlay() {
    _removeActiveChatOverlay(refreshAfterClose: true);
  }

  void _removeActiveChatOverlay({required bool refreshAfterClose}) {
    final entry = _activeChatOverlay;
    _activeChatOverlay = null;
    _activeOverlayChatroomId = null;
    // Stop intercepting internal links once no chat overlay is up.
    DeepLinkService.dismissTransientOverlay = null;

    if (entry != null && entry.mounted) {
      entry.remove();
    }

    if (refreshAfterClose && mounted) {
      unawaited(_refreshChats());
    }
  }

  /// Push-tap deep link for GROUP messages: fetch the groups once, find the
  /// target and open its chat screen directly — the user lands INSIDE the
  /// group, not on the list.
  bool _didOpenInitialGroup = false;

  Future<void> _openInitialGroupIfNeeded() async {
    if (_didOpenInitialGroup || !mounted) return;
    final groupId = widget.initialGroupId;
    if (groupId == null || groupId.isEmpty) return;
    _didOpenInitialGroup = true;

    var group = _groups.cast<Map<String, dynamic>?>().firstWhere(
          (g) => (g?['id'] ?? '').toString() == groupId,
          orElse: () => null,
        );
    if (group == null) {
      final gs = await AdsyConnectService.getGroups();
      group = gs
          .whereType<Map>()
          .map((g) => Map<String, dynamic>.from(g))
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (g) => (g?['id'] ?? '').toString() == groupId,
            orElse: () => null,
          );
    }
    if (group == null || !mounted) return;
    await _openGroup(group);
  }

  Future<void> _openInitialChatIfNeeded() async {
    if (_didOpenInitialChat || !mounted) {
      return;
    }

    final initialChatId = widget.initialChatId;
    if (initialChatId == null || initialChatId.isEmpty) {
      return;
    }

    _didOpenInitialChat = true;
    var chat = _chatConversations.cast<Map<String, dynamic>?>().firstWhere(
          (candidate) => candidate?['id']?.toString() == initialChatId,
          orElse: () => null,
        );

    if (chat == null) {
      final details =
          await AdsyConnectService.getChatRoomDetails(initialChatId);
      if (!mounted || details == null) {
        return;
      }

      final parsed = _parseChatRooms([details]);
      if (parsed.isEmpty) {
        return;
      }

      chat = parsed.first;
      setState(() {
        if (!_chatConversations
            .any((c) => c['id']?.toString() == initialChatId)) {
          _chatConversations.insert(0, chat!);
        }
      });
    }

    if (!mounted) {
      return;
    }

    unawaited(_openChat(chat));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingChats && _chatConversations.isEmpty) {
      return const ChatListSkeleton();
    }

    // NOTE: no full-screen "No conversations yet" here — even with zero
    // chats the search bar, group/archive buttons, tabs and groups must stay
    // visible (a user can have groups but no 1:1 chats). The per-tab empty
    // state below handles the empty list area.
    final chatsToShow = _filteredChats;
    final isFiltering = _chatSearchQuery.trim().isNotEmpty;

    return Stack(
      children: [
        AdsyRefreshIndicator(
          onRefresh: _activeChatTab == _ChatTab.groups
              ? _loadGroups
              : _refreshChats,
          color: const Color(0xFF111827),
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (_activeChatTab != _ChatTab.groups &&
                  !isFiltering &&
                  scrollInfo.metrics.pixels >=
                      scrollInfo.metrics.maxScrollExtent - 200) {
                _loadMoreChats();
              }
              return false;
            },
            // Everything scrolls together — search, contacts rail, header
            // and tabs are NOT sticky (concept design).
            child: CustomScrollView(
              controller: _listScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      // Story-style rail: quick access to recent chats.
                      if (_chatSearchQuery.trim().isEmpty)
                        _buildContactsRail(),
                      // "Chats" header: title + expanding search + menu
                      // (chat filters now live inside the "…" menu).
                      _buildChatsHeader(),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                if (isFiltering)
                  ..._buildSmartSearchSlivers(chatsToShow)
                else if (_activeChatTab == _ChatTab.groups)
                  ..._buildGroupSlivers()
                else if (chatsToShow.isEmpty && !_isLoadingChats)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 70),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_activeChatTab == _ChatTab.all)
                            AdsyChatIcon(
                                size: 46, color: Colors.grey.shade300)
                          else
                            Icon(_chatTabEmptyIcon,
                                size: 46, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          Text(
                            _chatTabEmptyMessage,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                    sliver: SliverList.builder(
                          itemCount: chatsToShow.length + (isFiltering ? 0 : 1),
                          itemBuilder: (context, index) {
                            if (!isFiltering && index == chatsToShow.length) {
                              if (_isLoadingMore) {
                                return const ChatListSkeleton(itemCount: 3);
                              } else if (!_hasMore && chatsToShow.isNotEmpty) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20, horizontal: 16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF1F5F9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFF111827),
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'All chats loaded',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF6B7280),
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'You\'re all caught up!',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }

                            final chat = chatsToShow[index];
                            return _buildChatItem(chat);
                          },
                        ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          ),
        ),
        // Universal back-to-top (same widget everywhere).
        AdsyBackToTop(controller: _listScrollController, bottom: 18),
        // Floating "+ New Chat" pill (concept design) — opens the quick
        // actions sheet.
        Positioned(
          left: 0,
          right: 0,
          bottom: 16,
          child: Center(
            child: GestureDetector(
              onTap: _showNewChatSheet,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 19),
                    SizedBox(width: 6),
                    Text(
                      'New Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Concept-design pieces: contacts rail, Chats header, New Chat sheet ──

  /// Horizontal story-style rail of the most recent 1:1 chats. First slot is
  /// the "+" tile (create group). Tap an avatar to jump into that chat.
  Widget _buildContactsRail() {
    // Online contacts lead the rail; within each group keep recency order
    // (the list itself is already most-recent-first).
    final candidates =
        _chatConversations.where((c) => c['isGroup'] != true).take(20).toList();
    final recent = [
      ...candidates.where((c) => c['isOnline'] == true),
      ...candidates.where((c) => c['isOnline'] != true),
    ].take(12).toList();
    if (recent.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 84 * adsyIosBoxScale(),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
        itemCount: recent.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          if (i == 0) {
            // "+" tile — create a group chat.
            return GestureDetector(
              onTap: _openCreateGroup,
              child: SizedBox(
                width: 56 * adsyIosBoxScale(),
                child: Column(
                  children: [
                    Container(
                      width: 54 * adsyIosBoxScale(),
                      height: 54 * adsyIosBoxScale(),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Color(0xFF334155), size: 24),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'নতুন গ্রুপ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          final chat = recent[i - 1];
          final avatar =
              AppConfig.getAbsoluteUrl(chat['userAvatar']?.toString() ?? '');
          final name = (chat['userName'] ?? '').toString();
          final firstName = name.split(' ').first;
          final isOnline = chat['isOnline'] == true;
          return GestureDetector(
            onTap: () => unawaited(_openChat(chat)),
            child: SizedBox(
              width: 56 * adsyIosBoxScale(),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 54 * adsyIosBoxScale(),
                        height: 54 * adsyIosBoxScale(),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFF1F5F9),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: avatar.isNotEmpty
                            ? Image.network(
                                avatar,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Color(0xFF334155),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Color(0xFF334155),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                      ),
                      if (isOnline)
                        Positioned(
                          bottom: 1,
                          right: 1,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    firstName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// "Chats" title + elastically expanding search + overflow menu. While the
  /// search is open the "…" menu hides (concept design).
  Widget _buildChatsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 0),
      child: Row(
        children: [
          const Text(
            'Chats',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
          // Quick filters: all chats / group chats — hidden while the
          // search input is expanded so it gets the full width.
          if (!_chatSearchOpen) ...[
            const SizedBox(width: 8),
            _quickFilterIcon(_ChatTab.all, Icons.chat_bubble_outline_rounded),
            const SizedBox(width: 5),
            _quickFilterIcon(_ChatTab.groups, Icons.groups_outlined),
          ],
          // Active filter chip for menu-only filters — tap ✕ to reset.
          if (_activeChatTab != _ChatTab.all &&
              _activeChatTab != _ChatTab.groups &&
              !_chatSearchOpen) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _activeChatTab = _ChatTab.all),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _chatTabLabel(_activeChatTab),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.close_rounded,
                        size: 13, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(width: 10),
          // Expanding search input — grows from the right.
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => SizeTransition(
                  sizeFactor: animation,
                  axis: Axis.horizontal,
                  axisAlignment: 1, // expand towards the left
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: _chatSearchOpen
                    ? Container(
                        key: const ValueKey('chat_search_open'),
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: TextField(
                          controller: _chatSearchController,
                          autofocus: true,
                          style: const TextStyle(fontSize: 13.5),
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: 'Search chats',
                            hintStyle: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13),
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('chat_search_closed')),
              ),
            ),
          ),
          // Search toggle: magnifier ↔ close.
          IconButton(
            onPressed: () {
              setState(() {
                _chatSearchOpen = !_chatSearchOpen;
                if (!_chatSearchOpen) _chatSearchController.clear();
              });
            },
            icon: Icon(
              _chatSearchOpen ? Icons.close_rounded : Icons.search_rounded,
              color: const Color(0xFF64748B),
              size: 21,
            ),
          ),
          if (!_chatSearchOpen)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded,
                  color: Color(0xFF64748B), size: 22),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onSelected: (v) {
                if (v == 'archived') {
                  _openArchivedChats();
                  return;
                }
                if (v == 'group') {
                  _openCreateGroup();
                  return;
                }
                // Filter selections.
                final tab = _ChatTab.values
                    .cast<_ChatTab?>()
                    .firstWhere((t) => 'tab_${t!.name}' == v,
                        orElse: () => null);
                if (tab != null) {
                  setState(() => _activeChatTab = tab);
                  if (tab == _ChatTab.groups && !_groupsLoadedOnce) {
                    _loadGroups();
                  }
                }
              },
              itemBuilder: (_) => [
                for (final t in _ChatTab.values)
                  PopupMenuItem(
                    value: 'tab_${t.name}',
                    height: 42,
                    child: Row(
                      children: [
                        Icon(_chatTabIcon(t),
                            size: 17,
                            color: _activeChatTab == t
                                ? const Color(0xFF111827)
                                : const Color(0xFF64748B)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _chatTabLabel(t),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: _activeChatTab == t
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ),
                        if (_tabCount(t) > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${_tabCount(t)}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        if (_activeChatTab == t) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_rounded,
                              size: 16, color: Color(0xFF111827)),
                        ],
                      ],
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'archived',
                  height: 42,
                  child: Row(
                    children: [
                      Icon(Icons.archive_outlined,
                          size: 17, color: Color(0xFF64748B)),
                      SizedBox(width: 10),
                      Text('আর্কাইভড চ্যাট',
                          style: TextStyle(fontSize: 13.5)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'group',
                  height: 42,
                  child: Row(
                    children: [
                      Icon(Icons.group_add_outlined,
                          size: 17, color: Color(0xFF64748B)),
                      SizedBox(width: 10),
                      Text('নতুন গ্রুপ তৈরি করুন',
                          style: TextStyle(fontSize: 13.5)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// The same user-search flow the old floating bubble used to open.
  void _openUserSearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewChatModal(parentContext: context),
    ).then((_) {
      // A brand-new chatroom may exist now — show it without a manual reload.
      if (mounted) unawaited(_loadChats());
    });
  }

  /// Concept-style quick actions sheet behind the "+ New Chat" pill —
  /// built on the shared AdsySheet kit (this sheet IS the design source).
  void _showNewChatSheet() {
    AdsySheet.show(
      context,
      children: [
        AdsySheetAction(
          icon: Icons.person_search_rounded,
          title: 'নতুন চ্যাট',
          subtitle: 'নাম দিয়ে খুঁজে যে কারো সাথে মেসেজ শুরু করুন',
          onTap: _openUserSearchModal,
        ),
        AdsySheetAction(
          icon: Icons.group_add_outlined,
          title: 'নতুন গ্রুপ',
          subtitle: 'বন্ধুদের নিয়ে একটি গ্রুপ চ্যাট তৈরি করুন',
          onTap: _openCreateGroup,
        ),
        AdsySheetAction(
          icon: Icons.archive_outlined,
          title: 'আর্কাইভড চ্যাট',
          subtitle: 'আর্কাইভ করা চ্যাটগুলো দেখুন ও ফিরিয়ে আনুন',
          onTap: _openArchivedChats,
        ),
      ],
    );
  }

  // Bottom sheet of per-conversation actions (long-press) — unified
  // AdsySheet design.
  void _showChatActions(Map<String, dynamic> chat) {
    final id = chat['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final bool muted = chat['isMuted'] == true;
    AdsySheet.show(
      context,
      children: [
        AdsySheetAction(
          icon: Icons.archive_outlined,
          title: 'আর্কাইভ করুন',
          subtitle: 'চ্যাটটি তালিকা থেকে সরিয়ে রাখুন',
          onTap: () => _archiveChat(chat),
        ),
        AdsySheetAction(
          icon: muted
              ? Icons.notifications_active_outlined
              : Icons.notifications_off_outlined,
          title: muted ? 'আনমিউট করুন' : 'মিউট করুন',
          subtitle: muted
              ? 'নোটিফিকেশন আবার চালু হবে'
              : 'এই চ্যাটের নোটিফিকেশন বন্ধ থাকবে',
          onTap: () => _muteChat(chat, !muted),
        ),
        AdsySheetAction(
          icon: Icons.delete_outline_rounded,
          title: 'চ্যাট মুছুন',
          subtitle: 'আপনার দিক থেকে চ্যাটটি মুছে যাবে',
          destructive: true,
          onTap: () => _deleteChat(chat),
        ),
      ],
    );
  }

  Future<void> _openArchivedChats() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ArchivedChatsScreen()),
    );
    // A chat was unarchived while inside — reload so it reappears in the list.
    if (changed == true && mounted) {
      _loadChats();
    }
  }

  Future<void> _archiveChat(Map<String, dynamic> chat) async {
    final id = chat['id']?.toString() ?? '';
    final ok = await AdsyConnectService.setArchived(id, true);
    if (!mounted) return;
    if (ok) {
      setState(() => _chatConversations.removeWhere((c) => c['id'] == chat['id']));
      AdsyToast.info(context, 'চ্যাট আর্কাইভ হয়েছে');
    } else {
      AdsyToast.error(context, 'আর্কাইভ করা যায়নি');
    }
  }

  Future<void> _muteChat(Map<String, dynamic> chat, bool muted) async {
    final id = chat['id']?.toString() ?? '';
    final ok = await AdsyConnectService.setMuted(id, muted);
    if (!mounted) return;
    if (ok) {
      setState(() => chat['isMuted'] = muted);
      AdsyToast.info(context, muted ? 'মিউট হয়েছে' : 'আনমিউট হয়েছে');
    } else {
      AdsyToast.error(context, 'করা যায়নি');
    }
  }

  Future<void> _deleteChat(Map<String, dynamic> chat) async {
    final id = chat['id']?.toString() ?? '';
    final confirm = await AdsyDialog.confirm(
      context,
      title: 'চ্যাট মুছবেন?',
      message: 'আপনার দিক থেকে এই চ্যাটের সব মেসেজ মুছে যাবে।',
      confirmLabel: 'মুছুন',
      cancelLabel: 'বাতিল',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (confirm != true) return;
    final res = await AdsyConnectService.clearConversation(id);
    if (!mounted) return;
    if (res != null) {
      setState(() => _chatConversations.removeWhere((c) => c['id'] == chat['id']));
      AdsyToast.success(context, 'চ্যাট মুছে গেছে');
    } else {
      AdsyToast.error(context, 'মুছতে ব্যর্থ');
    }
  }

  IconData get _chatTabEmptyIcon {
    switch (_activeChatTab) {
      case _ChatTab.groups:
        return Icons.groups_outlined;
      case _ChatTab.spam:
        return Icons.verified_user_outlined;
      case _ChatTab.mutual:
        return Icons.handshake_outlined;
      case _ChatTab.nonFollowers:
        return Icons.person_outline_rounded;
      case _ChatTab.all:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  String get _chatTabEmptyMessage {
    switch (_activeChatTab) {
      case _ChatTab.groups:
        return 'এখনো কোনো গ্রুপ চ্যাট নেই';
      case _ChatTab.spam:
        return 'কোনো স্প্যাম মেসেজ নেই';
      case _ChatTab.mutual:
        return 'কোনো মিউচুয়াল চ্যাট নেই';
      case _ChatTab.nonFollowers:
        return 'নন-ফলোয়ারদের কোনো চ্যাট নেই';
      case _ChatTab.all:
        return 'এখনো কোনো চ্যাট নেই';
    }
  }

  /// Groups tab content as slivers so it scrolls together with the header
  /// area in the main CustomScrollView.
  List<Widget> _buildGroupSlivers() {
    if (_loadingGroups) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 70),
            child: Center(child: AdsyLoadingIndicator()),
          ),
        ),
      ];
    }
    if (_groups.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 70),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.groups_outlined,
                    size: 46, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text('এখনো কোনো গ্রুপ চ্যাট নেই',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _openCreateGroup,
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF111827)),
                  icon: const Icon(Icons.group_add_outlined, size: 18),
                  label: const Text('গ্রুপ তৈরি করুন'),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
        sliver: SliverList.builder(
          itemCount: _groups.length,
          itemBuilder: (_, i) => _buildGroupItem(_groups[i]),
        ),
      ),
    ];
  }

  Widget _buildGroupItem(Map<String, dynamic> group) {
    final name = (group['name'] ?? '').toString();
    var preview = (group['last_message_preview'] ?? '').toString();
    // Never leak a shared-post payload into the list preview.
    if (preview.contains('ADSYPOST')) {
      final who = preview.split(':').first.trim();
      preview = who.isNotEmpty && !who.contains('ADSYPOST')
          ? '$who: 📎 একটি পোস্ট'
          : '📎 একটি পোস্ট শেয়ার করা হয়েছে';
    }
    final memberCount =
        group['member_count'] ?? (group['members'] as List? ?? []).length;
    final imageUrl = (group['image_url'] ?? '').toString();
    final lastAt =
        DateTime.tryParse((group['last_message_at'] ?? '').toString());
    final unread = ((group['unread_count'] as num?) ?? 0).toInt();
    return InkWell(
      onTap: () => _openGroup(group),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: Colors.white,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFFF1F5F9)),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.groups,
                          color: Color(0xFF334155), size: 24))
                  : const Icon(Icons.groups,
                      color: Color(0xFF334155), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937))),
                      ),
                      if (lastAt != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(lastAt),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preview.isNotEmpty ? preview : '$memberCount জন মেম্বার',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          unread > 0 ? FontWeight.w600 : FontWeight.w400,
                      color: unread > 0
                          ? const Color(0xFF1F2937)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            // Unread badge — same amber pill as the 1:1 rows.
            if (unread > 0) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 19),
                padding:
                    const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2.5),
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                child: Text(
                  unread.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Small circular quick-filter toggle beside the "Chats" title.
  Widget _quickFilterIcon(_ChatTab tab, IconData icon) {
    final active = _activeChatTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() => _activeChatTab = tab);
        if (tab == _ChatTab.groups && !_groupsLoadedOnce) _loadGroups();
      },
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
        ),
        // The main chats filter wears the AdsyConnect brand icon.
        child: tab == _ChatTab.all
            ? AdsyChatIcon(
                size: 15,
                color: active ? Colors.white : const Color(0xFF64748B),
              )
            : Icon(icon,
                size: 16,
                color: active ? Colors.white : const Color(0xFF64748B)),
      ),
    );
  }

  /// Social-style search results: matched conversations first ("চ্যাট"),
  /// then other platform users ("নতুন মানুষ") to start a chat with.
  List<Widget> _buildSmartSearchSlivers(
      List<Map<String, dynamic>> chatsToShow) {
    final nothingFound =
        chatsToShow.isEmpty && _peopleResults.isEmpty && !_peopleSearching;
    return [
      if (chatsToShow.isNotEmpty) ...[
        SliverToBoxAdapter(child: _searchSectionLabel('চ্যাট')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
          sliver: SliverList.builder(
            itemCount: chatsToShow.length,
            itemBuilder: (context, index) =>
                _buildChatItem(chatsToShow[index]),
          ),
        ),
      ],
      if (_peopleSearching)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 26),
            child: Center(child: AdsyLoadingIndicator()),
          ),
        )
      else if (_peopleResults.isNotEmpty) ...[
        SliverToBoxAdapter(child: _searchSectionLabel('নতুন মানুষ')),
        SliverToBoxAdapter(child: _buildPeopleFilterTabs()),
        if (_filteredPeople().isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: Text(
                  'এই ফিল্টারে কেউ নেই',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
            sliver: SliverList.builder(
              itemCount: _filteredPeople().length,
              itemBuilder: (context, index) =>
                  _buildPersonTile(_filteredPeople()[index]),
            ),
          ),
      ],
      if (nothingFound)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 70),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off_rounded,
                    size: 46, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text(
                  'No results found',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _searchSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  /// People search results narrowed by the active filter tab.
  List<Map<String, dynamic>> _filteredPeople() {
    switch (_peopleFilter) {
      case 'following':
        return _peopleResults
            .where((u) => u['is_following'] == true)
            .toList();
      case 'new':
        return _peopleResults
            .where((u) => u['is_following'] != true)
            .toList();
      default:
        return _peopleResults;
    }
  }

  Widget _buildPeopleFilterTabs() {
    const tabs = [
      ('all', 'সব'),
      ('following', 'ফলোয়িং'),
      ('new', 'নতুন'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      child: Row(
        children: [
          for (final t in tabs) ...[
            GestureDetector(
              onTap: () => setState(() => _peopleFilter = t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _peopleFilter == t.$1
                      ? const Color(0xFF111827)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  t.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _peopleFilter == t.$1
                        ? Colors.white
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  /// A platform user (no existing conversation) in smart-search results.
  Widget _buildPersonTile(Map<String, dynamic> user) {
    final name = (user['first_name'] != null && user['last_name'] != null)
        ? '${user['first_name']} ${user['last_name']}'.trim()
        : (user['username'] ?? 'User').toString();
    final avatar = AppConfig.getAbsoluteUrl(
        (user['image'] ?? user['profile_picture'] ?? '').toString());
    final profession = (user['profession'] ?? '').toString();
    final verified = user['kyc'] == true || user['is_verified'] == true;
    final isPro = user['is_pro'] == true;

    return InkWell(
      onTap: () => unawaited(_startChatWithUser(user)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: Colors.white,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF1F5F9),
              ),
              clipBehavior: Clip.antiAlias,
              child: avatar.isNotEmpty
                  ? Image.network(
                      avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      if (verified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            size: 14, color: Color(0xFF2563EB)),
                      ],
                      if (isPro) ...[
                        const SizedBox(width: 4),
                        const AdsyProBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    profession.isNotEmpty
                        ? profession
                        : 'নতুন চ্যাট শুরু করুন',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Follow — this is a brand-new person after all.
            GestureDetector(
              onTap: () => unawaited(_toggleFollowPerson(user)),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: user['is_following'] == true
                      ? Colors.white
                      : const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: user['is_following'] == true
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF111827),
                  ),
                ),
                child: Text(
                  user['is_following'] == true ? 'Following' : 'Follow',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: user['is_following'] == true
                        ? const Color(0xFF64748B)
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// True when a chat-list preview is genuine user text worth matching in
  /// search (skips call logs, shared posts and system placeholders).
  bool _searchableMessage(String lowerMsg) {
    final m = lowerMsg.trim();
    if (m.isEmpty) return false;
    const nonText = [
      'video call',
      'audio call',
      'message removed',
      'no messages yet',
      'photo',
      'voice message',
    ];
    for (final p in nonText) {
      if (m.startsWith(p) || m.startsWith('📷') || m.startsWith('🎤')) {
        return false;
      }
    }
    if (m.contains('একটি পোস্ট')) return false;
    return true;
  }

  /// Optimistic follow/unfollow from the smart-search person tile.
  Future<void> _toggleFollowPerson(Map<String, dynamic> user) async {
    final id = user['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final wasFollowing = user['is_following'] == true;
    setState(() => user['is_following'] = !wasFollowing);
    final ok = wasFollowing
        ? await UserSuggestionsService.unfollowUser(id)
        : await UserSuggestionsService.followUser(id);
    if (!ok && mounted) {
      setState(() => user['is_following'] = wasFollowing);
      AdsyToast.error(context, 'করা যায়নি, আবার চেষ্টা করুন');
    }
  }

  /// Preview text with the search query highlighted (soft yellow marker).
  Widget _highlightedText(String text, TextStyle base) {
    final q = _chatSearchQuery.trim();
    if (q.isEmpty) {
      return Text(text,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: base);
    }
    final idx = text.toLowerCase().indexOf(q.toLowerCase());
    if (idx < 0) {
      return Text(text,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: base);
    }
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + q.length),
            style: base.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
              backgroundColor: const Color(0x55FACC15),
            ),
          ),
          TextSpan(text: text.substring(idx + q.length)),
        ],
      ),
    );
  }

  // Chat filter labels/icons — the filters live inside the Chats "…" menu.
  String _chatTabLabel(_ChatTab tab) {
    switch (tab) {
      case _ChatTab.all:
        return 'সব';
      case _ChatTab.mutual:
        return 'মিউচুয়াল';
      case _ChatTab.groups:
        return 'গ্রুপ';
      case _ChatTab.nonFollowers:
        return 'নন-ফলোয়ার';
      case _ChatTab.spam:
        return 'স্প্যাম';
    }
  }

  IconData _chatTabIcon(_ChatTab tab) {
    switch (tab) {
      case _ChatTab.all:
        return Icons.chat_bubble_outline_rounded;
      case _ChatTab.mutual:
        return Icons.handshake_outlined;
      case _ChatTab.groups:
        return Icons.groups_outlined;
      case _ChatTab.nonFollowers:
        return Icons.person_outline_rounded;
      case _ChatTab.spam:
        return Icons.report_gmailerrorred_rounded;
    }
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    // Group entries merged into the main list render as group tiles.
    if (chat['isGroup'] == true && chat['_group'] is Map) {
      return _buildGroupItem(
          Map<String, dynamic>.from(chat['_group'] as Map));
    }
    final bool hasUnread = chat['unreadCount'] > 0;
    final bool isOnline = chat['isOnline'] ?? false;
    final bool isTyping = chat['isTyping'] ?? false;

    return Dismissible(
      key: ValueKey('chat_${chat['id']}'),
      // Swipe left → archive; swipe right → delete (confirmed inside).
      background: Container(
        color: const Color(0xFFDC2626),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: const Color(0xFF64748B),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.archive_outlined, color: Colors.white),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.endToStart) {
          _archiveChat(chat);
        } else {
          _deleteChat(chat);
        }
        return false; // we mutate the list ourselves after the async call
      },
      child: InkWell(
      onTap: () => unawaited(_openChat(chat)),
      onLongPress: () => _showChatActions(chat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: Colors.white,
        child: Row(
          children: [
            // Avatar with online indicator (iOS gets a slightly bigger box —
            // it renders visually smaller there).
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48 * adsyIosBoxScale(),
                  height: 48 * adsyIosBoxScale(),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF1F5F9),
                  ),
                  child: ClipOval(
                    child: chat['userAvatar'] != null &&
                            AppConfig.getAbsoluteUrl(chat['userAvatar'])
                                .isNotEmpty
                        ? Image.network(
                            AppConfig.getAbsoluteUrl(chat['userAvatar']),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  chat['userName'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF334155),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              chat['userName'][0].toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                chat['userName'],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: hasUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: const Color(0xFF1F2937),
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (chat['isVerified'] == true) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified,
                                  size: 14, color: Color(0xFF2563EB)),
                            ],
                            if (chat['isPro'] == true) ...[
                              const SizedBox(width: 4),
                              const AdsyProBadge(),
                            ],
                            if (isTyping) ...[
                              const SizedBox(width: 4),
                              const Text(
                                'typing\u2026',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                            // Deactivated/suspended account chip beside the
                            // name.
                            if (chat['isDeleted'] == true ||
                                chat['isSuspended'] == true) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                      color: const Color(0xFFFECACA)),
                                ),
                                child: Text(
                                  chat['isDeleted'] == true
                                      ? '\u0987\u0989\u099c\u09be\u09b0 \u09a1\u09bf\u09b2\u09bf\u099f\u09c7\u09a1'
                                      : '\u09b8\u09be\u09b8\u09aa\u09c7\u09a8\u09cd\u09a1\u09c7\u09a1',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (chat['isMuted'] == true) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.notifications_off_rounded,
                            size: 14, color: Colors.grey.shade400),
                      ],
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(chat['timestamp']),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: hasUnread
                              ? const Color(0xFF111827)
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  // Only show profession if it exists and is not empty
                  if (chat['profession'] != null &&
                      chat['profession'].toString().isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      chat['profession'],
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                        letterSpacing: -0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  _highlightedText(
                    (chat['lastMessage'] ?? '').toString(),
                    TextStyle(
                      fontSize: 13,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                      color: hasUnread
                          ? const Color(0xFF1F2937)
                          : const Color(0xFF6B7280),
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Unread badge
            if (hasUnread)
              // Amber unread badge, matching the concept design.
              Container(
                constraints: const BoxConstraints(minWidth: 19),
                padding:
                    const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2.5),
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                child: Text(
                  chat['unreadCount'].toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  /// Compact messenger-style timestamps: now / 12m / 3h / 6d / 5w.
  String _formatTimestamp(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) return 'now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${(difference.inDays / 7).floor()}w';
  }
}

/// Standalone list of the user's archived chats with an unarchive action.
/// Pops `true` when at least one chat was unarchived so the caller can refresh.
class ArchivedChatsScreen extends StatefulWidget {
  const ArchivedChatsScreen({super.key});

  @override
  State<ArchivedChatsScreen> createState() => _ArchivedChatsScreenState();
}

class _ArchivedChatsScreenState extends State<ArchivedChatsScreen> {
  bool _loading = true;
  bool _changed = false;
  List<Map<String, dynamic>> _rooms = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rooms =
          await AdsyConnectService.getChatRooms(pageSize: 100, archived: true);
      if (!mounted) return;
      setState(() {
        _rooms = rooms.map(_parseRoom).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _parseRoom(dynamic room) {
    final otherUser = room['other_user'] ?? {};
    final lastMessage = room['last_message'];
    final isDeleted = lastMessage?['is_deleted'] == true;
    final content = lastMessage?['content']?.toString() ??
        room['last_message_preview']?.toString() ??
        '';
    String preview;
    if (isDeleted || content == 'Message deleted') {
      preview = 'Message removed';
    } else if (content.isEmpty) {
      preview = 'No messages yet';
    } else {
      preview = content;
    }
    final first = (otherUser['first_name'] ?? '').toString();
    final last = (otherUser['last_name'] ?? '').toString();
    final username = (otherUser['username'] ?? 'User').toString();
    final name = [first, last].where((s) => s.isNotEmpty).join(' ');
    return {
      'id': room['id'],
      'userId': otherUser['id']?.toString() ?? '',
      'userName': name.isNotEmpty ? name : username,
      'userAvatar': otherUser['avatar'],
      'lastMessage': preview,
      'isVerified':
          otherUser['kyc'] == true || otherUser['is_verified'] == true,
      'isPro': otherUser['is_pro'] == true,
    };
  }

  Future<void> _unarchive(Map<String, dynamic> room) async {
    final id = room['id']?.toString() ?? '';
    final ok = await AdsyConnectService.setArchived(id, false);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _rooms.removeWhere((r) => r['id'] == room['id']);
        _changed = true;
      });
      AdsyToast.info(context, 'চ্যাট আনআর্কাইভ হয়েছে');
    } else {
      AdsyToast.error(context, 'আনআর্কাইভ করা যায়নি');
    }
  }

  void _openChat(Map<String, dynamic> room) {
    unawaited(AdsyConnectChatInterface.open(
      context,
      chatroomId: room['id']?.toString() ?? '',
      userId: room['userId']?.toString() ?? '',
      userName: room['userName']?.toString() ?? '',
      userAvatar: room['userAvatar']?.toString(),
      isVerified: room['isVerified'] == true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          surfaceTintColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF334155)),
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
          title: const Text('আর্কাইভ করা চ্যাট',
              style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
        ),
        body: _loading
            ? const Center(child: AdsyLoadingIndicator())
            : _rooms.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: _rooms.length,
                    separatorBuilder: (_, __) => Divider(
                        height: 1, color: Colors.grey.shade100, indent: 74),
                    itemBuilder: (_, i) => _buildTile(_rooms[i]),
                  ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.archive_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('কোনো আর্কাইভ করা চ্যাট নেই',
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTile(Map<String, dynamic> room) {
    final avatar =
        AppConfig.getAbsoluteUrl((room['userAvatar'] ?? '').toString());
    final name = room['userName']?.toString() ?? '';
    return InkWell(
      onTap: () => _openChat(room),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade200),
              ),
              clipBehavior: Clip.antiAlias,
              child: avatar.isNotEmpty
                  ? Image.network(avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.person,
                          color: Colors.grey.shade400, size: 24))
                  : Icon(Icons.person, color: Colors.grey.shade400, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B))),
                      ),
                      if (room['isVerified'] == true) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            size: 14, color: Color(0xFF2563EB)),
                      ],
                      if (room['isPro'] == true) ...[
                        const SizedBox(width: 4),
                        const AdsyProBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(room['lastMessage']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12.5, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Unarchive action.
            TextButton.icon(
              onPressed: () => _unarchive(room),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF111827),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.unarchive_outlined, size: 18),
              label: const Text('আনআর্কাইভ',
                  style:
                      TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
