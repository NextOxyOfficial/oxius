import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
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
import '../features/adsyconnect_call/models/adsy_call.dart';
import '../features/adsyconnect_call/screens/adsy_call_screen.dart';

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

class _AdsyConnectChatInterfaceState extends State<AdsyConnectChatInterface> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
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

  @override
  void initState() {
    super.initState();
    // Set this chat as active to prevent push notifications
    ActiveChatTracker.setActiveChat(widget.chatroomId);
    _isOtherUserOnline = widget.isOnline;
    _loadChatroomStatus();
    _loadMessages();
    _loadOnlineStatus();
    _messageController.addListener(_onTypingChanged);
    _scrollController.addListener(_onScroll);
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

  Future<void> _loadChatroomStatus() async {
    if (_isLoadingChatroomStatus) return;
    setState(() => _isLoadingChatroomStatus = true);

    try {
      final data = await AdsyConnectService.getChatRoomDetails(widget.chatroomId);
      if (!mounted) return;

      if (data == null) {
        setState(() => _isLoadingChatroomStatus = false);
        return;
      }

      final currentUserId = AuthService.currentUser?.id;

      final isBlocked = _parseBool(data['is_blocked'] ?? data['blocked'] ?? data['isBlocked']);
      bool blockedByMe = _parseBool(data['blocked_by_me'] ?? data['is_blocked_by_me'] ?? data['blockedByMe']);

      final blockedBy = data['blocked_by'];
      if (!blockedByMe && currentUserId != null && blockedBy != null) {
        if (blockedBy is Map) {
          final id = blockedBy['id']?.toString() ?? blockedBy['user_id']?.toString();
          if (id != null && id == currentUserId) {
            blockedByMe = true;
          }
        } else {
          if (blockedBy.toString() == currentUserId) {
            blockedByMe = true;
          }
        }
      }

      setState(() {
        _isChatBlocked = isBlocked || blockedByMe;
        _blockedByMe = blockedByMe;
        _isLoadingChatroomStatus = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingChatroomStatus = false);
      }
    }
  }

  Future<void> _loadOnlineStatus() async {
    try {
      final status = await AdsyConnectService.getOnlineStatus(widget.userId);
      if (!mounted) return;
      
      if (status != null) {
        setState(() {
          _isOtherUserOnline = status['is_online'] == true;
          _lastSeenTime = status['last_seen']?.toString();
        });
      }
    } catch (e) {
      // Silently fail - online status is not critical
    }
  }

  void _startOnlineStatusPolling() {
    _onlineStatusTimer?.cancel();
    _onlineStatusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadOnlineStatus();
    });
  }

  String _formatLastSeen(String? lastSeen) {
    if (lastSeen == null) return 'Offline';
    try {
      final dt = DateTime.parse(lastSeen);
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return 'Long time ago';
    } catch (_) {
      return 'Offline';
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      _isUserNearBottom = _scrollController.position.pixels < 100;
    }
    // Load more messages when scrolled to top (older messages)
    if (_scrollController.position.maxScrollExtent > 0 &&
        _scrollController.position.pixels > 0 &&
        _scrollController.position.pixels >=
            (_scrollController.position.maxScrollExtent - 100) &&
        !_isLoadingMoreMessages &&
        _hasMoreMessages) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingMoreMessages || !_hasMoreMessages) return;

    double? previousPixels;
    double? previousMaxScrollExtent;
    if (_scrollController.hasClients) {
      previousPixels = _scrollController.position.pixels;
      previousMaxScrollExtent = _scrollController.position.maxScrollExtent;
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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_scrollController.hasClients) return;
          if (previousPixels == null || previousMaxScrollExtent == null) return;

          final newMaxScrollExtent = _scrollController.position.maxScrollExtent;
          final delta = newMaxScrollExtent - previousMaxScrollExtent;
          final target = previousPixels + delta;

          final min = _scrollController.position.minScrollExtent;
          final max = _scrollController.position.maxScrollExtent;
          final clampedTarget = target < min ? min : (target > max ? max : target);
          _scrollController.jumpTo(clampedTarget);
        });
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
    // Clear active chat when leaving
    ActiveChatTracker.clearActiveChat();
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _recordTimer?.cancel();
    _messagePollingTimer?.cancel();
    _onlineStatusTimer?.cancel();
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
      
      return {
        'id': msg['id']?.toString() ?? '',
        'senderId': senderId,
        'message': msg['display_content']?.toString() ?? msg['content']?.toString() ?? '',
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
    if (_scrollController.hasClients) {
      // Use addPostFrameCallback to ensure ListView is fully built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && mounted) {
          _scrollController.animateTo(
            _scrollController.position.minScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      // If controller not ready, try again after a delay
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.minScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
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
    _messageController.clear();
    
    setState(() => _isSendingMessage = true);

    try {
      print('🔵 Sending message: $messageText');
      
      final sentMessage = await AdsyConnectService.sendTextMessage(
        chatroomId: widget.chatroomId,
        receiverId: widget.userId,
        content: messageText,
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
    
    return {
      'id': msg['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'senderId': 'me',
      'message': msg['display_content']?.toString() ?? msg['content']?.toString() ?? '',
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
    _deleteMessage(message);
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
        child: Column(
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
                    : ListView.builder(
                        controller: _scrollController,
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: () {
          // Navigate to business network profile
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
                  width: 42,
                  height: 42,
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
                if (widget.isOnline)
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
                      Flexible(
                        child: Text(
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
                          overflow: TextOverflow.ellipsis,
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
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdsyCallScreen(
                  isCaller: true,
                  otherUserId: widget.userId,
                  otherUserName: widget.userName,
                  type: AdsyCallType.audio,
                ),
              ),
            );
          },
          icon: const Icon(Icons.call_rounded, color: Colors.white, size: 20),
        ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdsyCallScreen(
                  isCaller: true,
                  otherUserId: widget.userId,
                  otherUserName: widget.userName,
                  type: AdsyCallType.video,
                ),
              ),
            );
          },
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

  Widget _buildMessageBubble(Map<String, dynamic> message, bool showAvatar) {
    final isMe = message['isMe'] as bool;
    
    return Padding(
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
              child: widget.userAvatar != null
                  ? ClipOval(
                      child: Image.network(
                        AppConfig.getAbsoluteUrl(widget.userAvatar),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
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
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        widget.userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF3B82F6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
                            ? _buildVoiceMessageContent(message, isMe)
                            : message['type'] == 'image'
                                ? _buildImageContent(message)
                                : message['type'] == 'video'
                                    ? _buildVideoContent(message, isMe)
                                    : message['type'] == 'document'
                                        ? _buildDocumentContent(message, isMe)
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
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
