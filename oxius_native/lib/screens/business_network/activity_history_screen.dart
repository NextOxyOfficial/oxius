import 'package:flutter/material.dart';

import '../../services/business_network_service.dart';
import '../../services/mindforce_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/business_network/post_card.dart';
import '../../utils/time_utils.dart';
import 'mindforce_detail_screen.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _MindForceRepliesTab extends StatefulWidget {
  const _MindForceRepliesTab();

  @override
  State<_MindForceRepliesTab> createState() => _MindForceRepliesTabState();
}

class _MindForceRepliesTabState extends State<_MindForceRepliesTab> {
  bool _isLoading = true;
  final List<_MindForceReplyItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadReplies();
  }

  Future<void> _loadReplies() async {
    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final problems = await MindForceService.getProblems();
      final List<_MindForceReplyItem> out = [];

      for (final problem in problems) {
        final comments = await MindForceService.getComments(problem.id);
        for (final comment in comments) {
          final commentUserId = comment.userDetails.id.toString();
          final commentUsername = (comment.userDetails.username ?? '').toString();

          final isSelf = commentUserId == currentUser.id ||
              (commentUsername.isNotEmpty && commentUsername == currentUser.username);

          if (!isSelf) continue;

          out.add(
            _MindForceReplyItem(
              problemId: problem.id,
              problemTitle: problem.title,
              commentId: comment.id,
              content: comment.content,
              createdAt: comment.createdAt,
              isSolved: comment.isSolved,
            ),
          );
        }
      }

      out.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(out);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    if (AuthService.currentUser == null) {
      return Center(
        child: Text(
          'Please login to view your activity',
          style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'No MindForce replies yet',
          style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReplies,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MindForceReplyTile(item: item),
          );
        },
      ),
    );
  }
}

class _MindForceReplyItem {
  final String problemId;
  final String problemTitle;
  final String commentId;
  final String content;
  final String createdAt;
  final bool isSolved;

  const _MindForceReplyItem({
    required this.problemId,
    required this.problemTitle,
    required this.commentId,
    required this.content,
    required this.createdAt,
    required this.isSolved,
  });
}

class _MindForceReplyTile extends StatelessWidget {
  final _MindForceReplyItem item;

  const _MindForceReplyTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MindForceDetailScreen(problemId: item.problemId),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.isSolved
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : const Color(0xFF3B82F6).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.isSolved ? Icons.check_circle_rounded : Icons.chat_bubble_rounded,
                  color: item.isSolved ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.problemTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.content,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      TimeUtils.formatTimeAgo(item.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Activity History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF0F172A),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFF3B82F6),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: const [
            Tab(text: 'Saved'),
            Tab(text: 'Likes'),
            Tab(text: 'Comments'),
            Tab(text: 'MindForce'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SavedPostsTab(),
          const _ActivityPlaceholderTab(
            title: 'Likes',
            subtitle:
                'To show posts you liked here, we need a backend endpoint for your own like history.',
          ),
          const _ActivityPlaceholderTab(
            title: 'Comments',
            subtitle:
                'To show comments you made here, we need a backend endpoint for your own comment history.',
          ),
          const _MindForceRepliesTab(),
        ],
      ),
    );
  }
}

class _SavedPostsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: BusinessNetworkService.getSavedPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load saved posts',
              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
          );
        }

        final posts = snapshot.data ?? const [];
        if (posts.isEmpty) {
          return Center(
            child: Text(
              'No saved posts yet',
              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PostCard(post: posts[index]),
            );
          },
        );
      },
    );
  }
}

class _ActivityPlaceholderTab extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ActivityPlaceholderTab({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
