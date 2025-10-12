import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/classified_post.dart';
import '../services/classified_post_service.dart';
import '../services/api_service.dart';
import 'classified_post_form_screen.dart';
import 'classified_post_details_screen.dart';

class MyClassifiedPostsScreen extends StatefulWidget {
  const MyClassifiedPostsScreen({Key? key}) : super(key: key);

  @override
  State<MyClassifiedPostsScreen> createState() => _MyClassifiedPostsScreenState();
}

class _MyClassifiedPostsScreenState extends State<MyClassifiedPostsScreen> {
  late final ClassifiedPostService _postService;
  
  List<ClassifiedPost> _posts = [];
  bool _isLoading = false;
  
  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;

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
          print('Editing post: ID=${post.id}, Slug=${post.slug}, Using slug for fetch=$postIdentifier');
          
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
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  List<ClassifiedPost> get _paginatedPosts {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _posts.sublist(
      startIndex,
      endIndex > _posts.length ? _posts.length : endIndex,
    );
  }

  int get _totalPages => (_posts.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        title: const Text(
          'My Posts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
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
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            )
          : _posts.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Stats Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Posts: ${_posts.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            'Page $_currentPage of $_totalPages',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Posts List
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadPosts,
                        color: const Color(0xFF10B981),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _paginatedPosts.length,
                          itemBuilder: (context, index) {
                            return _buildPostCard(_paginatedPosts[index]);
                          },
                        ),
                      ),
                    ),
                    
                    // Pagination
                    if (_totalPages > 1) _buildPagination(),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.post_add_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first post to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
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
            icon: const Icon(Icons.add),
            label: const Text('Create Post'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(ClassifiedPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Post Content
          InkWell(
            onTap: () => _handleAction(post, 'view'),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 90,
                      height: 90,
                      color: const Color(0xFFF3F4F6),
                      child: post.medias != null && post.medias!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: post.medias!.first.image ?? '',
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => const Icon(
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
                  
                  const SizedBox(width: 12),
                  
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 6),
                        
                        // Price and Status Badge Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Price
                            Text(
                              post.displayPrice,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            
                            // Status Badge
                            _buildStatusBadge(post),
                          ],
                        ),
                        
                        const SizedBox(height: 6),
                        
                        // Date
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 13,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              post.getRelativeTime(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
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
          
          // Action Buttons
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // View Button
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.visibility_outlined,
                    label: 'View',
                    onTap: () => _handleAction(post, 'view'),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Edit Button
                if (post.serviceStatus.toLowerCase() != 'completed')
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      onTap: () => _handleAction(post, 'edit'),
                    ),
                  ),
                const SizedBox(width: 8),
                
                // Pause/Activate Button
                if (post.serviceStatus.toLowerCase() != 'completed')
                  Expanded(
                    child: _buildActionButton(
                      icon: post.activeService ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      label: post.activeService ? 'Pause' : 'Activate',
                      onTap: () => _handleAction(post, post.activeService ? 'pause' : 'activate'),
                      color: post.activeService ? Colors.orange : const Color(0xFF10B981),
                    ),
                  ),
                const SizedBox(width: 8),
                
                // Complete Button
                if (post.serviceStatus.toLowerCase() != 'completed')
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.check_circle_outline,
                      label: 'Complete',
                      onTap: () => _handleAction(post, 'complete'),
                      color: Colors.blue,
                    ),
                  ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
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

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Button
          OutlinedButton(
            onPressed: _currentPage > 1
                ? () => setState(() => _currentPage--)
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF10B981),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Previous'),
          ),
          
          // Page Numbers
          Text(
            'Page $_currentPage of $_totalPages',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          
          // Next Button
          OutlinedButton(
            onPressed: _currentPage < _totalPages
                ? () => setState(() => _currentPage++)
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF10B981),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
