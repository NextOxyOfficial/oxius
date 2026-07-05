import 'package:flutter/material.dart';
import 'package:oxius_native/utils/image_utils.dart';
import 'package:oxius_native/utils/app_fonts.dart';
import 'package:oxius_native/theme/app_text.dart';
import '../services/gigs_service.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import '../services/user_state_service.dart';
import '../screens/gig_details_screen.dart';
import 'home/account_balance_section.dart';
import 'home/mobile_recharge_section.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

class MicroGigsSection extends StatefulWidget {
  const MicroGigsSection({super.key});

  @override
  State<MicroGigsSection> createState() => _MicroGigsSectionState();
}

class _MicroGigsSectionState extends State<MicroGigsSection> {
  final TranslationService _translationService = TranslationService();
  final GigsService _gigsService = GigsService();
  final UserStateService _userStateService = UserStateService();

  static const Color _indigo = Color(0xFF6366F1);
  static const Color _violet = Color(0xFF8B5CF6);
  static const Color _emerald = Color(0xFF10B981);
  static const Color _emeraldDark = Color(0xFF059669);
  static const Color _slate100 = Color(0xFFF1F5F9);
  static const Color _slate200 = Color(0xFFE2E8F0);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _slate500 = Color(0xFF64748B);
  static const Color _slate800 = Color(0xFF1E293B);

  List<Map<String, dynamic>> _microGigs = [];
  List<Map<String, dynamic>> _categories = [];

  bool _isLoading = true;
  String? _loadError;
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
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      // Load gigs with pagination and categories in parallel
      final results = await Future.wait([
        _gigsService.fetchMicroGigs(
          showSubmitted: false,
          page: _currentPage,
          pageSize: _itemsPerPage,
        ),
        _gigsService.fetchMicroGigCategories(),
      ]);

