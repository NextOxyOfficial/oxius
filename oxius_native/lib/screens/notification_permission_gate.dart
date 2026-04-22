import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPermissionGate extends StatefulWidget {
  final Widget child;

  const NotificationPermissionGate({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<NotificationPermissionGate> createState() => _NotificationPermissionGateState();
}

class _NotificationPermissionGateState extends State<NotificationPermissionGate> {
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
      _hasPermission = settings.authorizationStatus == AuthorizationStatus.authorized ||
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
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasPermission && !_userSkipped) {
      return Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final iconSize = isWide ? 96.0 : 80.0;
              final iconPadding = isWide ? 36.0 : 28.0;
              final titleSize = isWide ? 32.0 : 26.0;
              final bodySize = isWide ? 18.0 : 15.0;
              final hPad = isWide ? 80.0 : 28.0;

              final content = Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
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
                    const SizedBox(height: 28),

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
                    const SizedBox(height: 14),

                    // Description
                    Text(
                      'Enable notifications to receive important updates and stay connected with your network.',
                      style: TextStyle(
                        fontSize: bodySize,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Benefits list
                    Container(
                      padding: const EdgeInsets.all(20),
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
                              fontSize: isWide ? 15.0 : 14.0,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildBenefit(Icons.chat_bubble_rounded, 'New messages from connections', isWide: isWide),
                          _buildBenefit(Icons.shopping_bag_rounded, 'Order updates and tracking', isWide: isWide),
                          _buildBenefit(Icons.support_agent_rounded, 'Support ticket replies', isWide: isWide),
                          _buildBenefit(Icons.campaign_rounded, 'Important announcements', isWide: isWide),
                          _buildBenefit(Icons.account_balance_wallet_rounded, 'Wallet transactions', isWide: isWide),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Enable button
                    SizedBox(
                      width: isWide ? 400 : double.infinity,
                      height: 54,
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
                            fontSize: isWide ? 17.0 : 16.0,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Skip option — notifications are optional. Users can
                    // enable them later from device Settings.
                    SizedBox(
                      width: isWide ? 400 : double.infinity,
                      child: TextButton(
                        onPressed: _skipForNow,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Skip for now',
                          style: TextStyle(
                            fontSize: isWide ? 15.0 : 14.0,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: isWide ? 400 : double.infinity,
                      child: Text(
                        'You can enable notifications later in Settings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isWide ? 12.0 : 11.0,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              return isWide
                  ? Center(child: SingleChildScrollView(child: content))
                  : SingleChildScrollView(child: content);
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
