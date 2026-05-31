import 'package:flutter/material.dart';
import '../../models/mindforce_models.dart';
import '../../services/mindforce_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/fcm_service.dart';
import '../../widgets/business_network/business_network_header.dart';
import '../../widgets/business_network/business_network_drawer.dart';
import '../../widgets/business_network/bottom_nav_bar.dart';
import '../../widgets/skeleton_loader.dart';
import '../business_network/profile_screen.dart';
import '../business_network/notifications_screen.dart';
import '../business_network/create_post_screen.dart';
import 'create_problem_screen.dart';
import '../../widgets/mindforce/problem_detail_bottom_sheet.dart';
import 'profile_options.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

class MindForceScreen extends StatefulWidget {
  const MindForceScreen({super.key});

  @override
  State<MindForceScreen> createState() => _MindForceScreenState();
}

class _MindForceScreenState extends State<MindForceScreen> {
  List<MindForceProblem> _problems = [];
  List<MindForceCategory> _categories = [];
  bool _isLoading = false;
  int _unreadNotificationCount = 0;
  bool _isLoadingMore = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  String _selectedFilter = 'all'; // all, active, solved, my
  int? _selectedCategoryId; // null means 'All'
  bool _hasMore = true;

  static const Color _page = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFF8FAFC);
  static const Color _ink = Color(0xFF1E293B);
  static const Color _muted = Color(0xFF64748B);
  static const Color _line = Color(0xFFE2E8F0);
  static const Color _brand = Color(0xFF6366F1);
  static const Color _brandSoft = Color(0xFFE0E7FF);
  static const Color _mintSoft = Color(0xFFD1FAE5);
  static const Color _amber = Color(0xFFD97706);
  static const Color _amberSoft = Color(0xFFFEF3C7);

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUnreadNotificationCount();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadUnreadNotificationCount() async {
    if (!AuthService.isAuthenticated) return;

    try {
      final result = await NotificationService.getNotifications(page: 1);
      if (mounted) {
        setState(() {
          _unreadNotificationCount = result['unreadCount'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading notification count: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreData();
      }
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasMore = true;
    });

    final problems = await MindForceService.getProblems();
    final categories = await MindForceService.getCategories();

    if (mounted) {
      setState(() {
        _problems = problems;
        _categories = categories;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // TODO: Implement paginated API call when backend supports it
    // For now, we'll just set hasMore to false
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        _hasMore = false; // Set to true when pagination is implemented
      });
    }
  }

  List<MindForceProblem> get _filteredProblems {
    var filtered = _problems;

    // Filter by status
    switch (_selectedFilter) {
      case 'active':
        filtered = filtered.where((p) => p.status == 'active').toList();
        break;
      case 'solved':
        filtered = filtered.where((p) => p.status == 'solved').toList();
        break;
      case 'my':
        final user = AuthService.currentUser;
        if (user == null) return [];
        filtered = filtered.where((p) => p.userDetails.id == user.id).toList();
        break;
      default:
        // By default, show only active problems (not solved)
        filtered = filtered.where((p) => p.status == 'active').toList();
        break;
    }

    // Filter by category
    if (_selectedCategoryId != null) {
      filtered =
          filtered.where((p) => p.category?.id == _selectedCategoryId).toList();
    }

    return filtered;
  }

  void _showCreateProblemDialog() {
    final user = AuthService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to create a problem')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateProblemScreen(
        categories: _categories,
        onSubmit: _handleCreateProblem,
      ),
    );
  }

  Future<void> _handleCreateProblem(Map<String, dynamic> data) async {
    final problem = await MindForceService.createProblem(
      title: data['title'],
      description: data['description'],
      categoryId: data['categoryId'],
      paymentOption: data['paymentOption'] ?? 'free',
      paymentAmount: data['paymentAmount'],
      images: data['images'] ?? [],
    );

    if (problem != null && mounted) {
      setState(() {
        _problems.insert(0, problem);
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Problem posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to post problem. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final activeCount =
        _problems.where((problem) => problem.status == 'active').length;
    final solvedCount =
        _problems.where((problem) => problem.status == 'solved').length;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _page,
      appBar: BusinessNetworkHeader(
        onMenuTap: () {
          if (isMobile) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scaffoldKey.currentState?.openDrawer();
            });
          }
        },
        onSearchTap: () {},
        onProfileTap: () {
          final user = AuthService.currentUser;
          if (user != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: user.id),
              ),
            );
          }
        },
      ),
      drawer: isMobile
          ? const BusinessNetworkDrawer(
              currentRoute: '/business-network/mindforce')
          : null,
      body: _isLoading
          ? SkeletonLoader.listView(itemCount: 6, showAvatar: true)
          : _buildProblemsList(
              activeCount: activeCount, solvedCount: solvedCount),
      bottomNavigationBar: isMobile
          ? BusinessNetworkBottomNavBar(
              currentIndex: 4, // More tab since MindForce is in drawer
              isLoggedIn: AuthService.isAuthenticated,
              onTap: _handleNavTap,
              unreadCount: _unreadNotificationCount,
            )
          : null,
    );
  }

  Widget _buildPageIntro(int activeCount, int solvedCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _brandSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  size: 19,
                  color: _brand,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MindForce',
                      style: TextStyle(
                        fontSize: 19,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'A Collaborative Network for Problem Solving',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: _ink,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _showCreateProblemDialog,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'Post',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _buildTopMetric('Active', '$activeCount', _brandSoft)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildTopMetric('Solved', '$solvedCount', _mintSoft)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildTopMetric('Topics', '${_categories.length}',
                      const Color(0xFFE5E7FF))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopMetric(String label, String value, Color tone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _muted,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _line),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFilter,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20, color: _muted),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Problems')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'solved', child: Text('Solved')),
                  DropdownMenuItem(value: 'my', child: Text('My Problems')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedFilter = value);
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _line),
          ),
          child: Text(
            '${_filteredProblems.length} results',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProblemsList(
      {required int activeCount, required int solvedCount}) {
    final problems = _filteredProblems;

    return AdsyRefreshIndicator(
      onRefresh: _loadData,
      child: Container(
        color: Colors.white,
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 14),
          itemCount: 1 +
              (problems.isEmpty ? 1 : problems.length) +
              (_isLoadingMore && problems.isNotEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPageIntro(activeCount, solvedCount),
                  const SizedBox(height: 8),
                  _buildToolbar(),
                  if (_categories.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        itemCount: _categories.length + 1,
                        itemBuilder: (context, chipIndex) {
                          if (chipIndex == 0) {
                            return _buildCategoryChip(
                              'All topics',
                              null,
                              _selectedCategoryId == null,
                            );
                          }
                          final category = _categories[chipIndex - 1];
                          return _buildCategoryChip(
                            category.name,
                            category.id,
                            _selectedCategoryId == category.id,
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  const Divider(height: 1, thickness: 1, color: _line),
                ],
              );
            }

            if (problems.isEmpty && index == 1) {
              return _buildEmptyStateCard(
                  activeCount: activeCount, solvedCount: solvedCount);
            }

            if (_isLoadingMore && index == problems.length + 1) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: AdsyLoadingIndicator(),
                ),
              );
            }

            final problemIndex = index - 1;
            return _buildCompactProblemItem(problems[problemIndex]);
          },
        ),
      ),
    );
  }

  String _getEmptyMessage() {
    switch (_selectedFilter) {
      case 'active':
        return 'No active problems';
      case 'solved':
        return 'No solved problems';
      case 'my':
        return 'You haven\'t posted any problems';
      default:
        return 'No problems found';
    }
  }

  String _getEmptyDescription() {
    if (_selectedCategoryId != null ||
        _selectedFilter == 'my' ||
        _selectedFilter == 'solved') {
      return 'This view is empty right now. Try another filter or clear the topic selection to explore more discussions.';
    }

    return 'Start the conversation with a clear problem statement so the right people can jump in quickly.';
  }

  bool get _hasActiveFilters {
    return _selectedFilter != 'all' || _selectedCategoryId != null;
  }

  Widget _buildEmptyStateCard(
      {required int activeCount, required int solvedCount}) {
    final selectedCategory = _categories
        .where((category) => category.id == _selectedCategoryId)
        .cast<MindForceCategory?>()
        .firstWhere(
          (category) => category != null,
          orElse: () => null,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 18, 6, 20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _brandSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_mosaic_rounded,
                    color: _brand,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _line),
                        ),
                        child: Text(
                          _hasActiveFilters
                              ? 'Filtered view'
                              : 'Quiet right now',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getEmptyMessage(),
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _getEmptyDescription(),
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: _muted,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildEmptyInsightTile(
                    'View',
                    _selectedFilter == 'all'
                        ? 'Active feed'
                        : _selectedFilter == 'my'
                            ? 'My problems'
                            : _selectedFilter[0].toUpperCase() +
                                _selectedFilter.substring(1),
                    _surface,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildEmptyInsightTile(
                    'Topic',
                    selectedCategory?.name ?? 'All topics',
                    _brandSoft,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildEmptyInsightTile(
                    'Open now',
                    '$activeCount active',
                    _mintSoft,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tips_and_updates_outlined,
                        size: 18, color: _amber),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      solvedCount > 0
                          ? '$solvedCount solved discussions are already in the network. A new post can attract faster, targeted replies.'
                          : 'Add one concise title and a focused description to make your post easier to solve.',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: _muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showCreateProblemDialog,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'Post a Problem',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (_hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedFilter = 'all';
                          _selectedCategoryId = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ink,
                        side: const BorderSide(color: _line),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                      label: const Text(
                        'Clear Filters',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInsightTile(String label, String value, Color tone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactProblemItem(MindForceProblem problem) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => ProblemDetailBottomSheet(
              problemId: problem.id,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          decoration: BoxDecoration(
            border: const Border(bottom: BorderSide(color: _line, width: 1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _line),
                    ),
                    child: ClipOval(
                      child: problem.userDetails.image != null
                          ? Image.network(
                              problem.userDetails.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.white,
                                  child: const Icon(Icons.person_outline,
                                      size: 16, color: _muted),
                                );
                              },
                            )
                          : Container(
                              color: Colors.white,
                              child: const Icon(Icons.person_outline,
                                  size: 16, color: _muted),
                            ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      problem.userDetails.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _ink,
                                      ),
                                    ),
                                  ),
                                  if (_isUserVerified(problem)) ...[
                                    const SizedBox(width: 3),
                                    const Icon(Icons.verified_rounded,
                                        size: 13, color: Color(0xFF2563EB)),
                                  ],
                                  if (_isUserPro(problem)) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: _ink,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        'PRO',
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (problem.category != null) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child:
                                    _buildCategoryTag(problem.category!.name),
                              ),
                            ],
                            if (problem.category != null &&
                                problem.status == 'solved')
                              const SizedBox(width: 6),
                            if (problem.status == 'solved')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _mintSoft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Solved',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 7,
                          runSpacing: 3,
                          children: [
                            Text(
                              _formatTimeAgo(problem.createdAt),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _muted,
                              ),
                            ),
                            _buildFeedMeta(
                                Icons.visibility_outlined, '${problem.views}'),
                            _buildFeedMeta(Icons.chat_bubble_outline_rounded,
                                '${problem.comments.length}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(left: 37),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            problem.title,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.24,
                              fontWeight: FontWeight.w600,
                              color: _ink,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (problem.description.trim().isNotEmpty ||
                        (problem.paymentOption == 'paid' &&
                            problem.paymentAmount != null)) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (problem.description.trim().isNotEmpty)
                            Expanded(
                              child: Text(
                                problem.description.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.35,
                                  color: _muted,
                                ),
                              ),
                            ),
                          if (problem.paymentOption == 'paid' &&
                              problem.paymentAmount != null) ...[
                            if (problem.description.trim().isNotEmpty)
                              const SizedBox(width: 8),
                            _buildMetaTag(
                                '৳${problem.paymentAmount!.toStringAsFixed(0)}',
                                _amberSoft,
                                _amber),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedMeta(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: _muted),
        const SizedBox(width: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _muted,
          ),
        ),
      ],
    );
  }

  Widget _buildMetaTag(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildCategoryTag(String label) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: _brandSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _brand.withValues(alpha: 0.12)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.right,
          softWrap: true,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: _brand,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  void _handleNavTap(int index) {
    final rootNavigator =
        FCMService.navigatorKey.currentState ?? Navigator.of(context);

    switch (index) {
      case 0:
        // Recent - Navigate to business network feed
        rootNavigator
            .pushNamedAndRemoveUntil(
          '/business-network',
          (route) => route.isFirst,
        )
            .then((_) {
          // Refresh notification count when returning
          _loadUnreadNotificationCount();
        });
        break;
      case 1:
        // Notifications
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationsScreen(),
          ),
        ).then((_) {
          // Refresh notification count when returning
          _loadUnreadNotificationCount();
        });
        break;
      case 2:
        // Create Post
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreatePostScreen(),
          ),
        );
        break;
      case 3:
        // Profile
        if (AuthService.isAuthenticated) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileOptionsScreen(),
            ),
          );
        } else {
          Navigator.pushNamed(context, '/login');
        }
        break;
      case 4:
        // AdsyClub/Home - Navigate to main home screen
        rootNavigator.pushNamedAndRemoveUntil('/', (route) => false);
        break;
    }
  }

  String _formatTimeAgo(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  bool _isUserPro(MindForceProblem problem) {
    return problem.userDetails.isPro;
  }

  bool _isUserVerified(MindForceProblem problem) {
    return problem.userDetails.kyc;
  }

  Widget _buildCategoryChip(String label, int? categoryId, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected ? _brand : _surface,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedCategoryId = isSelected ? null : categoryId;
            });
          },
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: isSelected ? _brand : _line),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : _muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
