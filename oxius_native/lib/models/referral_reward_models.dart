/// Models for the Referral Reward Program (New Year offer, etc.)

class ReferralRewardProgram {
  final int id;
  final String name;
  final double referrerReward;
  final double refereeReward;
  final String description;
  final String? bannerImage;
  final DateTime? startDate;
  final DateTime? endDate;

  ReferralRewardProgram({
    required this.id,
    required this.name,
    required this.referrerReward,
    required this.refereeReward,
    required this.description,
    this.bannerImage,
    this.startDate,
    this.endDate,
  });

  factory ReferralRewardProgram.fromJson(Map<String, dynamic> json) {
    return ReferralRewardProgram(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      referrerReward: (json['referrer_reward'] ?? 0).toDouble(),
      refereeReward: (json['referee_reward'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      bannerImage: json['banner_image'],
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date']) : null,
    );
  }
}

class ReferralRewardProgramResponse {
  final bool active;
  final ReferralRewardProgram? program;

  ReferralRewardProgramResponse({
    required this.active,
    this.program,
  });

  factory ReferralRewardProgramResponse.fromJson(Map<String, dynamic> json) {
    return ReferralRewardProgramResponse(
      active: json['active'] ?? false,
      program: json['program'] != null
          ? ReferralRewardProgram.fromJson(json['program'])
          : null,
    );
  }
}

class RewardClaimConditions {
  final bool hasPostedBn;
  final bool hasCompletedMicrogig;
  final bool hasKycVerified;
  final bool allMet;

  RewardClaimConditions({
    required this.hasPostedBn,
    required this.hasCompletedMicrogig,
    required this.hasKycVerified,
    required this.allMet,
  });

  factory RewardClaimConditions.fromJson(Map<String, dynamic> json) {
    return RewardClaimConditions(
      hasPostedBn: json['has_posted_bn'] ?? false,
      hasCompletedMicrogig: json['has_completed_microgig'] ?? false,
      hasKycVerified: json['has_kyc_verified'] ?? false,
      allMet: json['all_met'] ?? false,
    );
  }
}

class ReferralRewardClaim {
  final int id;
  final String claimType; // 'referrer' or 'referee'
  final String status; // 'pending', 'eligible', 'claimed'
  final double rewardAmount;
  final String? referredUserId;
  final String? referredUserName;
  final RewardClaimConditions conditions;
  final bool allMet;
  final DateTime? claimedAt;

  ReferralRewardClaim({
    required this.id,
    required this.claimType,
    required this.status,
    required this.rewardAmount,
    this.referredUserId,
    this.referredUserName,
    required this.conditions,
    required this.allMet,
    this.claimedAt,
  });

  factory ReferralRewardClaim.fromJson(Map<String, dynamic> json) {
    return ReferralRewardClaim(
      id: json['id'] ?? 0,
      claimType: json['claim_type'] ?? 'referee',
      status: json['status'] ?? 'pending',
      rewardAmount: (json['reward_amount'] ?? 0).toDouble(),
      referredUserId: json['referred_user']?['id']?.toString(),
      referredUserName: json['referred_user']?['name'],
      conditions: RewardClaimConditions.fromJson(json['conditions'] ?? {}),
      allMet: json['all_met'] ?? false,
      claimedAt: json['claimed_at'] != null ? DateTime.tryParse(json['claimed_at']) : null,
    );
  }

  bool get isEligible => status == 'eligible';
  bool get isClaimed => status == 'claimed';
  bool get isPending => status == 'pending';
}

class MyClaimsResponse {
  final bool activeProgram;
  final ReferralRewardProgram? program;
  final List<ReferralRewardClaim> claims;

  MyClaimsResponse({
    required this.activeProgram,
    this.program,
    required this.claims,
  });

  factory MyClaimsResponse.fromJson(Map<String, dynamic> json) {
    return MyClaimsResponse(
      activeProgram: json['active_program'] ?? false,
      program: json['program'] != null
          ? ReferralRewardProgram.fromJson(json['program'])
          : null,
      claims: (json['claims'] as List?)
              ?.map((c) => ReferralRewardClaim.fromJson(c))
              .toList() ??
          [],
    );
  }

  /// Get the referee claim (for referred users)
  ReferralRewardClaim? get refereeClaim {
    for (final c in claims) {
      if (c.claimType == 'referee') return c;
    }
    return null;
  }

  /// Get referrer claims (for users who referred others)
  List<ReferralRewardClaim> get referrerClaims =>
      claims.where((c) => c.claimType == 'referrer').toList();
}

class RewardInfo {
  final bool isReferee;
  final String? referrerName;
  final double rewardAmount;
  final String? claimStatus;

  RewardInfo({
    required this.isReferee,
    this.referrerName,
    required this.rewardAmount,
    this.claimStatus,
  });

  factory RewardInfo.fromJson(Map<String, dynamic> json) {
    return RewardInfo(
      isReferee: json['is_referee'] ?? false,
      referrerName: json['referrer_name'],
      rewardAmount: (json['reward_amount'] ?? 0).toDouble(),
      claimStatus: json['claim_status'],
    );
  }
}

class CheckConditionsResponse {
  final RewardClaimConditions conditions;
  final RewardInfo? rewardInfo;

  CheckConditionsResponse({
    required this.conditions,
    this.rewardInfo,
  });

  factory CheckConditionsResponse.fromJson(Map<String, dynamic> json) {
    return CheckConditionsResponse(
      conditions: RewardClaimConditions.fromJson(json['conditions'] ?? {}),
      rewardInfo: json['reward_info'] != null
          ? RewardInfo.fromJson(json['reward_info'])
          : null,
    );
  }
}

class ClaimRewardResponse {
  final bool success;
  final String message;
  final double? newBalance;

  ClaimRewardResponse({
    required this.success,
    required this.message,
    this.newBalance,
  });

  factory ClaimRewardResponse.fromJson(Map<String, dynamic> json) {
    return ClaimRewardResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      newBalance: json['new_balance']?.toDouble(),
    );
  }
}
