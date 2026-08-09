import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/adsyconnect_realtime_service.dart';
import '../services/adsyconnect_service.dart';
import '../services/active_chat_tracker.dart';
import '../utils/adsy_ios_scale.dart';
import '../utils/chat_autoscroll.dart';
import '../utils/chat_history_cache.dart';
import '../utils/image_compressor.dart';
import '../utils/network_error_handler.dart';
import '../widgets/skeleton_loader.dart';
import '../config/app_config.dart';
import '../services/house_ads_service.dart';
import '../utils/download_open_utils.dart';
import '../utils/gallery_saver.dart';
import '../utils/media_headers.dart';
import '../widgets/chat/chat_media_viewer.dart';
import '../utils/shared_post_message.dart';
import '../services/agora_call_service.dart';
import '../services/fcm_service.dart';
import '../widgets/chat/chat_app_bar.dart';
import '../widgets/chat/chat_message_bubble.dart';
import '../widgets/chat/chat_message_input.dart';
import '../widgets/chat/chat_edit_message_sheet.dart';
import '../widgets/chat/message_options_sheet.dart';
import '../utils/video_upload_helper.dart';
import 'business_network/profile_screen.dart';
import 'call_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_back_to_top.dart';
import 'package:oxius_native/widgets/common/adsy_report_sheet.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';
import '../utils/url_launcher_utils.dart';
import 'package:oxius_native/widgets/common/adsy_chat_icon.dart';

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

  /// Something the chat was opened ABOUT — today, the ad whose "মেসেজ করুন"
  /// button brought the user here. It shows as a removable card above the
  /// composer and rides along on the first message as its quote, so the
  /// advertiser sees which ad the person is writing about instead of a
  /// context-free "hi".
  final SharedPostMessage? pendingAttachment;

  /// The ad that opened this chat. When the message goes through, it is
  /// reported as a LEAD for that ad — the advertiser paid to be written to,
  /// so the conversation has to be traceable back to the campaign.
  final String? pendingAdId;

  /// Where the ad was shown (bn_feed, shorts_reel …) — recorded with the lead
  /// so the advertiser can see which surface actually produces conversations.
  final String? pendingAdPlacement;

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
    this.pendingAttachment,
    this.pendingAdId,
    this.pendingAdPlacement,
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

  /// The pushed route for each open chat, so an [open] call for a chat that is
  /// already on the stack can bring it back to the front instead of refusing.
  /// [_openRouteNames] alone cannot do that — it knows a chat is open
  /// somewhere, but not where, and "somewhere" is often buried under the very
  /// screen the user is tapping Chat on.
  static final Map<String, Route<dynamic>> _openRoutes = <String, Route<dynamic>>{};
  static const Duration _navigatorSettleDelay = Duration(milliseconds: 380);
  static bool _chatPushInFlight = false;

  /// A Cupertino route, deliberately, on every platform.
  ///
  /// It is what carries the left-to-right back-swipe: the app dropped the
  /// global CupertinoPageTransitionsTheme (it broke the iOS archive on CI),
  /// so a MaterialPageRoute here meant the chat was the one screen you could
  /// not swipe out of. This gives the gesture back for this route alone,
  /// without touching the theme everything else builds against.
  /// Whether [chatroomId]'s route is currently on a navigator stack.
  static bool isRouteOpen(String chatroomId) =>
      _openRouteNames.contains(routeNameFor(chatroomId));

  static CupertinoPageRoute<T> _chatRoute<T>({
    required String chatroomId,
    required String userId,
    required String userName,
    String? userAvatar,
    String? profession,
    bool isOnline = false,
    bool isVerified = false,
    bool isPro = false,
  }) {
    return CupertinoPageRoute<T>(
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

      final routeName = routeNameFor(chatroomId);
      var navigator = Navigator.of(context, rootNavigator: useRootNavigator);

      // The same chat must never sit on the stack twice. But refusing outright
      // is what made the Chat button on a profile look broken: you reach that
      // profile from the peer's own chat, so their chat route is still alive
      // directly underneath it — the guard fired, nothing happened, and going
      // back left you staring at the conversation list. If the chat is on this
      // navigator, bring it forward; that is what the tap asked for.
      final existing = _openRoutes[routeName];
      if (existing != null &&
          existing.isActive &&
          identical(existing.navigator, navigator)) {
        navigator.popUntil((route) => identical(route, existing));
        return null;
      }
      if (existing == null && _openRouteNames.contains(routeName)) {
        // A copy of this chat is alive without being a route of its own — it
        // is embedded in a sheet or a card. There is nothing to surface, and a
        // second instance would fight the first over the same socket.
        return null;
      }

      CupertinoPageRoute<T> buildRoute() => _chatRoute<T>(
            chatroomId: chatroomId,
            userId: userId,
            userName: userName,
            userAvatar: userAvatar,
            profession: profession,
            isOnline: isOnline,
            isVerified: isVerified,
            isPro: isPro,
          );

      var route = buildRoute();
      try {
        pushedRoute = navigator.push<T>(route);
      } catch (error) {
        if (!_isNavigatorLockedError(error)) rethrow;
        await Future<void>.delayed(_navigatorSettleDelay);
        if (!context.mounted) return null;
        navigator = Navigator.of(context, rootNavigator: useRootNavigator);
        route = buildRoute();
        pushedRoute = navigator.push<T>(route);
      }

      _openRoutes[routeName] = route;
      unawaited(route.popped.whenComplete(() {
        if (identical(_openRoutes[routeName], route)) {
          _openRoutes.remove(routeName);
        }
      }));

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

/// Controller that hides the IME composing-region underline that otherwise
/// appears under the word being typed.
class _NoComposingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return super
        .buildTextSpan(context: context, style: style, withComposing: false);
  }
}

