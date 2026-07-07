import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_state_service.dart';

/// Bottom sheet that nudges the user to finish their profile.
///
/// Shown once right after login when `profile_completion < 100`. The completion
/// percentage and the list of missing steps come from the backend
/// (`UserSerializer.profile_completion` / `missing_steps`).
class ProfileCompletionSheet {
  // Set right after a successful login (email or social) and consumed once by
  // the home screen, so we prompt on login rather than on every app launch.
  static bool _pending = false;

  /// Flag that a profile-completion prompt should be shown on the next home
  /// screen build, but only if the profile is actually incomplete.
  static void markPendingIfNeeded(User user) {
    if (user.profileCompletion < 100) {
      _pending = true;
    }
  }

  /// Show the prompt if one is pending. Safe to call from home screen init.
  static Future<void> maybeShowPending(BuildContext context) async {
    if (!_pending) return;
    _pending = false;

    final user = UserStateService().currentUser;
    if (user == null || user.profileCompletion >= 100) return;

    await show(context, user);
  }

  static const _primaryColor = Color(0xFF1D4ED8);

  static IconData _iconForStep(String key) {
    switch (key) {
      case 'photo':
        return Icons.add_a_photo_rounded;
      case 'name':
        return Icons.badge_rounded;
      case 'phone':
        return Icons.phone_rounded;
      case 'about':
        return Icons.notes_rounded;
      case 'address':
        return Icons.location_on_rounded;
      case 'profession':
        return Icons.work_rounded;
      case 'date_of_birth':
        return Icons.cake_rounded;
      case 'gender':
        return Icons.wc_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  static Future<void> show(BuildContext context, User user) {
    final percent = user.profileCompletion.clamp(0, 100);
    final steps = user.missingSteps;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Local navigator (default). The home screen is a normal route, not an
      // overlay, so the sheet renders correctly.
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border:
                                Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.account_circle_outlined,
                              color: _primaryColor, size: 23),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'প্রোফাইল সম্পূর্ণ করুন',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(999),
                            border:
                                Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            '$percent%',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percent / 100,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_primaryColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'আপনার প্রোফাইল $percent% সম্পূর্ণ',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (steps.isNotEmpty) ...[
                      const Text(
                        'যা এখনো বাকি আছে:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...steps.take(6).map((step) {
                        final key = step['key']?.toString() ?? '';
                        final label = step['label']?.toString() ?? '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0)),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Icon(_iconForStep(key),
                                    size: 18, color: const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Navigator.pushNamed(context, '/settings');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'প্রোফাইল সম্পূর্ণ করুন',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text(
                          'পরে করব',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
