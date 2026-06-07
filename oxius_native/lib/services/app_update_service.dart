import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import 'fcm_service.dart';

class AppUpdateInfo {
  final bool updateAvailable;
  final bool forceUpdate;
  final String latestVersion;
  final int latestBuild;
  final String storeUrl;
  final String title;
  final String message;
  final int snoozeHours;

  const AppUpdateInfo({
    required this.updateAvailable,
    required this.forceUpdate,
    required this.latestVersion,
    required this.latestBuild,
    required this.storeUrl,
    required this.title,
    required this.message,
    required this.snoozeHours,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      updateAvailable: json['update_available'] == true,
      forceUpdate: json['force_update'] == true,
      latestVersion: (json['latest_version'] ?? '').toString(),
      latestBuild: int.tryParse((json['latest_build'] ?? 0).toString()) ?? 0,
      storeUrl: (json['store_url'] ?? '').toString(),
      title: (json['title'] ?? 'Update available').toString(),
      message: (json['message'] ??
              'A new version of AdsyClub is available. Please update to continue.')
          .toString(),
      snoozeHours: int.tryParse((json['snooze_hours'] ?? 24).toString()) ?? 24,
    );
  }

  String get snoozeKey =>
      'app_update_snoozed_until_${latestVersion}_$latestBuild';
}

class AppUpdateService {
  static bool _checkedThisProcess = false;
  static bool _dialogShowing = false;

  static String? get _platform {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return null;
  }

  static Future<void> checkAndPrompt(BuildContext context) async {
    if (_checkedThisProcess || _dialogShowing) return;
    _checkedThisProcess = true;

    final platform = _platform;
    if (platform == null) return;

    try {
      final info = await _fetchUpdateInfo(platform);
      if (info == null || !info.updateAvailable || info.storeUrl.isEmpty) {
        return;
      }

      if (!info.forceUpdate && await _isSnoozed(info)) {
        return;
      }

      // IMPORTANT: AppUpdateGate lives in MaterialApp.builder, which sits ABOVE
      // the app's Navigator — so the context passed here has no Navigator
      // ancestor and showDialog() would throw "No Navigator" (silently swallowed
      // by the catch, so the prompt never appeared). Use the root navigator's
      // own context instead.
      final dialogContext = await _navigatorContext();
      if (dialogContext == null) return;

      _dialogShowing = true;
      await _showUpdateDialog(dialogContext, info);
    } catch (e) {
      debugPrint('[app_update] check failed: $e');
    } finally {
      _dialogShowing = false;
    }
  }

  /// The app's root navigator context (below the Navigator/Overlay), waiting
  /// briefly for it to be ready on a cold start.
  static Future<BuildContext?> _navigatorContext() async {
    for (var i = 0; i < 25; i++) {
      final ctx = FCMService.navigatorKey.currentContext;
      if (ctx != null) return ctx;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return null;
  }

  static Future<AppUpdateInfo?> _fetchUpdateInfo(String platform) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final build = int.tryParse(packageInfo.buildNumber) ?? 0;
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/app-version/check/').replace(
      queryParameters: {
        'platform': platform,
        'version': packageInfo.version,
        'build': build.toString(),
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      debugPrint('[app_update] check returned ${response.statusCode}');
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;
    return AppUpdateInfo.fromJson(decoded);
  }

  static Future<bool> _isSnoozed(AppUpdateInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(info.snoozeKey) ?? 0;
    return DateTime.now().millisecondsSinceEpoch < until;
  }

  static Future<void> _snooze(AppUpdateInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now()
        .add(Duration(hours: info.snoozeHours.clamp(1, 168)))
        .millisecondsSinceEpoch;
    await prefs.setInt(info.snoozeKey, until);
  }

  static Future<void> _showUpdateDialog(
    BuildContext context,
    AppUpdateInfo info,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (dialogContext) {
        return PopScope(
          canPop: !info.forceUpdate,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            title: Text(info.title),
            content: Text(info.message),
            actions: [
              if (!info.forceUpdate)
                TextButton(
                  onPressed: () async {
                    await _snooze(info);
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Later'),
                ),
              FilledButton(
                onPressed: () => _openStore(info.storeUrl),
                child: const Text('Update Now'),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _openStore(String storeUrl) async {
    final uri = Uri.tryParse(storeUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class AppUpdateGate extends StatefulWidget {
  final Widget child;

  const AppUpdateGate({super.key, required this.child});

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppUpdateService.checkAndPrompt(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
