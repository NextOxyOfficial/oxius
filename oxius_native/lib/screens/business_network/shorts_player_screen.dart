import 'package:flutter/material.dart';

import '../../models/business_network_models.dart';
import '../../services/business_network_service.dart';
import 'shorts_viewer.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

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
  final Map<int, BusinessNetworkPost> _updatedPostsById = {};

  // Two independent reels: 'discover' (ranked feed, all users) and
  // 'following' (newest-first videos from followed users only). Each keeps
  // its own list + paging so switching back doesn't refetch from scratch.
  String _scope = 'discover';
  final Map<String, List<BusinessNetworkPost>> _postsByScope = {
    'discover': [],
    'following': [],
  };
  final Map<String, bool> _hasMoreByScope = {
    'discover': true,
    'following': true,
  };
  final Map<String, int> _nextPageByScope = {'discover': 1, 'following': 1};
  final Map<String, bool> _loadedOnceByScope = {
    'discover': false,
    'following': false,
  };
  bool _isLoadingMore = false;

  static const int _shortsPageSize = 12;
  static const int _initialShortsPageWindow = 3;
  static const int _loadMoreShortsPageWindow = 2;

  List<BusinessNetworkPost> get _posts => _postsByScope[_scope]!;

  bool _hasVideo(BusinessNetworkPost post) {
    return post.media.any((m) => m.isVideo);
  }

  @override
  void initState() {
    super.initState();
    _postsByScope['discover']!.add(widget.initialPost);
    _loadInitial('discover');
  }

  Future<void> _loadInitial(String scope) async {
    final result = await BusinessNetworkService.getShortsFeed(
      startPage: _nextPageByScope[scope]!,
      pageSize: _shortsPageSize,
      pageWindow: _initialShortsPageWindow,
      excludePostIds: _postsByScope[scope]!.map((p) => p.id).toSet(),
      feed: scope == 'following' ? 'following' : null,
    );
    final newPosts = (result['posts'] as List<BusinessNetworkPost>?) ??
        <BusinessNetworkPost>[];

    if (!mounted) return;

    setState(() {
      _mergePosts(scope, newPosts);
      _hasMoreByScope[scope] = result['hasMore'] as bool? ?? true;
      _nextPageByScope[scope] =
          result['nextPage'] as int? ?? (_nextPageByScope[scope]! + 1);
      _loadedOnceByScope[scope] = true;
    });
  }

  void _mergePosts(String scope, List<BusinessNetworkPost> incoming) {
    final list = _postsByScope[scope]!;
    final existingIds = list.map((e) => e.id).toSet();
    for (final p in incoming) {
      if (!_hasVideo(p)) continue;
      if (!existingIds.contains(p.id)) {
        list.add(p);
      }
    }
  }

  void _recordPostUpdate(BusinessNetworkPost post) {
    _updatedPostsById[post.id] = post;

    for (final list in _postsByScope.values) {
      final idx = list.indexWhere((p) => p.id == post.id);
      if (idx >= 0) {
        list[idx] = post;
      }
    }
  }

  Future<void> _loadMore() async {
    final scope = _scope;
    if (_isLoadingMore || !_hasMoreByScope[scope]!) return;

    setState(() {
      _isLoadingMore = true;
    });

    final result = await BusinessNetworkService.getShortsFeed(
      startPage: _nextPageByScope[scope]!,
      pageSize: _shortsPageSize,
      pageWindow: _loadMoreShortsPageWindow,
      excludePostIds: _postsByScope[scope]!.map((post) => post.id).toSet(),
      feed: scope == 'following' ? 'following' : null,
    );

    final newPosts = (result['posts'] as List<BusinessNetworkPost>?) ??
        <BusinessNetworkPost>[];

    if (!mounted) return;

    setState(() {
      _mergePosts(scope, newPosts);
      _hasMoreByScope[scope] = result['hasMore'] as bool? ?? false;
      _nextPageByScope[scope] =
          result['nextPage'] as int? ?? (_nextPageByScope[scope]! + 1);
      _isLoadingMore = false;
    });
  }

  void _switchScope(String scope) {
    if (scope == _scope) return;
    setState(() {
      _scope = scope;
    });
    if (!_loadedOnceByScope[scope]!) {
      _loadInitial(scope);
    }
  }

  void _close() {
    Navigator.pop(context, _updatedPostsById.isEmpty ? null : _updatedPostsById);
  }

  @override
  Widget build(BuildContext context) {
    final stillLoadingFirstBatch =
        _posts.isEmpty && !_loadedOnceByScope[_scope]!;

    return PopScope<Map<int, BusinessNetworkPost>>(
      canPop: false,
      onPopInvokedWithResult:
          (bool didPop, Map<int, BusinessNetworkPost>? result) {
        if (didPop) return;
        Navigator.pop(
            context, _updatedPostsById.isEmpty ? null : _updatedPostsById);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: stillLoadingFirstBatch
            ? Stack(
                children: [
                  const Center(
                    child: AdsyLoadingIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _close,
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            // Keyed by scope: switching tabs rebuilds the viewer with the
            // other reel (its own shuffle, page position and controllers).
            : ShortsViewer(
                key: ValueKey('shorts_$_scope'),
                posts: List<BusinessNetworkPost>.from(_posts),
                initialVideoUrl: _scope == 'discover'
                    ? widget.initialMedia.bestUrl
                    : null,
                onRequestMore: _loadMore,
                onLike: _recordPostUpdate,
                onComment: _recordPostUpdate,
                allLoaded: !_hasMoreByScope[_scope]!,
                feedScope: _scope,
                onFeedScopeChanged: _switchScope,
                onClose: _close,
              ),
      ),
    );
  }
}
