import 'package:flutter/material.dart';
import 'package:oxius_native/utils/app_fonts.dart';

/// Toast type → drives the accent colour and leading icon.
enum AdsyToastType { success, error, info, warning }

/// AdsyToast — one consistent, professional in-app toast/snackbar used across
/// the whole app. Floating rounded card, leading icon chip, clean message.
///
/// Use instead of hand-rolled `ScaffoldMessenger...showSnackBar(SnackBar(...))`
/// so every screen looks identical. `AdsyToast.error` also sanitises the
/// message so raw backend/exception text is never shown to the user.
class AdsyToast {
  AdsyToast._();

  static void success(BuildContext context, String message) =>
      _show(context, message, AdsyToastType.success);

  static void info(BuildContext context, String message) =>
      _show(context, message, AdsyToastType.info);

  static void warning(BuildContext context, String message) =>
      _show(context, message, AdsyToastType.warning);

  /// Accepts either a friendly String or a raw error/Exception object; the
  /// message is sanitised so technical details never leak to the UI.
  static void error(BuildContext context, Object? message) =>
      _show(context, sanitize(message), AdsyToastType.error);

  static void _show(BuildContext context, String message, AdsyToastType type) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final (Color accent, Color tint, IconData icon) = switch (type) {
      AdsyToastType.success => (
          const Color(0xFF059669),
          const Color(0xFFECFDF5),
          Icons.check_circle_rounded
        ),
      AdsyToastType.error => (
          const Color(0xFFDC2626),
          const Color(0xFFFEF2F2),
          Icons.error_rounded
        ),
      AdsyToastType.warning => (
          const Color(0xFFD97706),
          const Color(0xFFFFFBEB),
          Icons.warning_rounded
        ),
      AdsyToastType.info => (
          const Color(0xFF2563EB),
          const Color(0xFFEFF6FF),
          Icons.info_rounded
        ),
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white,
          elevation: 0,
          duration: const Duration(seconds: 3),
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                  child: Icon(icon, color: accent, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.roboto(
                      fontSize: 13.5,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  /// Clean an error for display.
  ///
  /// IMPORTANT: human-readable backend reason messages (e.g. "KYC যাচাই করুন
  /// তবেই গিগ পোস্ট করতে পারবেন", "ব্যালেন্স যথেষ্ট নয়") MUST pass through
  /// unchanged so the user sees the specific reason. Only genuine raw technical
  /// dumps (Dart exceptions, JSON, HTML, stack traces, URLs) are replaced with a
  /// generic message.
  static String sanitize(Object? raw) {
    const generic = 'কিছু একটা সমস্যা হয়েছে, আবার চেষ্টা করুন';
    if (raw == null) return generic;
    var s = raw.toString().trim();
    if (s.isEmpty) return generic;

    // Drop a leading exception/error type label only (keeps the human message).
    s = s
        .replaceFirst(
          RegExp(
              r'^(Exception|_?TypeError|Error|FormatException|SocketException|HttpException|TimeoutException|DioError|DioException|HandshakeException|ClientException|StateError|RangeError|ArgumentError)\s*:?\s*',
              caseSensitive: false),
          '',
        )
        .trim();
    if (s.isEmpty) return generic;

    // Only fall back to generic when the text STILL looks like a raw technical
    // dump — NOT for ordinary backend reason sentences (which are kept as-is).
    final technical = RegExp(
      r'''(\{\s*["']|["']\s*:\s*["']|<[a-zA-Z/!]|https?://|#\d+\s+\S+:\d+|\bstack\s*trace\b|\bstatus\s*code\b|\bSocketException\b|\bHandshakeException\b|\berrno\b|\bNoSuchMethod\b)''',
      caseSensitive: false,
    );
    if (technical.hasMatch(s) || s.length > 300) return generic;

    return s;
  }
}
