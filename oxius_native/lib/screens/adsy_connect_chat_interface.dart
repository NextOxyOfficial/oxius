import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/adsyconnect_realtime_service.dart';
import '../services/adsyconnect_service.dart';
import '../services/active_chat_tracker.dart';
import '../utils/image_compressor.dart';
import '../utils/network_error_handler.dart';
import '../widgets/chat_video_player.dart';
import '../widgets/link_preview_card.dart';
import '../widgets/linkify_text.dart';
import '../widgets/skeleton_loader.dart';
import '../config/app_config.dart';
import '../services/agora_call_service.dart';
import '../services/fcm_service.dart';
import '../widgets/chat/chat_app_bar.dart';
import '../widgets/chat/chat_message_bubble.dart';
import '../widgets/chat/chat_message_input.dart';
import 'business_network/profile_screen.dart';
import 'call_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_report_sheet.dart';

class AdsyConnectChatInterface extends StatefulWidget {
  final String chatroomId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? profession;
  final bool isOnline;
  final bool isVerified;
  final bool isPro;
  final VoidCallback? onClose;

  const AdsyConnectChatInterface({
    super.key,
    required this.chatroomId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.profession,
    this.isOnline = false,
    this.isVerified = false,
    this.isPro = false,
    this.onClose,
  });

  /// Stable route name used to identify a chat in the Navigator stack so the
  /// same chat is never duplicated. If you open chat A → then somehow open
  /// chat A again from a different screen, [open] will detect the existing
  /// route and pop back to it instead of pushing a second copy. This matches
  /// WhatsApp / Telegram / Messenger behaviour where a single back press
  /// always returns to a different page (not the same chat repeated).
  ///
  /// NOTE: Must NOT contain a `:` separator. On Flutter web the Navigator
  /// runs `Uri.parse(routeName)` for browser-history sync, and a name like
  /// `adsy_chat:<id>` is interpreted as a URI with scheme `adsy_chat` —
  /// which fails because `_` is illegal in URI schemes. The FormatException
  /// then locks the Navigator (`_debugLocked = true`) and EVERY subsequent
  /// push / showModalBottomSheet / showDialog in the app silently fails.
  /// Using a leading slash makes Flutter treat this as a path, not a scheme.
  static String routeNameFor(String chatroomId) => '/adsy_chat/$chatroomId';
  static final Set<String> _openRouteNames = <String>{};
  static const Duration _navigatorSettleDelay = Duration(milliseconds: 380);
  static bool _chatPushInFlight = false;

  static MaterialPageRoute<T> _chatRoute<T>({
    required String chatroomId,
    required String userId,
    required String userName,
    String? userAvatar,
    String? profession,
    bool isOnline = false,
    bool isVerified = false,
    bool isPro = false,
  }) {
    return MaterialPageRoute<T>(
      settings: RouteSettings(name: routeNameFor(chatroomId)),
      builder: (_) => AdsyConnectChatInterface(
        chatroomId: chatroomId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        profession: profession,
        isOnline: isOnline,
        isVerified: isVerified,
        isPro: isPro,
      ),
    );
  }

  static Future<void> _waitForCurrentRouteToSettle(
    BuildContext context,
  ) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) return;

    final animation = ModalRoute.of(context)?.animation;
    if (animation == null ||
        animation.status == AnimationStatus.completed ||
        animation.status == AnimationStatus.dismissed) {
      return;
    }

    final completer = Completer<void>();
    late AnimationStatusListener listener;
    listener = (status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        animation.removeStatusListener(listener);
        if (!completer.isCompleted) completer.complete();
      }
    };
    animation.addStatusListener(listener);

    try {
      await completer.future.timeout(_navigatorSettleDelay);
    } on TimeoutException {
      animation.removeStatusListener(listener);
    }

    await WidgetsBinding.instance.endOfFrame;
  }

  static bool _isNavigatorLockedError(Object error) {
    final message = error.toString();
    return message.contains('_debugLocked') ||
        message.contains('!navigator._debugLocked');
  }

  static void _releaseChatPushGateAfterTransition() {
    unawaited(Future<void>.delayed(_navigatorSettleDelay, () {
      _chatPushInFlight = false;
    }));
  }

  /// Open a chat with built-in stack deduplication.
  ///
  /// Returns a Future that completes when the chat route is popped.
  static Future<T?> open<T>(
    BuildContext context, {
    required String chatroomId,
    required String userId,
    required String userName,
    String? userAvatar,
    String? profession,
    bool isOnline = false,
    bool isVerified = false,
    bool isPro = false,
    bool useRootNavigator = false,
  }) async {
    if (_chatPushInFlight) {
      return Future<T?>.value(null);
    }
    _chatPushInFlight = true;

    Future<T?>? pushedRoute;
    try {
      await _waitForCurrentRouteToSettle(context);
      if (!context.mounted) return null;

      final navigator = Navigator.of(context, rootNavigator: useRootNavigator);

      try {
        pushedRoute = navigator.push<T>(
          _chatRoute<T>(
            chatroomId: chatroomId,
            userId: userId,
            userName: userName,
            userAvatar: userAvatar,
            profession: profession,
            isOnline: isOnline,
            isVerified: isVerified,
            isPro: isPro,
          ),
        );
      } catch (error) {
        if (!_isNavigatorLockedError(error)) rethrow;
        await Future<void>.delayed(_navigatorSettleDelay);
        if (!context.mounted) return null;
        pushedRoute =
            Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
          _chatRoute<T>(
            chatroomId: chatroomId,
            userId: userId,
            userName: userName,
            userAvatar: userAvatar,
            profession: profession,
            isOnline: isOnline,
            isVerified: isVerified,
            isPro: isPro,
          ),
        );
      }

      _releaseChatPushGateAfterTransition();
      return await pushedRoute;
    } finally {
      if (pushedRoute == null) {
        _chatPushInFlight = false;
      }
    }
  }

  @override
  State<AdsyConnectChatInterface> createState() =>
      _AdsyConnectChatInterfaceState();
}

