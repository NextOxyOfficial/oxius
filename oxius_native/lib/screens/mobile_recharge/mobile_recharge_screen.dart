import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/translation_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class MobileRechargeScreen extends StatefulWidget {
  const MobileRechargeScreen({super.key});

  @override
  State<MobileRechargeScreen> createState() => _MobileRechargeScreenState();
}

class _MobileRechargeScreenState extends State<MobileRechargeScreen> {
  final TranslationService _translationService = TranslationService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  String t(String key) => _translationService.translate(key);
  
  String _selectedOperator = 'all';
  String _activeFilter = 'all';
  bool _isLoading = false;
  bool _showRechargeModal = false;
  Map<String, dynamic>? _selectedPackage;
  
  final List<Map<String, dynamic>> _operators = [
    {
      'id': 'all',
      'name': 'All',
      'icon': 'assets/images/all.png',
      'bgColor': const Color(0xFF10B981),
    },
    {
      'id': 'grameenphone',
      'name': 'GP',
      'icon': 'assets/images/gp.png',
      'bgColor': const Color(0xFF00A651),
    },
    {
      'id': 'robi',
      'name': 'Robi',
      'icon': 'assets/images/robi.png',
      'bgColor': const Color(0xFFE60012),
    },
    {
      'id': 'banglalink',
      'name': 'BL',
      'icon': 'assets/images/bl.png',
      'bgColor': const Color(0xFFFF6600),
    },
    {
      'id': 'airtel',
      'name': 'Airtel',
      'icon': 'assets/images/airtel.png',
      'bgColor': const Color(0xFFE60012),
    },
  ];
  
  final List<Map<String, String>> _filters = [
    {'value': 'all', 'label': 'All'},
    {'value': 'balance', 'label': 'Balance'},
    {'value': 'data', 'label': 'Data'},
    {'value': 'voice', 'label': 'Voice'},
    {'value': 'combo', 'label': 'Combo'},
  ];
  
  // Mock packages data - replace with actual API call
  final List<Map<String, dynamic>> _packages = [
    {
      'id': 1,
      'type': 'data',
      'price': '৳49',
      'priceValue': 49.0,
      'data': '1GB',
      'validity': '7 Days',
      'calls': 'N/A',
      'operator': 'grameenphone',
      'operator_details': {'name': 'GP', 'icon': 'assets/images/gp.png'},
      'popular': true,
    },
    {
      'id': 2,
      'type': 'combo',
      'price': '৳99',
      'priceValue': 99.0,
      'data': '2GB',
      'validity': '30 Days',
      'calls': '100 Min',
      'operator': 'robi',
      'operator_details': {'name': 'Robi', 'icon': 'assets/images/robi.png'},
      'popular': true,
    },
    {
      'id': 3,
      'type': 'voice',
      'price': '৳29',
      'priceValue': 29.0,
      'data': 'N/A',
      'validity': '3 Days',
      'calls': '50 Min',
      'operator': 'banglalink',
      'operator_details': {'name': 'BL', 'icon': 'assets/images/bl.png'},
      'popular': false,
    },
    {
      'id': 4,
      'type': 'data',
      'price': '৳149',
      'priceValue': 149.0,
      'data': '5GB',
      'validity': '30 Days',
      'calls': 'N/A',
      'operator': 'grameenphone',
      'operator_details': {'name': 'GP', 'icon': 'assets/images/gp.png'},
      'popular': true,
    },
    {
      'id': 5,
      'type': 'balance',
      'price': '৳100',
      'priceValue': 100.0,
      'data': 'N/A',
      'validity': '365 Days',
      'calls': 'As per rate',
      'operator': 'airtel',
      'operator_details': {'name': 'Airtel', 'icon': 'assets/images/airtel.png'},
      'popular': false,
    },
  ];
  
  List<Map<String, dynamic>> get _popularPackages {
    return _packages.where((p) => p['popular'] == true).toList();
  }
  
