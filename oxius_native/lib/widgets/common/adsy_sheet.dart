import 'package:flutter/material.dart';

/// The app's ONE bottom-sheet design language — taken from the AdsyConnect
/// "New Chat" sheet: white rounded-24 surface, slim drag handle, action rows
/// with an icon in a soft bordered box + bold title + muted subtitle, and a
/// soft gray Cancel pill. Use [AdsySheet.show] + [AdsySheetAction] instead of
/// hand-rolling sheets so every sheet in the app looks the same.
class AdsySheet {
  AdsySheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required List<Widget> children,
    bool showCancel = true,
    String cancelLabel = 'Cancel',
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: isScrollControlled,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ...children,
              if (showCancel) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      cancelLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One action row inside an [AdsySheet]: icon box + title (+ subtitle).
/// Pops the sheet, then runs [onTap].
class AdsySheetAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool destructive;
  final VoidCallback onTap;

  const AdsySheetAction({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.destructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
        destructive ? const Color(0xFFDC2626) : const Color(0xFF334155);
    final titleColor =
        destructive ? const Color(0xFFDC2626) : const Color(0xFF111827);
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: destructive
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: destructive
                      ? const Color(0xFFFECACA)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