class _AdsyConnectChatInterfaceState extends State<AdsyConnectChatInterface>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final FocusNode _messageFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  // Subscriptions for the currently-playing voice message. Cancelled and
  // replaced every time a new voice message starts to prevent listener
  // accumulation (previously every play() added 3 new listeners that were
  // never removed, causing memory growth and ghost setState calls).
  StreamSubscription<dynamic>? _audioPlayerStateSub;
  StreamSubscription<dynamic>? _audioPositionSub;
  StreamSubscription<dynamic>? _audioDurationSub;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isTyping = false;
  bool _isLoadingMessages = true;
  bool _isLoadingMoreMessages = false;
  bool _isSendingMessage = false;
  bool _isUploadingAttachment = false;
  bool _isCompressingImages = false;
  bool _isRecording = false;
  int _recordDuration = 0;
  int _currentPage = 1;
  bool _hasMoreMessages = true;
  Timer? _recordTimer;
  Timer? _messagePollingTimer;
  String? _recordingPath;
  List<Map<String, dynamic>> _messages = [];
  String? _lastMessageId;
  List<XFile> _selectedImages = [];
  List<String> _compressedImages = [];
  String? _playingVoiceMessageId;
  Duration _voicePosition = Duration.zero;
  Duration _voiceDuration = Duration.zero;
  bool _isChatBlocked = false;
  bool _blockedByMe = false;
  bool _isLoadingChatroomStatus = false;
  int _statusPollCounter = 0;
  bool _isUserNearBottom = true;
  bool _isOtherUserOnline = false;
  bool _isOtherUserTyping = false;
  String? _lastSeenTime;
  Timer? _onlineStatusTimer;
  Timer? _remoteTypingResetTimer;
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;
  Map<String, dynamic>? _replyingToMessage;

  bool _isSearchMode = false;
  bool _suppressSearchListener = false;
  String _searchQuery = '';
  List<int> _searchMatchIndexes = [];
  Set<String> _searchMatchedMessageIds = <String>{};
  int _currentSearchMatchPosition = 0;
  String? _currentSearchMessageId;

  @override
  void initState() {
    super.initState();
    AdsyConnectChatInterface._openRouteNames.add(
      AdsyConnectChatInterface.routeNameFor(widget.chatroomId),
    );
    WidgetsBinding.instance.addObserver(this);
    ActiveChatTracker.setActiveChat(widget.chatroomId);
    AdsyConnectService.setActiveChat(widget.chatroomId);
    _isOtherUserOnline = widget.isOnline;
    _loadChatroomStatus();
    _loadMessages();
    _loadOnlineStatus();
    unawaited(AdsyConnectRealtimeService.instance.connect());
    _realtimeSubscription = AdsyConnectRealtimeService.instance.events.listen(
      _handleRealtimeEvent,
    );
    _messageController.addListener(_onTypingChanged);
    _searchController.addListener(_onSearchChanged);
    _itemPositionsListener.itemPositions.addListener(_onItemPositionsChanged);
    _startMessagePolling();
    _startOnlineStatusPolling();
  }

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // iOS/Android both kill idle sockets after a few minutes in background.
      // Force a reconnect now so chat state is restored instantly — without
      // this the user can see stale "typing" indicators and miss messages
      // until the next polling tick (20s) or until a keepalive fails.
      unawaited(AdsyConnectRealtimeService.instance.forceReconnect());
      _loadOnlineStatus();
      _loadChatroomStatus();
      // Also pull any messages that may have arrived while we were paused —
      // belt-and-suspenders against socket replay gaps.
      _loadMessages();
    }
  }

  void _onItemPositionsChanged() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final bottomVisible =
        positions.any((p) => p.index == 0 && p.itemTrailingEdge > 0);
    if (bottomVisible != _isUserNearBottom && mounted) {
      setState(() {
        _isUserNearBottom = bottomVisible;
      });
    }

    if (_messages.isEmpty) return;
    if (_isLoadingMoreMessages || !_hasMoreMessages) return;

    int maxIndex = 0;
    for (final p in positions) {
      if (p.index > maxIndex) maxIndex = p.index;
    }

    final topMostMessageBuilderIndex = _messages.length - 1;
    if (maxIndex >= topMostMessageBuilderIndex) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingMoreMessages || !_hasMoreMessages) return;

    String? anchorMessageId;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty && _messages.isNotEmpty) {
      int maxIndex = 0;
      for (final p in positions) {
        if (p.index > maxIndex) maxIndex = p.index;
      }

      final anchorBuilderIndex = maxIndex.clamp(0, _messages.length - 1);
      final anchorMessageIndex = _messages.length - 1 - anchorBuilderIndex;
      if (anchorMessageIndex >= 0 && anchorMessageIndex < _messages.length) {
        anchorMessageId = _messages[anchorMessageIndex]['id']?.toString();
      }
    }

    setState(() {
      _isLoadingMoreMessages = true;
    });

    try {
      final nextPage = _currentPage + 1;
      print('ðŸ”µ Loading older messages, page: $nextPage');

      final messages = await AdsyConnectService.getMessages(
        widget.chatroomId,
        page: nextPage,
      );

      print('ðŸŸ¢ Loaded ${messages.length} older messages');

      if (mounted && messages.isNotEmpty) {
        // Backend returns oldest-to-newest (ascending by created_at)
        final parsedMessages = _parseMessages(messages);
        setState(() {
          // Insert older messages at the beginning
          _messages.insertAll(0, parsedMessages);
          _currentPage = nextPage;
          _hasMoreMessages = messages.length >= 20;
          _isLoadingMoreMessages = false;
        });

        if (anchorMessageId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final idx = _messages.indexWhere(
              (m) => (m['id']?.toString() ?? '') == anchorMessageId,
            );
            if (idx == -1) return;
            final targetBuilderIndex = _messages.length - 1 - idx;
            if (_itemScrollController.isAttached) {
              _itemScrollController.jumpTo(index: targetBuilderIndex);
            }
          });
        }
      } else {
        setState(() {
          _hasMoreMessages = false;
          _isLoadingMoreMessages = false;
        });
      }
    } catch (e) {
      print('ðŸ”´ Error loading older messages: $e');
      if (mounted) {
        setState(() => _isLoadingMoreMessages = false);
      }
    }
  }

  @override
  void dispose() {
    if (_isTyping) {
      AdsyConnectRealtimeService.instance.sendTypingStatus(
        chatroomId: widget.chatroomId,
        isTyping: false,
      );
    }
    // Make sure we don't leave any focus capturing pointer events on the
    // returning chat-list screen.
    FocusManager.instance.primaryFocus?.unfocus();
    AdsyConnectChatInterface._openRouteNames.remove(
      AdsyConnectChatInterface.routeNameFor(widget.chatroomId),
    );
    ActiveChatTracker.clearActiveChat();
    AdsyConnectService.clearActiveChat();
    _realtimeSubscription?.cancel();
    _remoteTypingResetTimer?.cancel();
    _messageController.dispose();
    _searchController.dispose();
    _itemPositionsListener.itemPositions
        .removeListener(_onItemPositionsChanged);
    _messageFocusNode.dispose();
    _searchFocusNode.dispose();
    _audioRecorder.dispose();
    _audioPlayerStateSub?.cancel();
    _audioPositionSub?.cancel();
    _audioDurationSub?.cancel();
    _audioPlayer.dispose();
    _recordTimer?.cancel();
    _messagePollingTimer?.cancel();
    _onlineStatusTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _playVoiceMessage(String messageId, String? mediaUrl) async {
    if (mediaUrl == null || mediaUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice message not available'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    try {
      // If already playing this message, pause it
      if (_playingVoiceMessageId == messageId) {
        if (_audioPlayer.playing) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.play();
        }
        return;
      }

      // Stop any currently playing message and load new one
      await _audioPlayer.stop();
      // Cancel previous subscriptions before attaching new ones — without
      // this, each voice-message play would leak 3 listeners forever.
      await _audioPlayerStateSub?.cancel();
      await _audioPositionSub?.cancel();
      await _audioDurationSub?.cancel();
      _audioPlayerStateSub = null;
      _audioPositionSub = null;
      _audioDurationSub = null;
      setState(() => _playingVoiceMessageId = messageId);

      // Set audio source and play
      await _audioPlayer.setUrl(mediaUrl);
      await _audioPlayer.play();

      // Listen to player state changes
      _audioPlayerStateSub = _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          if (state.processingState == ProcessingState.completed) {
            setState(() => _playingVoiceMessageId = null);
          }
        }
      });

      // Listen to position changes
      _audioPositionSub = _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() => _voicePosition = position);
        }
      });

      // Listen to duration changes
      _audioDurationSub = _audioPlayer.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() => _voiceDuration = duration);
        }
      });
    } catch (e) {
      print('Error playing voice message: $e');
      setState(() => _playingVoiceMessageId = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play voice message: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _onTypingChanged() {
    final isCurrentlyTyping = _messageController.text.isNotEmpty;
    if (isCurrentlyTyping != _isTyping) {
      setState(() => _isTyping = isCurrentlyTyping);
      AdsyConnectRealtimeService.instance.sendTypingStatus(
        chatroomId: widget.chatroomId,
        isTyping: isCurrentlyTyping,
      );
    }
  }

  void _handleRealtimeEvent(Map<String, dynamic> event) {
    final type = event['type']?.toString();
    if (type == null || !mounted) {
      return;
    }

    if (type == 'user_online_status') {
      final userId = event['user_id']?.toString();
      if (userId != widget.userId) {
        return;
      }

      setState(() {
        _isOtherUserOnline = _parseBool(event['is_online']);
        _lastSeenTime = event['last_seen']?.toString() ?? _lastSeenTime;
        if (_isOtherUserOnline) {
          _isOtherUserTyping = false;
        }
      });
      return;
    }

    if (type == 'typing_status') {
      final chatroomId = event['chatroom_id']?.toString();
      final userId = event['user_id']?.toString();
      if (chatroomId != widget.chatroomId || userId != widget.userId) {
        return;
      }

      final isTyping = _parseBool(event['is_typing']);
      _remoteTypingResetTimer?.cancel();
      if (isTyping) {
        _remoteTypingResetTimer = Timer(const Duration(seconds: 4), () {
          if (!mounted) {
            return;
          }
          setState(() {
            _isOtherUserTyping = false;
          });
        });
      }

      setState(() {
        _isOtherUserTyping = isTyping;
      });
      return;
    }

    if (type == 'new_message') {
      final rawMessage = event['message'];
      if (rawMessage is! Map) {
        return;
      }

      final message = Map<String, dynamic>.from(rawMessage);
      final chatroomId = message['chatroom']?.toString();
      if (chatroomId != widget.chatroomId) {
        return;
      }

      final parsedMessages = _parseMessages([message]);
      if (parsedMessages.isEmpty) {
        return;
      }

      final parsed = parsedMessages.first;
      final isIncoming = parsed['isMe'] != true;
      setState(() {
        _upsertMessage(parsed);
        if (_searchQuery.trim().isNotEmpty) {
          _recomputeSearchMatches(keepCurrent: true);
        }
        if (isIncoming) {
          _lastMessageId = parsed['id'];
          _isOtherUserTyping = false;
        }
      });

      if (_isUserNearBottom) {
        _scrollToBottom();
      }
      if (isIncoming) {
        unawaited(_markMessagesAsRead());
      }
      return;
    }

    if (type == 'message_read' || type == 'message_read_update') {
      final chatroomId = event['chatroom_id']?.toString();
      if (chatroomId != null &&
          chatroomId.isNotEmpty &&
          chatroomId != widget.chatroomId) {
        return;
      }

      final messageIds = <String>{};
      final singleMessageId = event['message_id']?.toString();
      if (singleMessageId != null && singleMessageId.isNotEmpty) {
        messageIds.add(singleMessageId);
      }

      final bulkMessageIds = event['message_ids'];
      if (bulkMessageIds is Iterable) {
        for (final value in bulkMessageIds) {
          final id = value?.toString() ?? '';
          if (id.isNotEmpty) {
            messageIds.add(id);
          }
        }
      }

      if (messageIds.isEmpty) {
        return;
      }

      final readAt = _tryParseTimestamp(event['read_at']);
      _applyReadReceipt(messageIds, readAt: readAt);
      return;
    }
  }

  void _onSearchChanged() {
    if (_suppressSearchListener) return;
    final q = _searchController.text;
    if (q == _searchQuery) return;

    setState(() {
      _searchQuery = q;
      _recomputeSearchMatches(keepCurrent: false);
    });

    if (_searchMatchIndexes.isNotEmpty) {
      _scrollToSearchMatchPosition(_currentSearchMatchPosition);
    }
  }

  String _messageSearchText(Map<String, dynamic> message) {
    final base = (message['message'] ?? message['content'] ?? '').toString();
    final preview = (message['replyPreview'] ?? '').toString();
    final fileName =
        (message['fileName'] ?? message['file_name'] ?? '').toString();
    final combined = '$base $preview $fileName'.trim();
    return combined;
  }

  void _recomputeSearchMatches({required bool keepCurrent}) {
    final q = _searchQuery.trim().toLowerCase();
    _searchMatchIndexes = [];
    _searchMatchedMessageIds = <String>{};

    if (q.isEmpty) {
      _currentSearchMatchPosition = 0;
      _currentSearchMessageId = null;
      return;
    }

    for (int i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      if (_isMessageDeleted(m)) continue;
      final hay = _messageSearchText(m).toLowerCase();
      if (!hay.contains(q)) continue;
      _searchMatchIndexes.add(i);
      final id = m['id']?.toString() ?? '';
      if (id.isNotEmpty) _searchMatchedMessageIds.add(id);
    }

    if (_searchMatchIndexes.isEmpty) {
      _currentSearchMatchPosition = 0;
      _currentSearchMessageId = null;
      return;
    }

    if (keepCurrent && _currentSearchMessageId != null) {
      final pos = _searchMatchIndexes.indexWhere((idx) {
        final id = _messages[idx]['id']?.toString() ?? '';
        return id == _currentSearchMessageId;
      });
      if (pos != -1) {
        _currentSearchMatchPosition = pos;
        return;
      }
    }

    _currentSearchMatchPosition = 0;
    final idx = _searchMatchIndexes.first;
    _currentSearchMessageId = _messages[idx]['id']?.toString();
  }

  void _openSearch() {
    if (_isSearchMode) return;
    setState(() {
      _isSearchMode = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
  }

  void _closeSearch() {
    if (!_isSearchMode) return;
    _suppressSearchListener = true;
    _searchController.clear();
    _suppressSearchListener = false;

    setState(() {
      _isSearchMode = false;
      _searchQuery = '';
      _searchMatchIndexes = [];
      _searchMatchedMessageIds = <String>{};
      _currentSearchMatchPosition = 0;
      _currentSearchMessageId = null;
    });
  }

  void _scrollToSearchMatchPosition(int position) {
    if (_searchMatchIndexes.isEmpty) return;
    if (!_itemScrollController.isAttached) return;

    final pos = position.clamp(0, _searchMatchIndexes.length - 1);
    final msgListIndex = _searchMatchIndexes[pos];
    if (msgListIndex < 0 || msgListIndex >= _messages.length) return;

    setState(() {
      _currentSearchMatchPosition = pos;
      _currentSearchMessageId = _messages[msgListIndex]['id']?.toString();
    });

    final targetBuilderIndex = _messages.length - 1 - msgListIndex;
    _itemScrollController.scrollTo(
      index: targetBuilderIndex,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.15,
    );
  }

  void _goToNextSearchMatch() {
    if (_searchMatchIndexes.isEmpty) return;
    final next = (_currentSearchMatchPosition + 1) % _searchMatchIndexes.length;
    _scrollToSearchMatchPosition(next);
  }

  void _goToPrevSearchMatch() {
    if (_searchMatchIndexes.isEmpty) return;
    final prev =
        (_currentSearchMatchPosition - 1 + _searchMatchIndexes.length) %
            _searchMatchIndexes.length;
    _scrollToSearchMatchPosition(prev);
  }

  Future<void> _loadChatroomStatus() async {
    if (_isLoadingChatroomStatus) return;
    if (!mounted) return;

    setState(() {
      _isLoadingChatroomStatus = true;
    });

    try {
      final details =
          await AdsyConnectService.getChatRoomDetails(widget.chatroomId);
      if (!mounted) return;

      if (details == null) {
        setState(() {
          _isLoadingChatroomStatus = false;
        });
        return;
      }

      Map<String, dynamic>? blockStatus;
      final rawBlockStatus = details['block_status'] ?? details['blockStatus'];
      if (rawBlockStatus is Map<String, dynamic>) {
        blockStatus = rawBlockStatus;
      } else if (rawBlockStatus is Map) {
        blockStatus = Map<String, dynamic>.from(rawBlockStatus);
      }

      final blockedValue = blockStatus?['is_blocked'] ??
          blockStatus?['isBlocked'] ??
          details['is_blocked'] ??
          details['isBlocked'] ??
          details['blocked'] ??
          details['is_chat_blocked'] ??
          details['isChatBlocked'];

      final blockedByMeValue = blockStatus?['blocked_by_me'] ??
          blockStatus?['blockedByMe'] ??
          blockStatus?['is_blocked_by_me'] ??
          details['blocked_by_me'] ??
          details['blockedByMe'] ??
          details['is_blocked_by_me'] ??
          details['isBlockedByMe'];

      final isBlocked = _parseBool(blockedValue);
      final blockedByMe = _parseBool(blockedByMeValue);

      setState(() {
        _isChatBlocked = isBlocked;
        _blockedByMe = blockedByMe;
        _isLoadingChatroomStatus = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingChatroomStatus = false;
      });
    }
  }

  Future<void> _loadOnlineStatus() async {
    try {
      final status = await AdsyConnectService.getOnlineStatus(widget.userId);
      if (!mounted) return;
      if (status == null) return;

      final isOnline = _parseBool(status['is_online'] ?? status['isOnline']);
      final lastSeen = (status['last_seen'] ??
              status['last_seen_at'] ??
              status['last_seen_time'] ??
              status['lastSeen'] ??
              status['lastSeenAt'] ??
              status['lastSeenTime'] ??
              status['updated_at'] ??
              status['updatedAt'])
          ?.toString();

      setState(() {
        _isOtherUserOnline = isOnline;
        _lastSeenTime = lastSeen;
      });
    } catch (_) {}
  }

  void _startOnlineStatusPolling() {
    _onlineStatusTimer?.cancel();
    _onlineStatusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _loadOnlineStatus();
      }
    });
  }

  String _formatLastSeen(String? lastSeen) {
    final raw = (lastSeen ?? '').trim();
    if (raw.isEmpty) return 'Offline';

    DateTime? time;
    try {
      time = DateTime.parse(raw).toLocal();
    } catch (_) {
      return 'Last seen $raw';
    }

    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 30) return 'Last seen just now';
    if (diff.inMinutes < 1) return 'Last seen ${diff.inSeconds}s ago';
    if (diff.inHours < 1) return 'Last seen ${diff.inMinutes}m ago';
    if (diff.inDays < 1) return 'Last seen ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Last seen ${diff.inDays}d ago';
    return 'Last seen ${time.day}/${time.month}/${time.year}';
  }

  void _startMessagePolling() {
    // WebSocket is the primary realtime path; polling stays as a recovery
    // fallback. Use a short interval so that if the socket drops, lag stays
    // sub-5s rather than the previous 10s.
    _messagePollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && !_isLoadingMessages) {
        _checkForNewMessages();
        _statusPollCounter++;
        if (_statusPollCounter >= 8) {
          _statusPollCounter = 0;
          _loadChatroomStatus();
        }
      }
    });
  }

  Future<void> _checkForNewMessages() async {
    try {
      final messages = await AdsyConnectService.getMessages(
        widget.chatroomId,
        page: 1,
      );

      if (messages.isEmpty) return;

      // Backend returns oldest-to-newest (ascending by created_at)
      final parsedMessages = _parseMessages(messages);
      if (parsedMessages.isEmpty) return;

      bool hasUpdates = false;

      // Update seen status for existing messages
      for (var serverMsg in parsedMessages) {
        final serverId = serverMsg['id']?.toString() ?? '';
        final existingIndex = _messages.indexWhere(
          (m) => (m['id']?.toString() ?? '') == serverId,
        );
        if (existingIndex != -1) {
          // Check if seen status changed
          if (_messages[existingIndex]['isSeen'] != serverMsg['isSeen']) {
            _messages[existingIndex]['isSeen'] = serverMsg['isSeen'];
            hasUpdates = true;
          }
        }
      }

      // Get the latest message ID from server
      final latestServerMessageId = parsedMessages.last['id'];

      // Find new messages that we don't have yet
      final newMessages = parsedMessages.where((msg) {
        final msgId = msg['id']?.toString() ?? '';
        return !_messages
            .any((existing) => (existing['id']?.toString() ?? '') == msgId);
      }).toList();

      if (newMessages.isNotEmpty) {
        hasUpdates = true;
        for (final m in newMessages) {
          _upsertMessage(m);
        }
        if (_searchQuery.trim().isNotEmpty) {
          _recomputeSearchMatches(keepCurrent: true);
        }
        _lastMessageId = newMessages.last['id'];

        // Auto-scroll to bottom if user is near bottom
        if (_isUserNearBottom) {
          _scrollToBottom();
        }
      }

      // Update UI if there were any changes
      if (hasUpdates && mounted) {
        setState(() {});
      }
    } catch (e) {
      // Silently fail for polling errors to avoid spamming user
      print('ðŸ”´ Error polling messages: $e');
    }
  }

  Future<void> _loadMessages({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoadingMessages = true;
        _currentPage = 1;
      });
    }

    try {
      print(
          'ðŸ”µ Loading messages for chatroom: ${widget.chatroomId}, page: $_currentPage');

      final messages = await AdsyConnectService.getMessages(
        widget.chatroomId,
        page: _currentPage,
      );

      print('ðŸŸ¢ Loaded ${messages.length} messages');

      if (mounted) {
        // Backend returns oldest-to-newest (ascending by created_at)
        final parsedMessages = _parseMessages(messages);
        setState(() {
          if (loadMore) {
            _messages.insertAll(0, parsedMessages);
          } else {
            _messages = parsedMessages;
            // Set last message ID for polling
            if (parsedMessages.isNotEmpty) {
              _lastMessageId = parsedMessages.last['id'];
            }
          }

          if (_searchQuery.trim().isNotEmpty) {
            _recomputeSearchMatches(keepCurrent: true);
          }
          _isLoadingMessages = false;
          _hasMoreMessages = messages.length >= 20;
          if (loadMore) _currentPage++;
        });

        if (!loadMore) {
          _scrollToBottom();
          // Mark messages as read when opening chat
          _markMessagesAsRead();
        }
      }
    } catch (e) {
      print('ðŸ”´ Error loading messages: $e');
      if (mounted) {
        setState(() => _isLoadingMessages = false);
        NetworkErrorHandler.showErrorSnackbar(
          context,
          e,
          onRetry: () => _loadMessages(loadMore: loadMore),
        );
      }
    }
  }

  List<Map<String, dynamic>> _parseMessages(List<dynamic> messages) {
    final parsedMessages = messages.map((msg) {
      final sender = msg['sender'] ?? {};
      final receiver = msg['receiver'] ?? {};
      final senderId = sender['id']?.toString() ?? '';
      final currentUserId = AuthService.currentUser?.id;
      final isMe = currentUserId != null && senderId == currentUserId;

      // Check if message has been seen by recipient
      // is_read means the recipient has opened and viewed the message
      final isSeen = msg['is_read'] == true;
      final readAt = _tryParseTimestamp(msg['read_at']);

      final rawText = msg['display_content']?.toString() ??
          msg['content']?.toString() ??
          '';
      final replyMeta = _tryParseReplyFromText(rawText);

      return {
        'id': msg['id']?.toString() ?? '',
        'senderId': senderId,
        'message': replyMeta?['messageText']?.toString() ?? rawText,
        'replyToId': replyMeta?['replyToId']?.toString(),
        'replyToSender': replyMeta?['replyToSender']?.toString(),
        'replyPreview': replyMeta?['replyPreview']?.toString(),
        'timestamp': msg['created_at'] != null
            ? DateTime.parse(msg['created_at'])
            : DateTime.now(),
        'timeDisplay': msg['time_display']?.toString(),
        'isMe': isMe,
        'type': msg['message_type']?.toString() ?? 'text',
        'mediaUrl': msg['media_url']
            ?.toString(), // Backend returns media_url, not media_file
        'thumbnailUrl': msg['thumbnail_url']?.toString(),
        'fileName': msg['file_name']?.toString(),
        'voice_duration': (msg['voice_duration'] as int?) ??
            (msg['voiceDuration'] as int?) ??
            0,
        'isSeen': isSeen, // Changed from isRead to isSeen for clarity
        'is_read': isSeen,
        'readAt': readAt,
        'isDeleted': (msg['is_deleted'] == true ||
            msg['is_deleted'] == 1 ||
            msg['is_deleted'] == '1' ||
            msg['is_deleted'] == 'true'),
        'isEdited': msg['is_edited'] == true ||
            msg['is_edited'] == 1 ||
            msg['is_edited'] == '1' ||
            msg['is_edited'] == 'true',
      };
    }).toList();

    // Add smart timestamp display logic
    return _addSmartTimestamps(parsedMessages);
  }

  List<Map<String, dynamic>> _addSmartTimestamps(
      List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) return messages;

    for (int i = 0; i < messages.length; i++) {
      bool showTimestamp = false;

      // Always show timestamp for first message
      if (i == 0) {
        showTimestamp = true;
      } else {
        final currentTime = messages[i]['timestamp'] as DateTime;
        final previousTime = messages[i - 1]['timestamp'] as DateTime;
        final difference = currentTime.difference(previousTime);

        // Show timestamp if gap is 3+ minutes
        if (difference.inMinutes >= 3) {
          showTimestamp = true;
        }
      }

      messages[i]['showTimestamp'] = showTimestamp;
    }

    return messages;
  }

  Future<void> _markMessagesAsRead() async {
    try {
      // Call API to mark messages as read
      await AdsyConnectService.markChatroomAsRead(widget.chatroomId);

      // Update local state immediately - mark all received messages as read
      _markLocalIncomingMessagesAsRead();
    } catch (e) {
      print('ðŸ”´ Error marking messages as read: $e');
      // Don't show error to user - this is a background operation
    }
  }

  void _markLocalIncomingMessagesAsRead() {
    if (!mounted) {
      return;
    }

    final readAt = DateTime.now();
    setState(() {
      for (final message in _messages) {
        if (message['isMe'] == false && message['isSeen'] != true) {
          message['isSeen'] = true;
          message['is_read'] = true;
          message['readAt'] = readAt;
        }
      }
    });
  }

  void _scrollToBottom() {
    if (!_itemScrollController.isAttached) return;
    _itemScrollController.scrollTo(
      index: 0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollToMessageId(String messageId) {
    final id = messageId.trim();
    if (id.isEmpty) return;
    if (!_itemScrollController.isAttached) return;
    if (_messages.isEmpty) return;

    final idx = _messages.indexWhere(
      (m) => (m['id']?.toString() ?? '') == id,
    );

    if (idx == -1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Original message is not loaded yet'),
          backgroundColor: Color(0xFF374151),
          duration: Duration(milliseconds: 1200),
        ),
      );
      return;
    }

    final targetBuilderIndex = _messages.length - 1 - idx;
    _itemScrollController.scrollTo(
      index: targetBuilderIndex,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.15,
    );
  }

  void _upsertMessage(Map<String, dynamic> message) {
    final id = message['id']?.toString() ?? '';
    if (id.isEmpty) {
      _messages.add(message);
      return;
    }

    final existingIndex = _messages.indexWhere(
      (m) => (m['id']?.toString() ?? '') == id,
    );

    if (existingIndex == -1) {
      final pendingIndex = _findEquivalentPendingMessageIndex(message);
      if (pendingIndex != -1) {
        final merged = Map<String, dynamic>.from(_messages[pendingIndex]);
        merged.addAll(message);
        merged['pending'] = false;
        _messages[pendingIndex] = merged;
        return;
      }

      _messages.add(message);
      return;
    }

    final merged = Map<String, dynamic>.from(_messages[existingIndex]);
    merged.addAll(message);
    _messages[existingIndex] = merged;
  }

  int _findEquivalentPendingMessageIndex(Map<String, dynamic> message) {
    final id = message['id']?.toString() ?? '';
    if (id.startsWith('temp_') || message['isMe'] != true) {
      return -1;
    }

    final messageText = (message['message'] ?? '').toString().trim();
    final messageType = (message['type'] ?? 'text').toString();
    if (messageText.isEmpty) {
      return -1;
    }

    return _messages.indexWhere((existing) {
      final existingId = existing['id']?.toString() ?? '';
      if (!existingId.startsWith('temp_') || existing['pending'] != true) {
        return false;
      }
      return existing['isMe'] == true &&
          (existing['type'] ?? 'text').toString() == messageType &&
          (existing['message'] ?? '').toString().trim() == messageText;
    });
  }

  void _applyReadReceipt(Set<String> messageIds, {DateTime? readAt}) {
    var changed = false;

    setState(() {
      for (var index = 0; index < _messages.length; index++) {
        final messageId = _messages[index]['id']?.toString() ?? '';
        if (!messageIds.contains(messageId)) {
          continue;
        }

        _messages[index]['isSeen'] = true;
        _messages[index]['is_read'] = true;
        _messages[index]['readAt'] =
            readAt ?? _messages[index]['readAt'] ?? DateTime.now();
        changed = true;
      }
    });

    if (changed && _searchQuery.trim().isNotEmpty) {
      _recomputeSearchMatches(keepCurrent: true);
    }
  }

  Future<void> _sendMessage() async {
    if (_isChatBlocked) return;
    if (_isSendingMessage) return;
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    final replyTo = _replyingToMessage;
    _messageController.clear();

    // Optimistic UI: show the message immediately with a pending marker so
    // the user gets instant feedback. The server response will replace this
    // temp entry by id.
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final optimistic = <String, dynamic>{
      'id': tempId,
      'isMe': true,
      'type': 'text',
      'message': messageText,
      'timestamp': now,
      'timeDisplay': _formatMessageTime(now),
      'showTimestamp': true,
      'isSeen': false,
      'pending': true,
    };

    setState(() {
      _upsertMessage(optimistic);
      _isSendingMessage = true;
      _replyingToMessage = null;
    });
    _scrollToBottom();

    try {
      print('ðŸ”µ Sending message: $messageText');

      String contentToSend = messageText;
      if (replyTo != null) {
        final replyToId = replyTo['id']?.toString() ?? '';
        final replyToText = _getReplyPreviewText(replyTo);
        final replyToSender = replyTo['isMe'] == true ? 'You' : widget.userName;
        final idPart = replyToId.isNotEmpty ? '($replyToId) ' : '';
        contentToSend =
            'â†©ï¸ $idPart$replyToSender: $replyToText\n\n$messageText';
      }

      final sentMessage = await AdsyConnectService.sendTextMessage(
        chatroomId: widget.chatroomId,
        receiverId: widget.userId,
        content: contentToSend,
      );

      print('ðŸŸ¢ Message sent: ${sentMessage['id']}');

      if (mounted) {
        setState(() {
          // Remove the optimistic temp entry and add the real server entry.
          _messages.removeWhere((m) => (m['id']?.toString() ?? '') == tempId);
          _upsertMessage(_parseSingleMessage(sentMessage));
          _isSendingMessage = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('ðŸ”´ Error sending message: $e');
      if (mounted) {
        setState(() {
          // Roll back the optimistic message on failure.
          _messages.removeWhere((m) => (m['id']?.toString() ?? '') == tempId);
          _isSendingMessage = false;
        });

        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('403') ||
            errorStr.contains('permission denied') ||
            errorStr.contains('blocked')) {
          setState(() {
            _isChatBlocked = true;
            _blockedByMe = false;
          });
        }

        // Restore the message text
        _messageController.text = messageText;

        // Show professional error message
        NetworkErrorHandler.showErrorSnackbar(
          context,
          e,
          onRetry: _sendMessage,
        );
      }
    }
  }

  Map<String, dynamic> _parseSingleMessage(Map<String, dynamic> msg) {
    // Check if message has been seen by recipient
    // is_read means the recipient has opened and viewed the message
    final isSeen = msg['is_read'] == true;
    final readAt = _tryParseTimestamp(msg['read_at']);

    final rawText =
        msg['display_content']?.toString() ?? msg['content']?.toString() ?? '';
    final replyMeta = _tryParseReplyFromText(rawText);

    return {
      'id': msg['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': 'me',
      'message': replyMeta?['messageText']?.toString() ?? rawText,
      'replyToId': replyMeta?['replyToId']?.toString(),
      'replyToSender': replyMeta?['replyToSender']?.toString(),
      'replyPreview': replyMeta?['replyPreview']?.toString(),
      'timestamp': msg['created_at'] != null
          ? DateTime.parse(msg['created_at'])
          : DateTime.now(),
      'timeDisplay': msg['time_display']?.toString(),
      'isMe': true,
      'type': msg['message_type']?.toString() ?? 'text',
      'mediaUrl': msg['media_url']
          ?.toString(), // Backend returns media_url, not media_file
      'thumbnailUrl': msg['thumbnail_url']?.toString(),
      'fileName': msg['file_name']?.toString(),
      'voice_duration': (msg['voice_duration'] as int?) ??
          (msg['voiceDuration'] as int?) ??
          0,
      'isSeen': isSeen, // Changed from isRead to isSeen for clarity
      'is_read': isSeen,
      'readAt': readAt,
      'isDeleted': (msg['is_deleted'] == true ||
          msg['is_deleted'] == 1 ||
          msg['is_deleted'] == '1' ||
          msg['is_deleted'] == 'true'),
      'showTimestamp': true, // Always show timestamp for sent messages
    };
  }

  DateTime? _tryParseTimestamp(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<void> _startRecording() async {
    try {
      // Check current permission state first so we can tell the difference
      // between "never asked", "denied this time", and "permanently denied".
      var status = await Permission.microphone.status;

      if (status.isDenied || status.isRestricted || status.isLimited) {
        // Trigger native permission dialog. On Android first run this shows
        // the system prompt; on iOS it shows on first call only.
        status = await Permission.microphone.request();
      }

      if (status.isPermanentlyDenied) {
        if (!mounted) return;
        final goSettings = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.mic_off_rounded, color: Color(0xFFEF4444)),
                SizedBox(width: 10),
                Text('Microphone blocked'),
              ],
            ),
            content: const Text(
              'Microphone access was previously denied. Please enable it in '
              'app settings to record voice messages.',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Open settings'),
              ),
            ],
          ),
        );
        if (goSettings == true) {
          await openAppSettings();
        }
        return;
      }

      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Microphone permission is required to record voice messages'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
        return;
      }

      // Check if recorder has permission
      if (await _audioRecorder.hasPermission()) {
        // Get temporary directory for recording
        final directory = await getTemporaryDirectory();
        final path =
            '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        // Start recording
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });

        // Start timer
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration++;
          });
        });
      }
    } catch (e) {
      print('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start recording'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _recordTimer?.cancel();

      if (path != null && _recordDuration > 0) {
        setState(() {
          _isRecording = false;
          _isSendingMessage = true;
        });

        // Send voice message to backend
        try {
          print(
              'ðŸ”µ Sending voice message: $path, duration: $_recordDuration seconds');

          final sentMessage = await AdsyConnectService.sendMediaMessage(
            chatroomId: widget.chatroomId,
            receiverId: widget.userId,
            messageType: 'voice',
            mediaFilePath: path,
            voiceDuration: _recordDuration,
          );

          print('ðŸŸ¢ Voice message sent: ${sentMessage['id']}');

          if (mounted) {
            setState(() {
              final parsed = _parseSingleMessage(sentMessage);
              parsed['voice_duration'] =
                  (sentMessage['voice_duration'] as int?) ??
                      (sentMessage['voiceDuration'] as int?) ??
                      _recordDuration;
              parsed['voiceDuration'] = parsed['voice_duration'];
              _upsertMessage(parsed);
              _isSendingMessage = false;
              _recordDuration = 0;
            });
            _scrollToBottom();
          }
        } catch (e) {
          print('ðŸ”´ Error sending voice message: $e');
          if (mounted) {
            setState(() {
              _isSendingMessage = false;
              _recordDuration = 0;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to send voice message: $e'),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });
    }
  }

  void _cancelRecording() async {
    try {
      await _audioRecorder.stop();
      _recordTimer?.cancel();

      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });
    } catch (e) {
      print('Error canceling recording: $e');
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Helper method to safely check if message is deleted
  // This ensures consistent boolean evaluation in both debug and release builds
  bool _isMessageDeleted(Map<String, dynamic> message) {
    final isDeleted = message['isDeleted'];
    return isDeleted == true ||
        isDeleted == 1 ||
        isDeleted == '1' ||
        isDeleted == 'true';
  }

  void _showMessageOptions(Map<String, dynamic> message) {
    final messageType = message['type']?.toString() ?? 'text';
    final isMe = message['isMe'] == true;
    final isDeleted = _isMessageDeleted(message);
    final isTextLike = messageType == 'text';
    final canEdit = isMe && isTextLike && !isDeleted;
    final canCopy = isTextLike &&
        !isDeleted &&
        (message['message'] ?? '').toString().trim().isNotEmpty;
    final canReply = !isDeleted;
    final canDelete = isMe && !isDeleted;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.82)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.09),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              if (canReply)
                _buildMessageOptionTile(
                  sheetContext: sheetContext,
                  icon: Icons.reply_rounded,
                  iconColor: const Color(0xFF10B981),
                  label: 'Reply',
                  onTap: () => _setReplyingTo(message),
                ),
              if (canCopy)
                _buildMessageOptionTile(
                  sheetContext: sheetContext,
                  icon: Icons.copy_rounded,
                  iconColor: const Color(0xFF6366F1),
                  label: 'Copy text',
                  onTap: () {
                    final text = (message['message'] ?? '').toString();
                    Clipboard.setData(ClipboardData(text: text));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message copied'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              if (canEdit)
                _buildMessageOptionTile(
                  sheetContext: sheetContext,
                  icon: Icons.edit_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  label: 'Edit Message',
                  onTap: () => _showEditMessageDialog(message),
                ),
              if (canDelete)
                _buildMessageOptionTile(
                  sheetContext: sheetContext,
                  icon: Icons.delete_outline_rounded,
                  iconColor: const Color(0xFFEF4444),
                  label: 'Delete Message',
                  destructive: true,
                  onTap: () => _deleteMessage(message),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageOptionTile({
    required BuildContext sheetContext,
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: ListTile(
        minVerticalPadding: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tileColor: Colors.white.withOpacity(0.78),
        leading: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color:
                destructive ? const Color(0xFFEF4444) : const Color(0xFF1F2937),
          ),
        ),
        onTap: () {
          Navigator.pop(sheetContext);
          onTap();
        },
      ),
    );
  }

  void _showEditMessageDialog(Map<String, dynamic> message) {
    final currentText =
        (message['message'] ?? message['content'] ?? '').toString();
    final editController = TextEditingController(text: currentText);

    showDialog(
      context: context,
      // Must use the LOCAL navigator, not the root one. This chat screen is
      // rendered inside the AdsyConnect chat OverlayEntry which sits ABOVE the
      // root Navigator, so a root-navigator dialog would be pushed BEHIND the
      // overlay and stay invisible until the user pops the overlay with Back.
      // (Same fix as _showBlockConfirmation.)
      useRootNavigator: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit Message',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Text field
              TextField(
                controller: editController,
                maxLines: 4,
                minLines: 2,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter your message...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final newText = editController.text.trim();
                        if (newText.isEmpty || newText == currentText) {
                          Navigator.pop(context);
                          return;
                        }

                        Navigator.pop(context);

                        // Update UI immediately
                        if (mounted) {
                          setState(() {
                            final index = _messages.indexWhere((m) =>
                                m['id'].toString() == message['id'].toString());
                            if (index != -1) {
                              _messages[index] = {
                                ..._messages[index],
                                'message': newText,
                                'content': newText,
                                'isEdited': true,
                              };
                              _messages =
                                  List.from(_addSmartTimestamps(_messages));
                            }
                          });
                        }

                        // Call backend to update
                        try {
                          await AdsyConnectService.editMessage(
                            message['id'].toString(),
                            newText,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Message edited'),
                                backgroundColor: Color(0xFF10B981),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          print('Error editing message: $e');
                          // Revert on error
                          if (mounted) {
                            setState(() {
                              final index = _messages.indexWhere((m) =>
                                  m['id'].toString() ==
                                  message['id'].toString());
                              if (index != -1) {
                                _messages[index] = {
                                  ..._messages[index],
                                  'message': currentText,
                                  'content': currentText,
                                  'isEdited': message['isEdited'] ?? false,
                                };
                                _messages =
                                    List.from(_addSmartTimestamps(_messages));
                              }
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to edit message'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteMessage(Map<String, dynamic> message) {
    showDialog(
      context: context,
      // Local navigator — same overlay rationale as _showEditMessageDialog /
      // _showBlockConfirmation. A root-navigator dialog would be hidden behind
      // the chat OverlayEntry until the user pops the page with Back.
      useRootNavigator: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              const Text(
                'Delete Message?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              // Message
              Text(
                'This message will be removed for everyone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);

                        // Update UI immediately for better UX
                        if (mounted) {
                          setState(() {
                            final index = _messages.indexWhere((m) =>
                                m['id'].toString() == message['id'].toString());

                            if (index != -1) {
                              // Update the message to show as deleted
                              _messages[index] = {
                                ..._messages[index],
                                'isDeleted': true,
                                'message': 'Message removed',
                                'type': 'text',
                              };

                              // Force rebuild with updated timestamps
                              _messages =
                                  List.from(_addSmartTimestamps(_messages));
                            }
                          });
                        }

                        // Then call backend to soft delete
                        try {
                          print('ðŸ”µ Deleting message ID: ${message['id']}');
                          await AdsyConnectService.deleteMessage(
                              message['id'].toString());
                          print('ðŸŸ¢ Message deleted successfully');

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Message deleted'),
                                backgroundColor: Color(0xFF10B981),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          print('ðŸ”´ Error deleting message: $e');
                          // Message already marked as deleted in UI, so just log the error
                          // Don't show error to user since UI is already updated
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAttachmentOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                // Title
                const Text(
                  'Send Attachment',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 16),
                // Attachment options grid
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildAttachmentOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Photos',
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromGallery();
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: const Color(0xFF3B82F6),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromCamera();
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.videocam_rounded,
                      label: 'Video',
                      color: const Color(0xFFEF4444),
                      onTap: () {
                        Navigator.pop(context);
                        _pickVideo();
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.insert_drive_file_rounded,
                      label: 'Files',
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.pop(context);
                        _pickDocument();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              letterSpacing: -0.1,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();

      if (images.isNotEmpty) {
        // Check if adding these images exceeds the limit
        if (_selectedImages.length + images.length > 8) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maximum 8 photos allowed'),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
          return;
        }

        setState(() => _isCompressingImages = true);

        // Compress all images
        List<String> compressed = [];
        for (var image in images) {
          final compressedBase64 = await ImageCompressor.compressToBase64(
            image,
            targetSize: 200 * 1024, // 200KB
            initialQuality: 80,
            maxDimension: 1920,
            verbose: true,
          );

          if (compressedBase64 != null) {
            compressed.add(compressedBase64);
          }
        }

        setState(() {
          _selectedImages.addAll(images);
          _compressedImages.addAll(compressed);
          _isCompressingImages = false;
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      setState(() => _isCompressingImages = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      // Check if limit reached
      if (_selectedImages.length >= 8) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 8 photos allowed'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );

      if (image != null) {
        setState(() => _isCompressingImages = true);

        // Compress image
        final compressedBase64 = await ImageCompressor.compressToBase64(
          image,
          targetSize: 200 * 1024, // 200KB
          initialQuality: 80,
          maxDimension: 1920,
          verbose: true,
        );

        if (compressedBase64 != null) {
          setState(() {
            _selectedImages.add(image);
            _compressedImages.add(compressedBase64);
            _isCompressingImages = false;
          });
        } else {
          throw Exception('Image compression failed');
        }
      } else {
        setState(() => _isCompressingImages = false);
      }
    } catch (e) {
      print('Error taking photo: $e');
      setState(() => _isCompressingImages = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null) {
        _sendMediaMessage(video.path, 'video');
      }
    } catch (e) {
      print('Error picking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick video'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _compressedImages.removeAt(index);
    });
  }

  Future<void> _sendSelectedImages() async {
    if (_isChatBlocked) return;
    if (_selectedImages.isEmpty) return;

    setState(() => _isSendingMessage = true);

    try {
      // Send all images
      for (int i = 0; i < _compressedImages.length; i++) {
        await _sendMediaMessage(_selectedImages[i].path, 'image');
        // Small delay between sends to avoid overwhelming the server
        if (i < _compressedImages.length - 1) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      // Clear selected images after sending
      setState(() {
        _selectedImages.clear();
        _compressedImages.clear();
        _isSendingMessage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${_compressedImages.length} photos sent successfully'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSendingMessage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send photos: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
        withReadStream: false,
      );

      if (result != null) {
        // For web/desktop, use bytes if path is null
        if (result.files.single.path != null) {
          _sendMediaMessage(result.files.single.path!, 'document',
              fileName: result.files.single.name);
        } else if (result.files.single.bytes != null) {
          // Handle web/desktop file selection
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File selected. Upload functionality coming soon.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick document: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _sendMediaMessage(String filePath, String type,
      {String? fileName}) async {
    if (_isChatBlocked) return;
    setState(() {
      _isSendingMessage = true;
      _isUploadingAttachment = true;
    });

    try {
      print('ðŸ”µ Sending $type message: $filePath');

      final sentMessage = await AdsyConnectService.sendMediaMessage(
        chatroomId: widget.chatroomId,
        receiverId: widget.userId,
        messageType: type,
        mediaFilePath: filePath,
        fileName: fileName,
      );

      print('ðŸŸ¢ Media message sent: ${sentMessage['id']}');
      print('ðŸŸ¢ Media URL: ${sentMessage['media_url']}');
      print('ðŸŸ¢ Full response: $sentMessage');

      if (mounted) {
        setState(() {
          _upsertMessage(_parseSingleMessage(sentMessage));
          _isSendingMessage = false;
          _isUploadingAttachment = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('ðŸ”´ Error sending media: $e');
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
          _isUploadingAttachment = false;
        });

        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('403') ||
            errorStr.contains('permission denied') ||
            errorStr.contains('blocked')) {
          setState(() {
            _isChatBlocked = true;
            _blockedByMe = false;
          });
        }

        // Show professional error message
        NetworkErrorHandler.showErrorSnackbar(
          context,
          e,
          customMessage:
              'Failed to send ${type == "image" ? "image" : type == "video" ? "video" : "file"}',
          onRetry: () => _sendMediaMessage(filePath, type, fileName: fileName),
        );
      }
    }
  }

  Future<void> _sendMediaMessageWeb(List<int> bytes, String type,
      {String? fileName}) async {
    if (_isChatBlocked) return;
    setState(() {
      _isSendingMessage = true;
      _isUploadingAttachment = true;
    });

    try {
      print('ðŸ”µ Sending $type message from web: ${bytes.length} bytes');

      final sentMessage = await AdsyConnectService.sendMediaMessage(
        chatroomId: widget.chatroomId,
        receiverId: widget.userId,
        messageType: type,
        mediaBytes: bytes,
        fileName: fileName,
      );

      print('ðŸŸ¢ Media message sent (web): ${sentMessage['id']}');
      print('ðŸŸ¢ Media URL (web): ${sentMessage['media_url']}');
      print('ðŸŸ¢ Full response (web): $sentMessage');

      if (mounted) {
        setState(() {
          _upsertMessage(_parseSingleMessage(sentMessage));
          _isSendingMessage = false;
          _isUploadingAttachment = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('ðŸ”´ Error sending media: $e');
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
          _isUploadingAttachment = false;
        });

        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('403') ||
            errorStr.contains('permission denied') ||
            errorStr.contains('blocked')) {
          setState(() {
            _isChatBlocked = true;
            _blockedByMe = false;
          });
        }

        // Show professional error message
        NetworkErrorHandler.showErrorSnackbar(
          context,
          e,
          customMessage:
              'Failed to send ${type == "image" ? "image" : type == "video" ? "video" : "file"}',
          onRetry: () => _sendMediaMessageWeb(bytes, type, fileName: fileName),
        );
      }
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'search':
        _openSearch();
        break;
      case 'view_profile':
        _openUserProfile();
        break;
      case 'block':
        if (!mounted) return;
        _showBlockConfirmation();
        break;
      case 'unblock':
        if (!mounted) return;
        _showUnblockConfirmation();
        break;
      case 'report':
        if (!mounted) return;
        _showReportDialog();
        break;
    }
  }

  Future<void> _blockUser() async {
    try {
      await AdsyConnectService.blockUser(widget.chatroomId);
      if (mounted) {
        setState(() {
          _isChatBlocked = true;
          _blockedByMe = true;
        });
      }

      await _loadChatroomStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.userName} has been blocked'),
            backgroundColor: const Color(0xFFF59E0B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        NetworkErrorHandler.showErrorSnackbar(context, e);
      }
    }
  }

  Future<void> _unblockUser() async {
    try {
      await AdsyConnectService.unblockUser(widget.chatroomId);
      if (mounted) {
        setState(() {
          _isChatBlocked = false;
          _blockedByMe = false;
          _selectedImages.clear();
          _compressedImages.clear();
        });
      }

      await _loadChatroomStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.userName} has been unblocked'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        NetworkErrorHandler.showErrorSnackbar(context, e);
      }
    }
  }

  void _showBlockConfirmation() {
    showModalBottomSheet<void>(
      context: context,
      // Must use the LOCAL navigator, not the root one. This chat screen is
      // rendered inside the AdsyConnect chat OverlayEntry which sits ABOVE the
      // root Navigator, so a root-navigator sheet would be pushed BEHIND the
      // overlay and stay invisible until the user pops the overlay with Back.
      useRootNavigator: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _buildUserActionSheet(
        context: sheetContext,
        icon: Icons.block_rounded,
        accentColor: const Color(0xFFF59E0B),
        title: 'Block ${widget.userName}',
        message:
            'This conversation will be muted and you will not be able to message each other until you unblock this user.',
        primaryLabel: 'Block user',
        primaryIcon: Icons.block_rounded,
        onPrimary: _blockUser,
      ),
    );
  }

  void _showUnblockConfirmation() {
    showModalBottomSheet<void>(
      context: context,
      // Local navigator — see _showBlockConfirmation for the overlay rationale.
      useRootNavigator: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _buildUserActionSheet(
        context: sheetContext,
        icon: Icons.lock_open_rounded,
        accentColor: const Color(0xFF10B981),
        title: 'Unblock ${widget.userName}',
        message:
            'Messaging will be enabled again and this chat can continue normally.',
        primaryLabel: 'Unblock',
        primaryIcon: Icons.lock_open_rounded,
        onPrimary: _unblockUser,
      ),
    );
  }

  Widget _buildUserActionSheet({
    required BuildContext context,
    required IconData icon,
    required Color accentColor,
    required String title,
    required String message,
    required String primaryLabel,
    required IconData primaryIcon,
    required Future<void> Function() onPrimary,
  }) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        unawaited(onPrimary());
                      },
                      icon: Icon(primaryIcon, size: 17),
                      label: Text(primaryLabel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog() {
    AdsyReportSheet.show(
      context,
      title: 'Report User',
      prompt: 'Why are you reporting ${widget.userName}?',
      options: AdsyReportSheet.userOptions,
      onSubmit: (option, details) async {
        try {
          await AdsyConnectService.reportUser(
            reportedUserId: widget.userId,
            reason: option.value,
            description: details.trim().isEmpty ? null : details.trim(),
          );
          return true;
        } catch (_) {
          return false;
        }
      },
    );
  }

  void _startCall(String callType) {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to make calls')),
      );
      return;
    }

    // Prevent initiating a second call while one is already active/minimised.
    // The user can return to the ongoing call via the banner at the top.
    if (AgoraCallService.isInCall) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'You are already in a call. End it before starting a new one.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final channelName = AgoraCallService.generateChannelName(
      currentUser.id,
      widget.userId,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          channelName: channelName,
          calleeId: widget.userId,
          calleeName: widget.userName,
          calleeAvatar: widget.userAvatar,
          isIncoming: false,
          callType: callType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Must NOT be transparent: a MaterialPageRoute's underlying background
      // is opaque black, so a transparent Scaffold leaks black behind the
      // status bar / app bar / during transition animations. Use the first
      // gradient color so the screen looks seamless before the body paints.
      backgroundColor: const Color(0xFFF0F9FF),
      extendBodyBehindAppBar: false,
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF0F9FF),
              const Color(0xFFFAF5FF),
              const Color(0xFFFDF2F8),
            ],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Messages List
                Expanded(
                  child: _isLoadingMessages
                      ? ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: 8,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment: index % 2 == 0
                                    ? MainAxisAlignment.start
                                    : MainAxisAlignment.end,
                                children: [
                                  Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.7,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SkeletonLoader.box(
                                          width: 150,
                                          height: 12,
                                        ),
                                        const SizedBox(height: 6),
                                        SkeletonLoader.box(
                                          width: 100,
                                          height: 12,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : _messages.isEmpty
                          ? _buildEmptyState()
                          : ScrollablePositionedList.builder(
                              itemScrollController: _itemScrollController,
                              itemPositionsListener: _itemPositionsListener,
                              reverse: true,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 12),
                              itemCount: _messages.length +
                                  (_isLoadingMoreMessages || !_hasMoreMessages
                                      ? 1
                                      : 0),
                              itemBuilder: (context, index) {
                                // With reverse: true, index 0 is at bottom (newest message)
                                // Header for loading older messages should be at the top (highest index)
                                final hasHeader =
                                    _isLoadingMoreMessages || !_hasMoreMessages;
                                final isHeaderIndex =
                                    hasHeader && index == _messages.length;

                                if (isHeaderIndex) {
                                  if (_isLoadingMoreMessages) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: AdsyLoadingIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                const Color(0xFF10B981),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Loading older messages...',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  if (!_hasMoreMessages &&
                                      _messages.length >= 20) {
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle_rounded,
                                            size: 14,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'No more messages',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return const SizedBox.shrink();
                                }

                                // With reverse: true and messages stored oldest-to-newest,
                                // index 0 should map to the last (newest) message
                                final listIndex = _messages.length - 1 - index;
                                if (listIndex < 0 ||
                                    listIndex >= _messages.length) {
                                  return const SizedBox.shrink();
                                }

                                final message = _messages[listIndex];

                                // Show avatar if this is the last message from this sender in a group
                                final showAvatar = listIndex == 0 ||
                                    _messages[listIndex - 1]['isMe'] !=
                                        message['isMe'];

                                return _buildMessageBubble(message, showAvatar);
                              },
                            ),
                ),
                // Message Input
                _buildMessageInput(),
              ],
            ),
            // Quick scroll to bottom arrow
            if (!_isUserNearBottom)
              Positioned(
                bottom: 80,
                right: 16,
                child: AnimatedOpacity(
                  opacity: _isUserNearBottom ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: GestureDetector(
                    onTap: _scrollToBottom,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ChatAppBar(
      userName: widget.userName,
      userAvatar: widget.userAvatar,
      userId: widget.userId,
      isVerified: widget.isVerified,
      isPro: widget.isPro,
      isOnline: _isOtherUserOnline,
      isTyping: _isOtherUserTyping,
      lastSeenLabel: _formatLastSeen(_lastSeenTime),
      blockedByMe: _blockedByMe,
      isSearchMode: _isSearchMode,
      searchController: _searchController,
      searchFocusNode: _searchFocusNode,
      searchQuery: _searchQuery,
      searchMatchCount: _searchMatchIndexes.length,
      currentMatchPosition: _currentSearchMatchPosition,
      onBack: () {
        FocusManager.instance.primaryFocus?.unfocus();
        if (widget.onClose != null) {
          widget.onClose!();
        } else {
          Navigator.pop(context);
        }
      },
      onCloseSearch: _closeSearch,
      onPrevMatch: _goToPrevSearchMatch,
      onNextMatch: _goToNextSearchMatch,
      onViewProfile: _openUserProfile,
      onStartCall: _startCall,
      onMenuAction: _handleMenuAction,
    );
  }

  void _openUserProfile() {
    FocusManager.instance.primaryFocus?.unfocus();
    final route = MaterialPageRoute(
      settings: RouteSettings(
        name: '/business-network/profile',
        arguments: {'userId': widget.userId},
      ),
      builder: (_) => ProfileScreen(userId: widget.userId),
    );

    if (widget.onClose != null) {
      widget.onClose!();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FCMService.navigatorKey.currentState?.push(route);
      });
      return;
    }

    (FCMService.navigatorKey.currentState ??
            Navigator.of(context, rootNavigator: true))
        .push(route);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Start a conversation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to ${widget.userName}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _setReplyingTo(Map<String, dynamic> message) {
    setState(() {
      _replyingToMessage = message;
    });
    _messageFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  String _getReplyPreviewText(Map<String, dynamic> message) {
    final type = message['type']?.toString() ?? 'text';
    switch (type) {
      case 'image':
        return 'ðŸ“· Photo';
      case 'video':
        return 'ðŸŽ¥ Video';
      case 'voice':
        return 'ðŸŽ¤ Voice message';
      case 'document':
        return 'ðŸ“„ ${message['file_name'] ?? message['fileName'] ?? 'Document'}';
      default:
        final text =
            (message['message'] ?? message['content'] ?? '').toString();
        if (text.startsWith('ðŸ“ž')) return text;
        return text.length > 50 ? '${text.substring(0, 50)}...' : text;
    }
  }

  Map<String, String>? _tryParseReplyFromText(String rawText) {
    final text = rawText.trim();
    if (!text.startsWith('â†©ï¸')) return null;

    final parts = text.split('\n\n');
    if (parts.length < 2) return null;

    final header = parts.first.trim();
    String rest = header.replaceFirst('â†©ï¸', '').trim();

    String replyToId = '';
    if (rest.startsWith('(')) {
      final end = rest.indexOf(')');
      if (end > 1) {
        replyToId = rest.substring(1, end).trim();
        rest = rest.substring(end + 1).trim();
      }
    }

    final colonIndex = rest.indexOf(':');
    if (colonIndex == -1) return null;

    final sender = rest.substring(0, colonIndex).trim();
    final preview = rest.substring(colonIndex + 1).trim();
    final messageText = parts.sublist(1).join('\n\n').trimLeft();

    return {
      'replyToId': replyToId,
      'replyToSender': sender,
      'replyPreview': preview,
      'messageText': messageText,
    };
  }

  void _viewImage(String filePath) {
    final isUrl =
        filePath.startsWith('http://') || filePath.startsWith('https://');

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: GestureDetector(
                onLongPress: () => _showImageOptions(filePath),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: isUrl
                      ? Image.network(
                          filePath,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: AdsyLoadingIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.white,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Failed to load image',
                                    style:
                                        TextStyle(color: Colors.grey.shade400),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Image.file(
                          File(filePath),
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Long press for options',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageOptions(String filePath) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.download_rounded, color: Color(0xFF3B82F6)),
              title: const Text('Download Image'),
              onTap: () async {
                Navigator.pop(context);
                await _downloadImage(filePath);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('Delete Image',
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Image'),
                    content: const Text(
                        'Are you sure you want to delete this image?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Delete functionality coming soon'),
                      backgroundColor: Color(0xFF3B82F6),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadImage(String imageUrl) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Downloading image...'),
          duration: Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image downloaded successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _downloadDocument(String? filePath, String fileName) {
    if (filePath == null || filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document not available'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $fileName...'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Implement actual download functionality
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool showAvatar) {
    final messageId = message['id']?.toString() ?? '';
    final isSearchHit = _isSearchMode &&
        _searchQuery.trim().isNotEmpty &&
        messageId.isNotEmpty &&
        _searchMatchedMessageIds.contains(messageId);
    final isCurrentSearchHit =
        isSearchHit && _currentSearchMessageId == messageId;
    return ChatMessageBubble(
      key: ValueKey(messageId.isNotEmpty ? messageId : message.hashCode),
      message: message,
      showAvatar: showAvatar,
      userName: widget.userName,
      userAvatar: widget.userAvatar,
      isSearchHit: isSearchHit,
      isCurrentSearchHit: isCurrentSearchHit,
      playingVoiceMessageId: _playingVoiceMessageId,
      voicePosition: _voicePosition,
      voiceDuration: _voiceDuration,
      onLongPress: _isMessageDeleted(message)
          ? null
          : () => _showMessageOptions(message),
      onOptions: _isMessageDeleted(message)
          ? null
          : () => _showMessageOptions(message),
      onReply: (msg) => _setReplyingTo(msg),
      onPlayVoice: (id, url) => _playVoiceMessage(id, url),
      onViewImage: _viewImage,
      onDownloadDoc: _downloadDocument,
      onScrollToMessage: _scrollToMessageId,
    );
  }

  Widget _buildMessageInput() {
    return ChatMessageInput(
      messageController: _messageController,
      messageFocusNode: _messageFocusNode,
      isRecording: _isRecording,
      isChatBlocked: _isChatBlocked,
      blockedByMe: _blockedByMe,
      isTyping: _isTyping,
      isUploadingAttachment: _isUploadingAttachment,
      isCompressingImages: _isCompressingImages,
      replyFromName: _replyingToMessage != null
          ? (_replyingToMessage!['isMe'] == true ? 'You' : widget.userName)
          : null,
      replyPreviewText: _replyingToMessage != null
          ? _getReplyPreviewText(_replyingToMessage!)
          : null,
      compressedImages: _compressedImages,
      recordDuration: Duration(seconds: _recordDuration),
      onSend: _sendMessage,
      onStartRecording: _startRecording,
      onStopRecording: _stopRecording,
      onCancelRecording: _cancelRecording,
      onUnblock: _showUnblockConfirmation,
      onCancelReply: _cancelReply,
      onShowAttachmentOptions: _showAttachmentOptions,
      onSendImages: _sendSelectedImages,
      onCancelImagePreview: () => setState(() {
        _selectedImages.clear();
        _compressedImages.clear();
      }),
      onRemoveImage: _removeSelectedImage,
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
