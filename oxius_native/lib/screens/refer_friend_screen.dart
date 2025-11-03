import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/referral_service.dart';
import '../models/referral_models.dart';
import 'dart:math' as math;

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
                        onPressed: _shareLink,
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
                  labelStyle: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w600),
                  indicatorColor: const Color(0xFF10B981),
                  tabs: [
                    Tab(text: 'Earnings (${_commissionData?.recentTransactions.length ?? 0})'),
                    Tab(text: 'Referred (${_referredUsers.length})'),
                  ],
                ),
                Container(
                  height: 300,
                  padding: const EdgeInsets.all(12),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEarningsTab(),
                      _buildReferredUsersTab(),
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

  Widget _buildReferredUsersTab() {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    }

    if (_usersError != null) {
      return Center(
        child: Text(
          _usersError!,
          style: GoogleFonts.roboto(fontSize: 12, color: Colors.red),
        ),
      );
    }

    if (_referredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'No referred users yet',
              style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _referredUsers.length,
      itemBuilder: (context, index) {
        final user = _referredUsers[index];
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    user.name[0].toUpperCase(),
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
                      user.name,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Joined ${_formatDate(user.joinedDate)}',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: user.status == 'active'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.status,
                  style: GoogleFonts.roboto(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: user.status == 'active' ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
