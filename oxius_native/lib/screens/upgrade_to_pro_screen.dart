import 'package:flutter/material.dart';
import '../services/user_state_service.dart';
import '../services/subscription_service.dart';
import '../utils/payment_policy.dart';
import '../widgets/ios_payment_blocked_widget.dart';

class UpgradeToProScreen extends StatefulWidget {
  const UpgradeToProScreen({super.key});

  @override
  State<UpgradeToProScreen> createState() => _UpgradeToProScreenState();
}

class _UpgradeToProScreenState extends State<UpgradeToProScreen> {
  final UserStateService _userState = UserStateService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  static const Color _ink = Color(0xFF14213D);
  static const Color _muted = Color(0xFF64748B);
  static const Color _surface = Color(0xFFFFFBF4);
  static const Color _panel = Color(0xFFFFFFFF);
  static const Color _gold = Color(0xFFF59E0B);
  static const Color _peach = Color(0xFFFFE7C7);
  static const Color _sage = Color(0xFFDFF4EA);
  static const Color _mint = Color(0xFF10B981);
  static const Color _primary = Color(0xFF2563EB);

  bool _isSubscribing = false;
  bool _isLoadingBalance = true;
  int _selectedMonths = 1;
  final int _monthlyPrice = 149;
  final int _yearlyDiscount = 289;

  int get _totalPrice => _selectedMonths == 1 
      ? _monthlyPrice 
      : (_monthlyPrice * _selectedMonths) - _yearlyDiscount;

  @override
  void initState() {
    super.initState();
    _refreshBalance();
  }

