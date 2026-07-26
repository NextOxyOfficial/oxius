import 'package:flutter/material.dart';

/// The emoji set the server accepts (ALLOWED_EMOJI in adsyconnect/reactions.py).
/// Keep the two in sync — anything else is rejected with 400.
const List<String> kChatReactions = [
  '👍', '❤️', '😂', '😮', '😢', '🙏', '🔥', '😡',
];

/// Messenger-style quick-reaction row shown when a bubble is long-pressed.
///
/// Sits above the message-options sheet so a long press offers BOTH: react
/// with one tap, or fall through to reply/copy/delete.
class MessageReactionBar extends StatelessWidget {
  /// Emoji the current user already picked, so it can be highlighted and
  /// tapping it again reads as "remove".
  final String? selected;
  final ValueChanged<String> onPick;

  const MessageReactionBar({super.key, this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final e in kChatReactions)
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onPick(e),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: e == selected
                      ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text(e, style: const TextStyle(fontSize: 24)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Reaction chips rendered under a bubble, e.g.  👍 3   ❤️ 1
class MessageReactionChips extends StatelessWidget {
  /// Raw `reactions` list from the API:
  /// [{emoji, count, reacted_by_me}]
  final List<dynamic> reactions;
  final bool alignRight;
  final VoidCallback? onTap;

  const MessageReactionChips({
    super.key,
    required this.reactions,
    this.alignRight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(
        top: 2,
        left: alignRight ? 0 : 6,
        right: alignRight ? 6 : 0,
        bottom: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          for (final r in reactions)
            GestureDetector(
              onTap: onTap,
              // Bare emoji — no pill background/border. The chip's tinted
              // bubble competed with the message bubble right above it.
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${(r as Map)['emoji'] ?? ''}',
                        style: const TextStyle(fontSize: 15)),
                    if (((r['count'] ?? 1) as num) > 1) ...[
                      const SizedBox(width: 2),
                      Text(
                        '${r['count']}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
