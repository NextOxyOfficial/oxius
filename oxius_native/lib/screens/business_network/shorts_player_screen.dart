import 'package:flutter/material.dart';

import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import 'shorts_viewer.dart';

class ShortsPlayerScreen extends StatefulWidget {
  final BusinessNetworkPost initialPost;
  final PostMedia initialMedia;

  const ShortsPlayerScreen({
    super.key,
    required this.initialPost,
    required this.initialMedia,
  });

  @override
  State<ShortsPlayerScreen> createState() => _ShortsPlayerScreenState();
}

class _ShortsPlayerScreenState extends State<ShortsPlayerScreen> {
  final List<BusinessNetworkPost> _posts = [];
  final Map<int, BusinessNetworkPost> _updatedPostsById = {};
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _lastCreatedAt;

  @override
  void initState() {
    super.initState();
    _posts.add(widget.initialPost);
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final result = await BusinessNetworkService.getPosts(page: 1, pageSize: 5);
    final newPosts = (result['posts'] as List<BusinessNetworkPost>?) ?? <BusinessNetworkPost>[];

    if (!mounted) return;

    setState(() {
      _mergePosts(newPosts);
      _hasMore = result['hasMore'] as bool? ?? true;
      if (newPosts.isNotEmpty) {
        _lastCreatedAt = newPosts.last.createdAt;
      }
    });
  }

  void _mergePosts(List<BusinessNetworkPost> incoming) {
    final existingIds = _posts.map((e) => e.id).toSet();
    for (final p in incoming) {
      if (!existingIds.contains(p.id)) {
        _posts.add(p);
      }
    }
  }

  void _recordPostUpdate(BusinessNetworkPost post) {
    _updatedPostsById[post.id] = post;

    final idx = _posts.indexWhere((p) => p.id == post.id);
    if (idx >= 0) {
      _posts[idx] = post;
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final result = await BusinessNetworkService.getPosts(
      page: 1,
      pageSize: 5,
      olderThan: _lastCreatedAt,
    );

    final newPosts = (result['posts'] as List<BusinessNetworkPost>?) ?? <BusinessNetworkPost>[];

    if (!mounted) return;

    setState(() {
      if (newPosts.isNotEmpty) {
        _mergePosts(newPosts);
        _lastCreatedAt = newPosts.last.createdAt;
      }
      _hasMore = result['hasMore'] as bool? ?? false;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Map<int, BusinessNetworkPost>>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Map<int, BusinessNetworkPost>? result) {
        if (didPop) return;
        Navigator.pop(context, _updatedPostsById.isEmpty ? null : _updatedPostsById);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: ShortsViewer(
          posts: List<BusinessNetworkPost>.from(_posts),
          initialVideoUrl: widget.initialMedia.bestUrl,
          onRequestMore: _loadMore,
          onLike: _recordPostUpdate,
          onComment: _recordPostUpdate,
          allLoaded: !_hasMore,
          onClose: () => Navigator.pop(context, _updatedPostsById.isEmpty ? null : _updatedPostsById),
        ),
      ),
    );
  }
}
