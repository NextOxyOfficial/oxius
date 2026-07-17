import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import '../config/app_config.dart';
import '../services/adsyconnect_service.dart';
import '../services/auth_service.dart';
import '../widgets/common/adsy_loading.dart';
import '../widgets/common/adsy_toast.dart';
import 'group_info_screen.dart';

/// Group conversation: text + voice messages, live typing indicator
/// ("কে/কতজন টাইপ করছে"), and the group-info management screen.
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
  bool _sending = false;
  Timer? _pollTimer;
  Timer? _typingPollTimer;
  DateTime _lastTypingSent = DateTime.fromMillisecondsSinceEpoch(0);
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  // Voice recording / playback
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _recording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _playingId;

  String get _groupId => (_group['id'] ?? '').toString();
  String get _myId => AuthService.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _group = Map<String, dynamic>.from(widget.group);
    _input.addListener(_onInputChanged);
    _loadMessages(initial: true);
    _pollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages());
    _typingPollTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _pollTyping());
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && mounted) {
        setState(() => _playingId = null);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _typingPollTimer?.cancel();
    _recordTimer?.cancel();
    _input.removeListener(_onInputChanged);
    _input.dispose();
    _scroll.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  // Throttled typing heartbeat — at most one ping per 2.5s while typing.
  void _onInputChanged() {
    if (_input.text.trim().isEmpty) return;
    final now = DateTime.now();
    if (now.difference(_lastTypingSent).inMilliseconds > 2500) {
      _lastTypingSent = now;
      AdsyConnectService.setGroupTyping(_groupId);
    }
    setState(() {}); // swap mic/send button
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

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final res = await AdsyConnectService.sendGroupMessage(_groupId, text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (res != null) {
      _input.clear();
      await _loadMessages();
    } else {
      AdsyToast.error(context, 'মেসেজ পাঠানো যায়নি');
    }
  }

  // ── Voice messages — same UX as the 1:1 chat ─────────────────────────────

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          AdsyToast.warning(context, 'মাইক্রোফোনের অনুমতি দিন');
        }
        return;
      }
      final dir = DateTime.now().millisecondsSinceEpoch;
      final path =
          '${(await _tempDirPath())}/group_voice_$dir.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      _recordSeconds = 0;
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordSeconds++);
      });
      setState(() => _recording = true);
    } catch (e) {
      if (mounted) AdsyToast.error(context, 'রেকর্ড শুরু করা যায়নি');
    }
  }

  Future<String> _tempDirPath() async {
    // record package accepts any writable path; use the system temp dir.
    return Directory.systemTemp.path;
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
    setState(() => _sending = true);
    final res = await AdsyConnectService.sendGroupMediaMessage(
      groupId: _groupId,
      filePath: path,
      messageType: 'voice',
      voiceDuration: duration,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (res != null) {
      await _loadMessages();
    } else {
      AdsyToast.error(context, 'ভয়েস মেসেজ পাঠানো যায়নি');
    }
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
      if (_playingId == id) {
        await _player.stop();
        setState(() => _playingId = null);
        return;
      }
      await _player.stop();
      await _player.setUrl(url);
      setState(() => _playingId = id);
      await _player.play();
    } catch (_) {
      if (mounted) setState(() => _playingId = null);
    }
  }

  Future<void> _openInfo() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GroupInfoScreen(group: _group)),
    );
    if (!mounted) return;
    if (result == 'left' || result == 'deleted') {
      Navigator.of(context).pop(true);
      return;
    }
    // Pull fresh group meta (name/photo/members may have changed).
    final groups = await AdsyConnectService.getGroups();
    if (!mounted) return;
    final updated = groups
        .map<Map<String, dynamic>>((g) => Map<String, dynamic>.from(g))
        .where((g) => g['id'].toString() == _groupId)
        .toList();
    if (updated.isNotEmpty) setState(() => _group = updated.first);
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
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _bubble(_messages[i]),
                      ),
          ),
          _buildTypingIndicator(),
          _buildInput(),
        ],
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

  Widget _bubble(Map<String, dynamic> m) {
    final sender = Map<String, dynamic>.from(m['sender'] ?? {});
    final senderId = (sender['id'] ?? '').toString();
    final isMe = senderId == _myId;
    final name = [
      (sender['first_name'] ?? '').toString(),
      (sender['last_name'] ?? '').toString(),
    ].where((s) => s.isNotEmpty).join(' ');
    final display =
        name.isNotEmpty ? name : (sender['username'] ?? 'User').toString();
    final isVoice = m['message_type'] == 'voice';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 5),
            bottomRight: Radius.circular(isMe ? 5 : 16),
          ),
          border: isMe ? null : Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sender name above received messages — essential in a group.
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(display,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB))),
              ),
            if (isVoice)
              _voiceContent(m, isMe)
            else
              Text(
                (m['content'] ?? '').toString(),
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: isMe ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _voiceContent(Map<String, dynamic> m, bool isMe) {
    final id = (m['id'] ?? '').toString();
    final url = m['media_url']?.toString();
    final duration = m['voice_duration'] is int
        ? m['voice_duration'] as int
        : int.tryParse('${m['voice_duration'] ?? 0}') ?? 0;
    final playing = _playingId == id;
    final fg = isMe ? Colors.white : const Color(0xFF2563EB);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _playVoice(id, url),
          child: Icon(
            playing ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
            size: 34,
            color: fg,
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.graphic_eq_rounded,
            size: 20, color: fg.withValues(alpha: 0.8)),
        const SizedBox(width: 6),
        Text(
          '${(duration ~/ 60).toString().padLeft(1, '0')}:${(duration % 60).toString().padLeft(2, '0')}',
          style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w600, color: fg),
        ),
      ],
    );
  }

  Widget _buildInput() {
    final hasText = _input.text.trim().isNotEmpty;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        color: Colors.white,
        child: _recording
            ? Row(
                children: [
                  IconButton(
                    onPressed: _cancelRecording,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFDC2626)),
                  ),
                  const Icon(Icons.mic, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '${(_recordSeconds ~/ 60)}:${(_recordSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B)),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _sending ? null : _stopAndSendRecording,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFF2563EB)),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white)))
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: 'মেসেজ লিখুন…',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _sending
                        ? null
                        : hasText
                            ? _send
                            : _startRecording,
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasText
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF10B981)),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white)))
                          : Icon(
                              hasText ? Icons.send_rounded : Icons.mic_rounded,
                              color: Colors.white,
                              size: 20),
                    ),
                  ),
                ],
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
