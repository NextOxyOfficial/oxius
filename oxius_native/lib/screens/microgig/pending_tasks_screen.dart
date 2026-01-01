import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/microgig_models.dart';
import '../../services/microgig_service.dart';
import '../../services/translation_service.dart';
import '../../widgets/linkify_text.dart';

class PendingTasksScreen extends StatefulWidget {
  const PendingTasksScreen({super.key});

  @override
  State<PendingTasksScreen> createState() => _PendingTasksScreenState();
}

class _PendingTasksScreenState extends State<PendingTasksScreen> {
  List<MicroGigTask> _tasks = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  MicroGigTask? _selectedTask;
  bool _showDetails = false;
  final TranslationService _translationService = TranslationService();
  Timer? _timer;
  final ScrollController _scrollController = ScrollController();
  
  // Pagination and filtering
  int _currentPage = 1;
  bool _hasMore = true;
  String _selectedFilter = 'all'; // all, pending, approved, rejected

  String t(String key) => _translationService.translate(key);

  @override
  void initState() {
    super.initState();
    _loadPendingTasks();
    _scrollController.addListener(_onScroll);
    // Update every second for live countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will trigger rebuild to update countdown
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreTasks();
    }
  }

  Future<void> _loadPendingTasks({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _tasks.clear();
      });
    }
    
    setState(() => _isLoading = true);
    
    final response = await MicrogigService.getPendingTasks(
      page: _currentPage,
      filter: _selectedFilter,
    );
    
    if (mounted) {
      setState(() {
        _tasks = response['tasks'] as List<MicroGigTask>;
        _hasMore = response['hasMore'] as bool;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreTasks() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() => _isLoadingMore = true);
    
    final response = await MicrogigService.getPendingTasks(
      page: _currentPage + 1,
      filter: _selectedFilter,
    );
    
    if (mounted) {
      setState(() {
        _tasks.addAll(response['tasks'] as List<MicroGigTask>);
        _hasMore = response['hasMore'] as bool;
        _currentPage++;
        _isLoadingMore = false;
      });
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _currentPage = 1;
      _tasks.clear();
    });
    _loadPendingTasks();
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  String _stripHtmlTags(String htmlString) {
    // Remove HTML tags using regex
    final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return htmlString.replaceAll(exp, '').trim();
  }

  String _formatCountdown(MicroGigTask task) {
    final elapsed = DateTime.now().difference(task.createdAt);
    final remaining = const Duration(hours: 48) - elapsed;
    
    if (remaining.isNegative) {
      return 'Auto-approved';
    }
    
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showTaskDetails(MicroGigTask task) {
    setState(() {
      _selectedTask = task;
      _showDetails = true;
    });
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterChip(
              label: 'All',
              value: 'all',
              icon: Icons.list,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterChip(
              label: 'Pending',
              value: 'pending',
              icon: Icons.pending_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterChip(
              label: 'Approved',
              value: 'approved',
              icon: Icons.check_circle_outline,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterChip(
              label: 'Rejected',
              value: 'rejected',
              icon: Icons.cancel_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedFilter == value;
    
    Color getColor() {
      if (!isSelected) return Colors.grey[300]!;
      switch (value) {
        case 'pending':
          return Colors.orange;
        case 'approved':
          return Colors.green;
        case 'rejected':
          return Colors.red;
        default:
          return const Color(0xFF3B82F6);
      }
    }

    return GestureDetector(
      onTap: () => _onFilterChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? getColor().withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? getColor() : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? getColor() : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? getColor() : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.task_alt,
                size: 16,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Tasks List',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(),
          // Task List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          RefreshIndicator(
                            onRefresh: () => _loadPendingTasks(isRefresh: true),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(4, 8, 4, 80),
                              itemCount: _tasks.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _tasks.length) {
                                  // Loading indicator at the bottom
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                final task = _tasks[index];
                                return _buildTaskCard(task);
                              },
                            ),
                          ),
                          if (_showDetails && _selectedTask != null)
                            _buildTaskDetailsOverlay(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(MicroGigTask task) {
    Color statusColor;
    if (task.approved) {
      statusColor = const Color(0xFF10B981);
    } else if (task.rejected) {
      statusColor = const Color(0xFFEF4444);
    } else {
      statusColor = const Color(0xFFF59E0B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showTaskDetails(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Status Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.gigTitle ?? 'Untitled Gig',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      task.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // Price and Auto-approval countdown row
              Row(
                children: [
                  // Price
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.payments_outlined,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '৳${task.gigPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Auto-approval countdown for pending tasks
                  if (!task.approved && !task.rejected) ...[
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          task.is48HoursPassed
                              ? Icons.check_circle
                              : Icons.timer,
                          size: 14,
                          color: task.is48HoursPassed
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Auto-Approval: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          task.is48HoursPassed
                              ? 'Done'
                              : _formatCountdown(task),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: task.is48HoursPassed
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskDetailsOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _showDetails = false),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping on card
            child: Container(
              margin: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 600),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedTask!.gigTitle ?? 'Task Details',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _showDetails = false),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Status',
                            _selectedTask!.status,
                            _selectedTask!.approved
                                ? Colors.green
                                : _selectedTask!.rejected
                                    ? Colors.red
                                    : Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Created',
                            _formatDate(_selectedTask!.createdAt),
                          ),
                          if (_selectedTask!.submitDetails != null) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Submission Details:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: LinkifyText(
                                _stripHtmlTags(_selectedTask!.submitDetails!),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                          if (_selectedTask!.mediaUrls.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Media:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedTask!.mediaUrls
                                  .map((url) => ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          url,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stack) {
                                            return Container(
                                              height: 120,
                                              width: 120,
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.image),
                                            );
                                          },
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                          if (_selectedTask!.rejected &&
                              _selectedTask!.reason != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rejected Reason:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedTask!.reason!,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}
