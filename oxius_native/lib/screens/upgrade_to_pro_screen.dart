import 'package:flutter/material.dart';
import '../services/user_state_service.dart';
import '../services/subscription_service.dart';
import '../utils/payment_policy.dart';
import '../widgets/ios_payment_blocked_widget.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

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
  static const Color _surface = Color(0xFFF8FAFC);
  static const Color _panel = Color(0xFFFFFFFF);
  static const Color _gold = Color(0xFFF59E0B);
  static const Color _peach = Color(0xFFFFE7C7);
  static const Color _sage = Color(0xFFDFF4EA);
  static const Color _mint = Color(0xFF10B981);
  static const Color _primary = Color(0xFF2563EB);

  bool _isSubscribing = false;
  bool _isLoadingBalance = false;
  bool _autoRenew = false;
  bool _autoRenewBusy = false;
  bool _autoRenewLoaded = false;
  bool? _hasActivePro; // server-confirmed paid-Pro status (null until loaded)
  int _selectedMonths = 1;
  int _monthlyPrice = 149; // effective (discounted) monthly price
  int _regularPrice = 299; // normal monthly price (struck-through)
  int _yearlyDiscount = 289;
  bool _discountActive = true;

  int get _totalPrice => _selectedMonths == 1
      ? _monthlyPrice
      : (_monthlyPrice * _selectedMonths) - _yearlyDiscount;

  // Prefer the server's confirmed paid-Pro status once loaded; fall back to the
  // cached (possibly stale) user state until then — so an expired/cancelled or
  // free account never shows "Pro active".
  bool get _isPro => _hasActivePro ?? _userState.isPro;

  @override
  void initState() {
    super.initState();
    _refreshBalance();
    _loadAutoRenew();
    _loadPricing();
  }

  Future<void> _loadPricing() async {
    final data = await _subscriptionService.getProPricing();
    if (!mounted || data == null) return;
    int? toInt(dynamic v) => double.tryParse('$v')?.round();
    setState(() {
      _monthlyPrice = toInt(data['effective_price']) ?? _monthlyPrice;
      _regularPrice = toInt(data['regular_price']) ?? _regularPrice;
      _yearlyDiscount = toInt(data['yearly_discount']) ?? _yearlyDiscount;
      _discountActive = data['discount_active'] == true;
    });
  }

  Future<void> _loadAutoRenew() async {
    // Always ask the server for the authoritative paid-Pro status so the screen
    // never relies on a stale cached flag.
    final data = await _subscriptionService.getAutoRenew();
    if (!mounted || data == null) return;
    setState(() {
      _hasActivePro = data['has_active_pro'] == true;
      _autoRenew = data['auto_renew'] == true;
      _autoRenewLoaded = _hasActivePro == true;
    });
  }

  Future<void> _toggleAutoRenew(bool value) async {
    if (_autoRenewBusy) return;
    setState(() {
      _autoRenewBusy = true;
      _autoRenew = value; // optimistic
    });
    final result = await _subscriptionService.setAutoRenew(value);
    if (!mounted) return;
    setState(() {
      _autoRenewBusy = false;
      if (result != null && result['auto_renew'] is bool) {
        _autoRenew = result['auto_renew'] as bool;
      } else {
        _autoRenew = !value; // revert on failure
      }
    });
    final msg = (result?['message'] ?? '').toString();
    if (msg.isNotEmpty) {
      if (_autoRenew) {
        AdsyToast.success(context, msg);
      } else {
        AdsyToast.info(context, msg);
      }
    }
  }

  Future<void> _refreshBalance() async {
    if (_isLoadingBalance && mounted) return;
    if (mounted) {
      setState(() => _isLoadingBalance = true);
    }

    try {
      final refreshed = await _userState.refreshUser();
      if (!refreshed && mounted && _userState.isAuthenticated) {
        AdsyToast.error(
            context, 'Could not refresh balance. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingBalance = false);
      }
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
        padding: EdgeInsets.fromLTRB(2, 8, 2, bottomInset + 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildQuickStatusStrip(),
            if (_isPro) ...[
              const SizedBox(height: 10),
              _buildAutoRenewCard(),
            ],
            const SizedBox(height: 10),
            _buildPlanComposer(),
            const SizedBox(height: 10),
            _buildFeaturesSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomCheckoutBar(bottomInset),
    );
  }

  Widget _buildQuickStatusStrip() {
    final isPro = _isPro;
    final balance = _userState.balance;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          // Membership chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isPro
                  ? _mint.withValues(alpha: 0.12)
                  : _gold.withValues(alpha: 0.12),
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
          Container(
            padding: const EdgeInsets.only(left: 10, right: 4),
            decoration: BoxDecoration(
              color: _mint.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet_rounded,
                    size: 15, color: _mint),
                const SizedBox(width: 5),
                Text(
                  '৳${balance.toStringAsFixed(0)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _mint,
                  ),
                ),
                SizedBox(
                  width: 34,
                  height: 34,
                  child: IconButton(
                    tooltip: 'Refresh balance',
                    onPressed: _refreshBalance,
                    padding: EdgeInsets.zero,
                    icon: _isLoadingBalance
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: AdsyLoadingIndicator(
                              strokeWidth: 1.7,
                              color: _mint,
                            ),
                          )
                        : Icon(
                            Icons.refresh_rounded,
                            size: 21,
                            color: _mint.withValues(alpha: 0.9),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoRenewCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _mint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.autorenew_rounded, color: _mint, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'অটো-রিনিউ',
                  style: TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w700, color: _ink),
                ),
                SizedBox(height: 2),
                Text(
                  'মেয়াদ শেষে Adsy Pay ব্যালেন্স থেকে স্বয়ংক্রিয়ভাবে রিনিউ হবে।',
                  style: TextStyle(fontSize: 11.5, color: _muted, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_autoRenewBusy)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          else
            Switch.adaptive(
              value: _autoRenew,
              activeThumbColor: _mint,
              onChanged: _autoRenewLoaded ? _toggleAutoRenew : null,
            ),
        ],
      ),
    );
  }

  Widget _buildPlanComposer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Pro plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Same features, different billing period.',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: _muted,
            ),
          ),
          const SizedBox(height: 12),
          _buildDurationOption(
            1,
            'Monthly',
            accent: _peach,
            badge: 'Trial',
          ),
          const SizedBox(height: 10),
          _buildDurationOption(
            12,
            'Yearly',
            accent: _sage,
            badge: 'Save ৳$_yearlyDiscount',
          ),
        ],
      ),
    );
  }

  Widget _buildDurationOption(
    int months,
    String title, {
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _ink : const Color(0xFFE5E7EB),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                months == 1
                    ? Icons.flash_on_rounded
                    : Icons.workspace_premium_rounded,
                color: _ink,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          total,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (months == 1 &&
                          _discountActive &&
                          _regularPrice > _monthlyPrice)
                        Text(
                          '৳$_regularPrice',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _muted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        price,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? _ink : _muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Included with Pro',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeature(Icons.storefront_rounded, 'eShop Manager access'),
          _buildFeature(Icons.inventory_2_rounded, 'Add up to 10 products'),
          _buildFeature(Icons.campaign_rounded, 'Unlimited ad posting'),
          _buildFeature(Icons.school_rounded, 'Unlimited eLearning access'),
          _buildFeature(Icons.task_alt_rounded, 'Task earning access'),
          _buildFeature(Icons.support_agent_rounded, 'Priority support'),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 16,
              color: _ink,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: _ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Icon(
              Icons.check_circle_rounded,
              size: 16,
              color: _mint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCheckoutBar(double bottomInset) {
    final isPro = _isPro;
    final balance = _userState.balance;
    final hasEnoughFunds = balance >= _totalPrice;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 10, 12, bottomInset > 0 ? 6 : 12),
        decoration: BoxDecoration(
          color: _panel.withValues(alpha: 0.97),
          border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_rounded,
                          size: 16, color: Color(0xFFE11D48)),
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
                        onTap: () =>
                            Navigator.pushNamed(context, '/deposit-withdraw'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
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
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _ink,
                        ),
                      ),
                      if (!isPro)
                        Text(
                          'Wallet: ৳${balance.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: hasEnoughFunds
                                ? _mint
                                : const Color(0xFFE11D48),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubscribing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: AdsyLoadingIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
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

    if (_isPro) {
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
    AdsyToast.success(context, 'You\'re already a Pro member!');
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
    AdsyToast.error(context, 'Error: $message');
  }
}
