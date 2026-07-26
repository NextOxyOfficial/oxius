import 'package:flutter/widgets.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Keeps a chat pinned to the newest message.
///
/// The obvious implementation — one `addPostFrameCallback` that jumps to
/// `maxScrollExtent` — is what made both chats stop short. Chat rows are laid
/// out lazily and their height is not final on that first frame: text wraps to
/// a second line, images and link previews resolve, the reply bar collapses,
/// and the keyboard animates the viewport. Every one of those grows the extent
/// *after* the jump has already happened, so the list settles a few hundred
/// pixels above the newest message and the user has to drag down by hand.
///
/// So instead of trusting a single frame, these helpers re-apply the
/// correction over the next few frames and stop as soon as the position holds
/// steady — cheap when nothing moves, and self-correcting when it does.
class ChatAutoScroll {
  ChatAutoScroll._();

  /// How many frames to keep correcting for. ~8 frames covers a keyboard
  /// animation and a late image layout without running visibly long.
  static const int _maxFrames = 8;

  /// Treat anything within this many pixels of the end as "at the bottom".
  static const double _epsilon = 4.0;

  /// Pins a plain [ScrollController] list (bottom == maxScrollExtent) to the
  /// end. Used by the group chat.
  ///
  /// Pass [animate] for a smooth glide on the first hop; corrections are always
  /// instant so they don't fight the animation.
  static void stickToBottom(
    ScrollController controller, {
    bool animate = true,
  }) {
    var frames = 0;
    var settled = 0;

    void step() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!controller.hasClients) return;
        final pos = controller.position;
        final target = pos.maxScrollExtent;
        final atEnd = (target - pos.pixels).abs() <= _epsilon;

        if (atEnd) {
          // Hold for two consecutive frames before trusting it — a single
          // settled frame can still be followed by a late image layout.
          if (++settled >= 2 || ++frames >= _maxFrames) return;
          step();
          return;
        }

        settled = 0;
        if (animate && frames == 0) {
          controller.animateTo(
            target,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        } else {
          controller.jumpTo(target);
        }

        if (++frames < _maxFrames) step();
      });
    }

    step();
  }

  /// Pins a `reverse: true` [ScrollablePositionedList] to its newest row
  /// (index 0). Used by the 1:1 chat.
  ///
  /// Re-issues the scroll while index 0 is not flush with the viewport edge,
  /// which is what happens when the row grows a line or the keyboard opens
  /// mid-animation.
  static void stickToNewest(
    ItemScrollController controller,
    ItemPositionsListener positions, {
    bool animate = true,
  }) {
    var frames = 0;
    var settled = 0;

    void step() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!controller.isAttached) {
          // The list hasn't mounted yet (first open). Keep trying briefly
          // rather than dropping the request, which used to leave a freshly
          // opened chat parked mid-history.
          if (++frames < _maxFrames) step();
          return;
        }

        final visible = positions.itemPositions.value;
        final newest = visible.where((p) => p.index == 0);
        // In a reversed list the leading edge is the bottom of the viewport,
        // so index 0 is fully in view once its leading edge is at/below 0.
        final atEnd = newest.isNotEmpty && newest.first.itemLeadingEdge >= -0.001;

        if (atEnd) {
          if (++settled >= 2 || ++frames >= _maxFrames) return;
          step();
          return;
        }

        settled = 0;
        if (animate && frames == 0) {
          controller.scrollTo(
            index: 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        } else {
          controller.jumpTo(index: 0);
        }

        if (++frames < _maxFrames) step();
      });
    }

    step();
  }
}
