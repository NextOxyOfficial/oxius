import 'package:flutter/material.dart';

/// The message-edit sheet, shared by 1:1 and group chats.
///
/// Replaces two diverging AlertDialogs. A bottom sheet fits the thumb zone,
/// slides with the keyboard instead of fighting it, and shows the ORIGINAL
/// message above the field — without it, mid-edit there is nothing to compare
/// against and no way to notice you wiped a word you meant to keep.
///
/// Returns the new text, or null when nothing should change (dismissed,
/// emptied, or text left identical) — the caller owns the API call and the
/// optimistic update, exactly as before.
class ChatEditMessageSheet {
  ChatEditMessageSheet._();

  static Future<String?> show(
    BuildContext context, {
    required String initialText,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // The chat screens historically rendered above the root navigator, so
      // every popup in them targets the LOCAL navigator (same reason the old
      // dialog did) — a root-navigator sheet could open underneath the chat.
      useRootNavigator: false,
      builder: (_) => _EditSheet(initialText: initialText),
    );
    final text = result?.trim() ?? '';
    if (text.isEmpty || text == initialText.trim()) return null;
    return text;
  }
}

class _EditSheet extends StatefulWidget {
  final String initialText;
  const _EditSheet({required this.initialText});

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  static const _ink = Color(0xFF111827);

  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  bool get _canSave {
    final t = _controller.text.trim();
    return t.isNotEmpty && t != widget.initialText.trim();
  }

  @override
  void initState() {
    super.initState();
    // Rebuild only for the save-button enabled state.
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Ride above the keyboard.
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'মেসেজ এডিট করুন',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'পাঠানোর ১০ মিনিটের মধ্যে এডিট করা যায়',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 14),

                // The original, pinned above the field for comparison.
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'আগের মেসেজ',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .3,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.initialText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _controller,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(
                      fontSize: 15, height: 1.45, color: _ink),
                  decoration: InputDecoration(
                    hintText: 'নতুন মেসেজ লিখুন…',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.all(13),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: _ink, width: 1.3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        foregroundColor: Colors.grey.shade600,
                      ),
                      child: const Text(
                        'বাতিল',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _canSave
                            ? () =>
                                Navigator.pop(context, _controller.text)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _ink,
                          disabledBackgroundColor:
                              const Color(0xFFE5E7EB),
                          disabledForegroundColor: Colors.grey.shade500,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: const Text(
                          'সেভ করুন',
                          style: TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
