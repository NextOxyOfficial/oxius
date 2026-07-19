import 'package:flutter/material.dart';
import 'dart:async';
import 'adsy_connect_chat_interface.dart';
import 'create_group_screen.dart';
import 'group_chat_screen.dart';
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

/// Chat-list buckets. Spam is hidden from every tab except its own so junk
/// never clutters real conversations.
enum _ChatTab { all, mutual, groups, nonFollowers, spam }

class AdsyConnectScreen extends StatefulWidget {
  const AdsyConnectScreen({super.key, this.initialChatId});

  final String? initialChatId;

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
  String _chatSearchQuery = '';
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
    }
  }

  /// Instantly reflect an incoming message on the chat list — preview, time,
  /// unread badge and position (move to top) — without waiting for the
  /// background page-1 re-fetch.
  void _applyIncomingMessageToList(dynamic message) {
    if (message is! Map) return;
    final roomId = (message['chatroom'] ?? '').toString();
    if (roomId.isEmpty) return;

    final index = _chatConversations
        .indexWhere((c) => (c['id'] ?? '').toString() == roomId);
    if (index == -1) {
      // Brand-new conversation — the background refresh inserts it.
      return;
    }

    final preview =
        (message['display_content'] ?? message['content'] ?? '').toString();
    final createdAt =
        DateTime.tryParse((message['created_at'] ?? '').toString()) ??
            DateTime.now();
    final senderId =
        (message['sender'] is Map ? message['sender']['id'] : null)?.toString();
    final isFromPeer = senderId != null &&
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
    _chatSearchController.dispose();
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
      return name.contains(q) || msg.contains(q);
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
        'isVerified': otherUser['is_verified'] ?? false,
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
          color: const Color(0xFFF0F9FF),
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
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatSearchController,
                      style: const TextStyle(fontSize: 14),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded,
                            color: Colors.grey.shade500, size: 20),
                        // Tight icon box so the icon + hint read as one line
                        // instead of the icon floating far from the text.
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 38, minHeight: 0),
                        hintText: 'Search chats',
                        hintStyle: TextStyle(
                            color: Colors.grey.shade500, fontSize: 14),
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.only(
                            left: 4, right: 12, top: 11, bottom: 11),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Create a new group chat.
                  InkWell(
                    onTap: _openCreateGroup,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Icon(Icons.group_add_outlined,
                          color: Colors.grey.shade700, size: 21),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Archived chats entry point.
                  InkWell(
                    onTap: _openArchivedChats,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Icon(Icons.archive_outlined,
                          color: Colors.grey.shade700, size: 21),
                    ),
                  ),
                ],
              ),
            ),
            _buildChatTabs(),
            Expanded(
              child: _activeChatTab == _ChatTab.groups
                  ? _buildGroupsList()
                  : chatsToShow.isEmpty && (isFiltering || !_isLoadingChats)
                  ? Center(
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
                            isFiltering
                                ? 'No results found'
                                : _chatTabEmptyMessage,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : AdsyRefreshIndicator(
                      onRefresh: _refreshChats,
                      color: const Color(0xFF3B82F6),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (!isFiltering &&
                              scrollInfo.metrics.pixels >=
                                  scrollInfo.metrics.maxScrollExtent - 200) {
                            _loadMoreChats();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
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
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B82F6)
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFF3B82F6),
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
                    ),
            ),
          ],
        ),
      ],
    );
  }

  // Bottom sheet of per-conversation actions (long-press).
  void _showChatActions(Map<String, dynamic> chat) {
    final id = chat['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final bool muted = chat['isMuted'] == true;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 6),
            _chatActionTile(ctx, Icons.archive_outlined, 'আর্কাইভ করুন',
                () => _archiveChat(chat)),
            _chatActionTile(
                ctx,
                muted ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                muted ? 'আনমিউট করুন' : 'মিউট করুন',
                () => _muteChat(chat, !muted)),
            _chatActionTile(ctx, Icons.delete_outline_rounded, 'চ্যাট মুছুন',
                () => _deleteChat(chat), danger: true),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _chatActionTile(BuildContext ctx, IconData icon, String label,
      VoidCallback onTap, {bool danger = false}) {
    final color = danger ? const Color(0xFFDC2626) : const Color(0xFF334155);
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: TextStyle(
              color: color, fontSize: 14.5, fontWeight: FontWeight.w600)),
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('চ্যাট মুছবেন?'),
        content: const Text('আপনার দিক থেকে এই চ্যাটের সব মেসেজ মুছে যাবে।'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('বাতিল')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('মুছুন')),
        ],
      ),
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

  Widget _buildGroupsList() {
    if (_loadingGroups) {
      return const Center(child: AdsyLoadingIndicator());
    }
    if (_groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 46, color: Colors.grey.shade300),
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
                  backgroundColor: const Color(0xFF2563EB)),
              icon: const Icon(Icons.group_add_outlined, size: 18),
              label: const Text('গ্রুপ তৈরি করুন'),
            ),
          ],
        ),
      );
    }
    return AdsyRefreshIndicator(
      onRefresh: _loadGroups,
      color: const Color(0xFF3B82F6),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        itemCount: _groups.length,
        itemBuilder: (_, i) => _buildGroupItem(_groups[i]),
      ),
    );
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
    return InkWell(
      onTap: () => _openGroup(group),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFFE5E7EB).withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFFEFF6FF)),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.groups,
                          color: Color(0xFF3B82F6), size: 24))
                  : const Icon(Icons.groups,
                      color: Color(0xFF3B82F6), size: 24),
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
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Horizontal scrollable pill tabs: All / Mutual / Groups / Non-followers /
  // Maybe spam. Spam is bucketed away from the other tabs.
  Widget _buildChatTabs() {
    const tabs = [
      (_ChatTab.all, 'সব', Icons.chat_bubble_outline_rounded),
      (_ChatTab.mutual, 'মিউচুয়াল', Icons.handshake_outlined),
      (_ChatTab.groups, 'গ্রুপ', Icons.groups_outlined),
      (_ChatTab.nonFollowers, 'নন-ফলোয়ার', Icons.person_outline_rounded),
      (_ChatTab.spam, 'স্প্যাম', Icons.report_gmailerrorred_rounded),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (tab, label, icon) = tabs[i];
          final active = _activeChatTab == tab;
          final count = _tabCount(tab);
          return InkWell(
            onTap: () {
              setState(() => _activeChatTab = tab);
              if (tab == _ChatTab.groups && !_groupsLoadedOnce) {
                _loadGroups();
              }
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF3B82F6) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  // Brand chat icon for the main tab; Material icons elsewhere.
                  if (tab == _ChatTab.all)
                    AdsyChatIcon(
                        size: 15, color: active ? Colors.white : null)
                  else
                    Icon(icon,
                        size: 15,
                        color: active ? Colors.white : Colors.grey.shade600),
                  const SizedBox(width: 5),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color:
                              active ? Colors.white : const Color(0xFF475569))),
                  if (count > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white.withValues(alpha: 0.25)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('$count',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? Colors.white
                                  : const Color(0xFF475569))),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: hasUnread
              ? const Color(0xFF3B82F6).withValues(alpha: 0.02)
              : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFFE5E7EB).withValues(alpha: 0.4),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEFF6FF),
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
                                    color: Color(0xFF3B82F6),
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
                                color: Color(0xFF3B82F6),
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
                              ? const Color(0xFF3B82F6)
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
                  Text(
                    chat['lastMessage'],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                      color: hasUnread
                          ? const Color(0xFF1F2937)
                          : const Color(0xFF6B7280),
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Unread badge
            if (hasUnread)
              Container(
                constraints: const BoxConstraints(minWidth: 19),
                padding:
                    const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2.5),
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
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
      'isVerified': otherUser['is_verified'] == true,
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
                            size: 14, color: Color(0xFF3B82F6)),
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
                foregroundColor: const Color(0xFF3B82F6),
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
