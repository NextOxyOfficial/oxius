import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/classified_post.dart';
import '../services/classified_post_service.dart';
import '../services/api_service.dart';
import 'classified_post_form_screen.dart';
import 'classified_post_details_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

class MyClassifiedPostsScreen extends StatefulWidget {
  const MyClassifiedPostsScreen({super.key});

  @override
  State<MyClassifiedPostsScreen> createState() =>
      _MyClassifiedPostsScreenState();
}

class _MyClassifiedPostsScreenState extends State<MyClassifiedPostsScreen> {
  late final ClassifiedPostService _postService;

  List<ClassifiedPost> _posts = [];
  bool _isLoading = false;

  // Status filter tab: all | active | pending | paused | completed
  String _statusFilter = 'all';

  static const Color _brand = Color(0xFF10B981);
  static const List<({String key, String label})> _statusTabs = [
    (key: 'all', label: 'All'),
    (key: 'active', label: 'Active'),
    (key: 'pending', label: 'Pending'),
    (key: 'paused', label: 'Paused'),
    (key: 'completed', label: 'Completed'),
  ];

  @override
  void initState() {
    super.initState();
    _postService = ClassifiedPostService(baseUrl: ApiService.baseUrl);
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);

    try {
      final posts = await _postService.fetchUserPosts();
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to load posts: $e');
      }
    }
  }

  Future<void> _handleAction(ClassifiedPost post, String action) async {
    bool? confirm = true;

    if (action == 'complete' || action == 'pause') {
      confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${action == 'complete' ? 'Complete' : 'Pause'} Post?'),
          content: Text(
            action == 'complete'
                ? 'Are you sure you want to mark this post as completed?'
                : 'Are you sure you want to pause this post?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    }

    if (confirm != true) return;

    try {
      Map<String, dynamic>? response;

      switch (action) {
        case 'pause':
          response = await _postService.updatePostStatus(
            postId: post.id,
            activeService: false,
          );
          break;
        case 'activate':
          response = await _postService.updatePostStatus(
            postId: post.id,
            activeService: true,
          );
          break;
        case 'complete':
          response = await _postService.updatePostStatus(
            postId: post.id,
            serviceStatus: 'completed',
          );
          break;
        case 'edit':
          // For editing, we need to pass both: use slug for fetching (GET), but keep ID for updating (PUT)
          // The form screen needs the slug to fetch data, but will use the ID from the fetched data for updates
          final postIdentifier = post.slug ?? post.id;
          debugPrint(
              'Editing post: ID=${post.id}, Slug=${post.slug}, Using slug for fetch=$postIdentifier');

          if (!mounted) return;
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassifiedPostFormScreen(
                postId: postIdentifier,
                categoryId: post.categoryDetails?.id,
              ),
            ),
          );
          if (result == true) {
            _loadPosts();
          }
          return;
        case 'view':
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassifiedPostDetailsScreen(
                postId: post.id,
                postSlug: post.slug ?? post.id,
              ),
            ),
          );
          return;
      }

      if (response != null && mounted) {
        _showSuccess('Post ${action}d successfully');
        _loadPosts();
      } else {
        _showError('Failed to $action post');
      }
    } catch (e) {
      _showError(_friendlyErrorMessage(e));
    }
  }

  String _friendlyErrorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  void _showError(String message) {
    AdsyToast.error(context, message);
  }

  void _showSuccess(String message) {
    AdsyToast.success(context, message);
  }

  /// Normalised status bucket used by both the badge and the filter tabs.
  String _statusOf(ClassifiedPost p) {
    final s = p.serviceStatus.toLowerCase();
    if (s == 'completed') return 'completed';
    if (!p.activeService) return 'paused';
    if (s == 'pending') return 'pending';
    if (s == 'approved') return 'active';
    return 'other';
  }

  List<ClassifiedPost> get _filteredPosts {
    if (_statusFilter == 'all') {
      // Active posts always float to the top of the "All" tab.
      final active = _posts.where((p) => _statusOf(p) == 'active').toList();
      final rest = _posts.where((p) => _statusOf(p) != 'active').toList();
      return [...active, ...rest];
    }
    return _posts.where((p) => _statusOf(p) == _statusFilter).toList();
  }

  int _statusCount(String key) =>
      key == 'all' ? _posts.length : _posts.where((p) => _statusOf(p) == key).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Posts',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Color(0xFF1F2937), size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ClassifiedPostFormScreen(),
                ),
              );
              if (result == true) {
                _loadPosts();
              }
            },
            icon: const Icon(Icons.add_rounded,
                color: Color(0xFF10B981), size: 18),
            label: const Text(
              'Create',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE5E7EB),
            height: 1,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: AdsyLoadingIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_brand),
              ),
            )
          : Column(
              children: [
                if (_posts.isNotEmpty) _buildStatusTabs(),
                Expanded(
                  child: _posts.isEmpty
                      ? _buildEmptyState()
                      : (_filteredPosts.isEmpty
                          ? _buildNoFilterResults()
                          : AdsyRefreshIndicator(
                              onRefresh: _loadPosts,
                              color: _brand,
                              child: ListView.builder(
                                // 2px side padding as requested.
                                padding:
                                    const EdgeInsets.fromLTRB(2, 8, 2, 16),
                                itemCount: _filteredPosts.length,
                                itemBuilder: (context, index) =>
                                    _buildPostCard(_filteredPosts[index]),
                              ),
                            )),
                ),
              ],
            ),
    );
  }

  /// Horizontal status filter tabs with live counts.
  Widget _buildStatusTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
        child: Row(
          children: _statusTabs.map((tab) {
            final selected = _statusFilter == tab.key;
            final count = _statusCount(tab.key);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => setState(() => _statusFilter = tab.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? _brand : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? _brand
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.22)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNoFilterResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_alt_off_rounded, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 14),
          Text(
            'No ${_statusFilter == 'all' ? '' : '$_statusFilter '}posts',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different status filter.',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _brand.withValues(alpha: 0.08),
              ),
              child: Icon(Icons.post_add_rounded,
                  size: 48, color: _brand.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: 22),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Post a free service ad and reach customers near you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5, height: 1.5, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClassifiedPostFormScreen(),
                    ),
                  );
                  if (result == true) _loadPosts();
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Create Post',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(ClassifiedPost post) {
    // List row separated by a thin divider line (like the AdsyPay transaction
    // history) instead of individual elevated cards.
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEDF0F4), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Post Content
          InkWell(
            onTap: () => _handleAction(post, 'view'),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image — sized to the full height of the row content.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 90,
                        child: Container(
                          color: const Color(0xFFF3F4F6),
                          child: post.medias != null && post.medias!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: post.medias!.first.image ?? '',
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Color(0xFF9CA3AF),
                                    size: 32,
                                  ),
                                )
                              : const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Color(0xFF9CA3AF),
                                  size: 32,
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + status badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  post.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F2937),
                                    height: 1.3,
                                    letterSpacing: -0.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(post),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Price + posted time (time now sits beside the price)
                          Row(
                            children: [
                              Text(
                                post.displayPrice,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.access_time_rounded,
                                size: 11,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  post.getRelativeTime(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF6B7280),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Action buttons — moved up beside the details (where
                          // the posted time used to be).
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _buildActionButton(
                                icon: Icons.visibility_outlined,
                                label: 'View',
                                onTap: () => _handleAction(post, 'view'),
                              ),
                              if (post.serviceStatus.toLowerCase() != 'completed')
                                _buildActionButton(
                                  icon: Icons.edit_outlined,
                                  label: 'Edit',
                                  onTap: () => _handleAction(post, 'edit'),
                                ),
                              if (post.serviceStatus.toLowerCase() != 'completed')
                                _buildActionButton(
                                  icon: post.activeService
                                      ? Icons.pause_circle_outline
                                      : Icons.play_circle_outline,
                                  label: post.activeService ? 'Pause' : 'Activate',
                                  onTap: () => _handleAction(
                                      post, post.activeService ? 'pause' : 'activate'),
                                  color: post.activeService
                                      ? Colors.orange
                                      : const Color(0xFF10B981),
                                ),
                              if (post.serviceStatus.toLowerCase() != 'completed')
                                _buildActionButton(
                                  icon: Icons.check_circle_outline,
                                  label: 'Complete',
                                  onTap: () => _handleAction(post, 'complete'),
                                  color: Colors.blue,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ClassifiedPost post) {
    Color badgeColor;
    String badgeText;

    if (post.serviceStatus.toLowerCase() == 'completed') {
      badgeColor = Colors.blue;
      badgeText = 'Completed';
    } else if (!post.activeService) {
      badgeColor = Colors.orange;
      badgeText = 'Paused';
    } else if (post.serviceStatus.toLowerCase() == 'pending') {
      badgeColor = Colors.amber;
      badgeText = 'Pending';
    } else if (post.serviceStatus.toLowerCase() == 'approved') {
      badgeColor = const Color(0xFF10B981);
      badgeText = 'Active';
    } else {
      badgeColor = Colors.red;
      badgeText = post.serviceStatus;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF6B7280),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