      if (mounted) {
        final gigsData = results[0] as Map<String, dynamic>;
        final gigsList = gigsData['results'] as List<Map<String, dynamic>>;

        setState(() {
          _microGigs = gigsList;
          _totalCount = gigsData['count'] as int;
          _categories = _processCategories(gigsList);
          _isLoading = false;
          _loadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = _translationService.t(
            'gigs_load_failed',
            fallback: 'Could not load gigs right now. Please try again.',
          );
        });
      }
    }
  }

  List<Map<String, dynamic>> _processCategories(
      List<Map<String, dynamic>> gigs) {
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
      _loadError = null;
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
          _loadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = _translationService.t(
            'gigs_filter_failed',
            fallback: 'Failed to apply filter. Please try again.',
          );
        });
      }
    }
  }

  Future<void> _filterByStatus(String status) async {
    setState(() {
      _filterStatus = status;
      _currentPage = 1;
      _isLoading = true;
      _loadError = null;
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
          _loadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = _translationService.t(
            'gigs_status_failed',
            fallback: 'Could not load this status right now.',
          );
        });
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
      _loadError = null;
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
          _loadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = _translationService.t(
            'gigs_page_failed',
            fallback: 'Could not load this page. Please retry.',
          );
        });
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
      // Regular section screen-side padding: 4px
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        children: [
          // Compact Title — 6px effective screen inset (4 outer + 2 here)
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.work_outline,
                  size: 20,
                  color: _indigo,
                ),
                const SizedBox(width: 8),
                Text(
                  _translationService.t('micro_gigs', fallback: 'Micro Gigs'),
                  style: AppText.sectionTitle(),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _violet.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _translationService.t('quick_earn', fallback: 'Quick Earn'),
                    style: AppText.badge(color: _violet),
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

          // Main content (flat)
          isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
        ],
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

        // Pagination - only show if more than one page
        if (_microGigs.isNotEmpty && _totalPages > 1) _buildPagination(),
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
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Color(0xFFF1F5F9),
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
              if (_microGigs.isNotEmpty && _totalPages > 1) _buildPagination(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileCategoriesDropdown() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title — 6px effective screen inset (4 outer + 2 here)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _indigo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.category_outlined,
                      size: 13, color: _indigo),
                ),
                const SizedBox(width: 7),
                Text(
                  _translationService.t('all_category',
                      fallback: 'All Categories'),
                  style: AppText.cardTitle(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedCategory,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: _slate500),
              style: AppText.bodyText(color: _slate800),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: _slate200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(
                      color: _indigo.withValues(alpha: 0.75), width: 1.2),
                ),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    _translationService.t('all_category',
                        fallback: 'All Categories'),
                    overflow: TextOverflow.ellipsis,
                  ),
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
                }),
              ],
              onChanged: (value) => _filterByCategory(value),
            ),
          ),
        ],
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
            style: AppText.cardTitle(),
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
                  style: isSelected
                      ? AppText.cardTitle()
                      : AppText.cardSubtitle(color: AppText.secondary),
                ),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${category['active']}',
                    style: AppText.meta(color: Colors.green.shade700),
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
    return Column(
      children: [
        Container(
          // Header — 6px effective screen inset (4 outer + 2 here)
          padding: const EdgeInsets.fromLTRB(2, 12, 2, 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _indigo.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.work_outline_rounded,
                        size: 14, color: _indigo),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _translationService.t('available_gigs',
                          fallback: 'Available Gigs'),
                      style: AppText.cardTitle(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _indigo.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _paginatedGigs.length.toString(),
                      style: AppText.meta(color: _indigo),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.center,
                child: _buildStatusFilter(),
              ),
            ],
          ),
        ),
        if (_loadError != null)
          Container(
            margin: const EdgeInsets.fromLTRB(2, 10, 2, 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _violet.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _violet.withValues(alpha: 0.30)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: _violet),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _loadError!,
                    style: AppText.cardSubtitle(color: _slate800),
                  ),
                ),
                TextButton(
                  onPressed: _refreshGigs,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _translationService.t('retry', fallback: 'Retry'),
                    style: AppText.linkText(color: _indigo),
                  ),
                ),
              ],
            ),
          ),
        if (_isLoading)
          Container(
            padding: const EdgeInsets.all(30),
            child: const Center(child: AdsyLoadingIndicator()),
          )
        else if (_microGigs.isEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                Icon(Icons.work_outline_rounded, size: 48, color: _slate400),
                const SizedBox(height: 10),
                Text(
                  _filterStatus == 'completed'
                      ? _translationService.t(
                          'no_completed_gigs',
                          fallback: 'No completed gigs yet.',
                        )
                      : _translationService.t(
                          'no_gigs_available',
                          fallback: 'No gigs available',
                        ),
                  style: AppText.cardSubtitle(color: _slate500),
                ),
                if (_filterStatus == 'completed') ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _filterByStatus('available'),
                    style: TextButton.styleFrom(
                      foregroundColor: _indigo,
                      textStyle: AppFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(
                      _translationService.t(
                        'view_open_gigs',
                        fallback: 'View Open Gigs',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _paginatedGigs.length,
            padding: const EdgeInsets.symmetric(vertical: 4),
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFF1F5F9),
            ),
            itemBuilder: (context, index) =>
                _buildGigCard(_paginatedGigs[index]),
          ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    final isLoggedIn = _userStateService.isAuthenticated;
    final currentValue =
        isLoggedIn || _filterStatus != 'completed' ? _filterStatus : 'all';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusChip('all', 'All', currentValue == 'all'),
        const SizedBox(width: 6),
        _buildStatusChip('available', 'Open', currentValue == 'available'),
        if (isLoggedIn) ...[
          const SizedBox(width: 6),
          _buildStatusChip(
              'completed', 'Complete', currentValue == 'completed'),
        ],
      ],
    );
  }

  Widget _buildStatusChip(String value, String label, bool isSelected) {
    return InkWell(
      onTap: () => _filterByStatus(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? _indigo.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? _indigo : _slate200),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppFonts.roboto(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? _indigo : _slate500,
          ),
        ),
      ),
    );
  }

  Future<void> _openGigDetails(Map<String, dynamic> gig) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GigDetailsScreen(gigSlug: gig['slug']),
      ),
    );

    if (result == true && mounted) {
      _refreshGigs();
    }
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
    final completion = requiredQty > 0 ? filledQty / requiredQty : 0.0;
    final progress = completion.clamp(0.0, 1.0).toDouble();
    final slotsLeft =
        (requiredQty - filledQty) > 0 ? (requiredQty - filledQty) : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _slate100,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AppImage.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    width: 44,
                    height: 44,
                    errorWidget: Icon(Icons.work_outline,
                        size: 20, color: Colors.grey.shade400),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.cardTitle(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _emerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_outline,
                                  size: 13, color: Color(0xFF15803D)),
                              const SizedBox(width: 4),
                              Text(
                                '$filledQty/$requiredQty',
                                style: AppText.meta(color: _emeraldDark),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _slate100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 13, color: Color(0xFF6B7280)),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(createdAt),
                                style: AppText.meta(color: _slate500),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _indigo.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            slotsLeft > 0
                                ? '$slotsLeft slots left'
                                : 'Filling soon',
                            style: AppText.meta(color: _indigo),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: _slate100,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 0.85 ? _violet : _indigo,
              ),
            ),
          ),
          const SizedBox(height: 11),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _indigo.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _indigo.withValues(alpha: 0.25)),
                ),
                child: Text(
                  '৳$price',
                  style: AppText.price(color: _indigo),
                ),
              ),
              SizedBox(
                height: 34,
                child: OutlinedButton(
                  onPressed: () => _openGigDetails(gig),
                  style: OutlinedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.white,
                    foregroundColor: _indigo,
                    side: const BorderSide(color: _indigo, width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: AppFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Earn Now'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          // Pagination buttons
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              // Previous Button
              _buildPaginationButton(
                label: 'Previous',
                icon: Icons.chevron_left,
                isEnabled: _currentPage > 1,
                onPressed:
                    _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                isIconLeft: true,
              ),

              // Page Numbers
              ..._getVisiblePages().map((page) {
                return _buildPageNumberButton(page);
              }),

              // Next Button
              _buildPaginationButton(
                label: 'Next',
                icon: Icons.chevron_right,
                isEnabled: _currentPage < _totalPages,
                onPressed: _currentPage < _totalPages
                    ? () => _goToPage(_currentPage + 1)
                    : null,
                isIconLeft: false,
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Results Info
          Text(
            'Page $_currentPage of $_totalPages  •  Showing ${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage * _itemsPerPage).clamp(0, _totalCount)} of $_totalCount gigs',
            style: AppText.meta(),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isEnabled ? _indigo.withValues(alpha: 0.1) : _slate100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isEnabled ? _indigo : _slate200,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isIconLeft)
                Icon(
                  icon,
                  size: 14,
                  color: isEnabled ? _indigo : _slate400,
                ),
              if (isIconLeft) const SizedBox(width: 2),
              Text(
                label,
                style: AppFonts.roboto(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isEnabled ? _indigo : _slate400,
                ),
              ),
              if (!isIconLeft) const SizedBox(width: 2),
              if (!isIconLeft)
                Icon(
                  icon,
                  size: 14,
                  color: isEnabled ? _indigo : _slate400,
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
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? _indigo : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? _indigo : _slate200,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              '$page',
              style: AppFonts.roboto(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.white : _slate500,
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
