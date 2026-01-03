import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../services/referral_service.dart';
import '../models/referral_models.dart';
import '../models/referral_reward_models.dart';

class ReferFriendScreen extends StatefulWidget {
  const ReferFriendScreen({super.key});

  @override
  State<ReferFriendScreen> createState() => _ReferFriendScreenState();
}

class _ReferFriendScreenState extends State<ReferFriendScreen> with SingleTickerProviderStateMixin {
  bool _isLoadingPlatform = true;
  bool _isLoadingCommissions = false;
  bool _isLoadingUsers = false;
  
  PlatformStats? _platformStats;
  CommissionData? _commissionData;
  List<ReferredUser> _referredUsers = [];
  String? _referralCode;
  String? _referralLink;
  
  String? _commissionError;
  String? _usersError;
  
  // Referral Reward Program
  MyClaimsResponse? _claimsData;
  CheckConditionsResponse? _conditionsData;
  bool _isLoadingClaims = false;
  bool _isClaimingReward = false;
  
  late TabController _tabController;
  int _activeTab = 0;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = AuthService.isAuthenticated;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _activeTab = _tabController.index);
      }
    });
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
      print('Error loading referral info: $e');
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
          _commissionError = 'Failed to load commission history';
          _isLoadingCommissions = false;
        });
      }
    }
  }

  Future<void> _loadReferredUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _usersError = null;
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
          _usersError = 'Failed to load referred users';
          _isLoadingUsers = false;
        });
      }
    }
  }

  Future<void> _loadRewardClaims() async {
    setState(() => _isLoadingClaims = true);
    try {
      final conditions = await ReferralService.checkConditions();
      if (mounted) {
        setState(() {
          _conditionsData = conditions;
        });
      }
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

    final eligible = claims.where((c) => c.claimType == 'referrer' && c.status == 'eligible').toList();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          successCount > 0
              ? 'Claimed $successCount reward(s) (৳${totalAmount.toStringAsFixed(0)})'
              : 'Failed to claim rewards',
        ),
        backgroundColor: successCount > 0 ? const Color(0xFF10B981) : Colors.red,
      ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? const Color(0xFF10B981) : Colors.red,
          ),
        );
        if (result.success) {
          _loadRewardClaims();
          AuthService.refreshUserData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to claim reward'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaimingReward = false);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareLink() {
    if (_referralLink != null) {
      Share.share(
        'Join me on AdsyClub and start earning! Use my referral link: $_referralLink',
        subject: 'Join AdsyClub',
      );
    }
  }

  void _openShareSheet() {
    final link = _referralLink;
    if (link == null || link.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Share Your Referral Link',
                          style: GoogleFonts.roboto(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            link,
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 34,
                          child: ElevatedButton.icon(
                            onPressed: () => _copyToClipboard(link),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                            label: Text(
                              'Copy',
                              style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: QrImageView(
                        data: link,
                        size: 160,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Scan to open referral link',
                      style: GoogleFonts.roboto(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Share on Social Media',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSocialButton('Facebook', Icons.facebook, const Color(0xFF1877F2), () => _shareOnSocial('facebook')),
                      _buildSocialButton('Twitter', Icons.alternate_email, const Color(0xFF1DA1F2), () => _shareOnSocial('twitter')),
                      _buildSocialButton('WhatsApp', Icons.chat, const Color(0xFF25D366), () => _shareOnSocial('whatsapp')),
                      _buildSocialButton('More', Icons.share_rounded, const Color(0xFF10B981), _shareLink),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.roboto(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareOnSocial(String platform) async {
    if (_referralLink == null) return;
    
    final encodedLink = Uri.encodeComponent(_referralLink!);
    final text = Uri.encodeComponent('Join me on AdsyClub and start earning!');
    String url = '';

    switch (platform) {
      case 'facebook':
        url = 'https://www.facebook.com/sharer/sharer.php?u=$encodedLink';
        break;
      case 'twitter':
        url = 'https://twitter.com/intent/tweet?url=$encodedLink&text=$text';
        break;
      case 'whatsapp':
        url = 'https://wa.me/?text=$text%20$encodedLink';
        break;
      case 'linkedin':
        url = 'https://www.linkedin.com/sharing/share-offsite/?url=$encodedLink';
        break;
    }

    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
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
          icon: const Icon(Icons.arrow_back_rounded, size: 22, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Refer & Earn',
          style: GoogleFonts.roboto(
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Invite Friends & Earn Together',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Earn Up to 20%',
                  style: GoogleFonts.roboto(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Commission',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Share your unique link with friends, and earn rewards with different commission rates: 5% on gig completions, 20% on subscriptions and sponsorships!',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Sign Up & Start Earning',
                          style: GoogleFonts.roboto(
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
                  'How It Works',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                _buildStep(1, 'Create Account', 'Sign up for a free account and get your unique referral link instantly', Icons.person_add_rounded),
                _buildStep(2, 'Share Your Link', 'Share your referral link with friends via email, social media, or messaging apps', Icons.share_rounded),
                _buildStep(3, 'Earn Commissions', 'Earn different commission rates: 5% on gigs, 20% on subscriptions & sponsorships', Icons.paid_rounded),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Stats
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(child: _buildStatCard('5-20%', 'Commission Rate', Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard(
                  _isLoadingPlatform ? '...' : '${_platformStats?.activeReferrers ?? 500}+',
                  'Active Referrers',
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
                Expanded(child: _buildStatCard(
                  _isLoadingPlatform ? '...' : '৳ ${_platformStats?.topEarnerAmount.toStringAsFixed(0) ?? '10000'}',
                  'Top Earner',
                  Colors.amber,
                )),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard(
                  _isLoadingPlatform ? '...' : _platformStats?.quickPayoutTime ?? '24hr',
                  'Quick Payouts',
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
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          // Referral Code Card
          Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Your Referral Code',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3), width: 2),
                  ),
                  child: Text(
                    _referralCode ?? 'Loading...',
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _copyToClipboard(_referralLink ?? ''),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: Text(
                          'Copy Link',
                          style: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openShareSheet,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF10B981)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.share_rounded, size: 16, color: Color(0xFF10B981)),
                        label: Text(
                          'Share',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF10B981),
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

          // Commission Stats
          if (_commissionData != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Earnings',
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildEarningCard(
                          '৳ ${_commissionData!.totalEarned.toStringAsFixed(0)}',
                          'Total Earned',
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildEarningCard(
                          '${_commissionData!.recentTransactions.length}',
                          'Transactions',
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (_commissionData != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commission Breakdown',
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBreakdownItem(
                    title: 'Gig Completions',
                    color: Colors.blue,
                    rate: _commissionData!.commissionBreakdown.gigCompletion.rate,
                    count: _commissionData!.commissionBreakdown.gigCompletion.count,
                    amount: _commissionData!.commissionBreakdown.gigCompletion.totalAmount,
                  ),
                  const SizedBox(height: 10),
                  _buildBreakdownItem(
                    title: 'Pro Subscriptions',
                    color: Colors.purple,
                    rate: _commissionData!.commissionBreakdown.proSubscription.rate,
                    count: _commissionData!.commissionBreakdown.proSubscription.count,
                    amount: _commissionData!.commissionBreakdown.proSubscription.totalAmount,
                  ),
                  const SizedBox(height: 10),
                  _buildBreakdownItem(
                    title: 'Gold Sponsors',
                    color: Colors.amber,
                    rate: _commissionData!.commissionBreakdown.goldSponsor.rate,
                    count: _commissionData!.commissionBreakdown.goldSponsor.count,
                    amount: _commissionData!.commissionBreakdown.goldSponsor.totalAmount,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF10B981),
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600),
                  indicatorColor: const Color(0xFF10B981),
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    Tab(text: 'Earnings (${_commissionData?.recentTransactions.length ?? 0})'),
                    Tab(text: 'Referred & Bonus'),
                  ],
                ),
                Container(
                  height: 340,
                  padding: const EdgeInsets.all(8),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEarningsTab(),
                      _buildReferredAndBonusTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.roboto(
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
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.roboto(
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
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEarningCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 10,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem({
    required String title,
    required Color color,
    required String rate,
    required int count,
    required double amount,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count transaction(s) • $rate',
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '৳ ${amount.toStringAsFixed(0)}',
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsTab() {
    if (_isLoadingCommissions) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    }

    if (_commissionError != null) {
      return Center(
        child: Text(
          _commissionError!,
          style: GoogleFonts.roboto(fontSize: 12, color: Colors.red),
        ),
      );
    }

    if (_commissionData == null || _commissionData!.recentTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'No earnings yet',
              style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _commissionData!.recentTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _commissionData!.recentTransactions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
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
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.referredUser?.name ?? 'Unknown User',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      '${transaction.type} (${transaction.commissionRate})',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '৳ ${transaction.amount.toStringAsFixed(0)}',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  Text(
                    _formatDate(transaction.date),
                    style: GoogleFonts.roboto(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReferredAndBonusTab() {
    // Loading state
    if (_isLoadingUsers || _isLoadingClaims) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    }

    // Not logged in
    if (!_isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'Login to view referrals & bonus',
              style: GoogleFonts.roboto(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    final claims = _claimsData;
    final hasBonus = claims != null && claims.activeProgram;
    final hasReferredUsers = _referredUsers.isNotEmpty;

    // Empty state
    if (!hasReferredUsers && !hasBonus) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'No referred users or bonus yet',
              style: GoogleFonts.roboto(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Bonus Program Card (compact)
        if (hasBonus) _buildCompactBonusCard(),
        
        // Referred Users Section
        if (hasReferredUsers) ...[
          if (hasBonus) const SizedBox(height: 8),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  claims.program?.name ?? 'Referral Reward',
                  style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              if (_eligibleReferrerClaimsCount > 0)
                SizedBox(
                  height: 26,
                  child: ElevatedButton(
                    onPressed: _isClaimingReward ? null : _claimAllRewards,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    child: _isClaimingReward
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0EA5E9)))
                        : Text('Claim All ($_eligibleReferrerClaimsCount)', style: GoogleFonts.roboto(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF0EA5E9))),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Claims summary
          if (refereeClaim != null || referrerClaims.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (refereeClaim != null) _buildMiniClaimChip(refereeClaim, isReferee: true),
                ...referrerClaims.take(3).map((c) => _buildMiniClaimChip(c, isReferee: false)),
                if (referrerClaims.length > 3)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                    child: Text('+${referrerClaims.length - 3} more', style: GoogleFonts.roboto(fontSize: 9, color: Colors.white)),
                  ),
              ],
            )
          else
            Text('Refer friends to earn rewards!', style: GoogleFonts.roboto(fontSize: 10, color: Colors.white.withOpacity(0.9))),
        ],
      ),
    );
  }

  Widget _buildMiniClaimChip(ReferralRewardClaim claim, {required bool isReferee}) {
    final isClaimed = claim.isClaimed;
    final isEligible = claim.isEligible;
    return GestureDetector(
      onTap: isEligible && !_isClaimingReward ? () => _claimReward(claim.id) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isClaimed ? Icons.check_circle_rounded : isEligible ? Icons.card_giftcard_rounded : Icons.hourglass_empty_rounded,
              size: 12,
              color: isClaimed ? Colors.green : isEligible ? const Color(0xFF10B981) : Colors.amber.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              '৳${claim.rewardAmount.toStringAsFixed(0)}',
              style: GoogleFonts.roboto(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937)),
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
        Row(
          children: [
            Text(
              'Referred Users (${_referredUsers.length})',
              style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ..._referredUsers.map((user) {
          final claim = _getClaimForReferredUser(user.id);
          final avatarUrl = AppConfig.getAbsoluteUrl(user.image);

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                // Avatar
                avatarUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          avatarUrl,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildUserInitial(user.initial),
                        ),
                      )
                    : _buildUserInitial(user.initial),
                const SizedBox(width: 8),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF1F2937)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatDate(user.joinedDate),
                        style: GoogleFonts.roboto(fontSize: 9, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                // Status + Claim
                _buildUserTrailing(user, claim),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildUserInitial(String initial) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(initial, style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF10B981))),
      ),
    );
  }

  Widget _buildUserTrailing(ReferredUser user, ReferralRewardClaim? claim) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: user.isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            user.isActive ? 'Active' : 'Inactive',
            style: GoogleFonts.roboto(fontSize: 8, fontWeight: FontWeight.w600, color: user.isActive ? Colors.green : Colors.grey),
          ),
        ),
        const SizedBox(width: 6),
        if (claim != null)
          claim.isClaimed
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Claimed', style: GoogleFonts.roboto(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.green)),
                )
              : claim.isEligible
                  ? SizedBox(
                      height: 24,
                      child: ElevatedButton(
                        onPressed: _isClaimingReward ? null : () => _claimReward(claim.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                        child: Text('৳${claim.rewardAmount.toStringAsFixed(0)}', style: GoogleFonts.roboto(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text('Incompleted', style: GoogleFonts.roboto(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.amber.shade700)),
                    )
        else
          Text('-', style: GoogleFonts.roboto(fontSize: 10, color: Colors.grey.shade400)),
      ],
    );
  }
}
