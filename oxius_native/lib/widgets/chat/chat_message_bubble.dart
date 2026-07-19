import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_config.dart';
import '../../services/business_network_service.dart';
import '../../utils/shared_post_message.dart';
import '../../utils/url_launcher_utils.dart';
import '../../widgets/chat_video_player.dart';
import '../../widgets/link_preview_card.dart';
import '../../widgets/linkify_text.dart';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

bool isMsgDeleted(Map<String, dynamic> msg) {
  final v = msg['isDeleted'];
  return v == true || v == 1 || v == '1' || v == 'true';
}

String formatVoiceDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Reply-quote card (standalone, no state deps)
// ---------------------------------------------------------------------------

class ChatReplyQuoteCard extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;
  final void Function(String messageId) onTapReply;

  const ChatReplyQuoteCard({
    super.key,
    required this.message,
    required this.isMe,
    required this.onTapReply,
  });

  @override
  Widget build(BuildContext context) {
    final preview = message['replyPreview']?.toString() ?? '';
    if (preview.isEmpty) return const SizedBox.shrink();

    final sender = message['replyToSender']?.toString() ?? '';
    final replyToId = message['replyToId']?.toString() ?? '';

    final accent =
        isMe ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF3B82F6);
    final bg = isMe
        ? Colors.white.withValues(alpha: 0.18)
        : const Color(0xFF3B82F6).withValues(alpha: 0.08);
    final border = isMe
        ? Colors.white.withValues(alpha: 0.22)
        : const Color(0xFF3B82F6).withValues(alpha: 0.18);
    final titleColor =
        isMe ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF111827);
    final previewColor =
        isMe ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF4B5563);

    return GestureDetector(
      onTap: replyToId.isNotEmpty ? () => onTapReply(replyToId) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        // Quote look: a small quote glyph beside the sender, no side bar.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.format_quote_rounded, size: 14, color: accent),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
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
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: previewColor,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ChatMessageBubble — handles its own swipe-to-reply gesture state
// ---------------------------------------------------------------------------

class ChatMessageBubble extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool showAvatar;
  final String userName;
  final String? userAvatar;

  // Search highlight
  final bool isSearchHit;
  final bool isCurrentSearchHit;

  // Voice playback state (from parent)
  final String? playingVoiceMessageId;
  final Duration voicePosition;
  final Duration voiceDuration;

  // Callbacks
  final VoidCallback? onLongPress;
  final void Function(Map<String, dynamic> message) onReply;
  final void Function(String messageId, String? mediaUrl) onPlayVoice;
  final void Function(String filePath) onViewImage;
  final void Function(String? filePath, String fileName) onDownloadDoc;
  final void Function(String messageId) onScrollToMessage;
  final VoidCallback? onOptions;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.showAvatar,
    required this.userName,
    this.userAvatar,
    this.isSearchHit = false,
    this.isCurrentSearchHit = false,
    this.playingVoiceMessageId,
    required this.voicePosition,
    required this.voiceDuration,
    this.onLongPress,
    required this.onReply,
    required this.onPlayVoice,
    required this.onViewImage,
    required this.onDownloadDoc,
    required this.onScrollToMessage,
    this.onOptions,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  double _swipeOffset = 0.0;
  bool _isSwiping = false;
  bool _replyTriggered = false;

  static const double _swipeThreshold = 60.0;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isMe = message['isMe'] as bool;
    final isDeleted = isMsgDeleted(message);
    final swipeProgress =
        (_swipeOffset.abs() / _swipeThreshold).clamp(0.0, 1.0);

    final quoteCard = _buildReplyQuoteCard(message, isMe);

    return GestureDetector(
      onHorizontalDragStart: isDeleted
          ? null
          : (details) {
              setState(() {
                _isSwiping = true;
                _swipeOffset = 0.0;
                _replyTriggered = false;
              });
            },
      onHorizontalDragUpdate: isDeleted
          ? null
          : (details) {
              setState(() {
                if (isMe) {
                  _swipeOffset = (_swipeOffset + details.delta.dx)
                      .clamp(-_swipeThreshold * 1.2, 0.0);
                } else {
                  _swipeOffset = (_swipeOffset + details.delta.dx)
                      .clamp(0.0, _swipeThreshold * 1.2);
                }
              });

              if (_swipeOffset.abs() >= _swipeThreshold && !_replyTriggered) {
                _replyTriggered = true;
                HapticFeedback.lightImpact();
              }
            },
      onHorizontalDragEnd: isDeleted
          ? null
          : (details) {
              if (_swipeOffset.abs() >= _swipeThreshold) {
                HapticFeedback.mediumImpact();
                widget.onReply(message);
              }
              setState(() {
                _isSwiping = false;
                _swipeOffset = 0.0;
                _replyTriggered = false;
              });
            },
      onHorizontalDragCancel: () {
        setState(() {
          _isSwiping = false;
          _swipeOffset = 0.0;
          _replyTriggered = false;
        });
      },
      child: Stack(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          // Swipe reply icon
          if (_isSwiping && swipeProgress > 0.1)
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
                          : const Color(0xFF10B981).withValues(alpha: 0.2),
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
          // Bubble with swipe transform
          AnimatedContainer(
            duration: Duration(milliseconds: _isSwiping ? 0 : 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(_swipeOffset, 0, 0),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: 4,
                left: isMe ? 48 : 0,
                right: isMe ? 0 : 48,
              ),
              child: Row(
                mainAxisAlignment:
                    isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isMe && widget.showAvatar)
                    _buildSmallAvatar()
                  else if (!isMe)
                    const SizedBox(width: 34),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: GestureDetector(
                                onLongPress:
                                    isDeleted ? null : widget.onLongPress,
                                child: _buildBubbleContainer(
                                  message: message,
                                  isMe: isMe,
                                  isDeleted: isDeleted,
                                  quoteCard: quoteCard,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        if (message['showTimestamp'] == true)
                          _buildTimestamp(message, isMe),
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

  Widget _buildSmallAvatar() {
    final avatarUrl = AppConfig.getAbsoluteUrl(widget.userAvatar ?? '');
    Widget fallback() => Center(
          child: Text(
            widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Color(0xFF3B82F6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );

    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(right: 6, bottom: 2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFEFF6FF),
      ),
      child: avatarUrl.isEmpty
          ? fallback()
          : ClipOval(
              child: Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback(),
              ),
            ),
    );
  }

  Widget? _buildReplyQuoteCard(Map<String, dynamic> message, bool isMe) {
    final preview = message['replyPreview']?.toString() ?? '';
    if (preview.isEmpty) return null;

    return ChatReplyQuoteCard(
      message: message,
      isMe: isMe,
      onTapReply: widget.onScrollToMessage,
    );
  }

  Widget _buildBubbleContainer({
    required Map<String, dynamic> message,
    required bool isMe,
    required bool isDeleted,
    Widget? quoteCard,
  }) {
    final msgType = message['type']?.toString() ?? 'text';
    final isMedia = msgType == 'image' || msgType == 'video';

    // A message that is ONLY a preview (a shared post, or a bare URL) drops the
    // coloured bubble so the white preview card stands on its own — the
    // Messenger/WhatsApp look the user asked for.
    final text = (message['message'] ?? '').toString();
    final previewOnly = msgType == 'text' &&
        !isDeleted &&
        (SharedPostMessage.tryDecode(text) != null ||
            RegExp(r'^(https?:\/\/|www\.)\S+$', caseSensitive: false)
                .hasMatch(text.trim()));

    return Container(
      padding: previewOnly
          ? EdgeInsets.zero
          : isMedia
              ? const EdgeInsets.all(3)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        // Messenger-standard surfaces: one solid brand blue for own
        // messages, quiet gray for received — no gradients. Preview-only
        // messages are transparent so only the card shows.
        color: previewOnly
            ? Colors.transparent
            : isMe
                ? const Color(0xFF2563EB)
                : const Color(0xFFF1F5F9),
        border: widget.isSearchHit
            ? Border.all(
                color: widget.isCurrentSearchHit
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFFBBF24).withValues(alpha: 0.65),
                width: widget.isCurrentSearchHit ? 2 : 1,
              )
            : null,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 5),
          bottomRight: Radius.circular(isMe ? 5 : 18),
        ),
      ),
      child: isDeleted
          ? _buildDeletedContent(isMe)
          : _buildContent(message, isMe, quoteCard),
    );
  }

  Widget _buildDeletedContent(bool isMe) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.block_rounded,
            size: 14, color: isMe ? Colors.white70 : Colors.grey.shade500),
        const SizedBox(width: 6),
        Text(
          'Message removed',
          style: TextStyle(
            fontSize: 13.5,
            fontStyle: FontStyle.italic,
            color: isMe ? Colors.white70 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    Map<String, dynamic> message,
    bool isMe,
    Widget? quoteCard,
  ) {
    final msgType = message['type']?.toString() ?? 'text';
    final text = (message['message'] ?? '').toString();
    final isEdited = message['isEdited'] == true ||
        message['is_edited'] == true ||
        message['is_edited'] == 1 ||
        message['is_edited'] == 'true';

    Widget wrapWithQuote(Widget child) {
      if (quoteCard == null) return child;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [quoteCard, child],
      );
    }

    if (msgType == 'voice') {
      return wrapWithQuote(_buildVoiceContent(message, isMe));
    }
    if (msgType == 'image') {
      return wrapWithQuote(_buildImageContent(message));
    }
    if (msgType == 'video') {
      return wrapWithQuote(_buildVideoContent(message, isMe));
    }
    if (msgType == 'document') {
      return wrapWithQuote(_buildDocumentContent(message, isMe));
    }
    if (msgType == 'text' && text.startsWith('📞')) {
      return wrapWithQuote(_buildCallLogContent(message, isMe));
    }
    // A shared post: minimal Facebook-style attachment — thumbnail + owner
    // name only, no link-preview chrome, no background box.
    final shared = SharedPostMessage.tryDecode(text);
    if (shared != null) {
      return wrapWithQuote(_buildSharedPostContent(shared, isMe));
    }
    // Default: text with link preview. When the whole message is just one
    // URL, the big meta card carries the meaning — shrink the raw link to a
    // muted one-liner under it (kept so the link survives if the preview
    // fetch ever fails) instead of showing the bare URL in message size.
    final urlOnly = RegExp(
      r'^(https?:\/\/|www\.)\S+$',
      caseSensitive: false,
    ).hasMatch(text.trim());

    return wrapWithQuote(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FirstLinkPreview(
            text: text,
            margin: EdgeInsets.only(bottom: urlOnly ? 0 : 6),
            // In chat: no card background (blends into the bubble), text
            // tuned to the bubble color, adsyclub links open in-app and
            // third-party links open the browser.
            bare: true,
            onDark: isMe,
          ),
          // When the whole message is just a URL, the preview carries the
          // meaning — don't also print the raw link. Only show the message
          // text when there's actual text alongside the link.
          if (!urlOnly)
            LinkifyText(
              text,
              style: TextStyle(
                fontSize: 16,
                color: isMe ? Colors.white : const Color(0xFF1F2937),
                height: 1.38,
              ),
              linkStyle: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF2563EB),
                decoration: TextDecoration.none,
              ),
            ),
          if (isEdited) ...[
            const SizedBox(height: 4),
            Text(
              'Edited',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isMe
                    ? Colors.white.withValues(alpha: 0.72)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Shared post rendered with the SAME standard card as link previews:
  // thumbnail left, owner name (title) + "Business Network" (source) right,
  // inside a white rounded bordered box. Opens the post on tap.
  Widget _buildSharedPostContent(SharedPostMessage shared, bool isMe) {
    final thumb = AppConfig.getAbsoluteUrl(shared.thumbUrl);
    // Bold = the actual post author's name; subtitle = the post's own caption
    // (never a generic "Business Network" label). Falls back gracefully for
    // legacy messages that carry only one of the two.
    final title = shared.displayName.isEmpty ? 'Post' : shared.displayName;
    final subtitle = shared.caption.trim().isNotEmpty
        ? shared.caption.trim()
        : 'Business Network পোস্ট';
    // The card HUGS its content: short titles/captions get a narrow card,
    // and the old full width (~320) is now the MAXIMUM, not the default.
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: InkWell(
          onTap: () {
            if (shared.postUrl.isNotEmpty) {
              UrlLauncherUtils.launchExternalUrl(shared.postUrl);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicWidth(
              child: IntrinsicHeight(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 78,
                      child: thumb.isNotEmpty
                          ? Image.network(
                              thumb,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _sharedThumbFallback(),
                            )
                          : _SharedThumbResolver(postUrl: shared.postUrl),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                  height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sharedThumbFallback() => const _SharedThumbIcon();

  Widget _buildVoiceContent(Map<String, dynamic> message, bool isMe) {
    final duration = (message['voiceDuration'] as int?) ??
        (message['voice_duration'] as int?) ??
        0;
    final messageId = message['id']?.toString() ?? '';
    final mediaUrl = message['mediaUrl'] as String?;
    final isPlaying = widget.playingVoiceMessageId == messageId;

    return GestureDetector(
      onTap: () => widget.onPlayVoice(messageId, mediaUrl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.2)
                    : const Color(0xFF3B82F6).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 28,
                color: isMe ? Colors.white : const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                    22,
                    (i) => Container(
                      width: 3,
                      height: (i % 4 + 2) * 4.0,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.85)
                            : const Color(0xFF3B82F6).withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isPlaying && widget.voiceDuration.inSeconds > 0
                      ? '${widget.voicePosition.inMinutes}:${(widget.voicePosition.inSeconds % 60).toString().padLeft(2, '0')} / ${widget.voiceDuration.inMinutes}:${(widget.voiceDuration.inSeconds % 60).toString().padLeft(2, '0')}'
                      : formatVoiceDuration(duration),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.9)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
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

    late final IconData icon;
    if (title.toLowerCase().contains('video')) {
      icon = Icons.videocam_rounded;
    } else if (title.toLowerCase().contains('audio')) {
      icon = Icons.call_rounded;
    } else {
      icon = Icons.phone_rounded;
    }

    late final Color accent;
    if (isDuration) {
      accent = const Color(0xFF10B981);
    } else if (lowerDetail.contains('busy') ||
        lowerDetail.contains('rejected')) {
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
            color: isMe
                ? Colors.white.withValues(alpha: 0.18)
                : accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: isMe ? Colors.white : accent),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.18)
                        : accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.20)
                          : accent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isMe ? Colors.white.withValues(alpha: 0.95) : accent,
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
    final filePath =
        (message['mediaUrl'] as String?) ?? (message['filePath'] as String?);

    if (filePath == null || filePath.isEmpty) {
      return _imagePlaceholder(Icons.image_rounded, 'Image');
    }

    final isUrl =
        filePath.startsWith('http://') || filePath.startsWith('https://');

    return GestureDetector(
      onTap: () => widget.onViewImage(filePath),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: isUrl
            ? Image.network(
                filePath,
                width: 180,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(
                    Icons.broken_image_rounded, 'Failed to load'),
              )
            : Image.file(
                File(filePath),
                width: 180,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(
                    Icons.broken_image_rounded, 'Failed to load'),
              ),
      ),
    );
  }

  Widget _imagePlaceholder(IconData icon, String label) {
    return Container(
      width: 180,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.grey),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildVideoContent(Map<String, dynamic> message, bool isMe) {
    final videoUrl =
        (message['mediaUrl'] as String?) ?? (message['filePath'] as String?);

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
            Text('Video unavailable',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    return ChatVideoPlayer(videoUrl: videoUrl, isMe: isMe);
  }

  Widget _buildDocumentContent(Map<String, dynamic> message, bool isMe) {
    final fileName = message['fileName'] as String? ?? 'Document';
    final extension = fileName.split('.').last.toUpperCase();
    final filePath = message['filePath'] as String?;

    return GestureDetector(
      onTap: () => widget.onDownloadDoc(filePath, fileName),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.3)
                    : const Color(0xFF10B981).withValues(alpha: 0.3),
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
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.download_rounded,
                    size: 12,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : const Color(0xFF6B7280),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp(Map<String, dynamic> message, bool isMe) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message['timeDisplay'] != null)
          Text(
            message['timeDisplay'].toString(),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            message['isSeen'] == true
                ? Icons.done_all_rounded
                : Icons.done_rounded,
            size: 14,
            color: message['isSeen'] == true
                ? const Color(0xFF3B82F6)
                : Colors.grey.shade400,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared-post thumbnail fallback
// ---------------------------------------------------------------------------

/// Grey placeholder icon for a shared-post card with no usable image.
class _SharedThumbIcon extends StatelessWidget {
  const _SharedThumbIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child:
          const Icon(Icons.image_rounded, size: 24, color: Color(0xFF9CA3AF)),
    );
  }
}

/// Resolves the REAL first-media thumbnail for shared-post messages whose
/// embedded thumb is empty (old/corrupted payloads, video posts without a
/// server thumbnail): pulls the post by its slug and uses its media. Results
/// are memoized per-URL so scrolling doesn't refetch.
class _SharedThumbResolver extends StatefulWidget {
  final String postUrl;
  const _SharedThumbResolver({required this.postUrl});

  // url -> resolved thumb ('' = known to have none).
  static final Map<String, String> _cache = {};

  @override
  State<_SharedThumbResolver> createState() => _SharedThumbResolverState();
}

class _SharedThumbResolverState extends State<_SharedThumbResolver> {
  String? _thumb;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final url = widget.postUrl;
    final cached = _SharedThumbResolver._cache[url];
    if (cached != null) {
      _thumb = cached;
      return;
    }
    final match =
        RegExp(r'/business-network/posts/([^/?#]+)').firstMatch(url);
    if (match == null) {
      _SharedThumbResolver._cache[url] = '';
      return;
    }
    final post =
        await BusinessNetworkService.getPostByIdentifier(match.group(1)!);
    final resolved = post?.shareThumbUrl ?? '';
    _SharedThumbResolver._cache[url] = resolved;
    if (mounted && resolved.isNotEmpty) {
      setState(() => _thumb = resolved);
    } else {
      _thumb = resolved;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _thumb ?? '';
    if (t.isEmpty) return const _SharedThumbIcon();
    return Image.network(
      AppConfig.getAbsoluteUrl(t),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const _SharedThumbIcon(),
    );
  }
}
