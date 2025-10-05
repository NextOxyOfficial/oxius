import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/gigs_service.dart';
import '../services/translation_service.dart';

class MicroGigsSection extends StatefulWidget {
  const MicroGigsSection({super.key});

  @override
  State<MicroGigsSection> createState() => _MicroGigsSectionState();
}

class _MicroGigsSectionState extends State<MicroGigsSection> {
  final TranslationService _translationService = TranslationService();
  final GigsService _gigsService = GigsService();
  
  List<Map<String, dynamic>> _microGigs = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _operators = [];
  
  bool _isLoading = true;
  String? _selectedCategory;
  String _filterStatus = 'approved'; // 'all', 'approved', 'completed'
  
  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  
  @override
  void initState() {
    super.initState();
    _translationService.addListener(_onTranslationsChanged);
    _loadData();
  }

  @override
  void dispose() {
    _translationService.removeListener(_onTranslationsChanged);
    super.dispose();
  }

  void _onTranslationsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load gigs, categories, and operators in parallel
      final results = await Future.wait([
        _gigsService.fetchMicroGigs(showSubmitted: false),
        _gigsService.fetchGigCategories(),
        _gigsService.fetchMobileRechargeOperators(),
      ]);
      
      if (mounted) {
        setState(() {
          _microGigs = results[0] as List<Map<String, dynamic>>;
          _categories = _processCategories(results[0] as List<Map<String, dynamic>>);
          _operators = results[2] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading micro gigs data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _processCategories(List<Map<String, dynamic>> gigs) {
    final Map<String, Map<String, dynamic>> categoryCounts = {};
    
    for (final gig in gigs) {
      final categoryDetails = gig['category_details'];
      if (categoryDetails == null) continue;
      
      final categoryName = categoryDetails['title'] ?? '';
      final categoryId = categoryDetails['id'];
      
      final isActive = gig['active_gig'] == true && 
                       gig['gig_status'] == 'approved' && 
                       gig['user']?['id'] != null;
      
      if (!categoryCounts.containsKey(categoryName)) {
        categoryCounts[categoryName] = {
          'category': categoryName,
          'id': categoryId,
          'total': 0,
          'active': 0,
        };
      }
      
      categoryCounts[categoryName]!['total'] = 
          (categoryCounts[categoryName]!['total'] as int) + 1;
      
      if (isActive) {
        categoryCounts[categoryName]!['active'] = 
            (categoryCounts[categoryName]!['active'] as int) + 1;
      }
    }
    
    return categoryCounts.values.toList();
  }

  List<Map<String, dynamic>> get _paginatedGigs {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    
    if (startIndex >= _microGigs.length) return [];
    return _microGigs.sublist(
      startIndex,
      endIndex > _microGigs.length ? _microGigs.length : endIndex,
    );
  }

  int get _totalPages => (_microGigs.length / _itemsPerPage).ceil();

  Future<void> _filterByCategory(String? categoryId) async {
    setState(() {
      _selectedCategory = categoryId;
      _currentPage = 1;
      _isLoading = true;
    });
    
    try {
      final gigs = categoryId == null
          ? await _gigsService.fetchMicroGigs(showSubmitted: _filterStatus == 'completed')
          : await _gigsService.fetchMicroGigsByCategory(
              categoryId, 
              showSubmitted: _filterStatus == 'completed',
            );
      
      if (mounted) {
        setState(() {
          _microGigs = gigs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error filtering gigs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _filterByStatus(String status) async {
    setState(() {
      _filterStatus = status;
      _currentPage = 1;
      _isLoading = true;
    });
    
    try {
      final showSubmitted = status == 'completed';
      final gigs = _selectedCategory == null
          ? await _gigsService.fetchMicroGigs(showSubmitted: showSubmitted)
          : await _gigsService.fetchMicroGigsByCategory(
              _selectedCategory!,
              showSubmitted: showSubmitted,
            );
      
      if (mounted) {
        setState(() {
          _microGigs = gigs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error filtering by status: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    setState(() => _currentPage = page);
  }

  List<int> _getVisiblePages() {
    final pages = <int>[];
    final start = (_currentPage - 2).clamp(1, _totalPages);
    final end = (_currentPage + 2).clamp(1, _totalPages);
    
    for (int i = start; i <= end; i++) {
      pages.add(i);
    }
    
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: 16,
      ),
      child: Column(
        children: [
          // Title
          Text(
            '${_translationService.t('micro_gigs', fallback: 'Micro Gigs')} (${_translationService.t('quick_earn', fallback: 'Quick Earn')})',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Mobile Recharge Link
          if (_operators.isNotEmpty) _buildMobileRechargeLink(isMobile),
          
          const SizedBox(height: 16),
          
          // Main Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
              border: Border.all(
                color: Colors.grey.shade200,
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
            child: isMobile
                ? _buildMobileLayout()
                : _buildDesktopLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileRechargeLink(bool isMobile) {
    return GestureDetector(
      onTap: () {
        // Navigate to mobile recharge page
        print('Navigate to /mobile-recharge');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade500),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _translationService.t('mobile_recharge', fallback: 'Mobile Recharge'),
              style: GoogleFonts.roboto(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: _operators.take(4).map((operator) {
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      operator['icon'] ?? '',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 24,
                          height: 24,
                          color: Colors.grey.shade300,
                        );
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Categories Dropdown (Mobile)
        _buildMobileCategoriesDropdown(),
        
        const SizedBox(height: 16),
        
        // Gigs List
        _buildGigsList(),
        
        // Pagination
        if (_microGigs.isNotEmpty) _buildPagination(),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Sidebar - Categories
        Container(
          width: 240,
          decoration: BoxDecoration(
            color: Colors.grey.shade50.withOpacity(0.7),
            border: Border(
              right: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
          ),
          child: _buildCategoriesSidebar(),
        ),
        
        // Right Content - Gigs
        Expanded(
          child: Column(
            children: [
              _buildGigsList(),
              if (_microGigs.isNotEmpty) _buildPagination(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCategoriesDropdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50.withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: InputDecoration(
          labelText: _translationService.t('select_category', fallback: 'Select Category'),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text(_translationService.t('all_category', fallback: 'All Categories')),
          ),
          ..._categories.map((category) {
            return DropdownMenuItem<String>(
              value: category['id'].toString(),
              child: Text(
                '${category['category']} (${category['active']})',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(),
              ),
            );
          }).toList(),
        ],
        onChanged: (value) => _filterByCategory(value),
      ),
    );
  }

  Widget _buildCategoriesSidebar() {
    return Column(
      children: [
        // All Categories Button
        ListTile(
          title: Text(
            _translationService.t('all_category', fallback: 'All Categories'),
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          onTap: () => _filterByCategory(null),
          selected: _selectedCategory == null,
          selectedTileColor: Colors.blue.shade50,
        ),
        const Divider(height: 1),
        
        // Category List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category['id'].toString();
              
              return ListTile(
                title: Text(
                  category['category'] ?? '',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${category['active']}',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
                onTap: () => _filterByCategory(category['id'].toString()),
                selected: isSelected,
                selectedTileColor: Colors.blue.shade50,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGigsList() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(48),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_microGigs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _translationService.t('no_gigs_available', fallback: 'No gigs available'),
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header with Filter
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _translationService.t('available_gigs', fallback: 'Available Gigs'),
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildStatusFilter(),
            ],
          ),
        ),
        
        // Gigs Cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _paginatedGigs.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            return _buildGigCard(_paginatedGigs[index]);
          },
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButton<String>(
      value: _filterStatus,
      underline: const SizedBox(),
      items: const [
        DropdownMenuItem(value: '', child: Text('All')),
        DropdownMenuItem(value: 'approved', child: Text('Available')),
        DropdownMenuItem(value: 'completed', child: Text('Completed')),
      ],
      onChanged: (value) {
        if (value != null) _filterByStatus(value);
      },
    );
  }

  Widget _buildGigCard(Map<String, dynamic> gig) {
    final user = gig['user'];
    if (user == null) return const SizedBox.shrink();
    
    final categoryDetails = gig['category_details'];
    final imageUrl = categoryDetails?['image'] ?? '';
    final title = gig['title'] ?? '';
    final filledQty = gig['filled_quantity'] ?? 0;
    final requiredQty = gig['required_quantity'] ?? 0;
    final price = gig['price'] ?? 0;
    final createdAt = gig['created_at'] ?? '';
    final userName = user['name'] ?? '';
    
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50.withOpacity(0.7),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gig Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.work_outline, color: Colors.grey.shade400),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              
              // Gig Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.notifications, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$filledQty / ',
                              style: GoogleFonts.roboto(fontSize: 14),
                            ),
                            Text(
                              '$requiredQty',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatDate(createdAt),
                          style: GoogleFonts.roboto(fontSize: 14),
                        ),
                        if (!isMobile)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Posted By: ',
                                style: GoogleFonts.roboto(fontSize: 14),
                              ),
                              Text(
                                '${userName.substring(0, userName.length > 6 ? 6 : userName.length)}***',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.green.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Price and Action Button (Desktop)
              if (!isMobile) ...[
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '৳$price',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to order page
                        print('Order gig: ${gig['slug']}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text('Earn'),
                    ),
                  ],
                ),
              ],
            ],
          ),
          
          // Mobile Price and Button
          if (isMobile) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '৳$price',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade900,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    print('Order gig: ${gig['slug']}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  ),
                  child: const Text('Earn'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Page $_currentPage of $_totalPages',
                style: GoogleFonts.roboto(fontSize: 14),
              ),
              const SizedBox(width: 16),
              
              // Previous Button
              OutlinedButton(
                onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                child: const Text('Previous'),
              ),
              const SizedBox(width: 8),
              
              // Page Numbers
              ..._getVisiblePages().map((page) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: () => _goToPage(page),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: page == _currentPage 
                          ? Colors.blue.shade500 
                          : Colors.white,
                      foregroundColor: page == _currentPage 
                          ? Colors.white 
                          : Colors.grey.shade800,
                      minimumSize: const Size(40, 36),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text('$page'),
                  ),
                );
              }).toList(),
              
              const SizedBox(width: 8),
              
              // Next Button
              OutlinedButton(
                onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
                child: const Text('Next'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Results Info
          Text(
            'Showing ${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage * _itemsPerPage).clamp(0, _microGigs.length)} of ${_microGigs.length} gigs',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
