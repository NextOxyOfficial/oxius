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
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
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
        _currentPage = 1;
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

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    final result = await BusinessNetworkService.getPosts(
      page: _currentPage,
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: ShortsViewer(
        posts: _posts,
        initialVideoUrl: widget.initialMedia.bestUrl,
        onRequestMore: _loadMore,
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}
