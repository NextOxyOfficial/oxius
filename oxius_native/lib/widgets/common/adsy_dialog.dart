import 'package:flutter/material.dart';

/// THE one confirm/alert dialog for the whole app — matches the AdsySheet /
/// AdsyConnect design language: white rounded card, ink title, slate body, a
/// gray "Cancel" pill and a filled action button (red when destructive).
///
/// Use [AdsyDialog.confirm] everywhere instead of hand-rolled AlertDialogs so
/// confirmations never drift between screens.
class AdsyDialog {
  AdsyDialog._();

  static const _ink = Color(0xFF111827);
  static const _slate = Color(0xFF64748B);

  /// Shows a confirm dialog. Resolves to true if the action was confirmed,
  /// false/null otherwise.
  ///
  /// [destructive] paints the action red (delete/remove/block). [icon] shows a
  /// tinted round glyph above the title.
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool destructive = false,
    IconData? icon,
    Color? accent,
  }) {
    final actionColor =
        accent ?? (destructive ? const Color(0xFFDC2626) : const Color(0xFF2563EB));
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (icon != null) ...[
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: actionColor.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 26, color: actionColor),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                title,
                textAlign: icon != null ? TextAlign.center : TextAlign.start,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -0.3,
                ),
              ),
              if (message != null && message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: icon != null ? TextAlign.center : TextAlign.start,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: _slate,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: cancelLabel,
                      onTap: () => Navigator.pop(ctx, false),
                      background: const Color(0xFFF1F5F9),
                      foreground: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DialogButton(
                      label: confirmLabel,
                      onTap: () => Navigator.pop(ctx, true),
                      background: actionColor,
                      foreground: Colors.white,
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

  /// A single-button acknowledgement dialog (no cancel).
  static Future<void> alert(
    BuildContext context, {
    required String title,
    String? message,
    String buttonLabel = 'OK',
    IconData? icon,
    Color? accent,
  }) {
    final actionColor = accent ?? const Color(0xFF2563EB);
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (icon != null) ...[
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: actionColor.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 26, color: actionColor),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -0.3,
                ),
              ),
              if (message != null && message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: _slate,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _DialogButton(
                label: buttonLabel,
                onTap: () => Navigator.pop(ctx),
                background: actionColor,
                foreground: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;

  const _DialogButton({
    required this.label,
    required this.onTap,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 46,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
