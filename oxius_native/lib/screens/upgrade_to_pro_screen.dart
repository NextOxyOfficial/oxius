import 'package:flutter/material.dart';
import '../services/user_state_service.dart';
import '../services/subscription_service.dart';

class UpgradeToProScreen extends StatefulWidget {
  const UpgradeToProScreen({super.key});

  @override
  State<UpgradeToProScreen> createState() => _UpgradeToProScreenState();
}

class _UpgradeToProScreenState extends State<UpgradeToProScreen> {
  final UserStateService _userState = UserStateService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _isSubscribing = false;
  int _selectedMonths = 1;
  final int _monthlyPrice = 149;
  final int _yearlyDiscount = 289;

  int get _totalPrice => _selectedMonths == 1 
      ? _monthlyPrice 
      : (_monthlyPrice * _selectedMonths) - _yearlyDiscount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Upgrade to Pro',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(4),
        child: Column(
          children: [
            // Hero Section
            _buildHeroSection(),
            const SizedBox(height: 4),
            
            // Pricing Cards
            _buildPricingCard(),
            const SizedBox(height: 4),
            
            // Features List
            _buildFeaturesSection(),
            const SizedBox(height: 4),
            
            // CTA Button
            _buildCTAButton(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Unlock Premium Features',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Grow your business with powerful tools',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Duration Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Plan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDurationOption(1, 'Monthly', '৳$_monthlyPrice/mo'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDurationOption(12, 'Yearly', '৳${(_monthlyPrice * 12 - _yearlyDiscount) ~/ 12}/mo', 
                        badge: 'Save ৳$_yearlyDiscount'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Price Display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '৳',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    Text(
                      _totalPrice.toString(),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'for ${_selectedMonths == 1 ? "1 month" : "12 months"}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (_selectedMonths == 12) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.savings, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          'You save ৳$_yearlyDiscount',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationOption(int months, String title, String price, {String? badge}) {
    final isSelected = _selectedMonths == months;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedMonths = months),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge.split(' ')[0], // Just "Save"
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s Included',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          _buildFeature(Icons.store, 'Access to eShop Manager'),
          _buildFeature(Icons.shopping_bag, 'Sell Products on AdsyClub'),
          _buildFeature(Icons.inventory_2, 'Add up to 10 Products'),
          _buildFeature(Icons.all_inbox, 'Receive Unlimited Orders'),
          _buildFeature(Icons.campaign, 'Post Unlimited Ads'),
          _buildFeature(Icons.task_alt, 'Earn from Completing Tasks'),
          _buildFeature(Icons.account_balance_wallet, 'Fast Deposit & Withdraw'),
          _buildFeature(Icons.support_agent, 'Priority Support 24/7'),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(
            Icons.check_circle,
            size: 18,
            color: Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButton() {
    return Container(
      margin: const EdgeInsets.all(4),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubscribing ? null : _handleUpgrade,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isSubscribing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _userState.isPro ? 'Already Pro' : 'Upgrade Now',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
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
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _showInsufficientFundsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Funds'),
        content: Text('You need ৳$_totalPrice. Current balance: ৳${_userState.balance.toStringAsFixed(2)}'),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 60,
                color: Color(0xFF10B981),
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
              backgroundColor: const Color(0xFF3B82F6),
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
