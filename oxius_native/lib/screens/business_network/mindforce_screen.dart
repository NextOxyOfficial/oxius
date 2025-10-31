import 'package:flutter/material.dart';
import '../../models/mindforce_models.dart';
import '../../services/mindforce_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/business_network/business_network_header.dart';
import '../../widgets/business_network/business_network_drawer.dart';
import '../../widgets/business_network/bottom_nav_bar.dart';
import '../../widgets/mindforce/problem_card.dart';
import '../business_network/profile_screen.dart';
import '../business_network/notifications_screen.dart';
import '../business_network/create_post_screen.dart';
import 'create_problem_screen.dart';
import 'mindforce_detail_screen.dart';

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
  int _currentPage = 1;
  bool _hasMore = true;

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
      print('Error loading notification count: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreData();
      }
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
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
      _currentPage++;
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
      filtered = filtered.where((p) => p.category?.id == _selectedCategoryId).toList();
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
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),
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
      drawer: isMobile ? const BusinessNetworkDrawer(currentRoute: '/business-network/mindforce') : null,
      body: Column(
        children: [
          // Header with Filter Dropdown
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology, size: 22, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  'MindForce',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 12),
                // Filter Dropdown
                Expanded(
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 0.5),
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey.shade50,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade600),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade800,
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
                const SizedBox(width: 8),
                // Post Button
                Material(
                  color: Colors.purple.shade600,
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    onTap: _showCreateProblemDialog,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Post',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
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
          ),
          
          // Category Tabs
          if (_categories.isNotEmpty)
            Container(
              height: 44,
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 1),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: _categories.length + 1, // +1 for 'All'
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // All category
                    return _buildCategoryChip(
                      'All',
                      null,
                      _selectedCategoryId == null,
                    );
                  }
                  final category = _categories[index - 1];
                  return _buildCategoryChip(
                    category.name,
                    category.id,
                    _selectedCategoryId == category.id,
                  );
                },
              ),
            ),
          
          // Content List
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildProblemsList(),
            ),
          ),
        ],
      ),
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

  Widget _buildProblemsList() {
    final problems = _filteredProblems;
    
    if (problems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology_outlined,
                size: 48,
                color: Colors.purple.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF616161),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _showCreateProblemDialog,
              icon: Icon(Icons.add, size: 18, color: Colors.purple.shade700),
              label: Text(
                'Post a Problem',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        itemCount: problems.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == problems.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          return _buildCompactProblemItem(problems[index]);
        },
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

  Widget _buildCompactProblemItem(MindForceProblem problem) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MindForceDetailScreen(
                problemId: problem.id,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200, width: 0.5),
                  ),
                  child: ClipOval(
                    child: problem.userDetails.image != null
                        ? Image.network(
                            problem.userDetails.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Icon(Icons.person, size: 18, color: Colors.grey.shade400),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: Icon(Icons.person, size: 18, color: Colors.grey.shade400),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                // Name, Badges, and Stats
                Expanded(
                  child: Row(
                    children: [
                      // Name with badges
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                problem.userDetails.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Verified Badge
                            if (_isUserVerified(problem)) ...[
                              const SizedBox(width: 3),
                              Icon(
                                Icons.verified,
                                size: 15,
                                color: Colors.blue.shade500,
                              ),
                            ],
                            // Pro Badge
                            if (_isUserPro(problem)) ...[
                              const SizedBox(width: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF7f00ff), Color(0xFFe100ff)],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Separator
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text('•', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ),
                      // Time
                      Text(
                        _formatTimeAgo(problem.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      // Separator
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text('•', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ),
                      // Views
                      Icon(Icons.visibility_outlined, size: 12, color: Colors.grey.shade700),
                      const SizedBox(width: 3),
                      Text(
                        '${problem.views}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      // Separator
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text('•', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ),
                      // Comments
                      Icon(Icons.chat_bubble_outline, size: 11, color: Colors.grey.shade700),
                      const SizedBox(width: 3),
                      Text(
                        '${problem.comments.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                if (problem.status == 'solved')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.shade200, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 11, color: Colors.green.shade700),
                        const SizedBox(width: 3),
                        Text(
                          'Solved',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Title - aligned with name
            Padding(
              padding: const EdgeInsets.only(left: 46), // Avatar (36px) + spacing (10px)
              child: Text(
                problem.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  height: 1.35,
                  letterSpacing: -0.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Payment Badge (if applicable) - aligned with title
            if (problem.paymentOption == 'paid' && problem.paymentAmount != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 46), // Aligned with title
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.amber.shade300, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payments_outlined, size: 13, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '৳${problem.paymentAmount!.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  void _handleNavTap(int index) {
    switch (index) {
      case 0:
        // Recent - Navigate to business network feed
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/business-network',
          (route) => route.settings.name == '/',
        ).then((_) {
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
        final user = AuthService.currentUser;
        if (user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: user.id),
            ),
          );
        } else {
          Navigator.pushNamed(context, '/login');
        }
        break;
      case 4:
        // AdsyClub/Home - Navigate to main home screen
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: isSelected ? Colors.purple.shade600 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedCategoryId = isSelected ? null : categoryId;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
