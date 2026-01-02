import 'package:flutter/material.dart';
import '../../services/translation_service.dart';
import '../../services/auth_service.dart';
import '../../services/mobile_recharge_service.dart';
import '../../services/wallet_service.dart';
import '../../models/wallet_models.dart';
import '../../widgets/mobile_sticky_nav.dart';

class MobileRechargeScreen extends StatefulWidget {
  const MobileRechargeScreen({super.key});

  @override
  State<MobileRechargeScreen> createState() => _MobileRechargeScreenState();
}

class _MobileRechargeScreenState extends State<MobileRechargeScreen> {
  final TranslationService _translationService = TranslationService();
  final TextEditingController _phoneController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String t(String key) => _translationService.translate(key);
  
  String _selectedOperator = 'all';
  String _activeFilter = 'all';
  bool _isLoading = true;
  bool _showRechargeModal = false;
  Map<String, dynamic>? _selectedPackage;
  List<Map<String, dynamic>> _packages = [];
  List<Map<String, dynamic>> _operators = [];
  
  // Balance state
  WalletBalance? _walletBalance;
  bool _isBalanceLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    await Future.wait([
      _loadOperators(),
      _loadPackages(),
      _loadBalance(),
    ]);
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadOperators() async {
    final operators = await MobileRechargeService.getOperators();
    if (mounted) {
      setState(() {
        _operators = [
          {'id': 'all', 'name': 'All', 'code': 'all'},
          ...operators,
        ];
      });
    }
  }

  Future<void> _loadPackages() async {
    print('🔄 Loading packages for operator: $_selectedOperator, type: $_activeFilter');
    
    // Don't send filter if "all" is selected
    // Backend expects operator as integer ID, not string
    final operatorFilter = _selectedOperator == 'all' ? null : _selectedOperator;
    final typeFilter = _activeFilter == 'all' ? null : _activeFilter;
    
    print('🔄 Actual filters being sent - operator: $operatorFilter, type: $typeFilter');
    
    final result = await MobileRechargeService.getPackages(
      operator: operatorFilter,
      type: typeFilter,
    );
    
    print('📦 API Response: ${result['success']}, count: ${result['results']?.length ?? 0}');
    
    if (mounted) {
      if (result['success'] == true) {
        final packages = List<Map<String, dynamic>>.from(result['results'] ?? []);
        print('📦 Setting ${packages.length} packages');
        print('📦 First package sample: ${packages.isNotEmpty ? packages.first : 'No packages'}');
        
        setState(() {
          _packages = packages;
        });
        
        print('📦 Popular packages: ${_popularPackages.length}');
        print('📦 Filtered packages: ${_filteredPackages.length}');
        
        if (packages.isEmpty) {
          print('⚠️ WARNING: No packages found for operator=$operatorFilter, type=$typeFilter');
          print('⚠️ Check if packages exist in Django admin: /admin/mobile_recharge/package/');
        }
      } else {
        print('❌ Failed to load packages: ${result['message']}');
        setState(() {
          _packages = [];
        });
      }
    }
  }

