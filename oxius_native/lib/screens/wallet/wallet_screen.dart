import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';
import '../../services/user_state_service.dart';
import '../../services/auth_service.dart';
import '../../services/translation_service.dart';
import '../../widgets/home/account_balance_section.dart';
import '../../widgets/home/mobile_recharge_section.dart';
import 'deposit_tab.dart';
import 'payment_verification_screen.dart';
import 'withdraw_tab.dart';
import 'transfer_tab.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

const _indigo = Color(0xFF6366F1);
const _violet = Color(0xFF8B5CF6);
const _slate50 = Color(0xFFF8FAFC);
const _slate200 = Color(0xFFE2E8F0);
const _slate500 = Color(0xFF64748B);
const _slate800 = Color(0xFF1E293B);

class WalletScreen extends StatefulWidget {
  final String? paymentCallbackUrl;

  const WalletScreen({super.key, this.paymentCallbackUrl});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  WalletBalance? _balance;
  int _currentTab = 0;
  String _transactionTab = 'sent'; // 'sent' or 'received'
  List<Transaction> _sentTransactions = [];
  List<Transaction> _receivedTransactions = [];
  bool _isLoadingTransactions = true;

  // Pagination
  static const int _pageSize = 20;
  int _sentPage = 1;
  int _receivedPage = 1;
  bool _hasMoreSent = true;
  bool _hasMoreReceived = true;
  bool _isLoadingMoreSent = false;
  bool _isLoadingMoreReceived = false;
  final ScrollController _transactionScrollController = ScrollController();

  final UserStateService _userState = UserStateService();
  final TranslationService _translationService = TranslationService();
  final GlobalKey<AccountBalanceSectionState> _balanceKey = GlobalKey();
  bool _isResumingPendingPayment = false;

  String t(String key) => _translationService.translate(key);

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadBalance();
    _loadTransactions();
    _resumePendingPaymentIfNeeded();