  List<Map<String, dynamic>> get _filteredPackages {
    return _packages.where((pack) {
      // Filter by operator
      if (_selectedOperator != 'all' && pack['operator'] != _selectedOperator) {
        return false;
      }
      
      // Filter by type
      if (_activeFilter != 'all' && pack['type'] != _activeFilter) {
        return false;
      }
      
      // Filter by search query
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        return pack['type'].toString().toLowerCase().contains(query) ||
               pack['price'].toString().toLowerCase().contains(query);
      }
      
      return true;
    }).toList();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 640;
    final user = AuthService.currentUser;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(t('mobile_recharge')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Text
              Center(
                child: Column(
                  children: [
                    Text(
                      t('mobile_recharge'),
                      style: TextStyle(
                        fontSize: isSmallMobile ? 18 : 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t('recharge_package_choice'),
                      style: TextStyle(
                        fontSize: isSmallMobile ? 14 : 16,
                        color: const Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Search Bar
              _buildSearchBar(isSmallMobile),
              
              const SizedBox(height: 24),
              
              // Operator Filter
              _buildOperatorFilter(isSmallMobile),
              
              const SizedBox(height: 16),
              
              // Type Filter
              _buildTypeFilter(isSmallMobile),
              
              const SizedBox(height: 16),
              
              // Available Balance
              if (user != null)
                Text(
                  '${t('available_balance')}: ৳${user.commissionEarned?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
              
              const SizedBox(height: 24),
              
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
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Show recharge history
                    },
                    icon: const Icon(Icons.history, size: 18),
                    label: Text(t('recharge_history')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      side: const BorderSide(color: Color(0xFF3B82F6)),
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
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSearchBar(bool isSmallMobile) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 448),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() {}),
        decoration: InputDecoration(
          hintText: t('search_packages'),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
  
  Widget _buildOperatorFilter(bool isSmallMobile) {
    return Column(
      children: [
        Text(
          t('select_operator'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _operators.map((operator) {
            final isSelected = _selectedOperator == operator['id'];
            return InkWell(
              onTap: () => setState(() => _selectedOperator = operator['id'] as String),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: (operator['bgColor'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.phone_android,
                        size: 20,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      operator['name'] as String,
                      style: TextStyle(
                        fontSize: isSmallMobile ? 11 : 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildTypeFilter(bool isSmallMobile) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _filters.map((filter) {
        final isActive = _activeFilter == filter['value'];
        return InkWell(
          onTap: () => setState(() => _activeFilter = filter['value']!),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF10B981) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Text(
              filter['label']!,
              style: TextStyle(
                fontSize: isSmallMobile ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildPackageGrid(List<Map<String, dynamic>> packages, bool isSmallMobile) {
    if (packages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No packages found',
            style: TextStyle(
              fontSize: isSmallMobile ? 14 : 16,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallMobile ? 2 : 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
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
                        child: const Icon(
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
  
  void _selectPackage(Map<String, dynamic> package) {
    setState(() {
      _selectedPackage = package;
      _showRechargeModal = true;
    });
    _showRechargeDialog(package);
  }
  
  void _showRechargeDialog(Map<String, dynamic> package) {
    final user = AuthService.currentUser;
    final userBalance = user?.commissionEarned ?? 0.0;
    final packagePrice = package['priceValue'] as double;
    final hasSufficientBalance = userBalance >= packagePrice;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Recharge'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Package Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Package', _capitalizeFirst(package['type'])),
                    const SizedBox(height: 8),
                    _buildDetailRow('Amount', package['price']),
                    const SizedBox(height: 8),
                    _buildDetailRow('Data', package['data']),
                    const SizedBox(height: 8),
                    _buildDetailRow('Validity', package['validity']),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Balance Warning or Phone Input
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
                          Icon(Icons.warning_amber, color: Color(0xFFDC2626), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Insufficient balance for this recharge. Please add funds to your account.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            // TODO: Navigate to deposit page
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Funds'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    hintText: 'Enter mobile number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: hasSufficientBalance ? () => _handleRecharge(package) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
            ),
            child: Text(hasSufficientBalance ? 'Recharge' : 'Insufficient Balance'),
          ),
        ],
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
          content: Text('Please enter a valid phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // TODO: Call actual recharge API
      // final response = await ApiService.post('/mobile-recharge/recharges/', {
      //   'package': package['id'],
      //   'phone_number': _phoneController.text,
      //   'operator': package['operator'],
      //   'amount': package['priceValue'],
      // });
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recharge successful!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _phoneController.clear();
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
}