  Future<void> _loadBalance() async {
    if (!mounted) return;
    
    setState(() => _isBalanceLoading = true);
    
    try {
      final balance = await WalletService.getBalance();
      if (mounted) {
        setState(() {
          _walletBalance = balance;
          _isBalanceLoading = false;
        });
        print('💰 Balance loaded: ৳${balance?.balance ?? 0}');
      }
    } catch (e) {
      print('❌ Error loading balance: $e');
      if (mounted) {
        setState(() => _isBalanceLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadOperators(),
      _loadPackages(),
      _loadBalance(),
    ]);
  }
  
  final List<Map<String, String>> _filters = [
    {'value': 'all', 'label': 'All'},
    {'value': 'balance', 'label': 'Balance'},
    {'value': 'data', 'label': 'Data'},
    {'value': 'voice', 'label': 'Voice'},
    {'value': 'combo', 'label': 'Combo'},
  ];
  
  
  List<Map<String, dynamic>> get _popularPackages {
    return _packages.where((p) => p['popular'] == true).toList();
  }
  
  List<Map<String, dynamic>> get _filteredPackages {
    // Server-side filtering is already applied in _loadPackages()
    // No need for additional client-side filtering since backend handles it
    // Just return all packages from the API response
    return _packages;
  }
  
  @override
  void dispose() {
    _phoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 640;
    final user = AuthService.currentUser;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    color: const Color(0xFF10B981),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Compact Header
                            Container(
                              padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    color: const Color(0xFF374151),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Mobile Recharge',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF111827),
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        if (_walletBalance != null && !_isBalanceLoading)
                                          Text(
                                            'Balance: ৳${_walletBalance!.balance.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF10B981),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          )
                                        else if (_isBalanceLoading)
                                          const SizedBox(
                                            height: 12,
                                            width: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                            ),
                                          ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                            
                            // Operator Filter
                            _buildOperatorFilter(isSmallMobile),
                            
                            const SizedBox(height: 16),
                            
                            // Type Filter
                            _buildTypeFilter(isSmallMobile),
                            
                            const SizedBox(height: 16),
                            
                            // Popular Packages
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  t('popular_packages'),
                                  style: TextStyle(
                                    fontSize: isSmallMobile ? 18 : 20,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _showRechargeHistoryBottomSheet(context),
                                  icon: const Icon(Icons.history_rounded, size: 18),
                                  label: const Text('History'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF3B82F6),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildPackageGrid(_popularPackages, isSmallMobile),
                            
                            const SizedBox(height: 32),
                            
                            // All Packages
                            Text(
                              t('all_packages'),
                              style: TextStyle(
                                fontSize: isSmallMobile ? 18 : 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _buildPackageGrid(_filteredPackages, isSmallMobile),
                            
                            const SizedBox(height: 100), // Bottom padding for sticky nav
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          
          // Mobile Sticky Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MobileStickyNav(
              currentRoute: 'MobileRecharge',
              scrollController: _scrollController,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOperatorFilter(bool isSmallMobile) {
    if (_operators.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sim_card_rounded, size: 16, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              const Text(
                'Select Operator',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _operators.map((operator) {
              // Convert ID to string for comparison (backend returns int, 'all' is string)
              final operatorId = operator['id']?.toString() ?? operator['code']?.toString() ?? '';
              final isSelected = _selectedOperator == operatorId;
              final operatorName = operator['name'] as String;
              return InkWell(
                onTap: () {
                  final selectedOpId = operator['id']?.toString() ?? operator['code']?.toString() ?? '';
                  print('👆 Selected operator: ${operator['name']} (ID: $selectedOpId)');
                  setState(() => _selectedOperator = selectedOpId);
                  _loadPackages();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Colors.white.withOpacity(0.2) 
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: operator['icon'] != null && operator['icon'].toString().isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Image.network(
                                  operator['icon'],
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('❌ Failed to load operator icon: ${operator['icon']}');
                                    return Icon(
                                      _getOperatorIcon(operatorName),
                                      size: 14,
                                      color: isSelected ? Colors.white : _getOperatorColor(operatorName),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            isSelected ? Colors.white : const Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                _getOperatorIcon(operatorName),
                                size: 14,
                                color: isSelected ? Colors.white : _getOperatorColor(operatorName),
                              ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        operatorName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTypeFilter(bool isSmallMobile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _filters.map((filter) {
          final isActive = _activeFilter == filter['value'];
          return InkWell(
            onTap: () {
              setState(() => _activeFilter = filter['value']!);
              _loadPackages();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF10B981) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? const Color(0xFF10B981) : Colors.grey.shade300,
                ),
              ),
              child: Text(
                filter['label']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFF6B7280),
                  letterSpacing: -0.1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildPackageGrid(List<Map<String, dynamic>> packages, bool isSmallMobile) {
    print('📱 Building grid with ${packages.length} packages');
    
    if (packages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 56,
                  color: Colors.orange.shade400,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No packages available',
                style: TextStyle(
                  fontSize: isSmallMobile ? 16 : 18,
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedOperator == 'all' && _activeFilter == 'all'
                    ? 'No packages found in the database'
                    : 'Try changing your filters',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallMobile ? 2 : 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: isSmallMobile ? 0.75 : 0.8,
      ),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final package = packages[index];
        return _buildPackageCard(package, isSmallMobile);
      },
    );
  }
  
  Widget _buildPackageCard(Map<String, dynamic> package, bool isSmallMobile) {
    return InkWell(
      onTap: () => _selectPackage(package),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF3F4F6)),
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
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge and Popular badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTagColor(package['type']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _capitalizeFirst(package['type']),
                          style: TextStyle(
                            fontSize: isSmallMobile ? 10 : 11,
                            fontWeight: FontWeight.w600,
                            color: _getTagTextColor(package['type']),
                          ),
                        ),
                      ),
                      if (package['popular'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Popular',
                            style: TextStyle(
                              fontSize: isSmallMobile ? 9 : 10,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Price and operator icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        package['price'],
                        style: TextStyle(
                          fontSize: isSmallMobile ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: package['operator_details']?['icon'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Image.network(
                                  package['operator_details']['icon'],
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.phone_android,
                                    size: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.phone_android,
                                size: 14,
                                color: Color(0xFF6B7280),
                              ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Package details
                  _buildPackageDetail(Icons.wifi, package['data'], isSmallMobile),
                  const SizedBox(height: 6),
                  _buildPackageDetail(Icons.calendar_today, package['validity'], isSmallMobile),
                  const SizedBox(height: 6),
                  _buildPackageDetail(Icons.phone, package['calls'], isSmallMobile),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Recharge button
            Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _selectPackage(package),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        t('recharge_now'),
                        style: TextStyle(
                          fontSize: isSmallMobile ? 12 : 13,
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
    );
  }
  
  Widget _buildPackageDetail(IconData icon, String text, bool isSmallMobile) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isSmallMobile ? 11 : 12,
              color: const Color(0xFF6B7280),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  Color _getTagColor(String type) {
    switch (type) {
      case 'data':
        return const Color(0xFFD1FAE5);
      case 'voice':
        return const Color(0xFFEDE9FE);
      case 'combo':
        return const Color(0xFFFEF3C7);
      case 'balance':
        return const Color(0xFFF3F4F6);
      default:
        return const Color(0xFFF3F4F6);
    }
  }
  
  Color _getTagTextColor(String type) {
    switch (type) {
      case 'data':
        return const Color(0xFF065F46);
      case 'voice':
        return const Color(0xFF5B21B6);
      case 'combo':
        return const Color(0xFF92400E);
      case 'balance':
        return const Color(0xFF374151);
      default:
        return const Color(0xFF374151);
    }
  }
  
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  
  IconData _getOperatorIcon(String operatorName) {
    final name = operatorName.toLowerCase();
    if (name == 'all') return Icons.grid_view_rounded;
    if (name.contains('gp') || name.contains('grameenphone')) return Icons.phone_android_rounded;
    if (name.contains('robi')) return Icons.signal_cellular_alt_rounded;
    if (name.contains('bl') || name.contains('banglalink')) return Icons.network_cell_rounded;
    if (name.contains('airtel')) return Icons.cell_tower_rounded;
    return Icons.sim_card_rounded;
  }
  
  Color _getOperatorColor(String operatorName) {
    final name = operatorName.toLowerCase();
    if (name == 'all') return const Color(0xFF10B981); // Green
    if (name.contains('gp') || name.contains('grameenphone')) return const Color(0xFF00A651); // GP Green
    if (name.contains('robi')) return const Color(0xFFE60012); // Robi Red
    if (name.contains('bl') || name.contains('banglalink')) return const Color(0xFFFF6600); // Banglalink Orange
    if (name.contains('airtel')) return const Color(0xFFDC143C); // Airtel Red
    return const Color(0xFF6B7280); // Default Gray
  }
  
  void _selectPackage(Map<String, dynamic> package) {
    setState(() {
      _selectedPackage = package;
      _showRechargeModal = true;
    });
    _showRechargeDialog(package);
  }
  
  void _showRechargeDialog(Map<String, dynamic> package) {
    final user = AuthService.currentUser;
    final userBalance = _walletBalance?.balance ?? 0.0;
    final packagePrice = (package['price'] ?? package['amount'] ?? 0.0) is String
        ? double.tryParse((package['price'] ?? package['amount'] ?? '0').toString().replaceAll('৳', '').trim()) ?? 0.0
        : (package['price'] ?? package['amount'] ?? 0.0).toDouble();
    final hasSufficientBalance = userBalance >= packagePrice;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 640;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 24,
          vertical: 24,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isSmallScreen ? double.infinity : 500,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.bolt, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confirm Recharge',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Review and submit',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_rounded, 
                                color: Color(0xFF10B981), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Available Balance',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                  ),
                                  Text(
                                    '৳${userBalance.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Package Details
                      const Text(
                        'Package Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('Type', _capitalizeFirst(package['type'] ?? 'N/A')),
                            const Divider(height: 16),
                            _buildDetailRow('Amount', '৳${packagePrice.toStringAsFixed(0)}'),
                            const Divider(height: 16),
                            _buildDetailRow('Data', package['data']?.toString() ?? 'N/A'),
                            const Divider(height: 16),
                            _buildDetailRow('Validity', package['validity']?.toString() ?? 'N/A'),
                            if (package['calls'] != null && package['calls'] != 'N/A') ...[
                              const Divider(height: 16),
                              _buildDetailRow('Calls', package['calls'].toString()),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Phone Number Input or Balance Warning
                      if (!hasSufficientBalance)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            border: Border.all(color: const Color(0xFFFECACA)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, 
                                      color: Color(0xFFDC2626), size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Insufficient balance for this recharge',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You need ৳${packagePrice.toStringAsFixed(2)} but have ৳${userBalance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(context, '/wallet');
                                  },
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Add Funds'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        const Text(
                          'Mobile Number',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 14,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: '01XXXXXXXXX',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                            prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter Bangladeshi mobile number only',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Footer Buttons
              if (hasSufficientBalance)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _handleRecharge(package),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Confirm Recharge',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 13 : 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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
  
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
  
  Future<void> _handleRecharge(Map<String, dynamic> package) async {
    // Validate phone number
    final phoneRegex = RegExp(r'^(?:\+?88)?01[3-9]\d{8}$');
    if (!phoneRegex.hasMatch(_phoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Bangladesh mobile number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Get operator ID (it's an integer from the API)
      final operatorId = package['operator'] as int;
      
      // Parse amount - it might be string or number from API
      final priceValue = package['price'] ?? package['amount'] ?? 0;
      final amount = priceValue is String 
          ? double.parse(priceValue) 
          : (priceValue is int ? priceValue.toDouble() : priceValue as double);
      
      print('📱 Submitting recharge - Package ID: ${package['id']}, Operator: $operatorId, Amount: $amount, Phone: ${_phoneController.text}');
      
      final result = await MobileRechargeService.submitRecharge(
        packageId: package['id'],
        phoneNumber: _phoneController.text,
        operator: operatorId,
        amount: amount,
      );
      
      if (mounted) {
        Navigator.pop(context);
        
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Recharge successful!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          _phoneController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Recharge failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recharge failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _showRechargeHistoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Recharge History',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
              
              Container(
                height: 1,
                color: Colors.grey.shade200,
              ),
              
              // History List
              Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
                  future: MobileRechargeService.getRechargeHistory(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: SizedBox(
                          height: 32,
                          width: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      );
                    }
                    
                    if (snapshot.hasError || snapshot.data?['success'] != true) {
                      final errorMessage = snapshot.data?['message'] ?? 
                                          snapshot.error?.toString() ?? 
                                          'Failed to load history';
                      print('🔴 History error: $errorMessage');
                      
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: Colors.red.shade400,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Failed to load history',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                errorMessage,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    final List<dynamic> recharges = snapshot.data!['results'] ?? [];
                    
                    if (recharges.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.receipt_long_rounded,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No recharge history',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your recharges will appear here',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(10),
                      itemCount: recharges.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final recharge = recharges[index];
                        final status = recharge['status'] ?? 'pending';
                        final statusColor = status == 'completed'
                            ? const Color(0xFF10B981)
                            : status == 'failed'
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFF59E0B);
                        
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
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
                              // Status indicator
                              Container(
                                width: 4,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Phone and status
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.phone_android_rounded,
                                              size: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              recharge['phone_number'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF111827),
                                                letterSpacing: -0.1,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: statusColor,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 6),
                                    
                                    // Operator and Date
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (recharge['operator'] != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              recharge['operator'].toString().toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF10B981),
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ),
                                        Text(
                                          recharge['created_at'] ?? '',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(width: 10),
                              
                              // Amount
                              Text(
                                '৳${recharge['amount'] ?? '0'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
