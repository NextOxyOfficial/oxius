import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'auth_service.dart';

/// Eligibility snapshot for the free Pro trial, as decided by the server.
///
/// The client only ever *renders* these rules — activation is re-checked
/// server-side, so a stale or edited response can't hand out a trial.
class ProTrialStatus {
  final bool enabled;
  final int days;
  final bool requiresKyc;
  final bool kycVerified;
  final bool kycPending;
  final bool alreadyUsed;
  final bool isPro;
  final bool trialActive;
  final bool eligible;

  /// '' when eligible; otherwise one of
  /// disabled | already_used | kyc_required | already_pro.
  final String reason;
  final DateTime? proValidity;

  const ProTrialStatus({
    required this.enabled,
    required this.days,
    required this.requiresKyc,
    required this.kycVerified,
    required this.kycPending,
    required this.alreadyUsed,
    required this.isPro,
    required this.trialActive,
    required this.eligible,
    required this.reason,
    this.proValidity,
  });

  factory ProTrialStatus.fromJson(Map<String, dynamic> m) => ProTrialStatus(
        enabled: m['enabled'] == true,
        days: (m['days'] as num?)?.toInt() ?? 0,
        requiresKyc: m['requires_kyc'] == true,
        kycVerified: m['kyc_verified'] == true,
        kycPending: m['kyc_pending'] == true,
        alreadyUsed: m['already_used'] == true,
        isPro: m['is_pro'] == true,
        trialActive: m['trial_active'] == true,
        eligible: m['eligible'] == true,
        reason: (m['reason'] ?? '').toString(),
        proValidity: m['pro_validity'] != null
            ? DateTime.tryParse(m['pro_validity'].toString())
            : null,
      );

  /// Whether the trial offer is worth showing at all. A user who already
  /// claimed it, or who is already Pro, shouldn't see the pitch.
  bool get shouldOffer => enabled && !alreadyUsed && !isPro;
}

class ProTrialActivation {
  final bool success;
  final String message;
  final ProTrialStatus? status;

  const ProTrialActivation(this.success, this.message, this.status);
}

class ProTrialService {
  static Future<ProTrialStatus?> fetchStatus() async {
    try {
      final res = await AuthService.authenticatedRequest(
        method: 'GET',
        endpoint: '/pro-trial/status/',
      );
      if (res.statusCode == 200) {
        return ProTrialStatus.fromJson(
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('pro trial status failed: $e');
    }
    return null;
  }

  static Future<ProTrialActivation> activate() async {
    try {
      final res = await AuthService.authenticatedRequest(
        method: 'POST',
        endpoint: '/pro-trial/activate/',
        body: jsonEncode({}),
      );
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final ok = res.statusCode >= 200 && res.statusCode < 300;
      return ProTrialActivation(
        ok,
        (body['detail'] ?? (ok ? 'ট্রায়াল চালু হয়েছে।' : 'ট্রায়াল চালু করা যায়নি।'))
            .toString(),
        ProTrialStatus.fromJson(body),
      );
    } catch (e) {
      debugPrint('pro trial activate failed: $e');
      return const ProTrialActivation(
        false,
        'সংযোগ সমস্যা। আবার চেষ্টা করুন।',
        null,
      );
    }
  }
}
