import 'package:shared_preferences/shared_preferences.dart';

/// Which side of rideshare this user is currently in, remembered across app
/// launches.
///
/// A driver who flips to driving does not want to flip again every single time
/// they open the app, so the choice is sticky. Passenger is the default only
/// for someone who has never chosen — not a state we fall back to on a whim.
class RideshareMode {
  static const passenger = 'passenger';
  static const driver = 'driver';

  static const _key = 'rideshare_active_mode_v1';

  const RideshareMode._();

  static bool isValid(String? mode) => mode == passenger || mode == driver;

  /// The remembered mode, or [passenger] if there is none.
  static Future<String> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    return isValid(stored) ? stored! : passenger;
  }

  static Future<void> save(String mode) async {
    if (!isValid(mode)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode);
  }

  /// Wipes the sticky choice — used when a driver profile stops being
  /// approved, so a suspended driver is not stranded on a dashboard they can
  /// no longer use.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static String label(String mode) =>
      mode == driver ? 'Driver' : 'Passenger';

  /// What the rider is told when the dashboard flips under them.
  static String switchMessage(String mode) => mode == driver
      ? 'ড্যাশবোর্ড এখন ড্রাইভার মোডে — পরেরবার খুললেও এটাই দেখবেন'
      : 'ড্যাশবোর্ড এখন প্যাসেঞ্জার মোডে — পরেরবার খুললেও এটাই দেখবেন';
}
