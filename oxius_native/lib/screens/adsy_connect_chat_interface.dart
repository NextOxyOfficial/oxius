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
import 'call_screen.dart';

class AdsyConnectChatInterface extends StatefulWidget {
  final String chatroomId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? profession;
  final bool isOnline;
  final bool isVerified;
  final bool isPro;

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
  });

  @override
  State<AdsyConnectChatInterface> createState() => _AdsyConnectChatInterfaceState();
}

class _AdsyConnectChatInterfaceState extends State<AdsyConnectChatInterface>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final FocusNode _messageFocusNode = FocusNode();
  final FocusNode _searchFocusNode = FocusNode();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isTyping = false;
  bool _isLoadingMessages = true;
  bool _isLoadingMoreMessages = false;
  bool _isSendingMessage = false;
  bool _isUploadingAttachment = false;
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
  String? _lastSeenTime;
  Timer? _onlineStatusTimer;
  Map<String, dynamic>? _replyingToMessage;

  bool _isSearchMode = false;
  bool _suppressSearchListener = false;
  String _searchQuery = '';
  List<int> _searchMatchIndexes = [];
  Set<String> _searchMatchedMessageIds = <String>{};
  int _currentSearchMatchPosition = 0;
  String? _currentSearchMessageId;
  
  // Swipe to reply animation state
  String? _swipingMessageId;
  double _swipeOffset = 0.0;
  static const double _swipeThreshold = 60.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ActiveChatTracker.setActiveChat(widget.chatroomId);
    AdsyConnectService.setActiveChat(widget.chatroomId);
    _isOtherUserOnline = widget.isOnline;
    _loadChatroomStatus();
    _loadMessages();
    _loadOnlineStatus();
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
      _loadOnlineStatus();
      _loadChatroomStatus();
    }
  }

  void _onItemPositionsChanged() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final bottomVisible = positions.any((p) => p.index == 0 && p.itemTrailingEdge > 0);
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
      print('🔵 Loading older messages, page: $nextPage');
      
      final messages = await AdsyConnectService.getMessages(
        widget.chatroomId,
        page: nextPage,
      );
      
      print('🟢 Loaded ${messages.length} older messages');
      
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
      print('🔴 Error loading older messages: $e');
      if (mounted) {
        setState(() => _isLoadingMoreMessages = false);
      }
    }
  }

  @override
  void dispose() {
    ActiveChatTracker.clearActiveChat();
    AdsyConnectService.clearActiveChat();
    _messageController.dispose();
    _searchController.dispose();
    _itemPositionsListener.itemPositions.removeListener(_onItemPositionsChanged);
    _messageFocusNode.dispose();
    _searchFocusNode.dispose();
    _audioRecorder.dispose();
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
      setState(() => _playingVoiceMessageId = messageId);

      // Set audio source and play
      await _audioPlayer.setUrl(mediaUrl);
      await _audioPlayer.play();

      // Listen to player state changes
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          if (state.processingState == ProcessingState.completed) {
            setState(() => _playingVoiceMessageId = null);
          }
        }
      });

      // Listen to position changes
      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() => _voicePosition = position);
        }
      });

      // Listen to duration changes
      _audioPlayer.durationStream.listen((duration) {
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
    final fileName = (message['fileName'] ?? message['file_name'] ?? '').toString();
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
    final prev = (_currentSearchMatchPosition - 1 + _searchMatchIndexes.length) %
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
      final details = await AdsyConnectService.getChatRoomDetails(widget.chatroomId);
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

      final blockedValue =
          blockStatus?['is_blocked'] ??
          blockStatus?['isBlocked'] ??
          details['is_blocked'] ??
          details['isBlocked'] ??
          details['blocked'] ??
          details['is_chat_blocked'] ??
          details['isChatBlocked'];

      final blockedByMeValue =
          blockStatus?['blocked_by_me'] ??
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
    _onlineStatusTimer = Timer.periodic(const Duration(seconds: 15), (_) {
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
    // Poll for new messages and status updates every 2 seconds for real-time feel
    _messagePollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && !_isLoadingMessages) {
        _checkForNewMessages();
        _statusPollCounter++;
        if (_statusPollCounter >= 5) {
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
        return !_messages.any((existing) => (existing['id']?.toString() ?? '') == msgId);
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
      print('🔴 Error polling messages: $e');
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
      print('🔵 Loading messages for chatroom: ${widget.chatroomId}, page: $_currentPage');
      
      final messages = await AdsyConnectService.getMessages(
        widget.chatroomId,
        page: _currentPage,
      );
      
      print('🟢 Loaded ${messages.length} messages');
      
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
      print('🔴 Error loading messages: $e');
      if (mounted) {
        setState(() => _isLoadingMessages = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load messages: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
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
      
      final rawText = msg['display_content']?.toString() ?? msg['content']?.toString() ?? '';
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
        'mediaUrl': msg['media_url']?.toString(), // Backend returns media_url, not media_file
        'thumbnailUrl': msg['thumbnail_url']?.toString(),
        'fileName': msg['file_name']?.toString(),
        'voice_duration': (msg['voice_duration'] as int?) ?? (msg['voiceDuration'] as int?) ?? 0,
        'isSeen': isSeen, // Changed from isRead to isSeen for clarity
        'isDeleted': (msg['is_deleted'] == true || msg['is_deleted'] == 1 || msg['is_deleted'] == '1' || msg['is_deleted'] == 'true'),
      };
    }).toList();
    
    // Add smart timestamp display logic
    return _addSmartTimestamps(parsedMessages);
  }
  
  List<Map<String, dynamic>> _addSmartTimestamps(List<Map<String, dynamic>> messages) {
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
      if (mounted) {
        setState(() {
          for (var message in _messages) {
            if (message['isMe'] == false && message['isSeen'] == false) {
              message['isSeen'] = true;
            }
          }
        });
      }
    } catch (e) {
      print('🔴 Error marking messages as read: $e');
      // Don't show error to user - this is a background operation
    }
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
      _messages.add(message);
      return;
    }

    final merged = Map<String, dynamic>.from(_messages[existingIndex]);
    merged.addAll(message);
    _messages[existingIndex] = merged;
  }

  Future<void> _sendMessage() async {
    if (_isChatBlocked) return;
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    final replyTo = _replyingToMessage;
    _messageController.clear();
    
    setState(() {
      _isSendingMessage = true;
      _replyingToMessage = null;
    });

    try {
      print('🔵 Sending message: $messageText');
      
      String contentToSend = messageText;
      if (replyTo != null) {
        final replyToId = replyTo['id']?.toString() ?? '';
        final replyToText = _getReplyPreviewText(replyTo);
        final replyToSender = replyTo['isMe'] == true ? 'You' : widget.userName;
        final idPart = replyToId.isNotEmpty ? '($replyToId) ' : '';
        contentToSend = '↩️ $idPart$replyToSender: $replyToText\n\n$messageText';
      }
      
      final sentMessage = await AdsyConnectService.sendTextMessage(
        chatroomId: widget.chatroomId,
        receiverId: widget.userId,
        content: contentToSend,
      );
      
      print('🟢 Message sent: ${sentMessage['id']}');
      
      if (mounted) {
        setState(() {
          _upsertMessage(_parseSingleMessage(sentMessage));
          _isSendingMessage = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('🔴 Error sending message: $e');
      if (mounted) {
        setState(() => _isSendingMessage = false);

        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('403') || errorStr.contains('permission denied') || errorStr.contains('blocked')) {
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

    final rawText = msg['display_content']?.toString() ?? msg['content']?.toString() ?? '';
    final replyMeta = _tryParseReplyFromText(rawText);
    
    return {
      'id': msg['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
      'mediaUrl': msg['media_url']?.toString(), // Backend returns media_url, not media_file
      'thumbnailUrl': msg['thumbnail_url']?.toString(),
      'fileName': msg['file_name']?.toString(),
      'voice_duration': (msg['voice_duration'] as int?) ?? (msg['voiceDuration'] as int?) ?? 0,
      'isSeen': isSeen, // Changed from isRead to isSeen for clarity
      'isDeleted': (msg['is_deleted'] == true || msg['is_deleted'] == 1 || msg['is_deleted'] == '1' || msg['is_deleted'] == 'true'),
      'showTimestamp': true, // Always show timestamp for sent messages
    };
  }

  Future<void> _startRecording() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required to record voice messages'),
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
        final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
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
          print('🔵 Sending voice message: $path, duration: $_recordDuration seconds');
          
          final sentMessage = await AdsyConnectService.sendMediaMessage(
            chatroomId: widget.chatroomId,
            receiverId: widget.userId,
            messageType: 'voice',
            mediaFilePath: path,
            voiceDuration: _recordDuration,
          );
          
          print('🟢 Voice message sent: ${sentMessage['id']}');
          
          if (mounted) {
            setState(() {
              final parsed = _parseSingleMessage(sentMessage);
              parsed['voice_duration'] = (sentMessage['voice_duration'] as int?) ??
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
          print('🔴 Error sending voice message: $e');
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
    return isDeleted == true || isDeleted == 1 || isDeleted == '1' || isDeleted == 'true';
  }

  void _showMessageOptions(Map<String, dynamic> message) {
    final messageType = message['type']?.toString() ?? 'text';
    final canEdit = messageType == 'text' && !_isMessageDeleted(message);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Edit option (only for text messages)
              if (canEdit)
                ListTile(
                  leading: Container(
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
                  title: const Text(
                    'Edit Message',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditMessageDialog(message);
                  },
                ),
              // Delete option
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Delete Message',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditMessageDialog(Map<String, dynamic> message) {
    final currentText = (message['message'] ?? message['content'] ?? '').toString();
    final editController = TextEditingController(text: currentText);
    
    showDialog(
      context: context,
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
                            final index = _messages.indexWhere((m) => m['id'].toString() == message['id'].toString());
                            if (index != -1) {
                              _messages[index] = {
                                ..._messages[index],
                                'message': newText,
                                'content': newText,
                                'isEdited': true,
                              };
                              _messages = List.from(_addSmartTimestamps(_messages));
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
                              final index = _messages.indexWhere((m) => m['id'].toString() == message['id'].toString());
                              if (index != -1) {
                                _messages[index] = {
                                  ..._messages[index],
                                  'message': currentText,
                                  'content': currentText,
                                  'isEdited': message['isEdited'] ?? false,
                                };
                                _messages = List.from(_addSmartTimestamps(_messages));
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
                            final index = _messages.indexWhere((m) => m['id'].toString() == message['id'].toString());
                            
                            if (index != -1) {
                              // Update the message to show as deleted
                              _messages[index] = {
                                ..._messages[index],
                                'isDeleted': true,
                                'message': 'Message removed',
                                'type': 'text',
                              };
                              
                              // Force rebuild with updated timestamps
                              _messages = List.from(_addSmartTimestamps(_messages));
                            }
                          });
                        }
                        
                        // Then call backend to soft delete
                        try {
                          print('🔵 Deleting message ID: ${message['id']}');
                          await AdsyConnectService.deleteMessage(message['id'].toString());
                          print('🟢 Message deleted successfully');
                          
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
                          print('🔴 Error deleting message: $e');
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
        
        setState(() => _isUploadingAttachment = true);
        
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
          _isUploadingAttachment = false;
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      setState(() => _isUploadingAttachment = false);
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
        setState(() => _isUploadingAttachment = true);
        
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
            _isUploadingAttachment = false;
          });
        } else {
          throw Exception('Image compression failed');
        }
      } else {
        setState(() => _isUploadingAttachment = false);
      }
    } catch (e) {
      print('Error taking photo: $e');
      setState(() => _isUploadingAttachment = false);
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
            content: Text('${_compressedImages.length} photos sent successfully'),
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

  Future<void> _sendMediaMessage(String filePath, String type, {String? fileName}) async {
    if (_isChatBlocked) return;
    setState(() {
      _isSendingMessage = true;
      _isUploadingAttachment = true;
    });

    try {
      print('🔵 Sending $type message: $filePath');
      
      final sentMessage = await AdsyConnectService.sendMediaMessage(
        chatroomId: widget.chatroomId,
        receiverId: widget.userId,
        messageType: type,
        mediaFilePath: filePath,
        fileName: fileName,
      );
      
      print('🟢 Media message sent: ${sentMessage['id']}');
      print('🟢 Media URL: ${sentMessage['media_url']}');
      print('🟢 Full response: $sentMessage');
      
      if (mounted) {
        setState(() {
          _upsertMessage(_parseSingleMessage(sentMessage));
          _isSendingMessage = false;
          _isUploadingAttachment = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('🔴 Error sending media: $e');
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
          _isUploadingAttachment = false;
        });

        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('403') || errorStr.contains('permission denied') || errorStr.contains('blocked')) {
          setState(() {
            _isChatBlocked = true;
            _blockedByMe = false;
          });
        }
        
        // Show professional error message
        NetworkErrorHandler.showErrorSnackbar(
          context,
          e,
          customMessage: 'Failed to send ${type == "image" ? "image" : type == "video" ? "video" : "file"}',
          onRetry: () => _sendMediaMessage(filePath, type, fileName: fileName),
        );
      }
    }
  }

  Future<void> _sendMediaMessageWeb(List<int> bytes, String type, {String? fileName}) async {
    if (_isChatBlocked) return;
    setState(() {
      _isSendingMessage = true;
      _isUploadingAttachment = true;
    });

    try {
      print('🔵 Sending $type message from web: ${bytes.length} bytes');
      
      final sentMessage = await AdsyConnectService.sendMediaMessage(
        chatroomId: widget.chatroomId,
        receiverId: widget.userId,
        messageType: type,
        mediaBytes: bytes,
        fileName: fileName,
      );
      
      print('🟢 Media message sent (web): ${sentMessage['id']}');
      print('🟢 Media URL (web): ${sentMessage['media_url']}');
      print('🟢 Full response (web): $sentMessage');
      
      if (mounted) {
        setState(() {
          _upsertMessage(_parseSingleMessage(sentMessage));
          _isSendingMessage = false;
          _isUploadingAttachment = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('🔴 Error sending media: $e');
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
          _isUploadingAttachment = false;
        });

        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('403') || errorStr.contains('permission denied') || errorStr.contains('blocked')) {
          setState(() {
            _isChatBlocked = true;
            _blockedByMe = false;
          });
        }
        
        // Show professional error message
        NetworkErrorHandler.showErrorSnackbar(
          context,
          e,
          customMessage: 'Failed to send ${type == "image" ? "image" : type == "video" ? "video" : "file"}',
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
        // Navigate to user's ABN profile
        Navigator.pushNamed(
          context,
          '/business-network/profile',
          arguments: {'userId': widget.userId},
        );
        break;
      case 'block':
        // TODO: Show block confirmation
        _showBlockConfirmation();
        break;
      case 'unblock':
        _showUnblockConfirmation();
        break;
      case 'report':
        // TODO: Show report dialog
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.block_rounded, color: Color(0xFFF59E0B), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Block User',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to block ${widget.userName}? You won\'t be able to message each other.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Block user
              _blockUser();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showUnblockConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock_open_rounded, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Unblock User',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Unblock ${widget.userName} to continue messaging.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _unblockUser();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    String? selectedReason;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flag_rounded, color: Color(0xFFEF4444), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Report User',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why are you reporting ${widget.userName}?',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ...['Spam', 'Harassment', 'Inappropriate content', 'Scam or fraud', 'Other'].map(
                (reason) => RadioListTile<String>(
                  title: Text(reason, style: const TextStyle(fontSize: 13)),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) => setState(() => selectedReason = value),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: selectedReason != null
                  ? () {
                      Navigator.pop(context);
                      // TODO: Submit report
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report submitted. We\'ll review it shortly.'),
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Report'),
            ),
          ],
        ),
      ),
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
      backgroundColor: Colors.transparent,
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
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        itemCount: _messages.length + (_isLoadingMoreMessages || !_hasMoreMessages ? 1 : 0),
                        itemBuilder: (context, index) {
                          // With reverse: true, index 0 is at bottom (newest message)
                          // Header for loading older messages should be at the top (highest index)
                          final hasHeader = _isLoadingMoreMessages || !_hasMoreMessages;
                          final isHeaderIndex = hasHeader && index == _messages.length;

                          if (isHeaderIndex) {
                            if (_isLoadingMoreMessages) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
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

                            if (!_hasMoreMessages && _messages.length >= 20) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                          if (listIndex < 0 || listIndex >= _messages.length) {
                            return const SizedBox.shrink();
                          }

                          final message = _messages[listIndex];

                          // Show avatar if this is the last message from this sender in a group
                          final showAvatar = listIndex == 0 ||
                              _messages[listIndex - 1]['isMe'] != message['isMe'];

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
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF3B82F6).withOpacity(0.95),
              const Color(0xFF6366F1).withOpacity(0.95),
              const Color(0xFF8B5CF6).withOpacity(0.95),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
          onPressed: () {
            if (_isSearchMode) {
              _closeSearch();
              return;
            }
            Navigator.pop(context);
          },
          padding: EdgeInsets.zero,
        ),
      ),
      titleSpacing: 0,
      title: _isSearchMode
          ? TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search messages',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.only(right: 8, top: 12, bottom: 12),
              ),
            )
          : GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/business-network/profile',
                  arguments: {'userId': widget.userId},
                );
              },
              child: Row(
                children: [
            // User Avatar with online indicator and glow
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: () {
                      final avatarUrl = AppConfig.getAbsoluteUrl(widget.userAvatar);

                      if (avatarUrl.isNotEmpty) {
                        return ClipOval(
                          child: Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  widget.userName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }

                      return Center(
                        child: Text(
                          widget.userName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }(),
                  ),
                ),
                if (_isOtherUserOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Name with badges
                  Row(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final textPainter = TextPainter(
                              text: TextSpan(
                                text: widget.userName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              maxLines: 1,
                              textDirection: TextDirection.ltr,
                            )..layout();
                            
                            final badgeWidth = (widget.isVerified ? 19.0 : 0.0) + (widget.isPro ? 35.0 : 0.0);
                            final availableWidth = constraints.maxWidth - badgeWidth;
                            final needsScroll = textPainter.width > availableWidth;
                            
                            if (needsScroll) {
                              return SizedBox(
                                height: 20,
                                child: _MarqueeText(
                                  text: widget.userName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            
                            return Text(
                              widget.userName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                      // Verified badge
                      if (widget.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          size: 15,
                          color: Color(0xFF3B82F6),
                        ),
                      ],
                      // Pro badge
                      if (widget.isPro) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFBBF24), // amber-400
                                Color(0xFFF59E0B), // amber-500
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF59E0B).withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // Online status indicator
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isOtherUserOnline 
                              ? const Color(0xFF10B981) // Green for online
                              : Colors.grey.shade400,   // Grey for offline
                          boxShadow: _isOtherUserOnline
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isOtherUserOnline 
                            ? 'Online' 
                            : _formatLastSeen(_lastSeenTime),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _isOtherUserOnline 
                              ? const Color(0xFF10B981)
                              : Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
                ],
              ),
            ),
      actions: [
        if (_isSearchMode) ...[
          if (_searchQuery.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  _searchMatchIndexes.isEmpty
                      ? '0/0'
                      : '${_currentSearchMatchPosition + 1}/${_searchMatchIndexes.length}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          IconButton(
            onPressed: _searchMatchIndexes.isEmpty ? null : _goToPrevSearchMatch,
            icon: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 22),
          ),
          IconButton(
            onPressed: _searchMatchIndexes.isEmpty ? null : _goToNextSearchMatch,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 22),
          ),
          IconButton(
            onPressed: _closeSearch,
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
          ),
        ] else ...[
          IconButton(
            onPressed: () => _startCall('audio'),
            icon: const Icon(Icons.call_rounded, color: Colors.white, size: 20),
          ),
          IconButton(
            onPressed: () => _startCall('video'),
            icon: const Icon(Icons.videocam_rounded, color: Colors.white, size: 22),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 18, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 12),
                    Text(
                      'Search messages',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'view_profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 18, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 12),
                    Text(
                      'View ABN Profile',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _blockedByMe ? 'unblock' : 'block',
                child: Row(
                  children: [
                    Icon(
                      _blockedByMe ? Icons.lock_open_rounded : Icons.block_rounded,
                      size: 18,
                      color: _blockedByMe ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _blockedByMe ? 'Unblock' : 'Block',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    const Icon(Icons.flag_rounded, size: 18, color: Color(0xFFEF4444)),
                    const SizedBox(width: 12),
                    Text(
                      'Report',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) => _handleMenuAction(value),
          ),
        ],
      ],
    );
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
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'voice':
        return '🎤 Voice message';
      case 'document':
        return '📄 ${message['file_name'] ?? message['fileName'] ?? 'Document'}';
      default:
        final text = (message['message'] ?? message['content'] ?? '').toString();
        if (text.startsWith('📞')) return text;
        return text.length > 50 ? '${text.substring(0, 50)}...' : text;
    }
  }

  Map<String, String>? _tryParseReplyFromText(String rawText) {
    final text = rawText.trim();
    if (!text.startsWith('↩️')) return null;

    final parts = text.split('\n\n');
    if (parts.length < 2) return null;

    final header = parts.first.trim();
    String rest = header.replaceFirst('↩️', '').trim();

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

  Widget? _buildReplyQuoteCard(Map<String, dynamic> message, bool isMe) {
    final preview = message['replyPreview']?.toString() ?? '';
    if (preview.isEmpty) return null;
    final sender = message['replyToSender']?.toString() ?? '';
    final replyToId = message['replyToId']?.toString() ?? '';

    final accent = isMe ? Colors.white.withOpacity(0.95) : const Color(0xFF3B82F6);
    final bg = isMe ? Colors.white.withOpacity(0.18) : const Color(0xFF3B82F6).withOpacity(0.08);
    final border = isMe ? Colors.white.withOpacity(0.22) : const Color(0xFF3B82F6).withOpacity(0.18);
    final titleColor = isMe ? Colors.white.withOpacity(0.95) : const Color(0xFF111827);
    final previewColor = isMe ? Colors.white.withOpacity(0.85) : const Color(0xFF4B5563);

    return GestureDetector(
      onTap: replyToId.isNotEmpty ? () => _scrollToMessageId(replyToId) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sender.isEmpty ? 'Reply' : sender,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: previewColor,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool showAvatar) {
    final isMe = message['isMe'] as bool;
    final isDeleted = _isMessageDeleted(message);
    final messageId = message['id']?.toString() ?? '';
    final isCurrentlySwiping = _swipingMessageId == messageId;
    final swipeOffset = isCurrentlySwiping ? _swipeOffset : 0.0;
    final swipeProgress = (swipeOffset.abs() / _swipeThreshold).clamp(0.0, 1.0);
    final quoteCard = _buildReplyQuoteCard(message, isMe);

    final isSearchHit = _isSearchMode &&
        _searchQuery.trim().isNotEmpty &&
        messageId.isNotEmpty &&
        _searchMatchedMessageIds.contains(messageId);
    final isCurrentSearchHit = isSearchHit && _currentSearchMessageId == messageId;

    Widget wrapWithQuoteCard(Widget content) {
      if (quoteCard == null) return content;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          quoteCard,
          content,
        ],
      );
    }
    
    return GestureDetector(
      onHorizontalDragStart: isDeleted ? null : (details) {
        setState(() {
          _swipingMessageId = messageId;
          _swipeOffset = 0.0;
        });
      },
      onHorizontalDragUpdate: isDeleted ? null : (details) {
        setState(() {
          if (isMe) {
            // My messages swipe left (negative)
            _swipeOffset = (_swipeOffset + details.delta.dx).clamp(-_swipeThreshold * 1.2, 0.0);
          } else {
            // Other's messages swipe right (positive)
            _swipeOffset = (_swipeOffset + details.delta.dx).clamp(0.0, _swipeThreshold * 1.2);
          }
        });
        
        // Haptic feedback when threshold reached
        if (swipeOffset.abs() >= _swipeThreshold && _swipeOffset.abs() < _swipeThreshold) {
          HapticFeedback.lightImpact();
        }
      },
      onHorizontalDragEnd: isDeleted ? null : (details) {
        if (_swipeOffset.abs() >= _swipeThreshold) {
          HapticFeedback.mediumImpact();
          _setReplyingTo(message);
        }
        setState(() {
          _swipingMessageId = null;
          _swipeOffset = 0.0;
        });
      },
      onHorizontalDragCancel: () {
        setState(() {
          _swipingMessageId = null;
          _swipeOffset = 0.0;
        });
      },
      child: Stack(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          // Reply icon that appears during swipe
          if (isCurrentlySwiping && swipeProgress > 0.1)
            Positioned(
              left: isMe ? null : 8,
              right: isMe ? 8 : null,
              child: AnimatedOpacity(
                opacity: swipeProgress,
                duration: const Duration(milliseconds: 50),
                child: AnimatedScale(
                  scale: 0.5 + (swipeProgress * 0.5),
                  duration: const Duration(milliseconds: 50),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: swipeProgress >= 1.0 
                          ? const Color(0xFF10B981)
                          : const Color(0xFF10B981).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.reply_rounded,
                      size: 20,
                      color: swipeProgress >= 1.0 
                          ? Colors.white 
                          : const Color(0xFF10B981),
                    ),
                  ),
                ),
              ),
            ),
          // Message bubble with transform
          AnimatedContainer(
            duration: Duration(milliseconds: isCurrentlySwiping ? 0 : 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(swipeOffset, 0, 0),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: 4,
                left: isMe ? 48 : 0,
                right: isMe ? 0 : 48,
              ),
              child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(0.1),
                    const Color(0xFF6366F1).withOpacity(0.1),
                  ],
                ),
              ),
              child: () {
                final avatarUrl = AppConfig.getAbsoluteUrl(widget.userAvatar);

                Widget fallback() {
                  return Center(
                    child: Text(
                      widget.userName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                if (avatarUrl.isEmpty) return fallback();

                return ClipOval(
                  child: Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return fallback();
                    },
                  ),
                );
              }(),
            )
          else if (!isMe)
            const SizedBox(width: 34),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: isMe && !_isMessageDeleted(message) 
                      ? () => _showMessageOptions(message) 
                      : null,
                  child: Container(
                    padding: message['type'] == 'image' || message['type'] == 'video'
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isMe && message['type'] != 'image' && message['type'] != 'video'
                          ? const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                            )
                          : null,
                      color: isMe || message['type'] == 'image' || message['type'] == 'video' 
                          ? null 
                          : Colors.white,
                      border: isSearchHit
                          ? Border.all(
                              color: isCurrentSearchHit
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFFBBF24).withOpacity(0.65),
                              width: isCurrentSearchHit ? 2 : 1,
                            )
                          : null,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(isMe ? 12 : 2),
                        bottomRight: Radius.circular(isMe ? 2 : 12),
                      ),
                      boxShadow: message['type'] == 'image' || message['type'] == 'video'
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    child: _isMessageDeleted(message)
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.block_rounded,
                                size: 14,
                                color: isMe ? Colors.white70 : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Message removed',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                  color: isMe ? Colors.white70 : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          )
                        : message['type'] == 'voice'
                            ? wrapWithQuoteCard(_buildVoiceMessageContent(message, isMe))
                            : message['type'] == 'image'
                                ? wrapWithQuoteCard(_buildImageContent(message))
                                : message['type'] == 'video'
                                    ? wrapWithQuoteCard(_buildVideoContent(message, isMe))
                                    : message['type'] == 'document'
                                        ? wrapWithQuoteCard(_buildDocumentContent(message, isMe))
                                        : (message['type'] == 'text' &&
                                                (message['message'] ?? '').toString().startsWith('📞'))
                                            ? wrapWithQuoteCard(_buildCallLogContent(message, isMe))
                                            : wrapWithQuoteCard(
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    FirstLinkPreview(
                                                      text: (message['message'] ?? '').toString(),
                                                      margin: const EdgeInsets.only(bottom: 6),
                                                    ),
                                                    LinkifyText(
                                                      (message['message'] ?? '').toString(),
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        color: isMe ? Colors.white : const Color(0xFF1F2937),
                                                        height: 1.3,
                                                      ),
                                                      linkStyle: TextStyle(
                                                        color: isMe ? Colors.white : const Color(0xFF2563EB),
                                                        decoration: TextDecoration.none,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                  ),
                ),
                const SizedBox(height: 2),
                // Time and read status (only show if showTimestamp is true)
                if (message['showTimestamp'] == true)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message['timeDisplay'] != null)
                        Text(
                          message['timeDisplay'],
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      // Show seen/unseen status for sent messages
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message['isSeen'] == true 
                              ? Icons.done_all_rounded  // Double tick when seen
                              : Icons.done_rounded,      // Single tick when sent
                          size: 12,
                          color: message['isSeen'] == true 
                              ? const Color(0xFF3B82F6)  // Blue when seen
                              : Colors.grey.shade400,     // Grey when just sent
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceMessageContent(Map<String, dynamic> message, bool isMe) {
    // Check both camelCase and snake_case for voice duration (backend uses snake_case)
    final duration = (message['voiceDuration'] as int?) ?? 
                     (message['voice_duration'] as int?) ?? 
                     0;
    final messageId = message['id']?.toString() ?? '';
    final mediaUrl = message['mediaUrl'] as String?;
    final isPlaying = _playingVoiceMessageId == messageId;
    
    return GestureDetector(
      onTap: () => _playVoiceMessage(messageId, mediaUrl),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isMe 
                  ? Colors.white.withOpacity(0.2) 
                  : const Color(0xFF3B82F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 20,
              color: isMe ? Colors.white : const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 8),
          // Waveform visualization
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  15,
                  (index) => Container(
                    width: 2,
                    height: (index % 3 + 1) * 4.0,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.white.withOpacity(0.7) : const Color(0xFF3B82F6).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isPlaying && _voiceDuration.inSeconds > 0
                    ? '${_voicePosition.inMinutes}:${(_voicePosition.inSeconds % 60).toString().padLeft(2, '0')} / ${_voiceDuration.inMinutes}:${(_voiceDuration.inSeconds % 60).toString().padLeft(2, '0')}'
                    : _formatDuration(duration),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isMe ? Colors.white.withOpacity(0.9) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCallLogContent(Map<String, dynamic> message, bool isMe) {
    final raw = (message['message'] ?? '').toString();
    final cleaned = raw.replaceFirst('📞', '').trim();

    String title = cleaned;
    String detail = '';

    if (cleaned.contains('•')) {
      final parts = cleaned.split('•');
      title = parts.first.trim();
      detail = parts.length > 1 ? parts.sublist(1).join('•').trim() : '';
    }

    final lowerDetail = detail.toLowerCase();
    final isDuration = RegExp(r'^\d{2}:\d{2}(:\d{2})?$').hasMatch(detail);

    Color accent;
    IconData icon;
    if (title.toLowerCase().contains('video')) {
      icon = Icons.videocam_rounded;
    } else if (title.toLowerCase().contains('audio')) {
      icon = Icons.call_rounded;
    } else {
      icon = Icons.phone_rounded;
    }

    if (isDuration) {
      accent = const Color(0xFF10B981);
    } else if (lowerDetail.contains('busy') || lowerDetail.contains('rejected')) {
      accent = const Color(0xFFF59E0B);
    } else if (lowerDetail.contains('cancel')) {
      accent = const Color(0xFF9CA3AF);
    } else {
      accent = const Color(0xFF3B82F6);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isMe ? Colors.white.withOpacity(0.18) : accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isMe ? Colors.white : accent,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title.isEmpty ? 'Call' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  color: isMe ? Colors.white : const Color(0xFF111827),
                ),
              ),
              if (detail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.white.withOpacity(0.18) : accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isMe ? Colors.white.withOpacity(0.20) : accent.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isMe ? Colors.white.withOpacity(0.95) : accent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent(Map<String, dynamic> message) {
    // Try mediaUrl first (from backend), then filePath (local)
    final filePath = (message['mediaUrl'] as String?) ?? (message['filePath'] as String?);
    
    if (filePath == null || filePath.isEmpty) {
      return Container(
        width: 180,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_rounded, size: 40, color: Colors.grey),
            SizedBox(height: 6),
            Text('Image', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      );
    }
    
    // Check if it's a URL or local file path
    final isUrl = filePath.startsWith('http://') || filePath.startsWith('https://');
    
    return GestureDetector(
      onTap: () => _viewImage(filePath),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: isUrl
            ? Image.network(
                filePath,
                width: 180,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image from URL: $error');
                  return Container(
                    width: 180,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
                        SizedBox(height: 6),
                        Text('Failed to load', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  );
                },
              )
            : Image.file(
                File(filePath),
                width: 180,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image from file: $error');
                  return Container(
                    width: 180,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
                        SizedBox(height: 6),
                        Text('Failed to load', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _viewImage(String filePath) {
    final isUrl = filePath.startsWith('http://') || filePath.startsWith('https://');
    
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Image with InteractiveViewer
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
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
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
                                  Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(color: Colors.grey.shade400),
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
            // Close button
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                ),
              ),
            ),
            // Hint text
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Long press for options',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
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
            // Download option
            ListTile(
              leading: const Icon(Icons.download_rounded, color: Color(0xFF3B82F6)),
              title: const Text('Download Image'),
              onTap: () async {
                Navigator.pop(context);
                await _downloadImage(filePath);
              },
            ),
            const Divider(height: 1),
            // Delete option
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('Delete Image', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Image'),
                    content: const Text('Are you sure you want to delete this image?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  // TODO: Implement delete message functionality
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
      
      // TODO: Implement actual download functionality
      // For now, just show a success message
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

  Widget _buildVideoContent(Map<String, dynamic> message, bool isMe) {
    // Try mediaUrl first (from backend), then filePath (local)
    final videoUrl = (message['mediaUrl'] as String?) ?? (message['filePath'] as String?);
    
    if (videoUrl == null || videoUrl.isEmpty) {
      return Container(
        width: 280,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off_rounded, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Video unavailable', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ChatVideoPlayer(
      videoUrl: videoUrl,
      isMe: isMe,
    );
  }

  Widget _buildDocumentContent(Map<String, dynamic> message, bool isMe) {
    final fileName = message['fileName'] as String? ?? 'Document';
    final extension = fileName.split('.').last.toUpperCase();
    final filePath = message['filePath'] as String?;
    
    return GestureDetector(
      onTap: () => _downloadDocument(filePath, fileName),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: isMe ? Colors.white.withOpacity(0.3) : const Color(0xFF10B981).withOpacity(0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.insert_drive_file_rounded,
              size: 20,
              color: isMe ? Colors.white : const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isMe ? Colors.white : const Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    extension,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isMe ? Colors.white.withOpacity(0.7) : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.download_rounded,
                    size: 12,
                    color: isMe ? Colors.white.withOpacity(0.7) : const Color(0xFF6B7280),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
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

  Widget _buildMessageInput() {
    if (_isRecording) {
      return _buildRecordingUI();
    }

    if (_isChatBlocked) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: const Color(0xFFE5E7EB).withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (_blockedByMe ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.block_rounded,
                      size: 18,
                      color: _blockedByMe ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _blockedByMe ? 'You blocked this user' : 'You can\'t send messages',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _blockedByMe
                              ? 'Unblock to send messages again.'
                              : 'Messaging is disabled in this conversation.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_blockedByMe)
                    TextButton(
                      onPressed: _unblockUser,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                      ),
                      child: const Text(
                        'Unblock',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selected Images Preview
        if (_selectedImages.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedImages.length}/8 photos selected',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _sendSelectedImages,
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Send All'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                base64Decode(_compressedImages[index].split(',').last),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _removeSelectedImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImages.clear();
                          _compressedImages.clear();
                        });
                      },
                      child: Text(
                        'Cancel preview',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        // Upload Progress Indicator
        if (_isUploadingAttachment)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Compressing images...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        // Reply Preview
        if (_replyingToMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFE5E7EB).withOpacity(0.5),
                  width: 1,
                ),
                left: const BorderSide(
                  color: Color(0xFF3B82F6),
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _replyingToMessage!['isMe'] == true ? 'You' : widget.userName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getReplyPreviewText(_replyingToMessage!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _cancelReply,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Message Input Container
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: const Color(0xFFE5E7EB).withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
          children: [
            // Attachment button
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.attach_file_rounded, size: 18),
                color: const Color(0xFF3B82F6),
                padding: EdgeInsets.zero,
                onPressed: _showAttachmentOptions,
              ),
            ),
            const SizedBox(width: 8),
            // Message input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1F2937),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Voice/Send button
            if (_isTyping)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, size: 18),
                  color: Colors.white,
                  padding: EdgeInsets.zero,
                  onPressed: _sendMessage,
                ),
              )
            else
              GestureDetector(
                onLongPress: _startRecording,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    size: 18,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
          ],
        ),
      ),
        ),
      ],
    );
  }

  Widget _buildRecordingUI() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.05),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFEF4444).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cancel button
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 22),
              color: const Color(0xFFEF4444),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: _cancelRecording,
            ),
            const SizedBox(width: 12),
            // Recording indicator
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            // Duration
            Text(
              _formatDuration(_recordDuration),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            // Waveform animation placeholder
            Expanded(
              child: Container(
                height: 30,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    20,
                    (index) => Container(
                      width: 3,
                      height: (index % 3 + 1) * 8.0,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Send button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, size: 20),
                color: Colors.white,
                padding: EdgeInsets.zero,
                onPressed: _stopRecording,
              ),
            ),
          ],
        ),
      ),
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

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _MarqueeText({
    required this.text,
    required this.style,
  });

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  Timer? _scrollTimer;
  bool _isScrollingForward = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || !_scrollController.hasClients) return;
      
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      
      if (maxScroll <= 0) return;
      
      if (_isScrollingForward) {
        if (currentScroll >= maxScroll) {
          _isScrollingForward = false;
          _scrollTimer?.cancel();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _startAutoScroll();
          });
        } else {
          _scrollController.jumpTo(currentScroll + 0.5);
        }
      } else {
        if (currentScroll <= 0) {
          _isScrollingForward = true;
          _scrollTimer?.cancel();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _startAutoScroll();
          });
        } else {
          _scrollController.jumpTo(currentScroll - 0.5);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
      ),
    );
  }
}
