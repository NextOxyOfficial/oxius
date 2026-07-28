import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/microgig_models.dart';
import '../../services/microgig_service.dart';
import '../../services/translation_service.dart';
import '../../widgets/linkify_text.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

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
  // Server-side total for the ACTIVE filter. Shown in the summary bar because
  // it is the only count that stays true — _tasks holds just the loaded pages.
  int _totalCount = 0;

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
        _totalCount = (response['count'] as int?) ?? 0;
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
        _totalCount = (response['count'] as int?) ?? _totalCount;
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
    final RegExp exp =
        RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
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
            color: Colors.black.withValues(alpha: 0.05),
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
          color: isSelected ? getColor().withValues(alpha: 0.1) : Colors.grey[100],
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
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
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
                ? const Center(child: AdsyLoadingIndicator())
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
                          AdsyRefreshIndicator(
                            onRefresh: () => _loadPendingTasks(isRefresh: true),
                            // index 0 = summary bar, 1 = the list surface,
                            // 2 = loader. Rows live INSIDE one card so they
                            // read as a continuous list, not stacked boxes.
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(0, 4, 0, 80),
                              itemCount: 2 + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == 0) return _buildSummaryBar();
                                if (index == 1) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      children: [
                                        for (var i = 0;
                                            i < _tasks.length;
                                            i++)
                                          _buildTaskRow(
                                            _tasks[i],
                                            isLast: i == _tasks.length - 1,
                                          ),
                                      ],
                                    ),
                                  );
                                }
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: AdsyLoadingIndicator(),
                                  ),
                                );
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

  /// Summary bar — the ONE number that is genuinely known for the active
  /// filter. _tasks only holds the pages loaded so far, so anything summed
  /// from it (earnings, per-status counts) would understate as you scroll;
  /// the server's count for this filter does not.
  Widget _buildSummaryBar() {
    final label = {
          'all': 'সর্বমোট টাস্ক',
          'pending': 'অপেক্ষমাণ',
          'approved': 'অনুমোদিত',
          'rejected': 'বাতিল',
        }[_selectedFilter] ??
        'সর্বমোট টাস্ক';
    final tone = {
          'pending': const Color(0xFFF59E0B),
          'approved': const Color(0xFF10B981),
          'rejected': const Color(0xFFEF4444),
        }[_selectedFilter] ??
        const Color(0xFF2563EB);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 17, color: tone),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: tone.withValues(alpha: 0.95),
            ),
          ),
          const Spacer(),
          Text(
            '$_totalCount',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: tone,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  /// Relative submit time — when a submission was made was missing entirely,
  /// which is the thing you actually want when scanning the list.
  String _relativeTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'এইমাত্র';
    if (diff.inMinutes < 60) return '${diff.inMinutes} মিনিট আগে';
    if (diff.inHours < 24) return '${diff.inHours} ঘণ্টা আগে';
    if (diff.inDays < 30) return '${diff.inDays} দিন আগে';
    final months = diff.inDays ~/ 30;
    if (months < 12) return '$months মাস আগে';
    return '${diff.inDays ~/ 365} বছর আগে';
  }

  /// One row of the submissions list.
  ///
  /// Deliberately NOT a detached card: rows sit on a single surface separated
  /// by hairlines, with a coloured status rail down the left edge. That reads
  /// as one continuous list rather than a stack of boxes, and leaves room for
  /// the detail that was missing before — when it was submitted, why it was
  /// rejected, and whether proof was attached.
  Widget _buildTaskRow(MicroGigTask task, {required bool isLast}) {
    late final Color statusColor;
    late final String statusLabel;
    late final IconData statusIcon;
    if (task.approved) {
      statusColor = const Color(0xFF10B981);
      statusLabel = 'অনুমোদিত';
      statusIcon = Icons.check_circle_rounded;
    } else if (task.rejected) {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'বাতিল';
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'অপেক্ষমাণ';
      statusIcon = Icons.schedule_rounded;
    }

    final hasProof = (task.taskCompletionLink ?? '').trim().isNotEmpty ||
        task.mediaUrls.isNotEmpty;

    return InkWell(
      onTap: () => _showTaskDetails(task),
      child: Container(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status rail — colour tells you the outcome before you read.
              Container(width: 3, color: statusColor.withValues(alpha: 0.85)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              task.gigTitle ?? 'Untitled Gig',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '৳${task.gigPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: task.approved
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF334155),
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(statusIcon, size: 13, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: Color(0xFFCBD5E1),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _relativeTime(task.createdAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          if (hasProof) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.attachment_rounded,
                                size: 13, color: Color(0xFF94A3B8)),
                          ],
                          const Spacer(),
                          const Icon(Icons.chevron_right_rounded,
                              size: 17, color: Color(0xFFCBD5E1)),
                        ],
                      ),
                      // Pending: the auto-approval clock is the single most
                      // useful thing to know, so it stays on the row.
                      if (!task.approved && !task.rejected) ...[
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Icon(
                              task.is48HoursPassed
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.timer_outlined,
                              size: 13,
                              color: task.is48HoursPassed
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              task.is48HoursPassed
                                  ? 'স্বয়ংক্রিয় অনুমোদন সম্পন্ন'
                                  : 'স্বয়ংক্রিয় অনুমোদন ${_formatCountdown(task)}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: task.is48HoursPassed
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Rejected: show WHY inline instead of making the user
                      // open the row to find out.
                      if (task.rejected &&
                          (task.reason ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFEF4444).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            task.reason!.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              height: 1.35,
                              color: Color(0xFFB91C1C),
                            ),
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
                                          errorBuilder:
                                              (context, error, stack) {
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
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.3)),
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