class _AdsyConnectChatInterfaceState extends State<AdsyConnectChatInterface>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = _NoComposingController();
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
  List<Map<String, dynamic>> _messages = [];
  final List<XFile> _selectedImages = [];
  final List<String> _compressedImages = [];
  String? _playingVoiceMessageId;
  Duration _voicePosition = Duration.zero;
  Duration _voiceDuration = Duration.zero;
  bool _isChatBlocked = false;
  bool _blockedByMe = false;
  bool _isMuted = false;
  bool _isLoadingChatroomStatus = false;
  int _statusPollCounter = 0;
  // Counts 4s ticks so the message poll can back off to every 6th one while
  // the socket is connected.
  int _idlePollTick = 0;
  bool _isUserNearBottom = true;
  bool _isOtherUserOnline = false;
  bool _isOtherUserTyping = false;
  // Counterpart deactivated (deleted) or suspended — profile link disabled.
  bool _counterpartDisabled = false;
  // Tap-to-reveal timestamp (group-chat parity): the tapped message shows
  // its full date+time; tapping again hides it.
  String? _tappedTimeMessageId;
  String? _lastSeenTime;
  /// Attachment waiting to ride along with the next message (see
  /// [AdsyConnectChatInterface.pendingAttachment]).
  SharedPostMessage? _pendingAttachment;
  Timer? _onlineStatusTimer;
  Timer? _remoteTypingResetTimer;
  Timer? _activeChatHeartbeat;
  // Repeats the REST typing heartbeat while the user keeps typing, so the
  // receiver's poll fallback (below) sees a fresh `updated_at`.
  Timer? _typingHeartbeatTimer;
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
    _startActiveChatHeartbeat();
    _isOtherUserOnline = widget.isOnline;
    // The ad/post this chat was opened about — pending until the user sends
    // (or dismisses) it.
    _pendingAttachment = widget.pendingAttachment;
    _loadChatroomStatus();
    // Instant open: seed from the in-memory history cache so a previously
    // visited chat paints its messages with NO spinner; the fetch below then
    // reconciles with fresh server data (stale-while-revalidate).
    final cached = ChatHistoryCache.get('room:${widget.chatroomId}');
    if (cached != null && cached.isNotEmpty) {
      _messages = cached;
      _isLoadingMessages = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBottom();
      });
    }
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

  // The chat lives in a root OverlayEntry with its OWN nested Navigator, so
  // the Android hardware back button (routed to the ROOT navigator) would pop
  // the chat-list route underneath instead of closing this chat — landing the
  // user on the page before the list. As a WidgetsBindingObserver added AFTER
  // the root navigator, our didPopRoute runs first; handle back here.
  @override
  Future<bool> didPopRoute() async {
    if (!mounted) return false;
    // In search mode, back exits search first.
    if (_isSearchMode) {
      _closeSearch();
      return true;
    }
    // A sheet/dialog opened on this overlay's local navigator? Dismiss it.
    final localNav = Navigator.of(context);
    if (localNav.canPop()) {
      localNav.pop();
      return true;
    }
    // Overlay mode: close the chat, revealing the list (never pop the root).
    if (widget.onClose != null) {
      widget.onClose!();
      return true;
    }
    // Plain route mode (not an overlay): let the Navigator pop normally.
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
      // belt-and-suspenders against socket replay gaps. MERGE, don't reload:
      // _loadMessages() would reset to page 1, collapse the loaded history
      // and yank a user who was reading old messages back to the bottom.
      _checkForNewMessages();
      // Back on screen: re-mark this chat active so we keep suppressing its push.
      AdsyConnectService.setActiveChat(widget.chatroomId);
      _startActiveChatHeartbeat();
    } else {
      // App backgrounded: the user isn't looking at the chat, so let its push
      // through again and stop the heartbeat.
      _stopActiveChatHeartbeat();
      AdsyConnectService.clearActiveChat();
    }
  }

  // Refresh the "active chat" marker periodically so the backend's freshness
  // window never expires while this screen stays open (prevents push for the
  // chat the user is actively viewing).
  void _startActiveChatHeartbeat() {
    _activeChatHeartbeat?.cancel();
    _activeChatHeartbeat = Timer.periodic(const Duration(minutes: 2), (_) {
      AdsyConnectService.setActiveChat(widget.chatroomId);
    });
  }

  void _stopActiveChatHeartbeat() {
    _activeChatHeartbeat?.cancel();
    _activeChatHeartbeat = null;
  }

  void _onItemPositionsChanged() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // "Near bottom" = the newest (or second-newest) bubble is on screen —
    // slightly forgiving so a hair of scroll doesn't break auto-stick.
    final bottomVisible =
        positions.any((p) => p.index <= 1 && p.itemTrailingEdge > 0);
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

    // No anchor capture needed: builder indexes count from the newest end,
    // so prepending older messages never shifts an existing row.
    setState(() {
      _isLoadingMoreMessages = true;
    });

    try {
      final nextPage = _currentPage + 1;
      debugPrint('🔵 Loading older messages, page: $nextPage');

      final messages = await AdsyConnectService.getMessages(
        widget.chatroomId,
        page: nextPage,
      );

      debugPrint('🟢 Loaded ${messages.length} older messages');

      if (mounted && messages.isNotEmpty) {
        // Backend returns oldest-to-newest (ascending by created_at)
        final parsedMessages = _parseMessages(messages);
        setState(() {
          // Insert older messages at the beginning
          _messages.insertAll(0, parsedMessages);
          // _addSmartTimestamps anchored the tick on the newest message OF
          // THIS PAGE. Prepending it without recomputing leaves two anchors:
          // one correct, one stranded mid-thread.
          _refreshStatusAnchor(_messages);
          _currentPage = nextPage;
          _hasMoreMessages = messages.length >= 20;
          _isLoadingMoreMessages = false;
        });

        // No anchor jump: in this reverse list the builder index is
        // (length-1-i), so prepending older messages does NOT shift any
        // existing row — the viewport is already stable. The old jumpTo
        // relocated the anchor to the bottom edge (alignment 0 = leading
        // edge = bottom here), leaping the view a screenful into history
        // on every page load.
        if (_searchQuery.trim().isNotEmpty) {
          // Every stored match index just shifted by the prepend count.
          _recomputeSearchMatches(keepCurrent: true);
        }
      } else {
        setState(() {
          _hasMoreMessages = false;
          _isLoadingMoreMessages = false;
        });
      }
    } catch (e) {
      debugPrint('🔴 Error loading older messages: $e');
      if (mounted) {
        setState(() => _isLoadingMoreMessages = false);
      }
    }
  }

  @override
  void dispose() {
    // Snapshot the freshest history (including messages sent/received during
    // this visit) so re-opening this chat is instant.
    if (_messages.isNotEmpty) {
      ChatHistoryCache.put('room:${widget.chatroomId}', _messages);
    }
    if (_isTyping) {
      AdsyConnectRealtimeService.instance.sendTypingStatus(
        chatroomId: widget.chatroomId,
        isTyping: false,
      );
      // Clear the REST heartbeat too so pollers don't see a stale "typing".
      AdsyConnectService.sendTypingHeartbeat(widget.chatroomId, false);
    }
    // Make sure we don't leave any focus capturing pointer events on the
    // returning chat-list screen.
    FocusManager.instance.primaryFocus?.unfocus();
    AdsyConnectChatInterface._openRouteNames.remove(
      AdsyConnectChatInterface.routeNameFor(widget.chatroomId),
    );
    ActiveChatTracker.clearActiveChat();
    AdsyConnectService.clearActiveChat();
    _activeChatHeartbeat?.cancel();
    _realtimeSubscription?.cancel();
    _remoteTypingResetTimer?.cancel();
    _typingHeartbeatTimer?.cancel();
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
      AdsyToast.error(context, 'Voice message not available');
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
      debugPrint('Error playing voice message: $e');
      setState(() => _playingVoiceMessageId = null);
      if (mounted) {
        AdsyToast.error(context, 'ভয়েস মেসেজ চালানো যায়নি');
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
      // REST path too — works when the socket is down, and the server relays
      // it to the other user over their socket.
      AdsyConnectService.sendTypingHeartbeat(
          widget.chatroomId, isCurrentlyTyping);
      _typingHeartbeatTimer?.cancel();
      if (isCurrentlyTyping) {
        // Keep `updated_at` fresh while typing continues so the receiver's
        // 4s poll (7s freshness window) doesn't flicker off mid-typing.
        _typingHeartbeatTimer =
            Timer.periodic(const Duration(seconds: 3), (_) {
          if (_isTyping) {
            AdsyConnectService.sendTypingHeartbeat(widget.chatroomId, true);
          }
        });
      }
    }
  }

  /// Apply a reaction pushed over the socket.
  ///
  /// The poll syncs reactions too, but only every few seconds; this makes the
  /// other person's reaction land immediately. `user_ids` per emoji lets each
  /// client derive its own "reacted_by_me" from one shared payload.
  void _applyReactionEvent(Map<String, dynamic> event) {
    if (event['scope'] != 'direct') return;
    final id = event['message_id']?.toString() ?? '';
    if (id.isEmpty) return;
    final idx = _messages.indexWhere((m) => (m['id']?.toString() ?? '') == id);
    if (idx == -1) return;
    final raw = event['reactions'];
    if (raw is! List) return;
    final me = AuthService.currentUser?.id ?? '';
    final mapped = raw.map((r) {
      final map = r as Map;
      final ids = (map['user_ids'] as List?) ?? const [];
      return {
        'emoji': map['emoji'],
        'count': map['count'],
        'reacted_by_me': ids.map((e) => e.toString()).contains(me),
      };
    }).toList();
    setState(() => _messages[idx]['reactions'] = mapped);
  }

  void _handleRealtimeEvent(Map<String, dynamic> event) {
    final type = event['type']?.toString();
    if (type == null || !mounted) {
      return;
    }

    if (type == 'message_reaction') {
      _applyReactionEvent(event);
      return;
    }

    // An edit or a delete used to reach the peer only on the next poll, so
    // they kept reading text the sender had already changed or removed.
    //
    // This mirrors the poll's sync loop KEY FOR KEY, and parses with
    // _parseMessages (which derives isMe from the sender id). The first
    // version merged _parseSingleMessage's output wholesale — that helper is
    // for parsing the response to YOUR OWN send and hardcodes isMe: true, so
    // a peer's edit flipped their bubble onto your side of the thread and
    // dragged the read ticks with it.
    if (type == 'message_edited' || type == 'message_deleted') {
      final raw = event['message'];
      if (raw is! Map) return;
      final serverMsg = _parseMessages([raw]).firstOrNull;
      if (serverMsg == null) return;
      final id = (serverMsg['id'] ?? '').toString();
      if (id.isEmpty) return;
      final idx = _messages.indexWhere((m) => (m['id'] ?? '').toString() == id);
      if (idx == -1) return;
      setState(() {
        final existing = _messages[idx];
        existing['isSeen'] = serverMsg['isSeen'];
        existing['isEdited'] = serverMsg['isEdited'];
        if (!_pendingReactionIds.contains(id) &&
            !_sameReactions(existing['reactions'], serverMsg['reactions'])) {
          existing['reactions'] = serverMsg['reactions'];
        }
        final serverText = serverMsg['message']?.toString();
        if (serverText != null &&
            serverText != existing['message']?.toString()) {
          existing['message'] = serverText;
          existing['content'] = serverText;
          existing['replyToId'] = serverMsg['replyToId'];
          existing['replyToSender'] = serverMsg['replyToSender'];
          existing['replyPreview'] = serverMsg['replyPreview'];
        }
        if (type == 'message_deleted' || serverMsg['isDeleted'] == true) {
          existing['isDeleted'] = true;
        }
        // A deleted newest message can no longer carry the tick.
        _refreshStatusAnchor(_messages);
      });
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

      // Deactivated/suspended counterpart → the profile link goes dead.
      final rawOther = details['other_user'];
      if (rawOther is Map) {
        final other = Map<String, dynamic>.from(rawOther);
        final disabled =
            other['is_active'] == false || other['is_suspended'] == true;
        if (disabled != _counterpartDisabled) {
          _counterpartDisabled = disabled;
        }
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
      final isMuted = _parseBool(
          details['is_muted'] ?? details['isMuted'] ?? details['muted']);

      setState(() {
        _isChatBlocked = isBlocked;
        _blockedByMe = blockedByMe;
        _isMuted = isMuted;
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
        // The socket is the primary path, so re-fetching every 4s while it is
        // healthy is pure waste — one open chat was issuing 15 message
        // requests a minute for nothing. Poll every ~24s while connected, and
        // snap back to 4s the moment the socket drops.
        if (AdsyConnectRealtimeService.instance.isConnected) {
          // 6 ticks (24s) was too slow to be a safety net: anything the
          // socket dropped — a reaction, a read receipt, a peer edit — sat
          // invisible for up to 24 seconds and read as "needs a reload".
          // 3 ticks (12s) costs one extra request per half-minute per open
          // chat and halves the worst case.
          _idlePollTick = (_idlePollTick + 1) % 3;
        } else {
          _idlePollTick = 0;
        }
        if (_idlePollTick == 0) _checkForNewMessages();
        _pollTypingStatus();
        _statusPollCounter++;
        if (_statusPollCounter >= 8) {
          _statusPollCounter = 0;
          _loadChatroomStatus();
        }
      }
    });
  }

  /// Poll fallback for the typing bubble: mirrors the websocket event when
  /// the socket is down. Fresh heartbeats (<=7s) count as typing.
  Future<void> _pollTypingStatus() async {
    final typing =
        await AdsyConnectService.isOtherUserTyping(widget.chatroomId);
    if (!mounted || typing == _isOtherUserTyping) return;
    setState(() => _isOtherUserTyping = typing);
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

      // Sync mutable fields on messages we already hold. Only isSeen was
      // synced here, so a reaction added by the OTHER person never appeared
      // until the whole list was rebuilt — it looked like reactions needed a
      // reload. Reactions and the edited flag change after send too, so they
      // are refreshed the same way.
      for (var serverMsg in parsedMessages) {
        final serverId = serverMsg['id']?.toString() ?? '';
        final existingIndex = _messages.indexWhere(
          (m) => (m['id']?.toString() ?? '') == serverId,
        );
        if (existingIndex != -1) {
          final existing = _messages[existingIndex];
          if (existing['isSeen'] != serverMsg['isSeen']) {
            existing['isSeen'] = serverMsg['isSeen'];
            hasUpdates = true;
          }
          if (existing['isEdited'] != serverMsg['isEdited']) {
            existing['isEdited'] = serverMsg['isEdited'];
            hasUpdates = true;
          }
          // Skip while our own reaction is in flight — see
          // _pendingReactionIds.
          if (!_pendingReactionIds.contains(existing['id']?.toString()) &&
              !_sameReactions(existing['reactions'], serverMsg['reactions'])) {
            existing['reactions'] = serverMsg['reactions'];
            hasUpdates = true;
          }
          // There is no socket event for peer edits or deletes — this poll
          // is the ONLY path that can update an open chat. Without these two
          // syncs the "Edited" badge appeared next to the OLD words, and a
          // deleted message stayed on screen until the chat was reopened.
          final serverText = serverMsg['message']?.toString();
          if (serverText != null &&
              serverText != existing['message']?.toString()) {
            existing['message'] = serverText;
            existing['content'] = serverText;
            existing['replyToId'] = serverMsg['replyToId'];
            existing['replyToSender'] = serverMsg['replyToSender'];
            existing['replyPreview'] = serverMsg['replyPreview'];
            hasUpdates = true;
          }
          if (serverMsg['isDeleted'] == true &&
              existing['isDeleted'] != true) {
            existing['isDeleted'] = true;
            hasUpdates = true;
          }
        }
      }

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

        // Auto-scroll to bottom if user is near bottom
        if (_isUserNearBottom) {
          _scrollToBottom();
        }
      }

      // Update UI if there were any changes
      if (hasUpdates && mounted) {
        // A peer edit/delete can retire the anchored row (the anchor skips
        // deleted messages), so recompute before painting or the ticks
        // disappear from the thread entirely.
        _refreshStatusAnchor(_messages);
        setState(() {});
      }
    } catch (e) {
      // Silently fail for polling errors to avoid spamming user
      debugPrint('🔴 Error polling messages: $e');
    }
  }

  Future<void> _loadMessages({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        // SWR: never throw a spinner over already-visible (cached) history.
        _isLoadingMessages = _messages.isEmpty;
        _currentPage = 1;
      });
    }

    try {
      debugPrint(
          '🔵 Loading messages for chatroom: ${widget.chatroomId}, page: $_currentPage');

      final messages = await AdsyConnectService.getMessages(
        widget.chatroomId,
        page: _currentPage,
      );

      debugPrint('🟢 Loaded ${messages.length} messages');

      if (mounted) {
        // Backend returns oldest-to-newest (ascending by created_at)
        final parsedMessages = _parseMessages(messages);
        setState(() {
          if (loadMore) {
            _messages.insertAll(0, parsedMessages);
            _refreshStatusAnchor(_messages);
          } else {
            _messages = parsedMessages;
            // Set last message ID for polling
            if (parsedMessages.isNotEmpty) {
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
          // Keep the instant-open cache fresh for the next visit.
          ChatHistoryCache.put('room:${widget.chatroomId}', _messages);
          _scrollToBottom();
          // Mark messages as read when opening chat
          _markMessagesAsRead();
        }
      }
    } catch (e) {
      debugPrint('🔴 Error loading messages: $e');
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

  /// Cheap value-compare of two reaction lists, so an unchanged poll doesn't
  /// trigger a rebuild (this runs every 5s for every message on screen).
  bool _sameReactions(dynamic a, dynamic b) {
    final la = a is List ? a : const [];
    final lb = b is List ? b : const [];
    if (la.length != lb.length) return false;
    for (var i = 0; i < la.length; i++) {
      final x = la[i], y = lb[i];
      if (x is! Map || y is! Map) return false;
      if (x['emoji'] != y['emoji'] ||
          x['count'] != y['count'] ||
          x['reacted_by_me'] != y['reacted_by_me']) {
        return false;
      }
    }
    return true;
  }

  List<Map<String, dynamic>> _parseMessages(List<dynamic> messages) {
    final parsedMessages = messages.map((msg) {
      final sender = msg['sender'] ?? {};
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
        // Carry the server's reaction list through the parser. Without this the
        // 5s poll (and any reload) rebuilds the map with no reactions, so a
        // reaction would flash and then vanish. The server is the source of
        // truth; the optimistic update in _reactToMessage only bridges the gap
        // until the next poll refreshes from here.
        'reactions': msg['reactions'] is List ? msg['reactions'] : const [],
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

    _refreshStatusAnchor(messages);
    return messages;
  }

  /// Puts the delivery/read state on the LAST message you sent.
  ///
  /// It must survive a reload. It used to ride along inside the timestamp
  /// row, which only appears on the first message or after a 3-minute gap —
  /// so the tick showed right after sending (that optimistic entry forces
  /// showTimestamp) and then vanished the next time the thread was rebuilt
  /// from the server. WhatsApp/Messenger keep the ticks on the newest
  /// outgoing message permanently; so do we.
  ///
  /// Lives here rather than in one caller because messages arrive through
  /// several paths (socket, poll, send, media) and the anchor has to move
  /// with every one of them.
  static void _refreshStatusAnchor(List<Map<String, dynamic>> messages) {
    var anchored = false;
    for (int i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      if (!anchored &&
          m['isMe'] == true &&
          m['isDeleted'] != true) {
        m['showStatus'] = true;
        anchored = true;
      } else {
        m['showStatus'] = false;
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      // Call API to mark messages as read
      await AdsyConnectService.markChatroomAsRead(widget.chatroomId);

      // Update local state immediately - mark all received messages as read
      _markLocalIncomingMessagesAsRead();
    } catch (e) {
      debugPrint('🔴 Error marking messages as read: $e');
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
    // One post-frame scroll wasn't enough: the row's final height isn't known
    // on that frame (text wrapping, link previews, the keyboard animating), so
    // the list settled above the new message. It also gave up silently when
    // the list hadn't attached yet. ChatAutoScroll keeps correcting for a few
    // frames until the newest row is actually flush with the bottom.
    if (!mounted) return;
    ChatAutoScroll.stickToNewest(
      _itemScrollController,
      _itemPositionsListener,
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
      AdsyToast.info(context, 'Original message is not loaded yet');
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
    _upsertMessageInner(message);
    _refreshStatusAnchor(_messages);
  }

  void _upsertMessageInner(Map<String, dynamic> message) {
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
        // The server copy carries no upload flag, so a plain merge would keep
        // the placeholder's `isUploading: true` forever — a delivered photo
        // stuck behind a spinner and a clock icon until the chat is reopened.
        merged['isUploading'] = false;
        _messages[pendingIndex] = merged;
        return;
      }

      _messages.add(message);
      return;
    }

    final merged = Map<String, dynamic>.from(_messages[existingIndex]);
    merged.addAll(message);
    // Same reason as the pending branch: a server-backed row is never still
    // uploading, and the incoming copy carries no key to overwrite it with.
    if (!_isLocalPlaceholder(merged)) {
      merged['isUploading'] = false;
    }
    _messages[existingIndex] = merged;
  }

  /// True for any locally-created placeholder awaiting its server copy.
  static bool _isLocalPlaceholder(Map<String, dynamic> m) {
    final id = (m['id'] ?? '').toString();
    return id.startsWith('temp_') ||
        id.startsWith('local_media_') ||
        id.startsWith('local_img_') ||
        id.startsWith('local_voice_');
  }

  /// Finds the placeholder a freshly-arrived server message belongs to.
  ///
  /// Text matched on its words. Media could not match on anything — the text
  /// is empty — so once the server started echoing a sender their own
  /// message, every photo appeared TWICE: once as the local bubble the HTTP
  /// response reconciled, and once appended by the socket echo. Media now
  /// matches the oldest in-flight placeholder of the same type, which is
  /// correct because sends are awaited one at a time.
  int _findEquivalentPendingMessageIndex(Map<String, dynamic> message) {
    if (_isLocalPlaceholder(message) || message['isMe'] != true) {
      return -1;
    }

    final messageText = (message['message'] ?? '').toString().trim();
    final messageType = (message['type'] ?? 'text').toString();
    final isMedia = messageType != 'text';

    return _messages.indexWhere((existing) {
      if (!_isLocalPlaceholder(existing)) return false;
      if (existing['isMe'] != true) return false;
      if ((existing['type'] ?? 'text').toString() != messageType) return false;

      if (isMedia) {
        // A filename is the strongest key when both sides carry one.
        final a = (existing['fileName'] ?? '').toString();
        final b = (message['fileName'] ?? '').toString();
        if (a.isNotEmpty && b.isNotEmpty) return a == b;
        return true; // oldest in-flight placeholder of this type
      }

      if (existing['pending'] != true) return false;
      return (existing['message'] ?? '').toString().trim() == messageText;
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
    final attachment = _pendingAttachment;
    _messageController.clear();

    // With an attachment pending, the message body IS the encoded card + the
    // typed words: the bubble then draws the card as a quote above ordinary
    // message text. Without one, nothing changes.
    final body = attachment != null
        ? attachment.withText(messageText).encode()
        : messageText;

    // Optimistic UI: show the message immediately with a pending marker so
    // the user gets instant feedback. The server response will replace this
    // temp entry by id.
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final optimistic = <String, dynamic>{
      'id': tempId,
      'isMe': true,
      'type': 'text',
      'message': body,
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
      // One message carries it — the second message is plain text again.
      _pendingAttachment = null;
    });
    _scrollToBottom();

    try {
      debugPrint('🔵 Sending message: $messageText');

      String contentToSend = body;
      if (replyTo != null) {
        final replyToId = replyTo['id']?.toString() ?? '';
        final replyToText = _getReplyPreviewText(replyTo);
        final replyToSender = replyTo['isMe'] == true ? 'You' : widget.userName;
        final idPart = replyToId.isNotEmpty ? '($replyToId) ' : '';
        contentToSend =
            '↩️ $idPart$replyToSender: $replyToText\n\n$body';
      }

      final sentMessage = await AdsyConnectService.sendTextMessage(
        chatroomId: widget.chatroomId,
        receiverId: widget.userId,
        content: contentToSend,
      );

      debugPrint('🟢 Message sent: ${sentMessage['id']}');

      // The message is stored — now, and only now, it counts as a lead for
      // the ad that opened this chat. Fire-and-forget: the advertiser's
      // bookkeeping must never be able to fail the user's message.
      if (attachment != null && (widget.pendingAdId ?? '').isNotEmpty) {
        unawaited(HouseAdsService.recordLead(
          adId: widget.pendingAdId!,
          chatroomId: widget.chatroomId,
          message: messageText,
          placement: widget.pendingAdPlacement ?? '',
        ));
      }

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
      debugPrint('🔴 Error sending message: $e');
      if (mounted) {
        setState(() {
          // Roll back the optimistic message on failure.
          _messages.removeWhere((m) => (m['id']?.toString() ?? '') == tempId);
          // The row we just dropped was the tick anchor, so without this the
          // status vanishes from the WHOLE thread until the next new message.
          _refreshStatusAnchor(_messages);
          _isSendingMessage = false;
          // The send failed, so the attachment was never delivered — put it
          // back with the text, or the retry would drop the ad silently.
          _pendingAttachment ??= attachment;
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
          // Local navigator — this chat screen lives in an OverlayEntry above
          // the root Navigator, so a root-navigator dialog would be hidden
          // behind the overlay until the user pops the page with Back.
          useRootNavigator: false,
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
          AdsyToast.error(context,
              'Microphone permission is required to record voice messages');
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
      debugPrint('Error starting recording: $e');
      if (mounted) {
        AdsyToast.error(context, 'Failed to start recording');
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
          debugPrint(
              '🔵 Sending voice message: $path, duration: $_recordDuration seconds');

          // Same instant-bubble treatment as photos: the recording is on
          // disk already, so there is no reason to show an empty thread
          // while it uploads.
          final voiceTempId =
              'local_voice_${DateTime.now().microsecondsSinceEpoch}';
          if (mounted) {
            setState(() {
              _messages.add(<String, dynamic>{
                'id': voiceTempId,
                'senderId': AuthService.currentUser?.id ?? '',
                'message': '',
                'timestamp': DateTime.now(),
                'isMe': true,
                'type': 'voice',
                'mediaUrl': path,
                'voice_duration': _recordDuration,
                'voiceDuration': _recordDuration,
                'isSeen': false,
                'is_read': false,
                'isDeleted': false,
                'isEdited': false,
                'reactions': const [],
                'isUploading': true,
              });
              _messages = List.from(_addSmartTimestamps(_messages));
            });
            _scrollToBottom();
          }

          final sentMessage = await AdsyConnectService.sendMediaMessage(
            chatroomId: widget.chatroomId,
            receiverId: widget.userId,
            messageType: 'voice',
            mediaFilePath: path,
            voiceDuration: _recordDuration,
          );

          debugPrint('🟢 Voice message sent: ${sentMessage['id']}');

          if (mounted) {
            setState(() {
              final parsed = _parseSingleMessage(sentMessage);
              _messages.removeWhere((m) => m['id'] == voiceTempId);
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
          debugPrint('🔴 Error sending voice message: $e');
          if (mounted) {
            setState(() {
              _isSendingMessage = false;
              _recordDuration = 0;
            });
            AdsyToast.error(context, 'ভয়েস মেসেজ পাঠানো যায়নি');
          }
        }
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
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

      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });
    } catch (e) {
      debugPrint('Error canceling recording: $e');
    }
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
    // Shared sheet (also used by group chats) — options appear only when
    // their callback is passed. Edit is limited to 10 minutes after send.
    final isMe = message['isMe'] == true;
    final isDeleted = _isMessageDeleted(message);
    final sentAt = message['timestamp'];
    final withinEditWindow = sentAt is DateTime &&
        DateTime.now().difference(sentAt).inMinutes < 10;
    showChatMessageOptions(
      context,
      message: {...message, 'isDeleted': isDeleted},
      onReply: () => _setReplyingTo(message),
      onEdit: isMe && withinEditWindow
          ? () => _showEditMessageDialog(message)
          : null,
      onDelete: isMe ? () => _deleteMessage(message) : null,
      myReaction: _myReactionOf(message),
      onReact: (emoji) => _reactToMessage(message, emoji),
    );
  }

  /// The emoji the current user already picked on [message], if any.
  String? _myReactionOf(Map<String, dynamic> message) {
    final list = message['reactions'];
    if (list is List) {
      for (final r in list) {
        if (r is Map && r['reacted_by_me'] == true) {
          return r['emoji']?.toString();
        }
      }
    }
    return null;
  }

  /// Optimistic react: paint it immediately, then reconcile with the server
  /// (and roll back if the call fails).
  /// Messages whose reaction is mid-flight. A poll GET issued BEFORE the tap
  /// can land after the server committed it, carrying a pre-reaction snapshot
  /// that wipes the chip — which is exactly the "reaction disappears, comes
  /// back only after reload" report.
  final Set<String> _pendingReactionIds = <String>{};

  Future<void> _reactToMessage(
      Map<String, dynamic> message, String emoji) async {
    final id = message['id']?.toString();
    if (id == null || id.isEmpty) return;
    _pendingReactionIds.add(id);
    final before = message['reactions'];
    final mine = _myReactionOf(message);
    setState(() {
      // Merge, don't replace: wiping the list also wiped the OTHER person's
      // reactions until the server answered.
      final others = [
        if (before is List)
          for (final r in before)
            if (r is Map && r['reacted_by_me'] != true) r,
      ];
      message['reactions'] = [
        ...others,
        if (mine != emoji) {'emoji': emoji, 'count': 1, 'reacted_by_me': true},
      ];
    });
    final updated = await AdsyConnectService.reactToMessage(id, emoji);
    if (!mounted) return;
    setState(() {
      // Re-look the message up by id — a poll refresh during the await can
      // replace the map, leaving `message` an orphan nothing renders.
      final idx =
          _messages.indexWhere((m) => (m['id']?.toString() ?? '') == id);
      if (idx != -1) {
        _messages[idx]['reactions'] = updated ?? before;
      }
    });
    _pendingReactionIds.remove(id);
  }

  Future<void> _showEditMessageDialog(Map<String, dynamic> message) async {
    final rawContent =
        (message['message'] ?? message['content'] ?? '').toString();
    // Editing a shared post edits the WORDS on it, not the envelope — the
    // field used to open full of "ADSYPOST::eyJ…" and saving destroyed the
    // card.
    final sharedShell = SharedPostMessage.tryDecode(rawContent);
    final currentText = sharedShell != null ? sharedShell.text : rawContent;

    final newText =
        await ChatEditMessageSheet.show(context, initialText: currentText);
    if (newText == null || !mounted) return;

    // A share keeps its card; only the words change. A reply keeps its
    // quote the same way: 'message' holds the STRIPPED body (the ↩️ header
    // was parsed off), so storing newText bare would erase the quote from
    // the server copy — rebuild the header from the parsed fields.
    String contentToStore = sharedShell != null
        ? sharedShell.withText(newText).encode()
        : newText;
    final replyToSender = (message['replyToSender'] ?? '').toString();
    final replyPreview = (message['replyPreview'] ?? '').toString();
    if (sharedShell == null && replyToSender.isNotEmpty) {
      final replyToId = (message['replyToId'] ?? '').toString();
      final idPart = replyToId.isNotEmpty ? '($replyToId) ' : '';
      contentToStore =
          '↩️ $idPart$replyToSender: $replyPreview\n\n$newText';
    }

    // Locally 'message' holds the STRIPPED body (the bubble reads the reply
    // fields separately) — only the server copy carries the ↩️ header.
    final localText = sharedShell != null ? contentToStore : newText;

    // Optimistic: paint the edit immediately, revert if the server refuses.
    setState(() {
      final index = _messages.indexWhere(
          (m) => m['id'].toString() == message['id'].toString());
      if (index != -1) {
        _messages[index] = {
          ..._messages[index],
          'message': localText,
          'content': localText,
          'isEdited': true,
        };
        _messages = List.from(_addSmartTimestamps(_messages));
      }
    });

    try {
      await AdsyConnectService.editMessage(
        message['id'].toString(),
        contentToStore,
      );
      if (mounted) AdsyToast.success(context, 'মেসেজ এডিট হয়েছে');
    } catch (e) {
      debugPrint('Error editing message: $e');
      if (!mounted) return;
      setState(() {
        final index = _messages.indexWhere(
            (m) => m['id'].toString() == message['id'].toString());
        if (index != -1) {
          _messages[index] = {
            ..._messages[index],
            'message': rawContent,
            'content': rawContent,
            'isEdited': message['isEdited'] ?? false,
          };
          _messages = List.from(_addSmartTimestamps(_messages));
        }
      });
      AdsyToast.error(context, 'এডিট করা যায়নি');
    }
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
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
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
                          debugPrint('🔵 Deleting message ID: ${message['id']}');
                          await AdsyConnectService.deleteMessage(
                              message['id'].toString());
                          debugPrint('🟢 Message deleted successfully');

                          if (context.mounted) {
                            AdsyToast.success(context, 'Message deleted');
                          }
                        } catch (e) {
                          debugPrint('🔴 Error deleting message: $e');
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
                  crossAxisCount: 5,
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
                      color: const Color(0xFF111827),
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
                    // Record now and send — the camera tile above takes a
                    // photo; this one shoots video, so a moment can go into
                    // the chat without a trip through the gallery.
                    _buildAttachmentOption(
                      icon: Icons.video_camera_back_rounded,
                      label: 'Record',
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.pop(context);
                        _recordVideo();
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
              color: color.withValues(alpha: 0.1),
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
            AdsyToast.error(context, 'Maximum 8 photos allowed');
          }
          return;
        }

        setState(() => _isCompressingImages = true);

        // Compress all images
        List<String> compressed = [];
        final List<XFile> accepted = [];
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
            accepted.add(image);
          } else {
            // Fall back to the raw bytes rather than silently skipping —
            // skipping desynced the two lists (preview strip showed fewer
            // photos, remove-at-index deleted the WRONG photo, and the
            // failed one was never sent while the user believed it was).
            try {
              final raw = await image.readAsBytes();
              compressed.add(base64Encode(raw));
              accepted.add(image);
            } catch (_) {
              if (mounted) {
                AdsyToast.error(context, 'একটি ছবি যোগ করা যায়নি');
              }
            }
          }
        }

        if (!mounted) return;
        setState(() {
          _selectedImages.addAll(accepted);
          _compressedImages.addAll(compressed);
          _isCompressingImages = false;
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      if (!mounted) return;
      setState(() => _isCompressingImages = false);
      AdsyToast.error(context, 'ছবি সিলেক্ট করা যায়নি');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      // Check if limit reached
      if (_selectedImages.length >= 8) {
        if (mounted) {
          AdsyToast.error(context, 'Maximum 8 photos allowed');
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

        final payload = compressedBase64 ??
            // Compression failed — send the raw bytes rather than throwing
            // the photo away after the user already took it.
            base64Encode(await image.readAsBytes());
        if (!mounted) return;
        setState(() {
          _selectedImages.add(image);
          _compressedImages.add(payload);
          _isCompressingImages = false;
        });
      } else {
        if (mounted) setState(() => _isCompressingImages = false);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      if (!mounted) return;
      setState(() => _isCompressingImages = false);
      AdsyToast.error(context, 'ছবি তোলা যায়নি');
    }
  }

  Future<void> _pickVideo() => _addVideo(ImageSource.gallery);

  /// Shoot a clip with the camera and send it, no gallery detour.
  Future<void> _recordVideo() => _addVideo(
        ImageSource.camera,
        maxDuration: const Duration(seconds: VideoUploadHelper.maxSeconds),
      );

  Future<void> _addVideo(ImageSource source, {Duration? maxDuration}) async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: source,
        maxDuration: maxDuration,
      );

      if (video != null && mounted) {
        // 3-minute cap only (over-limit → Google Drive sheet). The re-encode
        // is deferred to the send below so picking stays instant instead of
        // freezing behind a full compression pass.
        final prepared = await VideoUploadHelper.prepareForUpload(
            context, video.path,
            driveHint: true, compress: false);
        if (!mounted) return;
        if (prepared != null) {
          // The compress pass takes tens of seconds. _isSendingMessage alone
          // renders NOTHING (the input strip watches _isUploadingAttachment),
          // so the app looked frozen for the entire encode — the single
          // biggest reason video "doesn't work".
          setState(() {
            _isSendingMessage = true;
            _isUploadingAttachment = true;
          });
          final encoded = await VideoUploadHelper.compressOnly(prepared);
          if (!mounted) return;

          // Size gate AFTER compression. The upload has a hard 180s timeout,
          // which on a typical mobile uplink buys ~20MB — anything larger was
          // guaranteed to fail, and the Retry button failed identically.
          final sizeOk = await VideoUploadHelper.isWithinUploadSize(encoded);
          if (!mounted) return;
          if (!sizeOk) {
            setState(() {
              _isSendingMessage = false;
              _isUploadingAttachment = false;
            });
            await VideoUploadHelper.showTooLargeSheet(context);
            return;
          }

          await _sendMediaMessage(encoded, 'video');
          // _sendMediaMessage clears these on both its paths, but it returns
          // early when the chat became blocked mid-encode.
          if (mounted && _isSendingMessage) {
            setState(() {
              _isSendingMessage = false;
              _isUploadingAttachment = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
          _isUploadingAttachment = false;
        });
        AdsyToast.error(context, 'ভিডিও পাঠানো যায়নি');
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

    // Placeholders raised by THIS batch. If the loop throws part-way, the
    // survivors have to be swept up: they carry `isUploading: true` forever
    // and claim a photo was delivered that never left the device.
    final batchTempIds = <String>[];

    try {
      // Send the COMPRESSED bytes, not the original file. This loop iterated
      // _compressedImages but uploaded _selectedImages[i].path, so multi-MB
      // originals went over the wire and timed out on slow uplinks (the group
      // chat was already fixed for this; 1:1 was not).
      for (int i = 0; i < _compressedImages.length; i++) {
        final b64raw = _compressedImages[i];
        if (b64raw.isNotEmpty) {
          // compressToBase64 returns a "data:image/jpeg;base64,…" URI — the
          // prefix must be stripped before decoding.
          final b64 = b64raw.contains(',')
              ? b64raw.substring(b64raw.indexOf(',') + 1)
              : b64raw;
          final bytes = base64Decode(b64);
          final name =
              'photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

          // Park the compressed bytes in a temp file so the bubble has a real
          // path to paint RIGHT NOW. Without it this path showed nothing at
          // all until the 24s poll happened to notice the message — the
          // server response was being thrown away here.
          String? localPath;
          try {
            final dir = await getTemporaryDirectory();
            final f = File('${dir.path}/$name');
            await f.writeAsBytes(bytes);
            localPath = f.path;
          } catch (_) {
            localPath = null;
          }

          final tempId =
              'local_img_${DateTime.now().microsecondsSinceEpoch}_$i';
          batchTempIds.add(tempId);
          if (localPath != null && mounted) {
            setState(() {
              _messages.add(<String, dynamic>{
                'id': tempId,
                'senderId': AuthService.currentUser?.id ?? '',
                'message': '',
                'timestamp': DateTime.now(),
                'isMe': true,
                'type': 'image',
                'mediaUrl': localPath,
                'fileName': name,
                'isSeen': false,
                'is_read': false,
                'isDeleted': false,
                'isEdited': false,
                'reactions': const [],
                'isUploading': true,
              });
              _messages = List.from(_addSmartTimestamps(_messages));
            });
            _scrollToBottom();
          }

          final sent = await AdsyConnectService.sendMediaMessage(
            chatroomId: widget.chatroomId,
            receiverId: widget.userId,
            messageType: 'image',
            mediaBytes: bytes,
            fileName: name,
          );

          // Reconcile in place — the response used to be dropped entirely.
          if (mounted) {
            setState(() {
              final parsed = _parseSingleMessage(sent);
              if (localPath != null) parsed['localPreviewPath'] = localPath;
              final realId = (parsed['id'] ?? '').toString();
              final tempIdx = _messages.indexWhere((m) => m['id'] == tempId);
              final realIdx = _messages.indexWhere((m) =>
                  (m['id'] ?? '').toString() == realId && realId.isNotEmpty);
              parsed['isUploading'] = false;
              if (realIdx != -1) {
                _messages[realIdx] = {..._messages[realIdx], ...parsed};
                if (tempIdx != -1) _messages.removeAt(tempIdx);
              } else if (tempIdx != -1) {
                _messages[tempIdx] = parsed;
              } else {
                _upsertMessage(parsed);
              }
              _messages = List.from(_addSmartTimestamps(_messages));
            });
          }
        } else {
          await _sendMediaMessage(_selectedImages[i].path, 'image');
        }
        // Small delay between sends to avoid overwhelming the server
        if (i < _compressedImages.length - 1) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      // Remember the count BEFORE clearing — the toast used to read the
      // just-cleared list and always announced "0 photos".
      final sentCount = _compressedImages.length;
      setState(() {
        _selectedImages.clear();
        _compressedImages.clear();
        _isSendingMessage = false;
      });

      if (mounted) {
        AdsyToast.success(context, '$sentCount photos sent successfully');
      }
    } catch (e) {
      setState(() {
        _messages.removeWhere(
            (m) => batchTempIds.contains((m['id'] ?? '').toString()));
        _refreshStatusAnchor(_messages);
        _isSendingMessage = false;
      });
      if (mounted) {
        AdsyToast.error(context, 'ছবি পাঠানো যায়নি');
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
        } else if (result.files.single.bytes != null && mounted) {
          // Handle web/desktop file selection
          AdsyToast.success(
              context, 'File selected. Upload functionality coming soon.');
        }
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
      if (mounted) {
        AdsyToast.error(context, 'ফাইল সিলেক্ট করা যায়নি');
      }
    }
  }

  Future<void> _sendMediaMessage(String filePath, String type,
      {String? fileName}) async {
    if (_isChatBlocked) return;

    // Paint the bubble NOW from the local file. Photos and videos used to
    // appear only after the whole upload finished — on a slow uplink that is
    // many seconds of the thread showing nothing, which reads as "it didn't
    // send". The bubble already renders a non-http path with Image.file, so
    // the local path is all it needs.
    final tempId = 'local_media_${DateTime.now().microsecondsSinceEpoch}';
    final optimistic = <String, dynamic>{
      'id': tempId,
      'senderId': AuthService.currentUser?.id ?? '',
      'message': '',
      'timestamp': DateTime.now(),
      'timeDisplay': null,
      'isMe': true,
      'type': type,
      'mediaUrl': filePath,
      'fileName': fileName,
      'isSeen': false,
      'is_read': false,
      'isDeleted': false,
      'isEdited': false,
      'reactions': const [],
      // Drives the little spinner/opacity while the bytes are in flight.
      'isUploading': true,
    };

    setState(() {
      _isSendingMessage = true;
      _isUploadingAttachment = true;
      _messages.add(optimistic);
      _messages = List.from(_addSmartTimestamps(_messages));
    });
    _scrollToBottom();

    try {
      debugPrint('🔵 Sending $type message: $filePath');

      final sentMessage = await AdsyConnectService.sendMediaMessage(
        chatroomId: widget.chatroomId,
        receiverId: widget.userId,
        messageType: type,
        mediaFilePath: filePath,
        fileName: fileName,
      );

      debugPrint('🟢 Media message sent: ${sentMessage['id']}');

      if (mounted) {
        setState(() {
          // Swap the local placeholder for the server's copy in place, so the
          // bubble never disappears and reappears.
          final parsed = _parseSingleMessage(sentMessage);
          parsed['localPreviewPath'] = filePath;
          final realId = (parsed['id'] ?? '').toString();
          final tempIdx = _messages.indexWhere((m) => m['id'] == tempId);
          final realIdx = _messages.indexWhere(
              (m) => (m['id'] ?? '').toString() == realId && realId.isNotEmpty);
          // The upload is done by definition — the server answered. Say so
          // explicitly so a merge can't inherit the placeholder's spinner.
          parsed['isUploading'] = false;

          if (realIdx != -1) {
            // The socket echo beat the HTTP response here. Merge into the
            // real row and DROP the placeholder — replacing it would leave
            // two bubbles for one photo.
            _messages[realIdx] = {..._messages[realIdx], ...parsed};
            if (tempIdx != -1) _messages.removeAt(tempIdx);
          } else if (tempIdx != -1) {
            // Keep showing the LOCAL file until the network image is cached —
            // swapping straight to the remote URL flashes an empty box.
            _messages[tempIdx] = parsed;
          } else {
            _upsertMessage(parsed);
          }
          _messages = List.from(_addSmartTimestamps(_messages));
          _isSendingMessage = false;
          _isUploadingAttachment = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      // Drop the placeholder — leaving it would claim a failed send succeeded.
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m['id'] == tempId);
          _refreshStatusAnchor(_messages);
        });
      }
      debugPrint('🔴 Error sending media: $e');
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
      case 'clear_chat':
        if (!mounted) return;
        _showClearChatConfirmation();
        break;
      case 'report':
        if (!mounted) return;
        _showReportDialog();
        break;
    }
  }

  void _showClearChatConfirmation() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'মেসেজ ক্লিয়ার করবেন?',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'আপনার দিক থেকে এই চ্যাটের সব মেসেজ মুছে যাবে। অন্যজন তাদের '
                'মেসেজ আগের মতোই দেখতে পাবে — দুজনেই ক্লিয়ার করলে '
                'মেসেজগুলো একেবারে মুছে যাবে।',
                style: TextStyle(
                    fontSize: 13.5, color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('বাতিল'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        _clearConversation();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('ক্লিয়ার করুন'),
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

  Future<void> _clearConversation() async {
    // Animated progress dialog: sweeps to ~90% while the server works (the
    // purge can take a moment on long chats), then completes when it returns.
    final progress = ValueNotifier<double>(0);
    var dialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: false,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          child: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (_, p, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: CircularProgressIndicator(
                          value: p,
                          strokeWidth: 5,
                          backgroundColor: const Color(0xFFEDE9FE),
                          valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF8B5CF6)),
                        ),
                      ),
                      Text(
                        '${(p * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'মেসেজ ক্লিয়ার হচ্ছে...',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => dialogOpen = false);

    // Ease toward 90% while waiting; the final jump to 100% happens on reply.
    final ticker =
        Timer.periodic(const Duration(milliseconds: 120), (t) {
      if (progress.value < 0.9) {
        progress.value =
            (progress.value + (0.9 - progress.value) * 0.08).clamp(0, 0.9);
      }
    });

    final result =
        await AdsyConnectService.clearConversation(widget.chatroomId);
    ticker.cancel();
    progress.value = 1.0;
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted && dialogOpen) Navigator.of(context).pop();

    if (!mounted) return;
    if (result != null) {
      setState(() => _messages.clear());
      // The user explicitly removed this content — the warm-open cache must
      // not resurrect it on the next visit (it did, indefinitely if offline).
      ChatHistoryCache.invalidate('room:${widget.chatroomId}');
      AdsyToast.success(context, 'মেসেজ ক্লিয়ার হয়ে গেছে');
    } else {
      AdsyToast.error(context, 'মেসেজ ক্লিয়ার করা যায়নি');
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
        AdsyToast.warning(context, '${widget.userName} has been blocked');
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
        AdsyToast.success(context, '${widget.userName} has been unblocked');
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
      AdsyToast.warning(context, 'Please login to make calls');
      return;
    }

    // Prevent initiating a second call while one is already active/minimised.
    // The user can return to the ongoing call via the banner at the top.
    if (AgoraCallService.isInCall) {
      AdsyToast.warning(context,
          'You are already in a call. End it before starting a new one.');
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
    // iOS-only text boost: same logical sizes look smaller on iPhones.
    return AdsyIosTextBoost(
        child: Scaffold(
      // Must NOT be transparent: a MaterialPageRoute's underlying background
      // is opaque black, so a transparent Scaffold leaks black behind the
      // status bar / app bar / during transition animations. Use the first
      // gradient color so the screen looks seamless before the body paints.
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: false,
      appBar: _buildAppBar(),
      // Concept design: plain white canvas — the bubbles carry the color.
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            Column(
              children: [
                // Messages List — tapping anywhere on it (or starting a
                // scroll drag) dismisses the keyboard so the history gets
                // the full screen back.
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    child: NotificationListener<ScrollStartNotification>(
                      onNotification: (n) {
                        if (n.dragDetails != null) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        }
                        return false;
                      },
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
                  ),
                ),
                // Animated "other user is typing" bubble, just above the input
                _buildTypingIndicator(),
                // The ad/post this chat was opened about, awaiting the first
                // message it will be quoted on.
                _buildPendingAttachment(),
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
                  // Universal scroll-jump circle (same as back-to-top).
                  child: AdsyScrollCircleButton(
                    onTap: _scrollToBottom,
                    up: false,
                  ),
                ),
              ),
          ],
        ),
      ),
    ));
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
      isMuted: _isMuted,
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
    // Deleted/suspended accounts have no visitable profile.
    if (_counterpartDisabled) {
      AdsyToast.info(context, 'একাউন্ট সাসপেন্ডেড');
      return;
    }
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
              color: const Color(0xFF111827).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const AdsyChatIcon(size: 48),
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

  /// Picture for the quoted message, when it has one — a shared post's
  /// thumbnail, or the photo/video being replied to.
  String? _replyThumbUrl(Map<String, dynamic> message) {
    final type = message['type']?.toString() ?? 'text';
    if (type == 'image' || type == 'video') {
      final url = (message['thumbnailUrl'] ?? message['mediaUrl'] ?? '')
          .toString();
      return url.isEmpty ? null : AppConfig.getAbsoluteUrl(url);
    }
    final shared = SharedPostMessage.tryDecode(
      (message['message'] ?? message['content'] ?? '').toString(),
    );
    final thumb = shared?.thumbUrl.trim() ?? '';
    return thumb.isEmpty ? null : AppConfig.getAbsoluteUrl(thumb);
  }

  String _getReplyPreviewText(Map<String, dynamic> message) {
    final type = message['type']?.toString() ?? 'text';
    switch (type) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'voice':
        return '🎤 Voice message';
      case 'document':
        return '📄 ${message['file_name'] ?? message['fileName'] ?? 'Document'}';
      default:
        var text = (message['message'] ?? message['content'] ?? '').toString();
        // Call-log messages start with a phone glyph; older ones carry the
        // mangled spelling, so check for both before treating this as prose.
        if (text.startsWith(_phoneMarker) ||
            text.startsWith(_phoneMarkerLegacy)) {
          return text;
        }
        // A shared post travels as an encoded envelope. Quoting one used to
        // copy that envelope into the reply header, so the other person read
        // "ADSYPOST::eyJuIjoi…" — describe the post instead.
        final shared = SharedPostMessage.tryDecode(text);
        if (shared != null) text = shared.quoteLine;
        return text.length > 50 ? '${text.substring(0, 50)}...' : text;
    }
  }

  /// Messages sent by builds that carried the cp1252-mangled emoji still
  /// have the broken marker inside them, so both spellings are accepted.
  static const _phoneMarker = '📞';
  static const _phoneMarkerLegacy = 'ðŸ“ž';
  static const _replyMarker = '↩️';
  static const _replyMarkerLegacy = 'â†©ï¸';

  Map<String, String>? _tryParseReplyFromText(String rawText) {
    final text = rawText.trim();
    final marker = text.startsWith(_replyMarker)
        ? _replyMarker
        : (text.startsWith(_replyMarkerLegacy) ? _replyMarkerLegacy : null);
    if (marker == null) return null;

    final parts = text.split('\n\n');
    if (parts.length < 2) return null;

    final header = parts.first.trim();
    String rest = header.replaceFirst(marker, '').trim();

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
    // Every photo and video in this chat, in order, so the viewer can be
    // swiped like a gallery instead of opening one file in isolation.
    final media = <ChatMediaItem>[];
    var initial = 0;
    for (final m in _messages) {
      final type = m['type']?.toString() ?? 'text';
      if (type != 'image' && type != 'video') continue;
      final url = (m['mediaUrl'] ?? '').toString();
      if (url.isEmpty) continue;
      if (url == filePath) initial = media.length;
      media.add(ChatMediaItem(
        url: url,
        isVideo: type == 'video',
        senderName: m['isMe'] == true ? 'আপনি' : widget.userName,
        timeLabel: m['timeDisplay']?.toString(),
      ));
    }
    if (media.isEmpty) {
      media.add(ChatMediaItem(url: filePath, isVideo: false));
    }

    ChatMediaViewer.open(
      context,
      items: media,
      initialIndex: initial,
      onLongPress: (item) =>
          _showImageOptions(item.url, isVideo: item.isVideo),
    );
  }

  void _showImageOptions(String filePath, {bool isVideo = false}) {
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
                  const Icon(Icons.download_rounded, color: Color(0xFF111827)),
              title: Text(isVideo ? 'Save Video' : 'Save Image'),
              onTap: () async {
                Navigator.pop(context);
                await _downloadImage(filePath, isVideo: isVideo);
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
                  useRootNavigator: false,
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
                if (confirm == true && context.mounted) {
                  AdsyToast.info(context, 'Delete functionality coming soon');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Really save the media. This used to be a stub that waited one second and
  /// announced success — the file never left the server.
  Future<void> _downloadImage(String imageUrl, {bool isVideo = false}) async {
    final url = imageUrl.startsWith('http')
        ? imageUrl
        : AppConfig.getAbsoluteUrl(imageUrl);
    if (url.isEmpty) {
      AdsyToast.error(context, 'মিডিয়াটি পাওয়া যায়নি');
      return;
    }
    try {
      AdsyToast.info(
          context, isVideo ? 'ভিডিও সেভ হচ্ছে…' : 'ছবি সেভ হচ্ছে…');

      // App-private cache first (no storage permission needed), then hand the
      // file to the platform — same pattern as the BN media downloader.
      final ext = isVideo ? 'mp4' : 'jpg';
      final fileName =
          'adsyconnect_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final cacheDir = await getTemporaryDirectory();
      final cachePath = '${cacheDir.path}/$fileName';

      final res = await http
          .get(Uri.parse(url), headers: kMediaHeaders)
          .timeout(const Duration(minutes: 2));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) {
        throw Exception('HTTP ${res.statusCode}');
      }
      await File(cachePath).writeAsBytes(res.bodyBytes);
      if (!mounted) return;

      if (Platform.isAndroid) {
        // Into the gallery via MediaStore so it shows in Photos.
        await GallerySaver.saveToGallery(
          sourcePath: cachePath,
          fileName: fileName,
          isVideo: isVideo,
        );
        if (!mounted) return;
        AdsyToast.success(
            context, isVideo ? 'ভিডিও গ্যালারিতে সেভ হয়েছে' : 'ছবি গ্যালারিতে সেভ হয়েছে');
      } else {
        // iOS/others: open with the system handler, which offers Save.
        await DownloadOpenUtils.openFile(context, cachePath);
      }
    } catch (e) {
      debugPrint('chat media save failed: $e');
      if (mounted) {
        AdsyToast.error(
            context, isVideo ? 'ভিডিও সেভ করা যায়নি' : 'ছবি সেভ করা যায়নি');
      }
    }
  }

  Future<void> _downloadDocument(String? filePath, String fileName) async {
    if (filePath == null || filePath.isEmpty) {
      AdsyToast.error(context, 'Document not available');
      return;
    }
    // Open the document through the system handler (browser / viewer), which
    // lets the OS download or preview it. Relative paths are resolved against
    // the media host first.
    final url = AppConfig.getAbsoluteUrl(filePath);
    final opened = await UrlLauncherUtils.launchExternalUrl(url);
    if (!mounted) return;
    if (!opened) {
      AdsyToast.error(context, 'Could not open $fileName');
    }
  }

  /// "Jul 08, 5:31 PM"-style stamp for the tap-to-reveal row.
  String _fullTimeStamp(Map<String, dynamic> message) {
    final t = message['timestamp'];
    if (t is! DateTime) return (message['timeDisplay'] ?? '').toString();
    final local = t.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '${months[local.month - 1]} ${local.day}, '
        '$h:${local.minute.toString().padLeft(2, '0')} $ampm';
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool showAvatar) {
    final messageId = message['id']?.toString() ?? '';
    final isSearchHit = _isSearchMode &&
        _searchQuery.trim().isNotEmpty &&
        messageId.isNotEmpty &&
        _searchMatchedMessageIds.contains(messageId);
    final isCurrentSearchHit =
        isSearchHit && _currentSearchMessageId == messageId;
    // Tap a message to reveal its date+time under it (tap again to hide) —
    // same interaction as group chats. Smart time separators stay as-is.
    final tapped =
        messageId.isNotEmpty && messageId == _tappedTimeMessageId;
    final display = tapped
        ? {
            ...message,
            'showTimestamp': true,
            // Tells the bubble this reveal is fresh — only tap-opened rows
            // play the fade/slide; the always-on smart timestamps would
            // otherwise re-fade every time scrolling rebuilds their row.
            'timeRevealAnimated': true,
            'timeDisplay': _fullTimeStamp(message),
          }
        : message;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // Message rows span the full width (translucent), so THIS handler wins
      // the gesture arena over the outer keyboard-dismiss detector. With the
      // keyboard open, any tap — on a bubble or the space beside it — must
      // dismiss the keyboard first; time-reveal is the next tap's job.
      onTap: () {
        if (MediaQuery.of(context).viewInsets.bottom > 0) {
          FocusManager.instance.primaryFocus?.unfocus();
          return;
        }
        if (messageId.isEmpty) return;
        setState(() => _tappedTimeMessageId =
            _tappedTimeMessageId == messageId ? null : messageId);
      },
      child: ChatMessageBubble(
      key: ValueKey(messageId.isNotEmpty ? messageId : message.hashCode),
      message: display,
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
      onSeekVoice: (id, url, to) async {
        // Scrub only the clip that is actually loaded; tapping the waveform
        // of a different message starts that one instead.
        if (_playingVoiceMessageId == id) {
          await _audioPlayer.seek(to);
        } else {
          await _playVoiceMessage(id, url);
        }
      },
      onViewImage: _viewImage,
      onDownloadDoc: _downloadDocument,
      onScrollToMessage: _scrollToMessageId,
      ),
    );
  }

  /// WhatsApp/Messenger-style typing indicator shown just above the input
  /// bar when the other user is typing. Fades/slides in and out and is
  /// left-aligned to match where received message bubbles start
  /// (list horizontal padding 8 + avatar column 34 = 42).
  Widget _buildTypingIndicator() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1.0,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.35),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
      ),
      child: _isOtherUserTyping
          ? Padding(
              key: const ValueKey('typing_indicator_visible'),
              padding: const EdgeInsets.fromLTRB(42, 2, 8, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _TypingIndicatorBubble(),
                  const SizedBox(width: 7),
                  // Say WHO is typing — the other person's name.
                  Flexible(
                    child: Text(
                      '${widget.userName} টাইপ করছেন…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('typing_indicator_hidden')),
    );
  }

  /// The pending attachment card sitting on top of the composer.
  ///
  /// Deliberately the same shape as the reply preview right below it — the
  /// user already knows that strip means "this is attached to what I type
  /// next", and ✕ removes it the same way.
  Widget _buildPendingAttachment() {
    final attachment = _pendingAttachment;
    // Nothing can be sent while the chat is blocked, so the card would only be
    // a promise the composer can't keep.
    if (attachment == null || _isChatBlocked) return const SizedBox.shrink();

    final thumb = AppConfig.getAbsoluteUrl(attachment.thumbUrl);
    final caption = attachment.caption.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          if (thumb.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                thumb,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                // The CDN serves media only to a recognised client.
                headers: kMediaHeaders,
                errorBuilder: (_, __, ___) => _attachmentThumbFallback(),
              ),
            )
          else
            _attachmentThumbFallback(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.displayName.isEmpty
                      ? 'বিজ্ঞাপন'
                      : attachment.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption.isEmpty ? 'এই বিজ্ঞাপন নিয়ে লিখছেন' : caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'সরিয়ে ফেলুন',
            icon: const Icon(Icons.close_rounded,
                size: 18, color: Color(0xFF6B7280)),
            onPressed: () => setState(() => _pendingAttachment = null),
          ),
        ],
      ),
    );
  }

  Widget _attachmentThumbFallback() => Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.campaign_outlined,
            size: 20, color: Color(0xFF94A3B8)),
      );

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
      replyThumbUrl: _replyingToMessage != null
          ? _replyThumbUrl(_replyingToMessage!)
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

/// Compact grey chat bubble (styled like a received message) containing three
/// dots that pulse in a smooth staggered wave — the classic WhatsApp /
/// Messenger "typing…" animation.
class _TypingIndicatorBubble extends StatefulWidget {
  const _TypingIndicatorBubble();

  @override
  State<_TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<_TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  static const int _dotCount = 3;
  static const double _dotSize = 7;

  late final AnimationController _controller;
  late final List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    // Each dot rides the same 1s loop, offset so the pulse travels
    // left-to-right like a tide.
    _dotAnimations = List.generate(_dotCount, (index) {
      final start = index * 0.15;
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, start + 0.6, curve: Curves.linear),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Maps the interval progress (0→1) to a smooth 0→1→0 pulse.
  double _pulse(double t) {
    final wave = t <= 0.5 ? t * 2 : (1 - t) * 2;
    return Curves.easeInOut.transform(wave.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(5),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_dotCount, (index) {
              final pulse = _pulse(_dotAnimations[index].value);
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: index == 1 ? 3 : 0,
                ),
                child: Transform.scale(
                  scale: 0.7 + 0.3 * pulse,
                  child: Container(
                    width: _dotSize,
                    height: _dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF64748B)
                          .withValues(alpha: 0.35 + 0.55 * pulse),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
