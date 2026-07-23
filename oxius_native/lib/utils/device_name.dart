import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Human-readable device model — "samsung SM-G991B (Android 14)",
/// "iPhone 15 Pro (iOS 18.2)" — sent as the `X-Device-Name` header on login
/// so the security email can say WHICH device signed in.
class DeviceName {
  DeviceName._();

  static String? _cached;

  static Future<String> get() async {
    final cached = _cached;
    if (cached != null) return cached;
    var name = '';
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        name = '${a.manufacturer} ${a.model} (Android ${a.version.release})';
      } else if (Platform.isIOS) {
        final i = await plugin.iosInfo;
        final model =
            i.modelName.isNotEmpty ? i.modelName : i.utsname.machine;
        name = '$model (iOS ${i.systemVersion})';
      } else {
        name = Platform.operatingSystem;
      }
    } catch (_) {
      name = '';
    }
    // HTTP header values must stay ASCII — strip anything exotic.
    name = name.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim();
    _cached = name;
    return name;
  }
}
