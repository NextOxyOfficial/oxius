import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

class NotificationPermissionGate extends StatefulWidget {
  final Widget child;

  const NotificationPermissionGate({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<NotificationPermissionGate> createState() =>
      _NotificationPermissionGateState();
}

class _NotificationPermissionGateState
    extends State<NotificationPermissionGate> {
  static const String _skipPrefKey = 'notification_permission_skipped_v1';

  bool _hasPermission = false;
  bool _isChecking = true;
  bool _userSkipped = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    bool skipped = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      skipped = prefs.getBool(_skipPrefKey) ?? false;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _hasPermission =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      _userSkipped = skipped;
      _isChecking = false;
    });
  }

  Future<void> _skipForNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_skipPrefKey, true);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _userSkipped = true);
  }

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true,
      announcement: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      setState(() {
        _hasPermission = true;
      });
    } else {
      // Show dialog to open settings
      _showSettingsDialog();
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xFF3B82F6),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Enable Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Notifications help you stay updated with messages, orders, and important announcements. You can enable them in your device settings, or skip for now.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _skipForNow();
            },
            child: Text(
              'Skip for now',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
              // Recheck after returning from settings
              await Future.delayed(const Duration(seconds: 1));
              _checkPermission();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: AdsyLoadingIndicator(),
        ),
      );
    }

    if (!_hasPermission && !_userSkipped) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              final maxH = constraints.maxHeight;
              final isTablet = maxW >= 600;
              final isLargeTablet = maxW >= 900;

              // Scale against shortest side so iPad portrait & landscape both
              // feel spacious without looking like a phone window.
              final iconSize = isLargeTablet ? 88.0 : (isTablet ? 76.0 : 70.0);
              final iconPadding =
                  isLargeTablet ? 30.0 : (isTablet ? 26.0 : 24.0);
              final titleSize = isLargeTablet ? 30.0 : (isTablet ? 26.0 : 24.0);
              final bodySize = isLargeTablet ? 17.0 : (isTablet ? 16.0 : 15.0);
              final hPad = isLargeTablet ? 56.0 : (isTablet ? 40.0 : 24.0);
              final vPad = isTablet ? 28.0 : 16.0;
              final cardMaxWidth =
                  isLargeTablet ? 640.0 : (isTablet ? 560.0 : double.infinity);

              final content = ConstrainedBox(
                constraints: BoxConstraints(minHeight: maxH),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardMaxWidth),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: hPad, vertical: vPad),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top-right skip link so reviewers immediately see that
                          // notifications are optional. (Guideline 4.5.4)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _skipForNow,
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF6B7280),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              child: const Text(
                                'Skip',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isTablet ? 8 : 4),

                          // Icon
                          Center(
                            child: Container(
                              padding: EdgeInsets.all(iconPadding),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_active_rounded,
                                size: iconSize,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                          SizedBox(height: isTablet ? 24 : 20),

                          // Title
                          Text(
                            'Stay Connected',
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),

                          // Description — notifications are explicitly optional.
                          Text(
                            'Notifications are optional. Enable them to receive updates about messages, orders and important announcements — or skip and continue using the app.',
                            style: TextStyle(
                              fontSize: bodySize,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isTablet ? 24 : 20),

                          // Benefits list
                          Container(
                            padding: EdgeInsets.all(isTablet ? 20 : 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You\'ll receive notifications for:',
                                  style: TextStyle(
                                    fontSize: isTablet ? 15.0 : 14.0,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                SizedBox(height: isTablet ? 14 : 12),
                                _buildBenefit(Icons.chat_bubble_rounded,
                                    'New messages from connections',
                                    isWide: isTablet),
                                _buildBenefit(Icons.shopping_bag_rounded,
                                    'Order updates and tracking',
                                    isWide: isTablet),
                                _buildBenefit(Icons.support_agent_rounded,
                                    'Support ticket replies',
                                    isWide: isTablet),
                                _buildBenefit(Icons.campaign_rounded,
                                    'Important announcements',
                                    isWide: isTablet),
                                _buildBenefit(
                                    Icons.account_balance_wallet_rounded,
                                    'Wallet transactions',
                                    isWide: isTablet),
                              ],
                            ),
                          ),
                          SizedBox(height: isTablet ? 24 : 20),

                          // Enable button (primary)
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _requestPermission,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Enable Notifications',
                                style: TextStyle(
                                  fontSize: isTablet ? 17.0 : 16.0,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Skip / continue — equal weight OutlinedButton so users
                          // (and reviewers) clearly see that notifications are not
                          // required to use the app. (Guideline 4.5.4)
                          SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _skipForNow,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF374151),
                                side: BorderSide(
                                    color: Colors.grey.shade300, width: 1.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Continue without notifications',
                                style: TextStyle(
                                  fontSize: isTablet ? 16.0 : 15.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'You can enable notifications anytime from device Settings.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isTablet ? 12.5 : 11.5,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: content,
              );
            },
          ),
        ),
      );
    }

    return widget.child;
  }

  Widget _buildBenefit(IconData icon, String text, {bool isWide = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: isWide ? 22 : 20,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isWide ? 15.0 : 14.0,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
