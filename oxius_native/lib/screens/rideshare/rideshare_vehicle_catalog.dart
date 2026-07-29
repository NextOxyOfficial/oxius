import 'package:flutter/material.dart';

/// The three ride classes, in one place.
///
/// Every surface that shows a vehicle — the selector sheet, the driver card,
/// the receipt, the map marker — used to spell its own emoji and its own
/// label, so "CNG" and "🛺" and "cng" drifted apart across files. The server
/// keys stay exactly as they were (`bike`, `car`, `cng`); only what the rider
/// SEES lives here, which is why renaming CNG to "Auto" is a one-line change
/// and not a hunt.
class RideVehicle {
  /// The API's vehicle_type. Never shown to a rider.
  final String key;

  /// What the rider reads.
  final String label;

  /// Riders it carries — the "4 Person" line in the design.
  final String capacity;

  /// Bundled artwork. Null falls back to [emoji], which is what Auto does
  /// until its illustration exists.
  final String? image;
  final String emoji;

  const RideVehicle({
    required this.key,
    required this.label,
    required this.capacity,
    required this.emoji,
    this.image,
  });

  /// The picture for a card, at [size]. Uses the illustration when there is
  /// one and degrades to the emoji rather than an empty box.
  Widget artwork({double size = 56}) {
    final path = image;
    if (path == null) {
      return SizedBox(
        height: size,
        child: Center(
          child: Text(emoji, style: TextStyle(fontSize: size * 0.62)),
        ),
      );
    }
    return Image.asset(
      path,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => SizedBox(
        height: size,
        child: Center(
          child: Text(emoji, style: TextStyle(fontSize: size * 0.62)),
        ),
      ),
    );
  }

  static const bike = RideVehicle(
    key: 'bike',
    label: 'Bike',
    capacity: '১ জন',
    emoji: '🏍',
    image: 'assets/images/vehicles/bike.png',
  );

  static const car = RideVehicle(
    key: 'car',
    label: 'Car',
    capacity: '৪ জন',
    emoji: '🚗',
    image: 'assets/images/vehicles/car.png',
  );

  /// Formerly "CNG". The server key is untouched — only the rider-facing
  /// name changed, so existing rides and driver vehicles keep working.
  static const auto = RideVehicle(
    key: 'cng',
    label: 'Auto',
    capacity: '৩ জন',
    emoji: '🛺',
  );

  static const all = <RideVehicle>[bike, car, auto];

  static RideVehicle byKey(String? key) => all.firstWhere(
        (v) => v.key == key,
        orElse: () => car,
      );

  /// Rider-facing name for a raw API key, for one-off strings.
  static String labelFor(String? key) => byKey(key).label;
}
