import 'package:flutter/material.dart';
import '../../models/mindforce_models.dart';
import '../../services/mindforce_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/business_network/business_network_header.dart';
import '../../widgets/business_network/business_network_drawer.dart';
import '../../widgets/business_network/bottom_nav_bar.dart';
import '../../widgets/mindforce/problem_card.dart';
import '../business_network/profile_screen.dart';

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
      builder: (context) => _CreateProblemDialog(
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
    );

    if (problem != null && mounted) {
      setState(() {
        _problems.insert(0, problem);
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Problem posted successfully!')),
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 896),
          child: Column(
            children: [
              // Header with Create button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'MindForce',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _showCreateProblemDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Post Problem'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF3B82F6),
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: const Color(0xFF3B82F6),
                  tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                ),
              ),
              
              // Content
              Expanded(
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
            ],
          ),
        ),
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
            Icon(Icons.help_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: problems.length,
        itemBuilder: (context, index) {
          return MindForceProblemCard(
            problem: problems[index],
            currentUserId: int.tryParse(AuthService.currentUser?.id ?? ''),
            onTap: () {
              // TODO: Navigate to problem detail
            },
          );
        },
      ),
    );
  }
}

class _CreateProblemDialog extends StatefulWidget {
  final List<MindForceCategory> categories;
  final Function(Map<String, dynamic>) onSubmit;

  const _CreateProblemDialog({
    required this.categories,
    required this.onSubmit,
  });

  @override
  State<_CreateProblemDialog> createState() => _CreateProblemDialogState();
}

class _CreateProblemDialogState extends State<_CreateProblemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _selectedCategoryId;
  String _paymentOption = 'free';
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Post a Problem',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              if (widget.categories.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCategoryId = value),
                ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onSubmit({
                          'title': _titleController.text,
                          'description': _descriptionController.text,
                          'categoryId': _selectedCategoryId,
                          'paymentOption': _paymentOption,
                          'paymentAmount': _amountController.text.isNotEmpty
                              ? double.tryParse(_amountController.text)
                              : null,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Post'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
