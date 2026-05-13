import 'dart:convert';
import 'package:flutter/material.dart';

/// The bottom input bar for the AdsyConnect chat screen.
///
/// Manages three modes:
///  1. **Blocked** — shows a "blocked" banner with optional Unblock button
///  2. **Recording** — shows recording indicator, waveform + send/cancel
///  3. **Normal** — attachment + text field + voice/send button
///
/// All state is owned by the parent; this widget is purely presentational.
class ChatMessageInput extends StatelessWidget {
  // Controllers owned by parent
  final TextEditingController messageController;
  final FocusNode messageFocusNode;

  // Current display state
  final bool isRecording;
  final bool isChatBlocked;
  final bool blockedByMe;
  final bool isTyping;
  final bool isUploadingAttachment;
  final bool isCompressingImages;

  // Reply preview (null = no active reply)
  final String? replyFromName;
  final String? replyPreviewText;

  // Image preview
  final List<String> compressedImages;

  // Recording duration for display
  final Duration recordDuration;

  // Callbacks
  final VoidCallback onSend;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onCancelRecording;
  final VoidCallback onUnblock;
  final VoidCallback onCancelReply;
  final VoidCallback onShowAttachmentOptions;
  final VoidCallback onSendImages;
  final VoidCallback onCancelImagePreview;
  final void Function(int index) onRemoveImage;

  const ChatMessageInput({
    super.key,
    required this.messageController,
    required this.messageFocusNode,
    required this.isRecording,
    required this.isChatBlocked,
    required this.blockedByMe,
    required this.isTyping,
    required this.isUploadingAttachment,
    this.isCompressingImages = false,
    this.replyFromName,
    this.replyPreviewText,
    required this.compressedImages,
    required this.recordDuration,
    required this.onSend,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancelRecording,
    required this.onUnblock,
    required this.onCancelReply,
    required this.onShowAttachmentOptions,
    required this.onSendImages,
    required this.onCancelImagePreview,
    required this.onRemoveImage,
  });

  static String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (isRecording) return _buildRecordingUI();
    if (isChatBlocked) return _buildBlockedBanner(context);
    return _buildNormalInput(context);
  }

  // -------------------------------------------------------------------------
  // Blocked banner
  // -------------------------------------------------------------------------

  Widget _buildBlockedBanner(BuildContext context) {
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
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (blockedByMe
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444))
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.block_rounded,
                size: 18,
                color: blockedByMe
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blockedByMe
                        ? 'You blocked this user'
                        : "You can't send messages",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    blockedByMe
                        ? 'Unblock to send messages again.'
                        : 'Messaging is disabled in this conversation.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (blockedByMe)
              TextButton(
                onPressed: onUnblock,
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
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Recording UI
  // -------------------------------------------------------------------------

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
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 22),
              color: const Color(0xFFEF4444),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onCancelRecording,
            ),
            const SizedBox(width: 12),
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _fmt(recordDuration),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 30,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    20,
                    (i) => Container(
                      width: 3,
                      height: (i % 3 + 1) * 8.0,
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
                onPressed: onStopRecording,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Normal input
  // -------------------------------------------------------------------------

  Widget _buildNormalInput(BuildContext context) {
    final hasImages = compressedImages.isNotEmpty;
    final hasReply = replyFromName != null && replyPreviewText != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- Image preview strip ---
        if (hasImages) _buildImagePreview(),

        // --- Compressing progress ---
        if (isCompressingImages)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Uploading...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8B5CF6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        // --- Uploading progress ---
        if (isUploadingAttachment && !isCompressingImages)
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Uploading...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        // --- Reply preview ---
        if (hasReply) _buildReplyPreview(),

        // --- Text row ---
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.attach_file_rounded, size: 22),
                    color: const Color(0xFF3B82F6),
                    padding: EdgeInsets.zero,
                    onPressed: onShowAttachmentOptions,
                  ),
                ),
                const SizedBox(width: 8),
                // Text field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: messageController,
                      focusNode: messageFocusNode,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1F2937),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send / Mic button
                if (isTyping)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, size: 22),
                      color: Colors.white,
                      padding: EdgeInsets.zero,
                      onPressed: onSend,
                    ),
                  )
                else
                  GestureDetector(
                    onLongPress: onStartRecording,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        size: 22,
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

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${compressedImages.length}/8 photos selected',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3B82F6),
                ),
              ),
              TextButton.icon(
                onPressed: isUploadingAttachment ? null : onSendImages,
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Send'),
                style: TextButton.styleFrom(
                  foregroundColor: isUploadingAttachment
                      ? Colors.grey
                      : const Color(0xFF3B82F6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: compressedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(
                              compressedImages[index].split(',').last),
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
                        onTap: () => onRemoveImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
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
                onTap: onCancelImagePreview,
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
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE5E7EB).withOpacity(0.5),
            width: 1,
          ),
          left: const BorderSide(color: Color(0xFF3B82F6), width: 3),
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
                  replyFromName!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  replyPreviewText!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCancelReply,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}
