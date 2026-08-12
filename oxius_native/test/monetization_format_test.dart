import 'package:flutter_test/flutter_test.dart';
import 'package:oxius_native/screens/business_network/monetization_sections.dart';

/// These four functions decide what a creator reads as their earnings, so a
/// bug here is a wrong number in front of the person being paid. They are pure,
/// so there is no excuse for not pinning them down.
void main() {
  group('monTaka', () {
    test('whole amounts drop the paisa', () {
      expect(monTaka(0), '৳০');
      expect(monTaka(1234), '৳১,২৩৪');
      expect(monTaka('4142.00'), '৳৪,১৪২');
    });

    test('paisa survive, always two digits', () {
      expect(monTaka('3928.57'), '৳৩,৯২৮.৫৭');
      expect(monTaka('100.50'), '৳১০০.৫০');
      expect(monTaka('0.05'), '৳০.০৫');
      expect(monTaka('0.10'), '৳০.১০');
    });

    test('float drift never prints three paisa digits', () {
      // What summing a column of doubles actually produces.
      expect(monTaka(99.99999999), '৳১০০');
      expect(monTaka(0.1 + 0.2), '৳০.৩০');
      expect(monTaka(147.96000000000001), '৳১৪৭.৯৬');
    });

    test('Bangladeshi grouping, not thousands', () {
      expect(monTaka(100000), '৳১,০০,০০০');
      expect(monTaka(1234567), '৳১২,৩৪,৫৬৭');
    });

    test('missing values read as zero rather than crashing', () {
      expect(monTaka(null), '৳০');
      expect(monTaka(''), '৳০');
      expect(monTaka('not a number'), '৳০');
    });
  });

  group('monCount', () {
    test('groups the Bangladeshi way', () {
      expect(monCount(0), '০');
      expect(monCount(999), '৯৯৯');
      expect(monCount(1000), '১,০০০');
      expect(monCount(100000), '১,০০,০০০');
      expect(monCount(12345678), '১,২৩,৪৫,৬৭৮');
    });

    test('accepts the strings the API sends', () {
      expect(monCount('4200'), '৪,২০০');
      expect(monCount(null), '০');
    });
  });

  group('monPeriodLabel', () {
    test('turns a period into a Bangla month', () {
      expect(monPeriodLabel('2026-08'), 'আগস্ট ২০২৬');
      expect(monPeriodLabel('2026-01'), 'জানুয়ারি ২০২৬');
      expect(monPeriodLabel('2025-12'), 'ডিসেম্বর ২০২৫');
    });

    test('passes anything unparseable straight through', () {
      expect(monPeriodLabel(''), '');
      expect(monPeriodLabel(null), '');
      expect(monPeriodLabel('2026-13'), '2026-13');
    });
  });

  group('monDateLabel', () {
    test('reads the API DD-MM-YYYY, not MM-DD-YYYY', () {
      expect(monDateLabel('07-09-2026'), '৭ সেপ্টেম্বর ২০২৬');
      expect(monDateLabel('31-12-2025'), '৩১ ডিসেম্বর ২০২৫');
    });

    test('degrades to Bangla digits when the shape is wrong', () {
      expect(monDateLabel(''), '');
      expect(monDateLabel(null), '');
      expect(monDateLabel('2026-09-07'), '2026-09-07'.replaceAllMapped(
          RegExp(r'\d'), (m) => bnDigits(m[0]!)));
    });
  });

  group('monStatusOf', () {
    test('held and forfeited carry an explanation, healthy months do not', () {
      expect(monStatusOf('held').note, isNotNull);
      expect(monStatusOf('forfeited').note, isNotNull);
      expect(monStatusOf('accruing').note, isNull);
      expect(monStatusOf('paid').note, isNull);
      expect(monStatusOf('cleared').note, isNull);
    });

    test('an unknown status falls back to accruing rather than blank', () {
      expect(monStatusOf('').label, monStatusOf('accruing').label);
      expect(monStatusOf('something_new').label, isNotEmpty);
    });
  });
}
