import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDownloadWizardButton extends StatefulWidget {
  final double iconSize;

  const AppDownloadWizardButton({
    super.key,
    this.iconSize = 20,
  });

  @override
  State<AppDownloadWizardButton> createState() => _AppDownloadWizardButtonState();
}

class _AppDownloadWizardButtonState extends State<AppDownloadWizardButton> {
  bool _shouldShow = false;
  bool _isLoading = true;

  static const _dismissKey = 'download_app_wizard_dismissed_v1';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (!kIsWeb) {
        if (mounted) {
          setState(() {
            _shouldShow = false;
            _isLoading = false;
          });
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool(_dismissKey) ?? false;
      if (dismissed) {
        if (mounted) {
          setState(() {
            _shouldShow = false;
            _isLoading = false;
          });
        }
        return;
      }

      final platform = defaultTargetPlatform;
      final isMobilePlatform = platform == TargetPlatform.android || platform == TargetPlatform.iOS;
      if (!isMobilePlatform) {
        if (mounted) {
          setState(() {
            _shouldShow = false;
            _isLoading = false;
          });
        }
        return;
      }

      bool isInstalled = false;
      try {
        isInstalled = await canLaunchUrl(Uri.parse('adsypay://pay/0'));
      } catch (_) {
        isInstalled = false;
      }

      if (mounted) {
        setState(() {
          _shouldShow = !isInstalled;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _shouldShow = kIsWeb;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissKey, true);
    if (mounted) {
      setState(() {
        _shouldShow = false;
      });
    }
  }

  Future<void> _openPlayStore() async {
    const url = 'https://play.google.com/store/apps/details?id=com.adsyclub.app';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _openAppStore() async {
    const url = 'https://apps.apple.com/';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _openAppDeepLink() async {
    final deepLink = Uri.parse('adsypay://pay/0');
    await launchUrl(deepLink, mode: LaunchMode.externalApplication);
  }

  void _showWizard() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final platform = defaultTargetPlatform;
        final isAndroid = platform == TargetPlatform.android;
        final isIOS = platform == TargetPlatform.iOS;

        return Container(
          margin: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.download_rounded,
                      size: 20,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Get the AdsyClub App',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Install the mobile app for faster access, notifications, and a smoother experience.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isAndroid ? _openPlayStore : (isIOS ? _openAppStore : null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        isAndroid ? 'Google Play' : isIOS ? 'App Store' : 'Download',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _openAppDeepLink,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF111827),
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Open App',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _dismiss();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Not now',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileWidth = screenWidth < 768;

    if (_isLoading || !_shouldShow || !isMobileWidth) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: _showWizard,
      tooltip: 'Download app',
      padding: const EdgeInsets.all(3),
      constraints: const BoxConstraints(),
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF10B981).withOpacity(0.08),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
        ),
        child: Center(
          child: Icon(
            Icons.download_rounded,
            size: widget.iconSize,
            color: const Color(0xFF10B981),
          ),
        ),
      ),
    );
  }
}