  Future<void> _refreshBalance() async {
    setState(() => _isLoadingBalance = true);
    await _userState.refreshUser();
    if (mounted) {
      setState(() => _isLoadingBalance = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Defense-in-depth: block the entire screen on iOS even if the route-level
    // guard in main.dart is somehow bypassed.
    if (PaymentPolicy.shouldBlockDigitalPayment()) {
      return const Scaffold(
        body: IOSPaymentBlockedWidget(featureName: 'Pro Subscription'),
      );
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text(
          'Upgrade to Pro',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        centerTitle: false,
        backgroundColor: _surface,
        surfaceTintColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _ink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(4, 6, 4, bottomInset + 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroSection(),
            const SizedBox(height: 14),
            _buildQuickStatusStrip(),
            const SizedBox(height: 14),
            _buildPlanComposer(),
            const SizedBox(height: 14),
            _buildFeaturesSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomCheckoutBar(bottomInset),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF123261),
            Color(0xFF1E4EA8),
            Color(0xFF3B82F6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              top: -28,
              right: -18,
              child: Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -36,
              left: -8,
              child: Container(
                width: 138,
                height: 138,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Premium membership',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Move faster with Pro access',
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.08,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.9,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sell more, post more, and unlock the tools that make your account work like a business hub.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStat(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatusStrip() {
    final isPro = _userState.isPro;
    final balance = _userState.balance;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1E8D7)),
      ),
      child: Row(
        children: [
          // Membership chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isPro ? _mint.withValues(alpha: 0.12) : _gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPro ? Icons.verified_rounded : Icons.bolt_rounded,
                  size: 15,
                  color: isPro ? _mint : _gold,
                ),
                const SizedBox(width: 5),
                Text(
                  isPro ? 'Already Pro' : 'Free Plan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isPro ? _mint : const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Wallet balance chip
          GestureDetector(
            onTap: _refreshBalance,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _mint.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_rounded, size: 14, color: _mint),
                  const SizedBox(width: 5),
                  _isLoadingBalance
                      ? const SizedBox(
                          width: 12, height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: _mint),
                        )
                      : Text(
                          '৳${balance.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _mint,
                          ),
                        ),
                  const SizedBox(width: 4),
                  Icon(Icons.refresh_rounded, size: 12, color: _mint.withValues(alpha: 0.7)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanComposer() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1E8D7)),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose your Pro rhythm',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pick a plan that matches how fast you want to grow. Yearly keeps the price lower and unlocks the same tools.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: _muted,
            ),
          ),
          const SizedBox(height: 16),
          _buildDurationOption(
            1,
            'Monthly',
            'Flexible start',
            accent: _peach,
            badge: 'Popular for trial',
          ),
          const SizedBox(height: 12),
          _buildDurationOption(
            12,
            'Yearly',
            'Best value for sellers',
            accent: _sage,
            badge: 'Save ৳$_yearlyDiscount',
          ),

        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _muted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: accent,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationOption(
    int months,
    String title,
    String subtitle, {
    required Color accent,
    String? badge,
  }) {
    final isSelected = _selectedMonths == months;
    final price = months == 1
        ? '৳$_monthlyPrice / month'
        : '৳${(_monthlyPrice * 12 - _yearlyDiscount) ~/ 12} / month';
    final total = months == 1
        ? 'Total ৳$_monthlyPrice'
        : 'Total ৳${(_monthlyPrice * 12) - _yearlyDiscount}';
    
    return GestureDetector(
      onTap: () => setState(() => _selectedMonths = months),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? _ink : accent.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? _ink : accent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.12) : Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                months == 1 ? Icons.flash_on_rounded : Icons.workspace_premium_rounded,
                color: isSelected ? Colors.white : _ink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : _ink,
                          ),
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? _gold.withValues(alpha: 0.18) : Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? const Color(0xFFFFF3C4) : _ink,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.82)
                          : _muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : _primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    total,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.76)
                          : _muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? Colors.white : _muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1E8D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Everything you unlock',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Designed for sellers, service providers, and members who want stronger visibility across the app.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: _muted,
            ),
          ),
          const SizedBox(height: 18),
          _buildFeature(Icons.storefront_rounded, 'Access to eShop Manager', _peach),
          _buildFeature(Icons.shopping_bag_rounded, 'Sell products across AdsyClub', _sage),
          _buildFeature(Icons.inventory_2_rounded, 'Add up to 10 products', const Color(0xFFE5DEFF)),
          _buildFeature(Icons.all_inbox_rounded, 'Receive unlimited orders', const Color(0xFFFFE2E2)),
          _buildFeature(Icons.campaign_rounded, 'Post unlimited ads', const Color(0xFFDFF7F0)),
          _buildFeature(Icons.task_alt_rounded, 'Earn from completing tasks', const Color(0xFFFDE9D5)),
          _buildFeature(Icons.account_balance_wallet_rounded, 'Fast deposit and withdraw', const Color(0xFFE0F2FE)),
          _buildFeature(Icons.support_agent_rounded, 'Priority support 24/7', const Color(0xFFFFF1CC)),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text, Color tint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 18,
              color: _ink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: _ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: _mint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCheckoutBar(double bottomInset) {
    final isPro = _userState.isPro;
    final balance = _userState.balance;
    final hasEnoughFunds = balance >= _totalPrice;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset > 0 ? 6 : 14),
        decoration: BoxDecoration(
          color: _panel.withValues(alpha: 0.97),
          border: const Border(top: BorderSide(color: Color(0xFFF1E8D7))),
          boxShadow: [
            BoxShadow(
              color: _ink.withValues(alpha: 0.05),
              blurRadius: 24,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Insufficient funds warning
            if (!isPro && !_isLoadingBalance && !hasEnoughFunds)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_rounded, size: 16, color: Color(0xFFE11D48)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Add ৳${(_totalPrice - balance).toStringAsFixed(0)} more to your wallet.',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9F1239),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/deposit-withdraw'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE11D48),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Add Funds',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Main row: price + button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isPro ? 'Membership' : 'Total',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _muted,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPro ? 'Pro active ✓' : '৳$_totalPrice',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (!isPro)
                        Text(
                          'Wallet: ৳${balance.toStringAsFixed(0)} available',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: hasEnoughFunds ? _mint : const Color(0xFFE11D48),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubscribing ? null : _handleUpgrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPro ? _mint : _ink,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _ink.withValues(alpha: 0.55),
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubscribing
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isPro ? 'Already Pro ✓' : 'Upgrade now',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            // Trust pills
            if (!isPro) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _TrustPill(icon: Icons.lock_rounded, label: 'Secure'),
                  SizedBox(width: 6),
                  _TrustPill(icon: Icons.bolt_rounded, label: 'Instant'),
                  SizedBox(width: 6),
                  _TrustPill(icon: Icons.receipt_long_rounded, label: 'Wallet billing'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpgrade() async {
    if (!_userState.isAuthenticated) {
      _showAuthDialog();
      return;
    }

    if (_userState.isPro) {
      _showAlreadyProSnackbar();
      return;
    }

    if (_userState.balance < _totalPrice) {
      _showInsufficientFundsDialog();
      return;
    }

    setState(() => _isSubscribing = true);

    try {
      final result = await _subscriptionService.createSubscription(
        months: _selectedMonths,
        total: _totalPrice,
      );

      if (result['success'] == true) {
        await _userState.refreshUser();
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        throw Exception(result['message'] ?? 'Subscription failed');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubscribing = false);
      }
    }
  }

  void _showAuthDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Login Required'),
        content: const Text('Please log in to upgrade to Pro'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  void _showAlreadyProSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You\'re already a Pro member!'),
        backgroundColor: _mint,
      ),
    );
  }

  void _showInsufficientFundsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Insufficient Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You need ৳$_totalPrice to upgrade.'),
            const SizedBox(height: 8),
            Text(
              'Current balance: ৳${_userState.balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please add ৳${(_totalPrice - _userState.balance).toStringAsFixed(2)} more.',
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/deposit-withdraw');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _mint,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Funds'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _mint.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 60,
                color: _mint,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome to Pro!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You now have access to all premium features',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $message'),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }
}

class _TrustPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF475569)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
