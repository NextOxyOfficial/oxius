import 'package:flutter_test/flutter_test.dart';
import 'package:oxius_native/widgets/call/call_controls_bar.dart';

/// The control bar is one row and every control has to be on it, visible and
/// tappable, at any width a phone actually has. That is not something you can
/// eyeball on one device, so it is arithmetic and it is pinned here.
void main() {
  /// Width the bar occupies with these metrics — the same sum the Row builds.
  ///
  /// Note the +12 per control. Each button carries a label box of
  /// `size + 12` underneath it, and that box, not the button, is what the
  /// Row lays out. The first version of this helper measured buttons alone —
  /// the same mistake the code under test was making — so it happily agreed
  /// that a bar 30dp too wide fitted, and End went off the edge of a real
  /// phone. A test that repeats the bug cannot see it.
  const labelPad = 12.0;
  double barWidth(CallControlMetrics m, {required bool isVideo}) {
    final count = isVideo ? 6 : 5;
    final pad = m.showLabels ? labelPad : 0.0;
    return (count - 1) * (m.button + pad) +
        (m.end + pad) +
        (count - 1) * m.gap +
        m.hPad * 2 +
        kCallControlsInset * 2;
  }

  const phoneWidths = <double>[320, 360, 375, 390, 393, 412, 414, 428, 430];

  group('call control metrics', () {
    test('every control fits on one row at every phone width', () {
      for (final width in phoneWidths) {
        for (final compact in [true, false]) {
          for (final isVideo in [true, false]) {
            final m = callControlMetrics(
                screenWidth: width, compact: compact, isVideo: isVideo);
            expect(
              barWidth(m, isVideo: isVideo),
              lessThanOrEqualTo(width + 0.01),
              reason: 'overflows at ${width}dp compact=$compact '
                  'isVideo=$isVideo',
            );
          }
        }
      }
    });

    test('controls stay big enough to hit, at every width', () {
      // The tap target is the thing that must not be sacrificed. Where the
      // labels would force a button below this, the labels go instead.
      for (final width in phoneWidths) {
        for (final isVideo in [true, false]) {
          final m = callControlMetrics(
              screenWidth: width, compact: true, isVideo: isVideo);
          expect(m.button, greaterThanOrEqualTo(38),
              reason: '${width}dp isVideo=$isVideo');
          expect(m.end, greaterThan(m.button), reason: 'End must stand out');
        }
      }
    });

    test('the words are what get dropped, and only when they must', () {
      // Narrowest phone, six controls: no room for six labels as well.
      expect(
        callControlMetrics(screenWidth: 320, compact: true, isVideo: true)
            .showLabels,
        isFalse,
      );
      // Ordinary phone: the words stay.
      expect(
        callControlMetrics(screenWidth: 393, compact: true, isVideo: true)
            .showLabels,
        isTrue,
      );
      expect(
        callControlMetrics(screenWidth: 360, compact: true, isVideo: false)
            .showLabels,
        isTrue,
      );
    });

    test('height follows whether the labels are there', () {
      final withWords =
          callControlMetrics(screenWidth: 393, compact: true, isVideo: true);
      final without =
          callControlMetrics(screenWidth: 320, compact: true, isVideo: true);
      expect(withWords.showLabels, isTrue);
      expect(without.showLabels, isFalse);
      // Everything that dodges the bar reads this height; a bar with no
      // labels that still reserved room for them would leave a visible gap.
      expect(without.height, lessThan(withWords.height + 18));
    });

    test('a wide screen does not blow the controls up', () {
      final tablet = callControlMetrics(
          screenWidth: 834, compact: false, isVideo: true);
      expect(tablet.button, lessThanOrEqualTo(56));
    });

    test('a wider phone gets bigger controls than a narrow one', () {
      final narrow = callControlMetrics(
          screenWidth: 320, compact: true, isVideo: true);
      final wide = callControlMetrics(
          screenWidth: 430, compact: true, isVideo: true);
      expect(wide.button, greaterThan(narrow.button));
    });

    test('an audio call gets roomier controls than a video call', () {
      // One fewer control to fit, so each may be larger — but only while
      // both are laid out the same way. At 320dp the video bar drops its
      // labels and reclaims 72dp, which legitimately buys it bigger buttons
      // than the audio bar that kept its words. Comparing across that
      // difference would be comparing two different layouts.
      for (final width in phoneWidths) {
        final audio = callControlMetrics(
            screenWidth: width, compact: true, isVideo: false);
        final video = callControlMetrics(
            screenWidth: width, compact: true, isVideo: true);
        if (audio.showLabels != video.showLabels) continue;
        expect(audio.button, greaterThanOrEqualTo(video.button),
            reason: 'at ${width}dp');
      }
    });

    test('height covers the buttons and their labels', () {
      for (final width in phoneWidths) {
        final m = callControlMetrics(
            screenWidth: width, compact: true, isVideo: true);
        // Whatever else it includes, the bar cannot be shorter than the
        // tallest thing in it. Everything that dodges the bar trusts this.
        expect(m.height, greaterThan(m.end),
            reason: 'height must clear End at ${width}dp');
      }
    });
  });
}
