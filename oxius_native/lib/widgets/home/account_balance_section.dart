import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/wallet_service.dart';
import '../../services/auth_service.dart';
import '../../services/translation_service.dart';
import '../../models/wallet_models.dart';
import '../../screens/wallet/wallet_screen.dart';
import '../../screens/microgig/pending_tasks_screen.dart';

class AccountBalanceSection extends StatefulWidget {
  const AccountBalanceSection({super.key});

  @override
  State<AccountBalanceSection> createState() => AccountBalanceSectionState();
}

class AccountBalanceSectionState extends State<AccountBalanceSection> {
  final TranslationService _translationService = TranslationService();
  WalletBalance? _balance;
  bool _isLoading = true;

  String t(String key) => _translationService.translate(key);

  @override
  void initState() {
    super.initState();
    loadBalance();
  }

  Future<void> loadBalance() async {
    setState(() => _isLoading = true);
    final balance = await WalletService.getBalance();
    if (mounted) {
      setState(() {
        _balance = balance;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show if user is authenticated
    if (!AuthService.isAuthenticated) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isSmallMobile = screenWidth < 640;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 4 : 8,
        vertical: isSmallMobile ? 8 : 12,
      ),
      constraints: BoxConstraints(
        maxWidth: screenWidth < 896 ? double.infinity : 896, // md:max-w-4xl
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFD1FAE5), // from-green-100
            Color(0xFFCCFBF1), // to-teal-100/60
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF34D399).withOpacity(0.7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: isSmallMobile ? 80 : 128,
              height: isSmallMobile ? 80 : 128,
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: isSmallMobile ? 100 : 160,
              height: isSmallMobile ? 100 : 160,
              decoration: BoxDecoration(
                color: const Color(0xFF99F6E4).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Content
          _isLoading
              ? Padding(
                  padding: EdgeInsets.all(isSmallMobile ? 16.0 : 24.0),
                  child: const Center(child: CircularProgressIndicator()),
                )
              : Column(
                  children: [
                    // Balance cards section
                    Padding(
                      padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
                      child: Column(
                        children: [
                          // Main balance and pending tasks - responsive layout
                          isMobile
                              ? Column(
                                  children: [
                                    _buildBalanceCard(
                                      icon: Icons.account_balance_wallet_outlined,
                                      label: t('balance'),
                                      amount: _balance?.balance ?? 0.0,
                                      color: const Color(0xFF10B981),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      isSmallMobile: isSmallMobile,
                                    ),
                                    SizedBox(height: isSmallMobile ? 8 : 12),
                                    _buildPendingTasksCard(
                                      amount: _balance?.pendingBalance ?? 0.0,
                                      isSmallMobile: isSmallMobile,
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: _buildBalanceCard(
                                        icon: Icons.account_balance_wallet_outlined,
                                        label: t('balance'),
                                        amount: _balance?.balance ?? 0.0,
                                        color: const Color(0xFF10B981),
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF10B981), Color(0xFF14B8A6)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        isSmallMobile: isSmallMobile,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildPendingTasksCard(
                                        amount: _balance?.pendingBalance ?? 0.0,
                                        isSmallMobile: isSmallMobile,
                                      ),
                                    ),
                                  ],
                                ),
                          
                          // Action buttons
                          SizedBox(height: isSmallMobile ? 12 : 16),
                          _buildActionButtons(context, isSmallMobile: isSmallMobile),
                        ],
                      ),
                    ),
                    
                    // Divider with dot accent
                    _buildDividerWithDot(),
                    
                    // Referral section
                    _buildReferralSection(isSmallMobile: isSmallMobile),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildDividerWithDot() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: Colors.grey[300],
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF34D399).withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReferralSection({bool isSmallMobile = false}) {
    final user = AuthService.currentUser;
    if (user == null) return const SizedBox.shrink();

    final referralLink = 'https://adsyclub.com/auth/register/?ref=${user.referralCode ?? ''}';

    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.5),
            const Color(0xFFD1FAE5).withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Refer header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.group,
                color: Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                t('refer'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Referral link input with copy button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF34D399).withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(
                      referralLink,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: referralLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(t('copied')),
                          duration: const Duration(seconds: 2),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    },
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Copy',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Referral stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  label: t('refer_user'),
                  value: user.referCount?.toString() ?? '0',
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                _buildStatItem(
                  label: t('earnings'),
                  value: '৳${user.commissionEarned?.toStringAsFixed(2) ?? '0.00'}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF065F46),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
    required Gradient gradient,
    bool isSmallMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isSmallMobile ? 36 : 40,
                height: isSmallMobile ? 36 : 40,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: isSmallMobile ? 18 : 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: isSmallMobile ? 11 : 12,
                        fontWeight: FontWeight.w500,
                        color: color.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '৳',
                          style: TextStyle(
                            fontSize: isSmallMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            amount.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: isSmallMobile ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTasksCard({required double amount, bool isSmallMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFBBF24).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isSmallMobile ? 36 : 40,
                height: isSmallMobile ? 36 : 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFBBF24).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.watch_later_outlined, color: Colors.white, size: isSmallMobile ? 18 : 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('pending_task'),
                      style: TextStyle(
                        fontSize: isSmallMobile ? 11 : 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '৳',
                          style: TextStyle(
                            fontSize: isSmallMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          amount.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: isSmallMobile ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PendingTasksScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t('view'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, {bool isSmallMobile = false}) {
    final buttons = [
      _buildActionButton(
        context: context,
        icon: Icons.account_balance,
        label: t('transaction'),
        color: const Color(0xFF10B981),
        isSmallMobile: isSmallMobile,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WalletScreen(),
            ),
          );
        },
      ),
      _buildActionButton(
        context: context,
        icon: Icons.mark_email_unread_outlined,
        label: t('inbox'),
        color: const Color(0xFF3B82F6),
        isSmallMobile: isSmallMobile,
        onTap: () {
          Navigator.pushNamed(context, '/inbox');
        },
      ),
      _buildActionButton(
        context: context,
        icon: Icons.list_rounded,
        label: t('my_gigs'),
        color: const Color(0xFF8B5CF6),
        isSmallMobile: isSmallMobile,
        onTap: () {
          Navigator.pushNamed(context, '/my-gigs');
        },
      ),
      _buildActionButton(
        context: context,
        icon: Icons.add_circle_outline,
        label: t('post_gigs'),
        color: const Color(0xFF64748B),
        isSmallMobile: isSmallMobile,
        onTap: () {
          Navigator.pushNamed(context, '/post-a-gig');
        },
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < buttons.length; i++) ...[          if (i > 0) SizedBox(width: isSmallMobile ? 6 : 8),
          Expanded(child: buttons[i]),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isSmallMobile = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isSmallMobile ? 8 : 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: isSmallMobile ? 18 : 20),
            SizedBox(height: isSmallMobile ? 2 : 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallMobile ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
