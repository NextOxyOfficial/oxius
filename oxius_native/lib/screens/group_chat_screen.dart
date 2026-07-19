import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import '../services/adsyconnect_service.dart';
import '../services/auth_service.dart';
import '../utils/image_compressor.dart';
import '../utils/url_launcher_utils.dart';
import '../utils/video_upload_helper.dart';
import '../widgets/chat/chat_message_bubble.dart';
import '../widgets/chat/chat_message_input.dart';
import '../widgets/chat/message_options_sheet.dart';
import '../widgets/common/adsy_loading.dart';
import '../widgets/common/adsy_toast.dart';
import 'business_network/profile_screen.dart';
import 'group_info_screen.dart';

/// Group conversation. Reuses the SAME polished pieces as the 1:1 chat —
/// [ChatMessageInput] (text, mic recording, attachments with image preview)
/// and [ChatMessageBubble] (text/image/video/document/voice bubbles, link
/// previews, shared-post cards) — so groups feel identical to direct chats.
/// Adds group-only bits: sender name above received bubbles, a live
/// "কে/কতজন টাইপ করছে" line, and the group-info management screen.
/// No audio/video calls in groups — by design.
class GroupChatScreen extends StatefulWidget {
  final Map<String, dynamic> group;

  const GroupChatScreen({super.key, required this.group});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  late Map<String, dynamic> _group;
  List<Map<String, dynamic>> _messages = [];
  List<String> _typingNames = [];
  bool _loading = true;
  // Messenger-style timestamps: tap a message to reveal its time, tap it
  // again (or anywhere outside) to hide.
  String? _timeShownId;
  // Active quote-reply target (raw group message) — mirrors the 1:1 chat.
  Map<String, dynamic>? _replyingTo;
  Timer? _pollTimer;
  Timer? _typingPollTimer;
  DateTime _lastTypingSent = DateTime.fromMillisecondsSinceEpoch(0);
  final ScrollController _scroll = ScrollController();

  // Input state — mirrors the 1:1 interface so ChatMessageInput drops in.
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<String> _compressedImages = [];
  bool _isCompressingImages = false;
  bool _isUploadingAttachment = false;
  bool _isTyping = false;

  // Voice recording / playback
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _recording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _playingVoiceId;
  Duration _voicePosition = Duration.zero;
  Duration _voiceDuration = Duration.zero;

