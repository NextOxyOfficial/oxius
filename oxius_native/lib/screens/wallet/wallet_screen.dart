import 'package:flutter/material.dart';
import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';
import '../../services/user_state_service.dart';
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
  final UserStateService _userState = UserStateService();
  final TranslationService _translationService = TranslationService();

  String t(String key) => _translationService.translate(key);

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _loadTransactions();
  }

  Future<void> _loadBalance() async {
    setState(() => _isLoadingBalance = true);
    final balance = await WalletService.getBalance();
    if (mounted) {
      setState(() {
        _balance = balance;
        _isLoadingBalance = false;
      });
    }
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoadingTransactions = true);
    final sent = await WalletService.getTransactions();
    final received = await WalletService.getReceivedTransfers();
    if (mounted) {
      setState(() {
        _sentTransactions = sent;
        _receivedTransactions = received;
        _isLoadingTransactions = false;
      });
    }
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
            Text(
              t('deposit_withdraw'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Balance Cards Section - Using Homepage Component
            const AccountBalanceSection(),

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
                      t('diposit'),
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      1,
                      Icons.arrow_upward,
                      t('withdraw'),
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      2,
                      Icons.swap_horiz,
                      t('transfer'),
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
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.history,
                            size: 16,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t('transaction_history'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                    // Transaction Type Toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(height: 12),

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
      default:
        return Colors.grey;
    }
  }

  Widget _buildTransactionTabButton(String value, String label) {
    final isSelected = _transactionTab == value;
    return GestureDetector(
      onTap: () => setState(() => _transactionTab = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
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
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'No ${_transactionTab} transactions',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length > 10 ? 10 : transactions.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final txn = transactions[index];
        final color = _getTransactionColor(txn.transactionType);
        final icon = _getTransactionIcon(txn.transactionType);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          txn.transactionType.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(txn.displayStatus),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (txn.senderName != null && _transactionTab == 'received')
                      Text(
                        'From: ${txn.senderName}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    if (txn.recipientName != null && _transactionTab == 'sent')
                      Text(
                        'To: ${txn.recipientName}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    if (txn.paymentMethod != null)
                      Text(
                        txn.paymentMethod!,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      '${txn.createdAt.day}/${txn.createdAt.month}/${txn.createdAt.year} ${txn.createdAt.hour}:${txn.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                '৳${txn.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    if (status.isEmpty) return const SizedBox.shrink();
    
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = const Color(0xFF10B981);
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: statusColor,
        ),
      ),
    );
  }
}
