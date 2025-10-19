import 'package:flutter/material.dart';
import '../../models/mindforce_models.dart';
import '../../services/mindforce_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/business_network/business_network_header.dart';
import '../../widgets/business_network/business_network_drawer.dart';
import '../../widgets/business_network/bottom_nav_bar.dart';
import '../../widgets/mindforce/problem_card.dart';
import '../business_network/profile_screen.dart';
import 'create_problem_screen.dart';

class MindForceScreen extends StatefulWidget {
  const MindForceScreen({super.key});

  @override
  State<MindForceScreen> createState() => _MindForceScreenState();
}

class _MindForceScreenState extends State<MindForceScreen> with SingleTickerProviderStateMixin {
  List<MindForceProblem> _problems = [];
  List<MindForceCategory> _categories = [];
  bool _isLoading = true;
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _tabs = ['Active', 'Solved', 'My Problems'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
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

  List<MindForceProblem> get _activeProblems {
    return _problems.where((p) => p.status == 'active').toList();
  }

  List<MindForceProblem> get _solvedProblems {
    return _problems.where((p) => p.status == 'solved').toList();
  }

  List<MindForceProblem> get _myProblems {
    final user = AuthService.currentUser;
    if (user == null) return [];
    return _problems.where((p) => p.userDetails.id == int.tryParse(user.id)).toList();
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
        onQRCodeTap: () {},
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
          // Compact Header with gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade600,
                  Colors.deepPurple.shade700,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'MindForce',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showCreateProblemDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Post',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple.shade700,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Compact Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.purple.shade700,
              unselectedLabelColor: const Color(0xFF757575),
              indicatorColor: Colors.purple.shade700,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
            ),
          ),
          
          // Content with 4px padding
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProblemsList(_activeProblems, 'No active problems'),
                        _buildProblemsList(_solvedProblems, 'No solved problems'),
                        _buildProblemsList(_myProblems, 'You haven\'t posted any problems'),
                      ],
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? BusinessNetworkBottomNavBar(
              currentIndex: 0,
              onTap: (index) {},
            )
          : null,
    );
  }

  Widget _buildProblemsList(List<MindForceProblem> problems, String emptyMessage) {
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
              emptyMessage,
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: problems.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MindForceProblemCard(
              problem: problems[index],
              currentUserId: int.tryParse(AuthService.currentUser?.id ?? ''),
              onTap: () {
                // TODO: Navigate to problem detail
              },
            ),
          );
        },
      ),
    );
  }
}
