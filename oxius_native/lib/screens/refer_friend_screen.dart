import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oxius_native/utils/app_fonts.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../widgets/ios_web_redirect_screen.dart';
import '../services/referral_service.dart';
import '../models/referral_models.dart';
import '../models/referral_reward_models.dart';
import '../widgets/common/adsy_share_sheet.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

class ReferFriendScreen extends StatefulWidget {
  const ReferFriendScreen({super.key});

  @override
  State<ReferFriendScreen> createState() => _ReferFriendScreenState();
}

class _ReferFriendScreenState extends State<ReferFriendScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoadingPlatform = true;
  bool _isLoadingCommissions = false;
  bool _isLoadingUsers = false;

  PlatformStats? _platformStats;
  CommissionData? _commissionData;
  List<ReferredUser> _referredUsers = [];
  String? _referralCode;
  String? _referralLink;

  String? _commissionError;

  // Referral Reward Program
  MyClaimsResponse? _claimsData;
  bool _isLoadingClaims = false;
  bool _isClaimingReward = false;

  late TabController _tabController;
  bool _isLoggedIn = false;

  // Design tokens (shared with the app's other pages).
  static const Color _kDark = Color(0xFF0F172A);
  static const Color _kMuted = Color(0xFF64748B);
  static const Color _kBorder = Color(0xFFE2E8F0);
  static const Color _kHairline = Color(0xFFF1F5F9);
  static const Color _kGreen = Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    _isLoggedIn = AuthService.isAuthenticated;
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _loadPlatformStats();
    if (_isLoggedIn) {
      _loadReferralInfo();
      _loadCommissionHistory();
      _loadReferredUsers();
      _loadRewardClaims();
    }
  }

  Future<void> _loadPlatformStats() async {
    setState(() => _isLoadingPlatform = true);
    try {
      final stats = await ReferralService.getPlatformStats();
      if (mounted) {
        setState(() {
          _platformStats = stats;
          _isLoadingPlatform = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPlatform = false);
    }
  }

  Future<void> _loadReferralInfo() async {
    try {
      final info = await ReferralService.getReferralInfo();
      if (mounted) {
        setState(() {
          _referralCode = info['code'];
          _referralLink = info['link'];
        });
      }
    } catch (e) {
      debugPrint('Error loading referral info: $e');
    }
  }

  Future<void> _loadCommissionHistory() async {
    setState(() {
      _isLoadingCommissions = true;
      _commissionError = null;
    });

    try {
      final data = await ReferralService.getCommissionHistory();
      if (mounted) {
        setState(() {
          _commissionData = data;
          _isLoadingCommissions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _commissionError = 'কমিশন হিস্ট্রি লোড করা যায়নি';
          _isLoadingCommissions = false;
        });
      }
    }
  }

  Future<void> _loadReferredUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final users = await ReferralService.getReferredUsers();
      if (mounted) {
        setState(() {
          _referredUsers = users;
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
        });
      }
    }
  }

  Future<void> _loadRewardClaims() async {
    setState(() => _isLoadingClaims = true);
    try {
      final data = await ReferralService.getMyClaims();
      if (mounted) {
        setState(() {
          _claimsData = data;
          _isLoadingClaims = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingClaims = false);
    }
  }

  ReferralRewardClaim? _getClaimForReferredUser(String referredUserId) {
    final claims = _claimsData?.claims;
    if (claims == null) return null;

    for (final c in claims) {
      if (c.claimType != 'referrer') continue;
      if (c.referredUserId == null) continue;
      if (c.referredUserId.toString() == referredUserId.toString()) return c;
    }
    return null;
  }

  int get _eligibleReferrerClaimsCount {
    final claims = _claimsData?.claims;
    if (claims == null) return 0;
    int count = 0;
    for (final c in claims) {
      if (c.claimType == 'referrer' && c.status == 'eligible') {
        count += 1;
      }
    }
    return count;
  }

  Future<void> _claimAllRewards() async {
    final claims = _claimsData?.claims;
    if (claims == null) return;

    final eligible = claims
        .where((c) => c.claimType == 'referrer' && c.status == 'eligible')
        .toList();
    if (eligible.isEmpty) return;

    setState(() => _isClaimingReward = true);

    int successCount = 0;
    double totalAmount = 0;
    for (final c in eligible) {
      try {
        final res = await ReferralService.claimReward(c.id);
        if (res.success) {
          successCount += 1;
          totalAmount += c.rewardAmount;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    AdsyToast.info(
      context,
      successCount > 0
          ? '$successCount টি রিওয়ার্ড নেওয়া হয়েছে (৳${totalAmount.toStringAsFixed(0)})'
          : 'রিওয়ার্ড নেওয়া যায়নি',
    );

    setState(() => _isClaimingReward = false);
    _loadRewardClaims();
    AuthService.refreshUserData();
  }

  Future<void> _claimReward(int claimId) async {
    setState(() => _isClaimingReward = true);
    try {
      final result = await ReferralService.claimReward(claimId);
      if (mounted) {
        AdsyToast.info(context, result.message);
        if (result.success) {
          _loadRewardClaims();
          AuthService.refreshUserData();
        }
      }
    } catch (e) {
      if (mounted) {
        AdsyToast.error(context, 'রিওয়ার্ড নেওয়া যায়নি');
      }
    } finally {
      if (mounted) setState(() => _isClaimingReward = false);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    AdsyToast.success(context, 'লিংক কপি হয়েছে!');
  }

  Future<void> _shareLink() async {
    if (_referralLink != null) {
      await AdsyShareSheet.show(
        context,
        data: AdsyShareData(
          title: 'AdsyClub-এ যোগ দিন',
          description: 'আমার রেফারেল লিংক দিয়ে আয় শুরু করো।',
          url: _referralLink!,
          subject: 'AdsyClub-এ যোগ দিন',
          eyebrow: 'রেফার করে আয়',
          hashtags: const ['AdsyClub', 'Referral'],
        ),
      );
    }
  }

  void _openShareSheet() {
    _shareLink();
  }

  String _formatDate(String dateString) {
    if (dateString.trim().isEmpty) {
      return 'N/A';
    }
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Color _getTypeColor(String typeCode) {
    switch (typeCode) {
      case 'gig_completion':
        return Colors.blue;
      case 'pro_subscription':
        return Colors.purple;
      case 'gold_sponsor':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              size: 22, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'রেফার করে আয়',
          style: AppFonts.roboto(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: _isLoggedIn ? _buildLoggedInView() : _buildPublicView(),
    );
  }

  Widget _buildPublicView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          // Hero Section
          Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'বন্ধুদের আনুন, একসাথে আয় করুন',
                    style: AppFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '২০% পর্যন্ত আয়',
                  style: AppFonts.roboto(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'কমিশন',
                  style: AppFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isIOSPlatform
                      ? 'আপনার লিংকটি বন্ধুদের শেয়ার করুন আর আয় করুন — গিগ শেষ করলে ৫%, রেফারেলে ২০% পর্যন্ত কমিশন!'
                      : 'আপনার লিংকটি বন্ধুদের শেয়ার করুন আর আয় করুন — গিগ শেষ করলে ৫%, সাবস্ক্রিপশন ও স্পন্সরে ২০% কমিশন!',
                  style: AppFonts.roboto(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text(
                          'সাইন আপ করে আয় শুরু করুন',
                          style: AppFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // How it Works
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Text(
                  'যেভাবে কাজ করে',
                  style: AppFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                _buildStep(
                    1,
                    'অ্যাকাউন্ট খুলুন',
                    'ফ্রি অ্যাকাউন্ট খুলুন আর সাথে সাথে নিজের রেফারেল লিংক পেয়ে যান',
                    Icons.person_add_rounded),
                _buildStep(
                    2,
                    'লিংক শেয়ার করুন',
                    'ইমেইল, সোশ্যাল মিডিয়া বা মেসেজে বন্ধুদের আপনার লিংক পাঠান',
                    Icons.share_rounded),
                _buildStep(
                  3,
                  'কমিশন আয় করুন',
                  isIOSPlatform
                      ? 'গিগে ৫%, রেফারেলে ২০% — আলাদা আলাদা হারে কমিশন পান'
                      : 'গিগে ৫%, সাবস্ক্রিপশন ও স্পন্সরশিপে ২০% — আলাদা হারে কমিশন পান',
                  Icons.paid_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Stats
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                        '৫-২০%', 'কমিশন রেট', Colors.green)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildStatCard(
                  _isLoadingPlatform
                      ? '...'
                      : '${_platformStats?.activeReferrers ?? 500}+',
                  'একটিভ রেফারার',
                  Colors.blue,
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                  _isLoadingPlatform
                      ? '...'
                      : '৳ ${_platformStats?.topEarnerAmount.toStringAsFixed(0) ?? '10000'}',
                  'সর্বোচ্চ আয়',
                  Colors.amber,
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildStatCard(
                  _isLoadingPlatform
                      ? '...'
                      : _platformStats?.quickPayoutTime ?? '২৪ ঘণ্টা',
                  'দ্রুত পেআউট',
                  Colors.purple,
                )),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLoggedInView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(),
          const SizedBox(height: 24),
          _buildHowItWorks(),
          const SizedBox(height: 24),
          _buildEarningsSummary(),
          const SizedBox(height: 24),
          _buildCommissionRates(),
          const SizedBox(height: 24),
          _buildHistorySection(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared building blocks
  // ---------------------------------------------------------------------------

  Widget _sectionHeader(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppFonts.roboto(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: _kDark,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppFonts.roboto(fontSize: 12.5, color: _kMuted, height: 1.3),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Hero — referral code + copy / share
  // ---------------------------------------------------------------------------

  Widget _buildHero() {
    final code = _referralCode ?? 'লোড হচ্ছে...';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'আপনার রেফারেল কোড',
          style: AppFonts.roboto(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: _kMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  code,
                  style: AppFonts.roboto(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: _kGreen,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _copyToClipboard(_referralCode ?? ''),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.copy_rounded, size: 18, color: _kMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _copyToClipboard(_referralLink ?? ''),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.link_rounded, size: 17),
                label: Text(
                  'লিংক কপি',
                  style: AppFonts.roboto(
                      fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openShareSheet,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kGreen,
                  side: const BorderSide(color: _kBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.share_rounded, size: 17),
                label: Text(
                  'শেয়ার',
                  style: AppFonts.roboto(
                      fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. How it works
  // ---------------------------------------------------------------------------

  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('যেভাবে কাজ করে'),
        const SizedBox(height: 14),
        _buildHowStep(
          1,
          'কোড শেয়ার করুন',
          'আপনার রেফারেল কোড বা লিংক বন্ধুদের পাঠান।',
        ),
        _buildHowStep(
          2,
          'বন্ধু যোগ দিক',
          'আপনার লিংকে সাইন আপ করে বন্ধু একটিভ হোক।',
        ),
        _buildHowStep(
          3,
          'কমিশন আয় করুন',
          isIOSPlatform
              ? 'গিগে ৫%, রেফারেলে ২০% পর্যন্ত কমিশন পান।'
              : 'গিগে ৫%, সাবস্ক্রিপশন ও স্পন্সরশিপে ২০% কমিশন পান।',
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildHowStep(int number, String title, String description,
      {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: AppFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kGreen,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 1.5, color: _kHairline),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.roboto(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      color: _kDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppFonts.roboto(
                      fontSize: 12.5,
                      height: 1.35,
                      color: _kMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Earnings summary — a simple stat row
  // ---------------------------------------------------------------------------

  Widget _buildEarningsSummary() {
    final total = _commissionData?.totalEarned ?? 0;
    final txns = _commissionData?.recentTransactions.length ?? 0;
    final refs = _referredUsers.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('আপনার আয়'),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                _buildStat('৳ ${total.toStringAsFixed(0)}', 'মোট আয়',
                    accent: true),
                _buildStatDivider(),
                _buildStat('$refs', 'বন্ধু রেফার'),
                _buildStatDivider(),
                _buildStat('$txns', 'কমিশন পেয়েছেন'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String value, String label, {bool accent = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: AppFonts.roboto(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: accent ? _kGreen : _kDark,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppFonts.roboto(fontSize: 11.5, color: _kMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, color: _kBorder);
  }

  // ---------------------------------------------------------------------------
  // 4. Commission rates — a clean informative list
  // ---------------------------------------------------------------------------

  Widget _buildCommissionRates() {
    final b = _commissionData?.commissionBreakdown;
    final rows = <List<String>>[
      ['গিগ শেষ', b?.gigCompletion.rate ?? '৫%', 'বন্ধুর গিগ আয়ের উপর'],
      [
        'প্রো সাবস্ক্রিপশন',
        b?.proSubscription.rate ?? '২০%',
        'বন্ধুর প্রো সাবস্ক্রিপশনে'
      ],
      [
        'গোল্ড স্পন্সর',
        b?.goldSponsor.rate ?? '২০%',
        'বন্ধুর গোল্ড স্পন্সরশিপে'
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('কমিশন রেট',
            subtitle: 'প্রতিটি ধরন থেকে আপনি যা আয় করেন'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            children: [
              for (int i = 0; i < rows.length; i++) ...[
                if (i > 0) Container(height: 1, color: _kHairline),
                _buildRateRow(rows[i][0], rows[i][1], rows[i][2]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRateRow(String title, String rate, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.roboto(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppFonts.roboto(fontSize: 11.5, color: _kMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            rate,
            style: AppFonts.roboto(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: _kGreen,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. History — transactions / referrals & bonus
  // ---------------------------------------------------------------------------

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('আয় ও রেফারেল'),
        const SizedBox(height: 8),
        TabBar(
          controller: _tabController,
          labelColor: _kGreen,
          unselectedLabelColor: _kMuted,
          labelStyle:
              AppFonts.roboto(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              AppFonts.roboto(fontSize: 13, fontWeight: FontWeight.w600),
          indicatorColor: _kGreen,
          indicatorWeight: 2,
          indicatorSize: TabBarIndicatorSize.tab,
          labelPadding: const EdgeInsets.symmetric(vertical: 4),
          dividerColor: _kBorder,
          dividerHeight: 1,
          // Two full-width tabs split the row evenly (no left-cramped scroll).
          isScrollable: false,
          tabs: [
            Tab(
                text:
                    'আয় (${_commissionData?.recentTransactions.length ?? 0})'),
            const Tab(text: 'রেফার ও বোনাস'),
          ],
        ),
        SizedBox(
          height: 360,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildEarningsTab(),
              _buildReferredAndBonusTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep(
      int number, String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                '$number',
                style: AppFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppFonts.roboto(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppFonts.roboto(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsTab() {
    if (_isLoadingCommissions) {
      return const Center(child: AdsyLoadingIndicator(color: _kGreen));
    }

    if (_commissionError != null) {
      return Center(
        child: Text(
          _commissionError!,
          style: AppFonts.roboto(fontSize: 12.5, color: Colors.red),
        ),
      );
    }

    if (_commissionData == null ||
        _commissionData!.recentTransactions.isEmpty) {
      return _buildEmptyState(
          Icons.receipt_long_rounded, 'এখনো কোনো আয় নেই');
    }

    final transactions = _commissionData!.recentTransactions;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => Container(height: 1, color: _kHairline),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getTypeColor(transaction.typeCode),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.referredUser?.name ?? 'অজানা ইউজার',
                      style: AppFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${transaction.type} (${transaction.commissionRate})',
                      style: AppFonts.roboto(fontSize: 11.5, color: _kMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '৳ ${transaction.amount.toStringAsFixed(0)}',
                    style: AppFonts.roboto(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _kGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(transaction.date),
                    style: AppFonts.roboto(fontSize: 10.5, color: _kMuted),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: _kBorder),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppFonts.roboto(fontSize: 12.5, color: _kMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildReferredAndBonusTab() {
    // Loading state
    if (_isLoadingUsers || _isLoadingClaims) {
      return const Center(child: AdsyLoadingIndicator(color: _kGreen));
    }

    // Not logged in
    if (!_isLoggedIn) {
      return _buildEmptyState(
          Icons.lock_outline_rounded, 'রেফারেল ও বোনাস দেখতে লগইন করুন');
    }

    final claims = _claimsData;
    final hasBonus = claims != null && claims.activeProgram;
    final hasReferredUsers = _referredUsers.isNotEmpty;

    // Empty state
    if (!hasReferredUsers && !hasBonus) {
      return _buildEmptyState(
          Icons.people_outline_rounded, 'এখনো কোনো রেফারেল বা বোনাস নেই');
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        // Bonus Program Card (compact)
        if (hasBonus) _buildCompactBonusCard(),

        // Referred Users Section
        if (hasReferredUsers) ...[
          if (hasBonus) const SizedBox(height: 16),
          _buildReferredUsersSection(),
        ],
      ],
    );
  }

  Widget _buildCompactBonusCard() {
    final claims = _claimsData!;
    final refereeClaim = claims.refereeClaim;
    final referrerClaims = claims.referrerClaims;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGreen.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.card_giftcard_rounded, color: _kGreen, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  claims.program?.name ?? 'রেফারেল রিওয়ার্ড',
                  style: AppFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kDark),
                ),
              ),
              if (_eligibleReferrerClaimsCount > 0)
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    onPressed: _isClaimingReward ? null : _claimAllRewards,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: _isClaimingReward
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: AdsyLoadingIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('সব নিন ($_eligibleReferrerClaimsCount)',
                            style: AppFonts.roboto(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Claims summary
          if (refereeClaim != null || referrerClaims.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (refereeClaim != null)
                  _buildMiniClaimChip(refereeClaim, isReferee: true),
                ...referrerClaims
                    .take(3)
                    .map((c) => _buildMiniClaimChip(c, isReferee: false)),
                if (referrerClaims.length > 3)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _kBorder)),
                    child: Text('আরও ${referrerClaims.length - 3} টি',
                        style: AppFonts.roboto(fontSize: 10, color: _kMuted)),
                  ),
              ],
            )
          else
            Text('বন্ধু রেফার করে রিওয়ার্ড নিন!',
                style: AppFonts.roboto(fontSize: 11.5, color: _kMuted)),
        ],
      ),
    );
  }

  Widget _buildMiniClaimChip(ReferralRewardClaim claim,
      {required bool isReferee}) {
    final isClaimed = claim.isClaimed;
    final isEligible = claim.isEligible;
    return GestureDetector(
      onTap: isEligible && !_isClaimingReward
          ? () => _claimReward(claim.id)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isClaimed
                  ? Icons.check_circle_rounded
                  : isEligible
                      ? Icons.card_giftcard_rounded
                      : Icons.hourglass_empty_rounded,
              size: 13,
              color: isClaimed
                  ? _kGreen
                  : isEligible
                      ? _kGreen
                      : Colors.amber.shade700,
            ),
            const SizedBox(width: 5),
            Text(
              '৳${claim.rewardAmount.toStringAsFixed(0)}',
              style: AppFonts.roboto(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferredUsersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'রেফার করা ইউজার (${_referredUsers.length})',
          style: AppFonts.roboto(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _kMuted),
        ),
        const SizedBox(height: 6),
        for (int i = 0; i < _referredUsers.length; i++) ...[
          if (i > 0) Container(height: 1, color: _kHairline),
          _buildReferredUserRow(_referredUsers[i]),
        ],
      ],
    );
  }

  Widget _buildReferredUserRow(ReferredUser user) {
    final claim = _getClaimForReferredUser(user.id);
    final avatarUrl = AppConfig.getAbsoluteUrl(user.image);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Avatar
          avatarUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    avatarUrl,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _buildUserInitial(user.initial),
                  ),
                )
              : _buildUserInitial(user.initial),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: AppFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(user.joinedDate),
                  style: AppFonts.roboto(fontSize: 11, color: _kMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status + Claim
          _buildUserTrailing(user, claim),
        ],
      ),
    );
  }

  Widget _buildUserInitial(String initial) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: _kGreen.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initial,
            style: AppFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _kGreen)),
      ),
    );
  }

  Widget _buildUserTrailing(ReferredUser user, ReferralRewardClaim? claim) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: user.isActive
                ? _kGreen.withValues(alpha: 0.1)
                : _kHairline,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            user.isActive ? 'সক্রিয়' : 'নিষ্ক্রিয়',
            style: AppFonts.roboto(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: user.isActive ? _kGreen : _kMuted),
          ),
        ),
        const SizedBox(width: 6),
        if (claim != null)
          claim.isClaimed
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('নেওয়া হয়েছে',
                      style: AppFonts.roboto(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: _kGreen)),
                )
              : claim.isEligible
                  ? SizedBox(
                      height: 28,
                      child: ElevatedButton(
                        onPressed: _isClaimingReward
                            ? null
                            : () => _claimReward(claim.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text('নিন ৳${claim.rewardAmount.toStringAsFixed(0)}',
                            style: AppFonts.roboto(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('অসম্পূর্ণ',
                          style: AppFonts.roboto(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.amber.shade800)),
                    )
        else
          Text('-',
              style: AppFonts.roboto(fontSize: 11, color: _kMuted)),
      ],
    );
  }
}
