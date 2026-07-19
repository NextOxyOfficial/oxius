import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common/adsy_toast.dart';

/// Long-press options for a chat message — ONE implementation shared by the
/// 1:1 interface and group chats so the sheet never drifts between the two.
///
/// Options render only when their callback is provided (and the message
/// allows them): Reply, Copy text (built in), Edit, Delete.
Future<void> showChatMessageOptions(
  BuildContext context, {
  required Map<String, dynamic> message,
  VoidCallback? onReply,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
}) {
  final messageType = message['type']?.toString() ?? 'text';
  final isDeleted = message['isDeleted'] == true;
  final isTextLike = messageType == 'text';
  final text = (message['message'] ?? '').toString();
  final canCopy = isTextLike && !isDeleted && text.trim().isNotEmpty;
  final canReply = onReply != null && !isDeleted;
  final canEdit = onEdit != null && isTextLike && !isDeleted;
  final canDelete = onDelete != null && !isDeleted;

  if (!canReply && !canCopy && !canEdit && !canDelete) {
    return Future.value();
  }

  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (sheetContext) => Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
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
              _OptionTile(
                sheetContext: sheetContext,
                icon: Icons.reply_rounded,
                iconColor: const Color(0xFF10B981),
                label: 'Reply',
                onTap: onReply,
              ),
            if (canCopy)
              _OptionTile(
                sheetContext: sheetContext,
                icon: Icons.copy_rounded,
                iconColor: const Color(0xFF6366F1),
                label: 'Copy text',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text));
                  AdsyToast.success(context, 'Message copied');
                },
              ),
            if (canEdit)
              _OptionTile(
                sheetContext: sheetContext,
                icon: Icons.edit_rounded,
                iconColor: const Color(0xFF3B82F6),
                label: 'Edit Message',
                onTap: onEdit,
              ),
            if (canDelete)
              _OptionTile(
                sheetContext: sheetContext,
                icon: Icons.delete_outline_rounded,
                iconColor: const Color(0xFFEF4444),
                label: 'Delete Message',
                destructive: true,
                onTap: onDelete,
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
  );
}

class _OptionTile extends StatelessWidget {
  final BuildContext sheetContext;
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _OptionTile({
    required this.sheetContext,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: ListTile(
        minVerticalPadding: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tileColor: Colors.white.withValues(alpha: 0.78),
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
}
