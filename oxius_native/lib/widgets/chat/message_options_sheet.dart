import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common/adsy_toast.dart';

/// Long-press options for a chat message — ONE implementation shared by the
/// 1:1 interface and group chats so the sheet never drifts between the two.
///
/// Concept design: white rounded sheet with the pressed message previewed on
/// top, then clean label rows with trailing icons (Copy / Reply / Edit /
/// Delete). Options render only when their callback is provided (and the
/// message allows them).
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
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
              margin: const EdgeInsets.only(top: 12, bottom: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            // Pressed-message preview bubble (text messages only).
            if (canCopy)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            if (canCopy)
              _OptionRow(
                sheetContext: sheetContext,
                label: 'Copy',
                icon: Icons.copy_rounded,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text));
                  AdsyToast.success(context, 'Message copied');
                },
              ),
            if (canReply)
              _OptionRow(
                sheetContext: sheetContext,
                label: 'Reply',
                icon: Icons.reply_rounded,
                onTap: onReply,
              ),
            if (canEdit)
              _OptionRow(
                sheetContext: sheetContext,
                label: 'Edit',
                icon: Icons.edit_outlined,
                onTap: onEdit,
              ),
            if (canDelete)
              _OptionRow(
                sheetContext: sheetContext,
                label: 'Delete',
                icon: Icons.delete_outline_rounded,
                destructive: true,
                isLast: true,
                onTap: onDelete,
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

/// Concept-style row: label on the left, small trailing icon on the right,
/// hairline divider between rows.
class _OptionRow extends StatelessWidget {
  final BuildContext sheetContext;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
  final bool isLast;

  const _OptionRow({
    required this.sheetContext,
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? const Color(0xFFDC2626) : const Color(0xFF111827);
    return InkWell(
      onTap: () {
        Navigator.pop(sheetContext);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(icon, size: 18, color: destructive ? color : const Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }
}