  String get _groupId => (_group['id'] ?? '').toString();
  String get _myId => AuthService.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _group = Map<String, dynamic>.from(widget.group);
    _messageController.addListener(_onInputChanged);
    _loadMessages(initial: true);
    _pollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages());
    _typingPollTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _pollTyping());
    _player.positionStream.listen((p) {
      if (mounted && _playingVoiceId != null) {
        setState(() => _voicePosition = p);
      }
    });
    _player.durationStream.listen((d) {
      if (mounted && d != null) setState(() => _voiceDuration = d);
    });
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && mounted) {
        setState(() {
          _playingVoiceId = null;
          _voicePosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _typingPollTimer?.cancel();
    _recordTimer?.cancel();
    _messageController.removeListener(_onInputChanged);
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scroll.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  // Throttled typing heartbeat — at most one ping per 2.5s while typing.
  void _onInputChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _isTyping) setState(() => _isTyping = hasText);
    if (!hasText) return;
    final now = DateTime.now();
    if (now.difference(_lastTypingSent).inMilliseconds > 2500) {
      _lastTypingSent = now;
      AdsyConnectService.setGroupTyping(_groupId);
    }
  }

  Future<void> _pollTyping() async {
    final names = await AdsyConnectService.getGroupTyping(_groupId);
    if (!mounted) return;
    if (names.join(',') != _typingNames.join(',')) {
      setState(() => _typingNames = names);
    }
  }

  Future<void> _loadMessages({bool initial = false}) async {
    final raw = await AdsyConnectService.getGroupMessages(_groupId);
    if (!mounted) return;
    final msgs = raw
        .map<Map<String, dynamic>>((m) => Map<String, dynamic>.from(m))
        .toList();
    final changed = msgs.length != _messages.length;
    setState(() {
      _messages = msgs;
      _loading = false;
    });
    if (initial || changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    final replyId = (_replyingTo?['id'] ?? '').toString();
    if (_replyingTo != null) setState(() => _replyingTo = null);
    final res = await AdsyConnectService.sendGroupMessage(
      _groupId,
      text,
      replyTo: replyId.isNotEmpty ? replyId : null,
    );
    if (!mounted) return;
    if (res != null) {
      await _loadMessages();
    } else {
      AdsyToast.error(context, 'মেসেজ পাঠানো যায়নি');
    }
  }

  /// Short human preview of a raw group message (for the reply bar).
  String _rawPreview(Map<String, dynamic> m) {
    switch ((m['message_type'] ?? 'text').toString()) {
      case 'voice':
        return '🎤 Voice message';
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'document':
        return '📄 ${m['file_name'] ?? 'Document'}';
      default:
        final t = (m['content'] ?? '').toString();
        return t.length > 60 ? '${t.substring(0, 60)}…' : t;
    }
  }

  void _setReplyingTo(Map<String, dynamic> raw) {
    setState(() => _replyingTo = raw);
    _messageFocusNode.requestFocus();
  }

  /// Edits allowed only within 10 minutes of sending.
  bool _withinEditWindow(Map<String, dynamic> raw) {
    final t = DateTime.tryParse((raw['created_at'] ?? '').toString());
    if (t == null) return false;
    return DateTime.now().toUtc().difference(t.toUtc()).inMinutes < 10;
  }

  Future<void> _editGroupMessage(Map<String, dynamic> raw) async {
    final controller =
        TextEditingController(text: (raw['content'] ?? '').toString());
    final newText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Edit Message',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          minLines: 1,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.all(10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (newText == null || newText.isEmpty || !mounted) return;
    final res = await AdsyConnectService.editGroupMessage(
        _groupId, (raw['id'] ?? '').toString(), newText);
    if (!mounted) return;
    if (res != null) {
      await _loadMessages();
    } else {
      AdsyToast.error(context, 'এডিট করা যায়নি (১০ মিনিট পেরিয়ে গেছে?)');
    }
  }

  Future<void> _deleteGroupMessage(Map<String, dynamic> raw) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Message?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('This message will be removed for everyone.',
            style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await AdsyConnectService.deleteGroupMessage(
        _groupId, (raw['id'] ?? '').toString());
    if (!mounted) return;
    if (ok) {
      await _loadMessages();
    } else {
      AdsyToast.error(context, 'মুছা যায়নি');
    }
  }

  // ── Attachments — same sheet + flows as the 1:1 chat ────────────────────

  Future<void> _showAttachmentOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
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
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 6),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Color(0xFF16A34A)),
              title: const Text('ছবি'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImagesFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined,
                  color: Color(0xFFDC2626)),
              title: const Text('ভিডিও'),
              onTap: () {
                Navigator.pop(ctx);
                _pickVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined,
                  color: Color(0xFF2563EB)),
              title: const Text('ডকুমেন্ট'),
              onTap: () {
                Navigator.pop(ctx);
                _pickDocument();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isEmpty) return;
      if (_selectedImages.length + images.length > 8) {
        if (mounted) AdsyToast.error(context, 'Maximum 8 photos allowed');
        return;
      }
      setState(() => _isCompressingImages = true);
      final List<String> compressed = [];
      for (final image in images) {
        final compressedBase64 = await ImageCompressor.compressToBase64(
          image,
          targetSize: 200 * 1024,
          initialQuality: 80,
          maxDimension: 1920,
        );
        if (compressedBase64 != null) compressed.add(compressedBase64);
      }
      if (!mounted) return;
      setState(() {
        _selectedImages.addAll(images);
        _compressedImages.addAll(compressed);
        _isCompressingImages = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isCompressingImages = false);
        AdsyToast.error(context, 'ছবি সিলেক্ট  করা যায়নি');
      }
    }
  }

  Future<void> _sendSelectedImages() async {
    if (_selectedImages.isEmpty) return;
    final count = _selectedImages.length;
    setState(() => _isUploadingAttachment = true);
    var failures = 0;
    try {
      for (int i = 0; i < count; i++) {
        // Upload the COMPRESSED image (the preview bytes) when available —
        // multi-MB originals over slow uplinks timed out and the old loop
        // ignored the null result, so photos vanished without any error.
        Map<String, dynamic>? res;
        if (i < _compressedImages.length && _compressedImages[i].isNotEmpty) {
          // Strip the data-URI prefix (compressToBase64 returns
          // "data:image/jpeg;base64,...") — raw base64Decode threw on it and
          // every send failed with a generic error.
          final b64 = _compressedImages[i].contains(',')
              ? _compressedImages[i]
                  .substring(_compressedImages[i].indexOf(',') + 1)
              : _compressedImages[i];
          res = await AdsyConnectService.sendGroupMediaMessage(
            groupId: _groupId,
            messageType: 'image',
            mediaBytes: base64Decode(b64),
            fileName: 'photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          );
        } else {
          res = await AdsyConnectService.sendGroupMediaMessage(
            groupId: _groupId,
            messageType: 'image',
            filePath: _selectedImages[i].path,
          );
        }
        if (res == null) failures++;
        if (i < count - 1) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
      if (!mounted) return;
      setState(() {
        _selectedImages.clear();
        _compressedImages.clear();
        _isUploadingAttachment = false;
      });
      if (failures > 0) {
        AdsyToast.error(
            context,
            failures == count
                ? 'ছবি পাঠানো যায়নি — আবার চেষ্টা করুন'
                : '$failures টি ছবি পাঠানো যায়নি');
      }
      await _loadMessages();
    } catch (_) {
      if (mounted) {
        setState(() => _isUploadingAttachment = false);
        AdsyToast.error(context, 'ছবি পাঠানো যায়নি');
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video =
          await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (video == null || !mounted) return;
      // 3-minute cap (over-limit → Google Drive sheet) + compression.
      setState(() => _isUploadingAttachment = true);
      final prepared = await VideoUploadHelper.prepareForUpload(
          context, video.path,
          driveHint: true);
      if (!mounted) return;
      setState(() => _isUploadingAttachment = false);
      if (prepared == null) return;
      await _sendMedia(prepared, 'video');
    } catch (_) {
      if (mounted) {
        setState(() => _isUploadingAttachment = false);
        AdsyToast.error(context, 'ভিডিও সিলেক্ট  করা যায়নি');
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
      );
      final path = result?.files.single.path;
      if (path == null) return;
      await _sendMedia(path, 'document',
          fileName: result!.files.single.name);
    } catch (_) {
      if (mounted) AdsyToast.error(context, 'ডকুমেন্ট সিলেক্ট  করা যায়নি');
    }
  }

  Future<void> _sendMedia(String filePath, String type,
      {String? fileName, int? voiceDuration}) async {
    setState(() => _isUploadingAttachment = true);
    final res = await AdsyConnectService.sendGroupMediaMessage(
      groupId: _groupId,
      messageType: type,
      filePath: filePath,
      fileName: fileName,
      voiceDuration: voiceDuration,
    );
    if (!mounted) return;
    setState(() => _isUploadingAttachment = false);
    if (res != null) {
      await _loadMessages();
    } else {
      AdsyToast.error(context, 'পাঠানো যায়নি');
    }
  }

  // ── Voice — same record UX as the 1:1 chat ──────────────────────────────

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) AdsyToast.warning(context, 'মাইক্রোফোনের অনুমতি দিন');
        return;
      }
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${Directory.systemTemp.path}/group_voice_$stamp.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      _recordSeconds = 0;
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordSeconds++);
      });
      setState(() => _recording = true);
    } catch (_) {
      if (mounted) AdsyToast.error(context, 'রেকর্ড শুরু করা যায়নি');
    }
  }

  Future<void> _stopAndSendRecording() async {
    _recordTimer?.cancel();
    final path = await _recorder.stop();
    final duration = _recordSeconds;
    setState(() {
      _recording = false;
      _recordSeconds = 0;
    });
    if (path == null) return;
    await _sendMedia(path, 'voice', voiceDuration: duration);
  }

  Future<void> _cancelRecording() async {
    _recordTimer?.cancel();
    await _recorder.stop();
    setState(() {
      _recording = false;
      _recordSeconds = 0;
    });
  }

  Future<void> _playVoice(String id, String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      if (_playingVoiceId == id) {
        await _player.stop();
        setState(() {
          _playingVoiceId = null;
          _voicePosition = Duration.zero;
        });
        return;
      }
      await _player.stop();
      await _player.setUrl(url);
      setState(() {
        _playingVoiceId = id;
        _voicePosition = Duration.zero;
      });
      await _player.play();
    } catch (_) {
      if (mounted) setState(() => _playingVoiceId = null);
    }
  }

  // ── Navigation ──────────────────────────────────────────────────────────

  Future<void> _openInfo() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GroupInfoScreen(group: _group)),
    );
    if (!mounted) return;
    if (result == 'left' || result == 'deleted') {
      Navigator.of(context).pop(true);
      return;
    }
    final groups = await AdsyConnectService.getGroups();
    if (!mounted) return;
    final updated = groups
        .map<Map<String, dynamic>>((g) => Map<String, dynamic>.from(g))
        .where((g) => g['id'].toString() == _groupId)
        .toList();
    if (updated.isNotEmpty) setState(() => _group = updated.first);
  }

  void _viewImage(String path) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: InteractiveViewer(
            maxScale: 5,
            child: Image.network(path,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48)),
          ),
        ),
      ),
    ));
  }

  // ── Message mapping — group payload → the 1:1 bubble's shape ────────────

  Map<String, dynamic> _bubbleMessage(Map<String, dynamic> m) {
    final sender = Map<String, dynamic>.from(m['sender'] ?? {});
    final senderId = (sender['id'] ?? '').toString();
    return {
      'id': (m['id'] ?? '').toString(),
      'type': (m['message_type'] ?? 'text').toString(),
      'message': (m['content'] ?? '').toString(),
      'isMe': senderId == _myId,
      'mediaUrl': m['media_url']?.toString(),
      'fileName': m['file_name']?.toString(),
      'voiceDuration':
          int.tryParse('${m['voice_duration'] ?? ''}') ?? 0,
      'isDeleted': m['is_deleted'] == true,
      // Quote-reply metadata — the bubble renders its standard quote card.
      'replyToId': m['reply_to']?.toString(),
      'replyPreview': m['reply_preview']?.toString(),
      'replyToSender': m['reply_sender_name']?.toString(),
      // Time stays hidden until the message is tapped (Messenger-style).
      'showTimestamp': (m['id'] ?? '').toString() == _timeShownId,
      'timeDisplay': _formatTime(
          DateTime.tryParse((m['created_at'] ?? '').toString())),
      'isSeen': false,
    };
  }

  String _formatTime(DateTime? t) {
    if (t == null) return '';
    final local = t.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '$h:${local.minute.toString().padLeft(2, '0')} $ampm';
  }

  String _senderName(Map<String, dynamic> m) {
    final sender = Map<String, dynamic>.from(m['sender'] ?? {});
    final name = [
      (sender['first_name'] ?? '').toString(),
      (sender['last_name'] ?? '').toString(),
    ].where((s) => s.isNotEmpty).join(' ');
    return name.isNotEmpty ? name : (sender['username'] ?? 'User').toString();
  }

  String? _senderAvatar(Map<String, dynamic> m) {
    final sender = Map<String, dynamic>.from(m['sender'] ?? {});
    return sender['avatar']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final memberCount =
        _group['member_count'] ?? (_group['members'] as List? ?? []).length;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF334155)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: InkWell(
          onTap: _openInfo,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFFEFF6FF)),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: (_group['image_url'] ?? '').toString().isNotEmpty
                    ? Image.network(_group['image_url'].toString(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.groups,
                            size: 20, color: Color(0xFF3B82F6)))
                    : const Icon(Icons.groups,
                        size: 20, color: Color(0xFF3B82F6)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((_group['name'] ?? '').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B))),
                    Text('$memberCount জন মেম্বার',
                        style: TextStyle(
                            fontSize: 11.5, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded,
                color: Color(0xFF334155)),
            onPressed: _openInfo,
            tooltip: 'গ্রুপ ইনফো',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: AdsyLoadingIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text('এখনো কোনো মেসেজ নেই — শুরু করুন!',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600)),
                      )
                    : GestureDetector(
                        // Tap on empty list area hides any revealed time.
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          if (_timeShownId != null) {
                            setState(() => _timeShownId = null);
                          }
                        },
                        child: ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) => _buildRow(i),
                        ),
                      ),
          ),
          _buildTypingIndicator(),
          // The SAME input bar as the 1:1 chat: text, attachments with image
          // preview strip, and mic recording UI.
          ChatMessageInput(
            messageController: _messageController,
            messageFocusNode: _messageFocusNode,
            isRecording: _recording,
            isChatBlocked: false,
            blockedByMe: false,
            isTyping: _isTyping,
            isUploadingAttachment: _isUploadingAttachment,
            isCompressingImages: _isCompressingImages,
            compressedImages: _compressedImages,
            recordDuration: Duration(seconds: _recordSeconds),
            replyFromName: _replyingTo != null
                ? ((Map<String, dynamic>.from(
                                _replyingTo!['sender'] ?? {})['id'] ??
                            '')
                        .toString() ==
                        _myId
                    ? 'You'
                    : _senderName(_replyingTo!))
                : null,
            replyPreviewText:
                _replyingTo != null ? _rawPreview(_replyingTo!) : null,
            onSend: _sendText,
            onStartRecording: _startRecording,
            onStopRecording: _stopAndSendRecording,
            onCancelRecording: _cancelRecording,
            onUnblock: () {},
            onCancelReply: () => setState(() => _replyingTo = null),
            onShowAttachmentOptions: _showAttachmentOptions,
            onSendImages: _sendSelectedImages,
            onCancelImagePreview: () => setState(() {
              _selectedImages.clear();
              _compressedImages.clear();
            }),
            onRemoveImage: (i) => setState(() {
              if (i < _selectedImages.length) _selectedImages.removeAt(i);
              if (i < _compressedImages.length) _compressedImages.removeAt(i);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(int i) {
    final raw = _messages[i];
    // Activity notices (member added/removed, renamed, …) render as a
    // centered pill so everyone sees what happened.
    if ((raw['message_type'] ?? '').toString() == 'system') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(40, 8, 40, 18),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EDF3),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              (raw['content'] ?? '').toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
                height: 1.35,
              ),
            ),
          ),
        ),
      );
    }
    final mapped = _bubbleMessage(raw);
    final isMe = mapped['isMe'] == true;
    // Show the avatar when the sender changes (like the 1:1 list).
    final prevSender = i > 0
        ? (Map<String, dynamic>.from(_messages[i - 1]['sender'] ?? {})['id'] ??
                '')
            .toString()
        : '';
    final thisSender =
        (Map<String, dynamic>.from(raw['sender'] ?? {})['id'] ?? '')
            .toString();
    final showAvatar = !isMe && thisSender != prevSender;

    final msgId = mapped['id'].toString();
    // Tap a message to reveal its time; tapping it again hides it. Media
    // taps (image viewer, voice play) keep their own handlers — the deepest
    // gesture wins, so this only fires on plain bubble areas.
    final bubble = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => setState(
          () => _timeShownId = _timeShownId == msgId ? null : msgId),
      child: ChatMessageBubble(
        key: ValueKey(msgId),
        message: mapped,
        // Avatar lives in the run header (Messenger-style), not per bubble.
        showAvatar: false,
        userName: _senderName(raw),
        userAvatar: _senderAvatar(raw),
        playingVoiceMessageId: _playingVoiceId,
        voicePosition: _voicePosition,
        voiceDuration: _voiceDuration,
        // Swipe-to-reply (same gesture as 1:1).
        onReply: (_) => _setReplyingTo(raw),
        // Long-press options — the SHARED sheet used by the 1:1 chat.
        // Edit shows only for own text messages within 10 minutes.
        onLongPress: () => showChatMessageOptions(
          context,
          message: mapped,
          onReply: () => _setReplyingTo(raw),
          onEdit: isMe && _withinEditWindow(raw)
              ? () => _editGroupMessage(raw)
              : null,
          onDelete: isMe ? () => _deleteGroupMessage(raw) : null,
        ),
        onOptions: () => showChatMessageOptions(
          context,
          message: mapped,
          onReply: () => _setReplyingTo(raw),
          onEdit: isMe && _withinEditWindow(raw)
              ? () => _editGroupMessage(raw)
              : null,
          onDelete: isMe ? () => _deleteGroupMessage(raw) : null,
        ),
        onPlayVoice: _playVoice,
        onViewImage: _viewImage,
        onDownloadDoc: (path, name) {
          final url = mapped['mediaUrl']?.toString();
          if (url != null && url.isNotEmpty) {
            UrlLauncherUtils.launchExternalUrl(url);
          }
        },
        onScrollToMessage: (_) {},
      ),
    );

    // Facebook-standard run header: avatar + name aligned together above the
    // FIRST message of a speaker's run.
    if (!isMe && showAvatar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 10, bottom: 3),
            // Tapping the avatar/name opens the sender's BN profile.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openSenderProfile(raw),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _runHeaderAvatar(raw),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _senderName(raw),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bubble,
        ],
      );
    }
    return bubble;
  }

  void _openSenderProfile(Map<String, dynamic> raw) {
    final sender = Map<String, dynamic>.from(raw['sender'] ?? {});
    final uid = (sender['id'] ?? '').toString();
    if (uid.isEmpty) return;
    if (sender['is_active'] == false || sender['is_suspended'] == true) {
      AdsyToast.info(context, 'এই অ্যাকাউন্টটি সাসপেন্ডেড');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: uid)),
    );
  }

  /// Small circular avatar for the run header (initial fallback).
  Widget _runHeaderAvatar(Map<String, dynamic> raw) {
    final url = (_senderAvatar(raw) ?? '').trim();
    final name = _senderName(raw);
    Widget fallback() => Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Color(0xFF3B82F6),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEFF6FF),
      ),
      child: url.isEmpty
          ? fallback()
          : ClipOval(
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback(),
              ),
            ),
    );
  }

  /// Bottom-left typing line: one person → "Name টাইপ করছেন…", several →
  /// "Name ও আরও N জন টাইপ করছে…" with the pulsing-dots animation.
  Widget _buildTypingIndicator() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _typingNames.isEmpty
          ? const SizedBox.shrink(key: ValueKey('g_typing_hidden'))
          : Padding(
              key: const ValueKey('g_typing_visible'),
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _TypingDots(),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        _typingNames.length == 1
                            ? '${_typingNames.first} টাইপ করছেন…'
                            : '${_typingNames.first} ও আরও ${_typingNames.length - 1} জন টাইপ করছে…',
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
              ),
            ),
    );
  }
}

/// Three pulsing dots — the classic "typing…" wave.
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_c.value + i * 0.2) % 1.0;
            final scale = 0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0, 1);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale.toDouble(),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFF64748B)),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
