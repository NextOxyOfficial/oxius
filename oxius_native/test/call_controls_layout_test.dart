import 'package:flutter_test/flutter_test.dart';
import 'package:oxius_native/widgets/call/call_controls_bar.dart';

/// The control bar is one row and every control has to be on it, visible and
/// tappable, at any width a phone actually has. That is not something you can
/// eyeball on one device, so it is arithmetic and it is pinned here.
void main() {
  /// Width the bar occupies with these metrics — the same sum the Row builds.
  double barWidth(CallControlMetrics m, {required bool isVideo}) {
    final count = isVideo ? 6 : 5;
    return (count - 1) * m.button +
        m.end +
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

    test('controls stay big enough to hit', () {
      // Six controls on the narrowest phone is the tightest case there is.
      final m = callControlMetrics(
          screenWidth: 320, compact: true, isVideo: true);
      expect(m.button, greaterThanOrEqualTo(36));
      expect(m.end, greaterThan(m.button), reason: 'End must stand out');
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
      // One fewer control to fit, so each may be larger.
      for (final width in phoneWidths) {
        final audio = callControlMetrics(
            screenWidth: width, compact: true, isVideo: false);
        final video = callControlMetrics(
            screenWidth: width, compact: true, isVideo: true);
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
