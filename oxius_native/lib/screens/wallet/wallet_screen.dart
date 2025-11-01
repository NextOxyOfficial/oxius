import 'package:flutter/material.dart';
import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';
import '../../services/user_state_service.dart';
import '../../services/auth_service.dart';
import '../../services/translation_service.dart';
import '../../widgets/home/account_balance_section.dart';
import '../../widgets/home/mobile_recharge_section.dart';
import '../microgig/pending_tasks_screen.dart';
import 'deposit_tab.dart';
import 'withdraw_tab.dart';
import 'transfer_tab.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  WalletBalance? _balance;
  bool _isLoadingBalance = true;
  int _currentTab = 0;
  String _transactionTab = 'sent'; // 'sent' or 'received'
  List<Transaction> _sentTransactions = [];
  List<Transaction> _receivedTransactions = [];
  bool _isLoadingTransactions = true;
  
  // Pagination
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

  String t(String key) => _translationService.translate(key);

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _loadBalance();
    _loadTransactions();
    
    // Add scroll listener for pagination
    _transactionScrollController.addListener(_onTransactionScroll);
  }
  
  void _onTransactionScroll() {
    if (_transactionScrollController.position.pixels >= 
        _transactionScrollController.position.maxScrollExtent - 200) {
      if (_transactionTab == 'sent' && !_isLoadingMoreSent && _hasMoreSent) {
        _loadMoreSentTransactions();
      } else if (_transactionTab == 'received' && !_isLoadingMoreReceived && _hasMoreReceived) {
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
    setState(() => _isLoadingBalance = true);
    
    // Always refresh user data first to get latest balance
    await AuthService.refreshUserData();
    
    final balance = await WalletService.getBalance();
    if (mounted) {
      setState(() {
        _balance = balance;
        _isLoadingBalance = false;
      });
      // Also refresh the AccountBalanceSection
      _balanceKey.currentState?.loadBalance();
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
      _sentPage = 1;
      _receivedPage = 1;
      _sentTransactions = [];
      _receivedTransactions = [];
    });
    
    final sent = await WalletService.getTransactions(page: _sentPage);
    final received = await WalletService.getReceivedTransfers(page: _receivedPage);
    
    if (mounted) {
      setState(() {
        _sentTransactions = sent;
        _receivedTransactions = received;
        _hasMoreSent = sent.length >= 10; // Assume 10 items per page
        _hasMoreReceived = received.length >= 10;
        _isLoadingTransactions = false;
      });
    }
  }
  
  Future<void> _loadMoreSentTransactions() async {
    if (_isLoadingMoreSent || !_hasMoreSent) return;
    
    setState(() {
      _isLoadingMoreSent = true;
      _sentPage++;
    });
    
    final moreSent = await WalletService.getTransactions(page: _sentPage);
    
    if (mounted) {
      setState(() {
        _sentTransactions.addAll(moreSent);
        _hasMoreSent = moreSent.length >= 10;
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
    
    final moreReceived = await WalletService.getReceivedTransfers(page: _receivedPage);
    
    if (mounted) {
      setState(() {
        _receivedTransactions.addAll(moreReceived);
        _hasMoreReceived = moreReceived.length >= 10;
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 16,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'AdsyPay',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        color: const Color(0xFF10B981),
        child: SingleChildScrollView(
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
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
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
              child: _currentTab == 0
                  ? DepositTab(
                      balance: _balance?.balance ?? 0.0,
                      onDepositSuccess: () {
                        _loadBalance();
                        _loadTransactions();
                      },
                    )
                  : _currentTab == 1
                      ? WithdrawTab(
                          balance: _balance?.balance ?? 0.0,
                          onWithdrawSuccess: () {
                            _loadBalance();
                            _loadTransactions();
                          },
                        )
                      : TransferTab(
                          balance: _balance?.balance ?? 0.0,
                          userPhone: _userState.userEmail,
                          onTransferSuccess: () {
                            _loadBalance();
                            _loadTransactions();
                          },
                        ),
            ),

            // Transaction History Section (Always show)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          t('transaction_history'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.2,
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
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTransactionTabButton('sent', 'Sent'),
                          ),
                          Expanded(
                            child: _buildTransactionTabButton('received', 'Received'),
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
                              child: CircularProgressIndicator(),
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
          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPendingTransactions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pending Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _balance?.pendingTransactions.length ?? 0,
                  itemBuilder: (context, index) {
                    final txn = _balance!.pendingTransactions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange[100],
                          child: Icon(
                            _getTransactionIcon(txn.transactionType),
                            color: Colors.orange,
                          ),
                        ),
                        title: Text(
                          txn.transactionType.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${txn.createdAt.day}/${txn.createdAt.month}/${txn.createdAt.year}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        trailing: Text(
                          '৳${txn.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
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
      case 'pro_subscription':
        return Icons.workspace_premium;
      case 'referral_commission':
        return Icons.people;
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
      case 'pro_subscription':
        return const Color(0xFFF59E0B); // Amber
      case 'referral_commission':
        return const Color(0xFFEAB308); // Yellow
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
          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.grey[600],
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactions = _transactionTab == 'sent' ? _sentTransactions : _receivedTransactions;
    
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 40, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                'No ${_transactionTab} transactions',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isLoadingMore = _transactionTab == 'sent' ? _isLoadingMoreSent : _isLoadingMoreReceived;
    
    return ListView.builder(
      controller: _transactionScrollController,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading skeleton at bottom
        if (index == transactions.length) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200, width: 1),
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
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _buildStatusBadge(txn.displayStatus),
                        ],
                      ),
                      const SizedBox(height: 3),
                      if (txn.senderName != null && _transactionTab == 'received')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            'From: ${txn.senderName}',
                            style: TextStyle(fontSize: 10, color: Colors.grey[600], letterSpacing: -0.1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (txn.recipientName != null && _transactionTab == 'sent')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            'To: ${txn.recipientName}',
                            style: TextStyle(fontSize: 10, color: Colors.grey[600], letterSpacing: -0.1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 9, color: Colors.grey[400]),
                          const SizedBox(width: 3),
                          Text(
                            '${txn.createdAt.day}/${txn.createdAt.month}/${txn.createdAt.year} ${txn.createdAt.hour}:${txn.createdAt.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 9, color: Colors.grey[500], letterSpacing: -0.1),
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
                      '৳${txn.amount.toStringAsFixed(2)}',
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
        color: statusColor.withOpacity(0.12),
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
      case 'referral_commission':
        return 'Referral Commission';
      default:
        return type.replaceAll('_', ' ').split(' ').map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join(' ');
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
                    color: color.withOpacity(0.1),
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
            _buildDetailRow('Amount', '৳${txn.amount.toStringAsFixed(2)}', color),
            // Transaction ID - Always show (either transaction number or UUID)
            _buildDetailRow(
              'Transaction ID', 
              txn.transactionNumber != null && txn.transactionNumber!.isNotEmpty 
                ? txn.transactionNumber! 
                : txn.id.substring(0, 13).toUpperCase(), // Show first 13 chars of UUID if no transaction number
            ),
            // Date
            _buildDetailRow(
              'Date',
              '${txn.createdAt.day}/${txn.createdAt.month}/${txn.createdAt.year} ${txn.createdAt.hour}:${txn.createdAt.minute.toString().padLeft(2, '0')}',
            ),
            // Payment Method - Always show
            _buildDetailRow('Payment Method', _getPaymentMethodDisplay(txn)),
            // Payment Number (only for deposit/withdraw with card_number)
            if ((txn.transactionType.toLowerCase() == 'deposit' || txn.transactionType.toLowerCase() == 'withdraw') && 
                txn.paymentNumber != null && txn.paymentNumber!.isNotEmpty)
              _buildDetailRow('Card/Account Number', txn.paymentNumber!),
            // Sender (from user_details)
            if (txn.senderName != null && txn.senderName!.isNotEmpty)
              _buildDetailRow('From', txn.senderName!),
            // Recipient (from to_user_details)
            if (txn.recipientName != null && txn.recipientName!.isNotEmpty)
              _buildDetailRow('To', txn.recipientName!),
            // Product Name (for order_payment)
            if (txn.transactionType.toLowerCase() == 'order_payment' && 
                txn.description != null && txn.description!.isNotEmpty)
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
      case 'pro_subscription':
        return 'Pro subscription payment';
      case 'mobile_recharge':
        return 'Mobile recharge transaction';
      case 'referral_commission':
        return 'Referral commission earned';
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
      case 'referral_commission':
        return 'Account Balance';
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
        return 'Account Balance';
      case 'bank':
        return 'Bank Transfer';
      case 'card':
        return 'Card Payment';
      default:
        // Capitalize first letter of each word
        return method.split('_').map((word) => 
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
        ).join(' ');
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
