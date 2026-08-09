import 'package:flutter_test/flutter_test.dart';
import 'package:oxius_native/screens/call_screen.dart';

/// The control bar must never overflow and never hide a control behind a
/// scroll gesture — End is in that bar, and a control you cannot see is a
/// control you cannot press mid-call. These pin the wrap decision to real
/// device widths rather than to whatever the one test phone happens to be.
void main() {
  /// Same arithmetic the widget lays out with, so a row that "fits"
  /// according to the decision really does fit.
  double neededWidth({required bool compact, required bool isVideo}) {
    final count = isVideo ? 6 : 5;
    final btn = compact ? 52.0 : 56.0;
    final end = compact ? 62.0 : 68.0;
    final gap = compact ? 8.0 : 10.0;
    final hPad = compact ? 10.0 : 14.0;
    const inset = 12.0;
    return (count - 1) * btn + end + (count - 1) * gap + hPad * 2 + inset * 2;
  }

  group('call controls wrap decision', () {
    test('a video call on a narrow phone wraps', () {
      // 360dp covers most budget Androids, and six controls do not fit.
      expect(
        callControlsNeedTwoRows(
            screenWidth: 360, compact: true, isVideo: true),
        isTrue,
      );
    });

    test('an audio call on the same phone does not', () {
      expect(
        callControlsNeedTwoRows(
            screenWidth: 360, compact: true, isVideo: false),
        isFalse,
      );
    });

    test('even the widest phone wraps a video call', () {
      // 430dp is iPhone Pro Max class, and six controls want 450. So a video
      // call is two rows on every phone there is — which is the right
      // outcome: six of these across a phone was always cramped, and the
      // alternative was the scroller that hid End off the edge. A tablet
      // still gets one row, so the wrap is genuinely width-driven.
      expect(
        callControlsNeedTwoRows(
            screenWidth: 430, compact: false, isVideo: true),
        isTrue,
      );
      expect(
        callControlsNeedTwoRows(
            screenWidth: 430, compact: false, isVideo: false),
        isFalse,
        reason: 'an audio call has five controls and still fits',
      );
    });

    test('a tablet never wraps', () {
      for (final isVideo in [true, false]) {
        expect(
          callControlsNeedTwoRows(
              screenWidth: 834, compact: false, isVideo: isVideo),
          isFalse,
          reason: 'isVideo=$isVideo',
        );
      }
    });

    test('the decision is exactly the fit, with no gap and no overlap', () {
      for (final compact in [true, false]) {
        for (final isVideo in [true, false]) {
          final needed = neededWidth(compact: compact, isVideo: isVideo);
          final label = 'compact=$compact isVideo=$isVideo';

          // Exactly wide enough: one row, and it fits.
          expect(
            callControlsNeedTwoRows(
                screenWidth: needed, compact: compact, isVideo: isVideo),
            isFalse,
            reason: '$label should fit at exactly $needed',
          );
          // A hair narrower: wraps rather than overflowing.
          expect(
            callControlsNeedTwoRows(
                screenWidth: needed - 1, compact: compact, isVideo: isVideo),
            isTrue,
            reason: '$label should wrap below $needed',
          );
        }
      }
    });

    test('every real phone width is either a clean fit or two rows', () {
      // No width may be a single row that does not fit — that is the
      // overflow the horizontal scroller used to paper over.
      const widths = <double>[320, 360, 375, 390, 393, 412, 414, 428, 430];
      for (final width in widths) {
        for (final compact in [true, false]) {
          for (final isVideo in [true, false]) {
            final wraps = callControlsNeedTwoRows(
                screenWidth: width, compact: compact, isVideo: isVideo);
            if (!wraps) {
              expect(
                neededWidth(compact: compact, isVideo: isVideo),
                lessThanOrEqualTo(width),
                reason: 'single row at ${width}dp compact=$compact '
                    'isVideo=$isVideo would overflow',
              );
            }
          }
        }
      }
    });
  });
}
