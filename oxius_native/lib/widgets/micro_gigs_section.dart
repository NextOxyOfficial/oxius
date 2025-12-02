import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/gigs_service.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import '../services/auth_service.dart';
import '../services/user_state_service.dart';
import '../screens/gig_details_screen.dart';
import 'home/account_balance_section.dart';
import 'home/mobile_recharge_section.dart';

class MicroGigsSection extends StatefulWidget {
  const MicroGigsSection({super.key});

  @override
  State<MicroGigsSection> createState() => _MicroGigsSectionState();
}

class _MicroGigsSectionState extends State<MicroGigsSection> {
  final TranslationService _translationService = TranslationService();
  final GigsService _gigsService = GigsService();
  final UserStateService _userStateService = UserStateService();
  
  List<Map<String, dynamic>> _microGigs = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _operators = [];
  
  bool _isLoading = true;
  String? _selectedCategory;
  String _filterStatus = 'all'; // 'all', 'available', 'completed'
  
  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _totalCount = 0;
  
  @override
  void initState() {
    super.initState();
    _translationService.addListener(_onTranslationsChanged);
    _userStateService.addListener(_onUserStateChanged);
    _loadData();
  }

  @override
  void dispose() {
    _translationService.removeListener(_onTranslationsChanged);
    _userStateService.removeListener(_onUserStateChanged);
    super.dispose();
  }

