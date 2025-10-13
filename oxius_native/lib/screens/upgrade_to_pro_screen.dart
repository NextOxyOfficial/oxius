import 'package:flutter/material.dart';
import '../services/user_state_service.dart';
import '../services/subscription_service.dart';

class UpgradeToProScreen extends StatefulWidget {
  const UpgradeToProScreen({super.key});

  @override
  State<UpgradeToProScreen> createState() => _UpgradeToProScreenState();
}

class _UpgradeToProScreenState extends State<UpgradeToProScreen>
    with TickerProviderStateMixin {
  final UserStateService _userState = UserStateService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _openModal = false;
  bool _showSuccessModal = false;
  bool _showFailureModal = false;
  bool _isLoading = false;
  bool _isSubscribing = false;
  String _paymentMethod = 'account_funds';
  String _errorMessage = '';
  String _transactionId = '';
  final int _price = 149;
  int _months = 1;
  final int _yearlyDiscount = 289;

  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  bool get _canSubscribe {
    if (!_userState.isAuthenticated) return false;
    if (_paymentMethod == 'account_funds') {
      final totalCost = _months == 1 ? _price : _months * _price - _yearlyDiscount;
      return _userState.balance >= totalCost;
    }
    return true;
  }

  void _showUpgradeModal() {
    if (!_userState.isAuthenticated) {
      _showAuthenticationRequired();
      return;
    }

    if (_userState.isPro) {
      _showAlreadyProMessage();
      return;
    }

    setState(() {
      _openModal = true;
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _showAuthenticationRequired() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.amber),
            SizedBox(width: 8),
            Text('Authentication Required'),
          ],
        ),
        content: const Text(
          'Please log in or register to upgrade to Pro',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login',
                  arguments: {'redirect': '/upgrade-to-pro'});
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  void _showAlreadyProMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'You\'re already enjoying all Pro features and benefits!',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _createSubscription() async {
    if (!_userState.isAuthenticated) {
      _showAuthenticationRequired();
      return;
    }

    if (_isSubscribing || !_canSubscribe) {
      if (_paymentMethod == 'account_funds' && !_canSubscribe) {
        _showInsufficientFundsDialog();
      }
      return;
    }

    setState(() {
      _isSubscribing = true;
    });

    try {
      if (_paymentMethod == 'account_funds') {
        final total = _months == 1 ? _price : _months * _price - _yearlyDiscount;
        
        final result = await _subscriptionService.createSubscription(
          months: _months,
          total: total,
        );

        if (result['success'] == true) {
          _transactionId = result['transaction_id'] ?? 'TXN_${DateTime.now().millisecondsSinceEpoch}';
          
          // Refresh user state
          await _userState.refreshUser();
          
          setState(() {
            _showSuccessModal = true;
            _openModal = false;
          });
        } else {
          throw Exception(result['message'] ?? 'Payment processing failed');
        }
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _showFailureModal = true;
        _openModal = false;
      });
    } finally {
      setState(() {
        _isSubscribing = false;
      });
    }
  }

  void _showInsufficientFundsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.orange),
            SizedBox(width: 8),
            Text('Insufficient Funds'),
          ],
        ),
        content: const Text(
          'Please add funds to your account to continue',
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
            child: const Text('Add Funds'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Pro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade50,
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildPricingCards(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          if (_openModal) _buildSubscriptionModal(context),
          if (_showSuccessModal) _buildSuccessModal(context),
          if (_showFailureModal) _buildFailureModal(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'Choose Your Plan',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Select the perfect plan for your needs.\nUpgrade anytime as your business grows.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPricingCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 800;
        
        if (isLargeScreen) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildFreePlanCard()),
              const SizedBox(width: 20),
              Expanded(child: _buildProPlanCard()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildFreePlanCard(),
              const SizedBox(height: 20),
              _buildProPlanCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildFreePlanCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.verified,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Free Plan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '৳ 0',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '/Month',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Perfect for getting started',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildFeatureItem('Access to eShop manager', false, isStrikethrough: true),
                _buildFeatureItem('Sell Products on AdsyClub', false, isStrikethrough: true),
                _buildFeatureItem('Receive Unlimited Order', false, isStrikethrough: true),
                _buildFeatureItem('Add up to 10 Products', false, isStrikethrough: true),
                _buildFeatureItem('Post unlimited ads', true),
                _buildFeatureItem('Earn money by completing task', true),
                _buildFeatureItem('Fast deposit and withdraw', true),
                _buildFeatureItem('Regular support via Email', true),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.blue.shade300),
                    ),
                    child: const Text('Get Started'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProPlanCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade300, width: 2),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade500, Colors.blue.shade700],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.verified,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Pro Plan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          '৳ 399',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          '৳ 149',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '/Month',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For businesses ready to grow',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildFeatureItem('Access to Eshop manager', true),
                    _buildFeatureItem('Sell Products on AdsyClub', true),
                    _buildFeatureItem('Receive Unlimited Order', true),
                    _buildFeatureItem('Add up to 10 Products', true),
                    _buildFeatureItem('Post Unlimited Ads', true),
                    _buildFeatureItem('Earn money by completing task', true),
                    _buildFeatureItem('Fast deposit and withdraw', true),
                    _buildFeatureItem('Priority technical support 24/7', true),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showUpgradeModal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_userState.isPro) ...[
                              const Text(
                                'Already Upgraded!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ] else ...[
                              const Icon(Icons.star),
                              const SizedBox(width: 8),
                              const Text(
                                'Upgrade Now!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade500, Colors.blue.shade700],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'RECOMMENDED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 100,
            child: Transform.rotate(
              angle: 1.5708, // 90 degrees in radians
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade500, Colors.blue.shade700],
                  ),
                ),
                child: const Text(
                  'BEST VALUE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text, bool included, {bool isStrikethrough = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: included ? Colors.blue.shade50 : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 16,
              color: included ? Colors.blue.shade600 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isStrikethrough ? Colors.grey : Colors.black87,
                decoration: isStrikethrough ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionModal(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade500, Colors.blue.shade700],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.star, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upgrade to Pro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Unlock premium features for your business',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(60),
                  child: CircularProgressIndicator(),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Duration selector
                      const Text(
                        'Select Duration',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDurationButton(
                              '1 Month',
                              _months == 1,
                              () => setState(() => _months = 1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDurationButton(
                              '1 Year (Save ৳$_yearlyDiscount)',
                              _months == 12,
                              () => setState(() => _months = 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Plan details
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('Plan:', 'Pro'),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'Price:',
                              '৳${_months == 1 ? _price : _months * _price - _yearlyDiscount}',
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow('Duration:', '${_months * 30} Days'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Payment method
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _paymentMethod == 'account_funds'
                                ? Colors.blue
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_wallet),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Account Balance',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Available: ৳${_userState.balance.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Instant',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubscribing || !_canSubscribe
                              ? null
                              : _createSubscription,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.grey,
                          ),
                          child: _isSubscribing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  !_canSubscribe
                                      ? 'Insufficient Funds'
                                      : 'Confirm Upgrade',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _openModal = false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade600 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessModal(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade500, Colors.green.shade700],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Payment Successful!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Transaction processed securely',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Plan:', 'Pro'),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Amount:',
                            '৳${_months == 1 ? _price : _months * _price - _yearlyDiscount}',
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            'Active until:',
                            DateTime.now()
                                .add(Duration(days: _months * 30))
                                .toString()
                                .split(' ')[0],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Transaction ID:'),
                        Text(
                          _transactionId,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _showSuccessModal = false);
                          Navigator.pushReplacementNamed(context, '/');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue to Home',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFailureModal(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade500, Colors.orange.shade600],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Payment Failed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'We couldn\'t process your payment',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage.isNotEmpty
                                  ? _errorMessage
                                  : 'We couldn\'t process your payment. Your account hasn\'t been charged.',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Suggested solutions:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSuggestion('Try a different payment method'),
                    _buildSuggestion('Check your account balance'),
                    _buildSuggestion('Contact customer support if issue persists'),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showFailureModal = false;
                            _openModal = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh),
                            SizedBox(width: 8),
                            Text(
                              'Try Again',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _showFailureModal = false;
                            _openModal = false;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestion(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.arrow_right,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
