import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Google Play "Prominent Disclosure & Consent" for location.
///
/// Play policy requires that BEFORE the runtime location permission prompt,
/// the app shows an in-app disclosure that (a) names the data (location),
/// (b) states the purpose, (c) explicitly says it may be collected in the
/// BACKGROUND — even when the app is closed — and (d) gets affirmative
/// consent. The rideshare driver feature streams live location while online
/// (including in the background) to match nearby riders; passengers share
/// their location only to find and track a ride.
///
/// Call [ensure] right before requesting the OS location permission. It
/// returns true only if the user accepts; on decline the caller must NOT
/// request the permission.
class LocationDisclosure {
  LocationDisclosure._();

  static const _prefsKeyForeground = 'loc_disclosure_accepted_v1';
  static const _prefsKeyBackground = 'loc_bg_disclosure_accepted_v1';

  /// Show the disclosure (once per accepted level) and return whether the
  /// user consented. [background] = the feature needs location while the app
  /// is in the background (driver mode); otherwise foreground-only (rider).
  static Future<bool> ensure(
    BuildContext context, {
    required bool background,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = background ? _prefsKeyBackground : _prefsKeyForeground;
    // A prior background acceptance also covers the foreground case.
    if (prefs.getBool(key) == true) return true;
    if (!background && prefs.getBool(_prefsKeyBackground) == true) return true;

    if (!context.mounted) return false;
    final accepted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _DisclosureDialog(background: background),
        ) ??
        false;

    if (accepted) await prefs.setBool(key, true);
    return accepted;
  }
}

class _DisclosureDialog extends StatelessWidget {
  final bool background;
  const _DisclosureDialog({required this.background});

  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF475569);
  static const _brand = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: _brand, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'AdsyClub লোকেশন ব্যবহার করবে',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              background
                  ? 'রাইড শেয়ারে ড্রাইভার হিসেবে অনলাইন থাকলে AdsyClub আপনার '
                      'ডিভাইসের লোকেশন সংগ্রহ করে — কাছাকাছি যাত্রীদের সাথে '
                      'আপনাকে ম্যাচ করতে এবং যাত্রীকে আপনার লাইভ অবস্থান দেখাতে।'
                  : 'রাইড খোঁজা ও চলমান রাইড ট্র্যাক করার জন্য AdsyClub আপনার '
                      'ডিভাইসের লোকেশন সংগ্রহ করে — কাছের ড্রাইভার খুঁজে দিতে '
                      'এবং আপনাকে নিরাপদে গন্তব্যে পৌঁছাতে।',
              style: const TextStyle(
                fontSize: 14.5,
                color: _muted,
                height: 1.5,
              ),
            ),
            if (background) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Text(
                  'গুরুত্বপূর্ণ: ড্রাইভার মোড চালু থাকলে অ্যাপ ব্যাকগ্রাউন্ডে '
                  'বা বন্ধ থাকলেও (app closed or not in use) আপনার লোকেশন '
                  'সংগ্রহ করা হতে পারে। ড্রাইভার মোড বন্ধ করলেই তা থেমে যায়।',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                    height: 1.45,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _bullet(
                'আপনার লোকেশন শুধু এই সেবা চালু থাকা অবস্থায় ব্যবহৃত হয়।'),
            _bullet('আমরা এই ডেটা বিজ্ঞাপনের জন্য বিক্রি করি না।'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'সম্মত আছি, চালিয়ে যান',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'এখন নয়',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.check_circle_rounded,
                size: 15, color: Color(0xFF10B981)),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: _muted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