  void _onTranslationsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onUserStateChanged() {
    if (!mounted) return;
    // Filter state will be handled automatically in _buildStatusFilter
    setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load gigs with pagination, categories, and operators in parallel
      final results = await Future.wait([
        _gigsService.fetchMicroGigs(
          showSubmitted: false,
          page: _currentPage,
          pageSize: _itemsPerPage,
        ),
        _gigsService.fetchMicroGigCategories(),
        _gigsService.fetchMobileRechargeOperators(),
      ]);
      
      if (mounted) {
        final gigsData = results[0] as Map<String, dynamic>;
        final gigsList = gigsData['results'] as List<Map<String, dynamic>>;
        
        setState(() {
          _microGigs = gigsList;
          _totalCount = gigsData['count'] as int;
          _categories = _processCategories(gigsList);
          _operators = results[2] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
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

  int get _totalPages => (_totalCount / _itemsPerPage).ceil();

  Future<void> _filterByCategory(String? categoryId) async {
    setState(() {
      _selectedCategory = categoryId;
      _currentPage = 1;
      _isLoading = true;
    });
    
    try {
      final gigsData = categoryId == null
          ? await _gigsService.fetchMicroGigs(
              showSubmitted: _filterStatus == 'completed',
              page: _currentPage,
              pageSize: _itemsPerPage,
            )
          : await _gigsService.fetchMicroGigsByCategory(
              categoryId, 
              showSubmitted: _filterStatus == 'completed',
              page: _currentPage,
              pageSize: _itemsPerPage,
            );
      
      if (mounted) {
        setState(() {
          _microGigs = gigsData['results'] as List<Map<String, dynamic>>;
          _totalCount = gigsData['count'] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
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
      // For 'all' and 'available', show non-submitted gigs (showSubmitted: false)
      // For 'completed', show submitted gigs (showSubmitted: true)
      final showSubmitted = status == 'completed';
      final gigsData = _selectedCategory == null
          ? await _gigsService.fetchMicroGigs(
              showSubmitted: showSubmitted,
              page: _currentPage,
              pageSize: _itemsPerPage,
            )
          : await _gigsService.fetchMicroGigsByCategory(
              _selectedCategory!,
              showSubmitted: showSubmitted,
              page: _currentPage,
              pageSize: _itemsPerPage,
            );
      
      if (mounted) {
        setState(() {
          _microGigs = gigsData['results'] as List<Map<String, dynamic>>;
          _totalCount = gigsData['count'] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshGigs() async {
    // Refresh the current view (category + filter)
    if (_selectedCategory != null) {
      await _filterByCategory(_selectedCategory!);
    } else {
      await _filterByStatus(_filterStatus);
    }
  }

  Future<void> _goToPage(int page) async {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    
    setState(() {
      _currentPage = page;
      _isLoading = true;
    });
    
    try {
      final gigsData = _selectedCategory == null
          ? await _gigsService.fetchMicroGigs(
              showSubmitted: _filterStatus == 'completed',
              page: _currentPage,
              pageSize: _itemsPerPage,
            )
          : await _gigsService.fetchMicroGigsByCategory(
              _selectedCategory!,
              showSubmitted: _filterStatus == 'completed',
              page: _currentPage,
              pageSize: _itemsPerPage,
            );
      
      if (mounted) {
        setState(() {
          _microGigs = gigsData['results'] as List<Map<String, dynamic>>;
          _totalCount = gigsData['count'] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  String _getImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
    if (url.startsWith('/')) return '$baseUrl$url';
    return '$baseUrl/$url';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        children: [
          // Compact Title
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
                    Icons.work_outline,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_translationService.t('micro_gigs', fallback: 'Micro Gigs')}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _translationService.t('quick_earn', fallback: 'Quick Earn'),
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Account Balance Section (shows if logged in)
          const AccountBalanceSection(),
          
          // Mobile Recharge Section
          const MobileRechargeSection(),
          
          const SizedBox(height: 4),
          
          // Main Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
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
                      _getImageUrl(operator['icon']),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50.withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  fontSize: 14,
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
    // Use UserStateService for reactive authentication state
    final isLoggedIn = _userStateService.isAuthenticated;

    // Build items list based on current state
    final List<DropdownMenuItem<String>> items = [
      const DropdownMenuItem(value: 'all', child: Text('All')),
      const DropdownMenuItem(value: 'available', child: Text('Available')),
    ];

    // Add completed option for logged-in users
    if (isLoggedIn) {
      items.add(const DropdownMenuItem(value: 'completed', child: Text('Completed')));
    }

    // Reset filter if user logged out and was viewing completed gigs
    final currentValue = isLoggedIn || _filterStatus != 'completed' ? _filterStatus : 'all';

    return DropdownButton<String>(
      value: currentValue,
      underline: const SizedBox(),
      items: items,
      onChanged: (value) {
        if (value != null) _filterByStatus(value);
      },
    );
  }

  Widget _buildGigCard(Map<String, dynamic> gig) {
    final user = gig['user'];
    if (user == null) return const SizedBox.shrink();
    
    final categoryDetails = gig['category_details'];
    final imageUrl = _getImageUrl(categoryDetails?['image']);
    final title = gig['title'] ?? '';
    final filledQty = gig['filled_quantity'] ?? 0;
    final requiredQty = gig['required_quantity'] ?? 0;
    final price = gig['price'] ?? 0;
    final createdAt = gig['created_at'] ?? '';
    final userName = user['name'] ?? '';
    
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gig Image
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  imageUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 40,
                      height: 40,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.work_outline, size: 20, color: Colors.grey.shade400),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // Gig Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline, size: 14, color: Color(0xFF6B7280)),
                            const SizedBox(width: 3),
                            Text(
                              '$filledQty/',
                              style: GoogleFonts.roboto(fontSize: 12, color: Color(0xFF6B7280)),
                            ),
                            Text(
                              '$requiredQty',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Color(0xFF6B7280)),
                            const SizedBox(width: 3),
                            Text(
                              _formatDate(createdAt),
                              style: GoogleFonts.roboto(fontSize: 12, color: Color(0xFF6B7280)),
                            ),
                          ],
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '৳$price',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GigDetailsScreen(
                              gigSlug: gig['slug'],
                            ),
                          ),
                        );
                        
                        // If submission was successful, refresh the gig list
                        if (result == true && mounted) {
                          _refreshGigs();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        textStyle: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Earn Now'),
                    ),
                  ],
                ),
              ],
            ],
          ),
          
          // Mobile Price and Button
          if (isMobile) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '৳$price',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GigDetailsScreen(
                          gigSlug: gig['slug'],
                        ),
                      ),
                    );
                    
                    // If submission was successful, refresh the gig list
                    if (result == true && mounted) {
                      _refreshGigs();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    textStyle: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Earn Now'),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Page info text at top
          Text(
            'Page $_currentPage of $_totalPages',
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          
          // Pagination buttons wrapped to prevent overflow
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              // Previous Button
              _buildPaginationButton(
                label: 'Previous',
                icon: Icons.chevron_left,
                isEnabled: _currentPage > 1,
                onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                isIconLeft: true,
              ),
              
              // Page Numbers
              ..._getVisiblePages().map((page) {
                return _buildPageNumberButton(page);
              }).toList(),
              
              // Next Button
              _buildPaginationButton(
                label: 'Next',
                icon: Icons.chevron_right,
                isEnabled: _currentPage < _totalPages,
                onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
                isIconLeft: false,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Results Info
          Text(
            'Showing ${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage * _itemsPerPage).clamp(0, _totalCount)} of $_totalCount gigs',
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required String label,
    required IconData icon,
    required bool isEnabled,
    required VoidCallback? onPressed,
    required bool isIconLeft,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isEnabled ? const Color(0xFF10B981).withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEnabled ? const Color(0xFF10B981) : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isIconLeft) Icon(
                icon,
                size: 16,
                color: isEnabled ? const Color(0xFF10B981) : Colors.grey.shade400,
              ),
              if (isIconLeft) const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isEnabled ? const Color(0xFF10B981) : Colors.grey.shade400,
                ),
              ),
              if (!isIconLeft) const SizedBox(width: 4),
              if (!isIconLeft) Icon(
                icon,
                size: 16,
                color: isEnabled ? const Color(0xFF10B981) : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageNumberButton(int page) {
    final isActive = page == _currentPage;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _goToPage(page),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF10B981) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? const Color(0xFF10B981) : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              '$page',
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ),
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