    // Add scroll listener for pagination
    _transactionScrollController.addListener(_onTransactionScroll);
  }

  void _resumePendingPaymentIfNeeded() {
    final callbackUrl = widget.paymentCallbackUrl;
    if (callbackUrl == null ||
        callbackUrl.isEmpty ||
        _isResumingPendingPayment) {
      return;
    }

    _isResumingPendingPayment = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pendingPayment = await WalletService.getPendingPaymentSession();
      if (!mounted || pendingPayment == null) {
        _isResumingPendingPayment = false;
        return;
      }

      final orderId = pendingPayment['order_id']?.toString();
      final checkoutUrl = pendingPayment['checkout_url']?.toString();
      final amountValue = pendingPayment['amount'];
      final amount = amountValue is num
          ? amountValue.toDouble()
          : double.tryParse(amountValue?.toString() ?? '0') ?? 0;
      final verificationOrderId =
          WalletService.extractVerificationOrderIdFromUrl(callbackUrl) ??
              pendingPayment['verification_order_id']?.toString() ??
              orderId;

      if (orderId == null ||
          checkoutUrl == null ||
          verificationOrderId == null) {
        _isResumingPendingPayment = false;
        return;
      }

      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => PaymentVerificationScreen(
            orderId: orderId,
            verificationOrderId: verificationOrderId,
            checkoutUrl: checkoutUrl,
            amount: amount,
            resumeOnly: true,
            initialGatewayUrl: callbackUrl,
          ),
        ),
      );

      if (completed == true) {
        await _refreshAll();
      }

      _isResumingPendingPayment = false;
    });
  }

  void _onTransactionScroll() {
    if (_transactionScrollController.position.pixels >=
        _transactionScrollController.position.maxScrollExtent - 200) {
      if (_transactionTab == 'sent' && !_isLoadingMoreSent && _hasMoreSent) {
        _loadMoreSentTransactions();
      } else if (_transactionTab == 'received' &&
          !_isLoadingMoreReceived &&
          _hasMoreReceived) {
        _loadMoreReceivedTransactions();
      }
    }
  }

  @override
  void dispose() {
    _transactionScrollController.dispose();
    super.dispose();
  }

  void _checkAuthentication() {
    // Check if user is logged in
    if (!AuthService.isAuthenticated) {
      // User is not logged in, redirect to login page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login to access AdsyPay'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }

  Future<void> _loadBalance() async {
    // Always refresh user data first to get latest balance
    await AuthService.refreshUserData();

    final balance = await WalletService.getBalance();
    if (mounted) {
      setState(() {
        _balance = balance;
      });
      // Also refresh the AccountBalanceSection
      _balanceKey.currentState?.loadBalance();
    }
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;

    setState(() {
      _isLoadingTransactions = true;
      _sentPage = 1;
      _receivedPage = 1;
    });

    try {
      final sent = await WalletService.getTransactions(
          page: _sentPage, pageSize: _pageSize);
      final received = await WalletService.getReceivedTransfers(
          page: _receivedPage, pageSize: _pageSize);

      if (mounted) {
        setState(() {
          _sentTransactions = sent;
          _receivedTransactions = received;
          _hasMoreSent = sent.length >= _pageSize;
          _hasMoreReceived = received.length >= _pageSize;
          _isLoadingTransactions = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      if (mounted) {
        setState(() {
          _sentTransactions = [];
          _receivedTransactions = [];
          _isLoadingTransactions = false;
        });
      }
    }
  }

  Future<void> _loadMoreSentTransactions() async {
    if (_isLoadingMoreSent || !_hasMoreSent) return;

    setState(() {
      _isLoadingMoreSent = true;
      _sentPage++;
    });

    final moreSent = await WalletService.getTransactions(
        page: _sentPage, pageSize: _pageSize);

    if (mounted) {
      setState(() {
        _sentTransactions.addAll(moreSent);
        _hasMoreSent = moreSent.length >= _pageSize;
        _isLoadingMoreSent = false;
      });
    }
  }

  Future<void> _loadMoreReceivedTransactions() async {
    if (_isLoadingMoreReceived || !_hasMoreReceived) return;

    setState(() {
      _isLoadingMoreReceived = true;
      _receivedPage++;
    });

    final moreReceived = await WalletService.getReceivedTransfers(
        page: _receivedPage, pageSize: _pageSize);

    if (mounted) {
      setState(() {
        _receivedTransactions.addAll(moreReceived);
        _hasMoreReceived = moreReceived.length >= _pageSize;
        _isLoadingMoreReceived = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    // Refresh both balance and transactions
    await Future.wait([
      _loadBalance(),
      _loadTransactions(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _slate50,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_indigo, _violet]),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'AdsyPay',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _slate800,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: _slate800,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: AdsyRefreshIndicator(
        onRefresh: _refreshAll,
        color: _indigo,
        child: SingleChildScrollView(
          controller: _transactionScrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Balance Cards Section - Using Homepage Component
              AccountBalanceSection(key: _balanceKey),

              // Mobile Recharge Section
              const MobileRechargeSection(),

              // Compact Tab Buttons
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _slate200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.035),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        0,
                        Icons.arrow_downward,
                        'Deposit',
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        1,
                        Icons.arrow_upward,
                        'Withdraw',
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        2,
                        Icons.swap_horiz,
                        'Transfer',
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Content
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _slate200),
                  ),
                  child: _currentTab == 0
                      ? DepositTab(
                          balance: _balance?.balance ?? 0.0,
                          onDepositSuccess: () async {
                            await _loadBalance();
                            await _loadTransactions();
                          },
                        )
                      : _currentTab == 1
                          ? WithdrawTab(
                              balance: _balance?.balance ?? 0.0,
                              onWithdrawSuccess: () async {
                                await _loadBalance();
                                await _loadTransactions();
                              },
                            )
                          : TransferTab(
                              balance: _balance?.balance ?? 0.0,
                              userPhone: _userState.userEmail,
                              onTransferSuccess: () async {
                                await _loadBalance();
                                await _loadTransactions();
                              },
                            ),
                ),
              ),

              // Transaction History Section (Always show)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: _indigo.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.history_rounded,
                              size: 14,
                              color: _indigo,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            t('transaction_history'),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _slate800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Transaction Type Toggle
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _slate200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTransactionTabButton('sent', 'Sent'),
                          ),
                          Expanded(
                            child: _buildTransactionTabButton(
                                'received', 'Received'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Transaction List
                    _isLoadingTransactions
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: AdsyLoadingIndicator(),
                            ),
                          )
                        : _buildTransactionList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [_indigo, _violet])
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : _slate500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : _slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return Icons.arrow_downward;
      case 'withdraw':
        return Icons.arrow_upward;
      case 'transfer':
        return Icons.swap_horiz;
      case 'diamond_purchase':
      case 'diamond_gift':
      case 'diamond_bonus':
      case 'diamond_refund':
      case 'diamond_admin':
        return Icons.diamond;
      case 'mobile_recharge':
        return Icons.phone_android;
      case 'order_payment':
        return Icons.shopping_bag;
      case 'ride_payment':
      case 'ride_cash':
        return Icons.local_taxi_rounded;
      case 'pro_subscription':
        return Icons.workspace_premium;
      case 'referral_commission':
        return Icons.people;
      case 'referral_reward':
        return Icons.card_giftcard;
      default:
        return Icons.money;
    }
  }

  Color _getTransactionColor(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return const Color(0xFF10B981);
      case 'withdraw':
        return const Color(0xFFEF4444);
      case 'transfer':
        return const Color(0xFF3B82F6);
      case 'diamond_purchase':
      case 'diamond_gift':
      case 'diamond_bonus':
      case 'diamond_refund':
      case 'diamond_admin':
        return const Color(0xFF9333EA); // Purple
      case 'mobile_recharge':
        return const Color(0xFF3B82F6); // Blue
      case 'order_payment':
        return const Color(0xFF059669); // Green
      case 'ride_payment':
      case 'ride_cash':
        return const Color(0xFF0F766E); // Teal
      case 'pro_subscription':
        return const Color(0xFFF59E0B); // Amber
      case 'referral_commission':
        return const Color(0xFFEAB308); // Yellow
      case 'referral_reward':
        return const Color(0xFF0EA5E9); // Sky
      default:
        return Colors.grey;
    }
  }

  Widget _buildTransactionTabButton(String value, String label) {
    final isSelected = _transactionTab == value;
    return GestureDetector(
      onTap: () => setState(() => _transactionTab = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? _indigo.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? _indigo : _slate500,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactions =
        _transactionTab == 'sent' ? _sentTransactions : _receivedTransactions;

    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 40, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                'No $_transactionTab transactions',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _slate500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isLoadingMore =
        _transactionTab == 'sent' ? _isLoadingMoreSent : _isLoadingMoreReceived;

    return ListView.builder(
      key: ValueKey('${_transactionTab}_${transactions.length}'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading skeleton at bottom
        if (index == transactions.length) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFC),
              border: Border(
                bottom: BorderSide(color: _slate200, width: 0.8),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 150,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final txn = transactions[index];
        final color = _getTransactionColor(txn.transactionType);
        final icon = _getTransactionIcon(txn.transactionType);

        return InkWell(
          onTap: () => _showTransactionDetails(txn),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: index.isEven ? Colors.white : const Color(0xFFFAFBFC),
              border: Border(
                bottom: BorderSide(color: _slate200, width: 0.8),
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getTransactionTypeName(txn.transactionType),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: _slate800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _buildStatusBadge(txn.displayStatus),
                        ],
                      ),
                      const SizedBox(height: 3),
                      if (txn.senderName != null &&
                          _transactionTab == 'received')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            'From: ${txn.senderName}',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                letterSpacing: -0.1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (txn.recipientName != null &&
                          _transactionTab == 'sent')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            'To: ${txn.recipientName}',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                letterSpacing: -0.1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 9, color: Colors.grey[400]),
                          const SizedBox(width: 3),
                          Text(
                            '${txn.createdAt.day}/${txn.createdAt.month}/${txn.createdAt.year} ${txn.createdAt.hour}:${txn.createdAt.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[500],
                                letterSpacing: -0.1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      // In the received tab for ride_payment, show the driver
                      // net payout (received_amount), not the total fare.
                      (_transactionTab == 'received' &&
                              (txn.transactionType == 'ride_payment' ||
                                  txn.transactionType == 'ride_due_settle'))
                          ? '৳${txn.receivedAmount.toStringAsFixed(2)}'
                          : '৳${txn.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (txn.paymentMethod != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _formatPaymentMethod(txn.paymentMethod!),
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status.isEmpty) return const SizedBox.shrink();

    Color statusColor;
    String displayStatus;

    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = const Color(0xFF10B981);
        displayStatus = 'Completed';
        break;
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        displayStatus = 'Pending';
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        displayStatus = 'Rejected';
        break;
      default:
        statusColor = Colors.grey;
        displayStatus = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: statusColor,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  String _getTransactionTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return 'Deposit';
      case 'withdraw':
        return 'Withdrawal';
      case 'transfer':
        return 'Transfer';
      case 'diamond_purchase':
        return 'Diamond Purchase';
      case 'diamond_gift':
        return 'Diamond Gift Sent';
      case 'diamond_bonus':
        return 'Diamond Bonus';
      case 'diamond_refund':
        return 'Diamond Refund';
      case 'diamond_admin':
        return 'Diamond Adjustment';
      case 'mobile_recharge':
        return 'Mobile Recharge';
      case 'pro_subscription':
        return 'Pro Subscription';
      case 'order_payment':
        return 'Product Purchase';
      case 'ride_payment':
        return 'Ride Payment';
      case 'ride_cash':
        return 'Ride Cash Payment';
      case 'referral_commission':
        return 'Referral Commission';
      case 'referral_reward':
        return 'Referral Reward';
      default:
        return type
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) =>
                word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  void _showTransactionDetails(Transaction txn) {
    final color = _getTransactionColor(txn.transactionType);
    final icon = _getTransactionIcon(txn.transactionType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTransactionTypeName(txn.transactionType),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusBadge(txn.displayStatus),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            // Amount
            _buildDetailRow(
                'Amount', '৳${txn.amount.toStringAsFixed(2)}', color),
            if (_isRideTransaction(txn)) ...[
              _buildDetailRow(
                  'Ride Fare', '৳${txn.payableAmount.toStringAsFixed(2)}'),
              _buildDetailRow(
                txn.transactionType.toLowerCase() == 'ride_cash'
                    ? 'Adsy Fee Due'
                    : 'Platform Fee',
                '৳${txn.feeAmount.toStringAsFixed(2)}',
              ),
              _buildDetailRow('Driver Receives',
                  '৳${txn.receivedAmount.toStringAsFixed(2)}'),
            ],
            // Transaction ID - Always show (either transaction number or UUID)
            _buildDetailRow(
              'Transaction ID',
              txn.transactionNumber != null && txn.transactionNumber!.isNotEmpty
                  ? txn.transactionNumber!
                  : txn.id
                      .substring(0, 13)
                      .toUpperCase(), // Show first 13 chars of UUID if no transaction number
            ),
            // Date
            _buildDetailRow(
              'Date',
              '${txn.createdAt.day}/${txn.createdAt.month}/${txn.createdAt.year} ${txn.createdAt.hour}:${txn.createdAt.minute.toString().padLeft(2, '0')}',
            ),
            // Payment Method - Always show
            _buildDetailRow('Payment Method', _getPaymentMethodDisplay(txn)),
            // Payment Number (only for deposit/withdraw with card_number)
            if ((txn.transactionType.toLowerCase() == 'deposit' ||
                    txn.transactionType.toLowerCase() == 'withdraw') &&
                txn.paymentNumber != null &&
                txn.paymentNumber!.isNotEmpty)
              _buildDetailRow('Card/Account Number', txn.paymentNumber!),
            // Sender (from user_details)
            if (txn.senderName != null && txn.senderName!.isNotEmpty)
              _buildDetailRow('From', txn.senderName!),
            // Recipient (from to_user_details)
            if (txn.recipientName != null && txn.recipientName!.isNotEmpty)
              _buildDetailRow('To', txn.recipientName!),
            // Product Name (for order_payment)
            if (txn.transactionType.toLowerCase() == 'order_payment' &&
                txn.description != null &&
                txn.description!.isNotEmpty)
              _buildDetailRow('Product', txn.description!),
            // Note/Description - Always show
            _buildDetailRow('Description', _getNoteDisplay(txn)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getNoteDisplay(Transaction txn) {
    // If note exists, return it
    if (txn.note != null && txn.note!.isNotEmpty) {
      return txn.note!;
    }

    // Otherwise, provide default description based on transaction type
    switch (txn.transactionType.toLowerCase()) {
      case 'deposit':
        return 'Money added to account';
      case 'withdraw':
        return 'Money withdrawn from account';
      case 'transfer':
        if (txn.recipientName != null && txn.recipientName!.isNotEmpty) {
          return 'Money transferred to ${txn.recipientName}';
        }
        return 'Money transferred';
      case 'order_payment':
        return 'Payment for product purchase';
      case 'ride_payment':
        return 'Ride fare paid from AdsyPay balance';
      case 'ride_cash':
        return 'Ride fare collected in cash; platform fee tracked separately';
      case 'pro_subscription':
        return 'Pro subscription payment';
      case 'mobile_recharge':
        return 'Mobile recharge transaction';
      case 'referral_commission':
        return 'Referral commission earned';
      case 'referral_reward':
        return 'Referral reward earned';
      case 'diamond_purchase':
        return 'Diamond purchase';
      case 'diamond_gift':
        return 'Diamond gift sent';
      case 'diamond_bonus':
        return 'Diamond bonus received';
      case 'diamond_refund':
        return 'Diamond refund';
      case 'diamond_admin':
        return 'Diamond adjustment by admin';
      default:
        return 'Transaction completed';
    }
  }

  bool _isRideTransaction(Transaction txn) {
    final type = txn.transactionType.toLowerCase();
    return type == 'ride_payment' || type == 'ride_cash';
  }

  String _getPaymentMethodDisplay(Transaction txn) {
    // If payment method exists, format it
    if (txn.paymentMethod != null && txn.paymentMethod!.isNotEmpty) {
      return _formatPaymentMethod(txn.paymentMethod!);
    }

    // Otherwise, provide default based on transaction type
    switch (txn.transactionType.toLowerCase()) {
      case 'withdraw':
        return 'Mobile Banking'; // Default for old withdrawals without payment_method
      case 'deposit':
        return 'Mobile Banking'; // Default for old deposits without payment_method
      case 'transfer':
        return 'Account Balance';
      case 'order_payment':
      case 'pro_subscription':
      case 'mobile_recharge':
      case 'ride_payment':
      case 'referral_commission':
      case 'referral_reward':
        return 'Account Balance';
      case 'ride_cash':
        return 'Cash';
      case 'diamond_purchase':
      case 'diamond_gift':
      case 'diamond_bonus':
      case 'diamond_refund':
      case 'diamond_admin':
        return 'Account Balance';
      default:
        return 'Not Specified';
    }
  }

  String _formatPaymentMethod(String method) {
    // Format payment method to be user-friendly
    switch (method.toLowerCase()) {
      case 'bkash':
        return 'bKash';
      case 'nagad':
        return 'Nagad';
      case 'rocket':
        return 'Rocket';
      case 'upay':
        return 'Upay';
      case 'balance':
      case 'wallet':
        return 'Account Balance';
      case 'bank':
        return 'Bank Transfer';
      case 'card':
        return 'Card Payment';
      case 'cash':
        return 'Cash';
      default:
        // Capitalize first letter of each word
        return method
            .split('_')
            .map((word) =>
                word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
