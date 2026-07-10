import 'package:flutter/material.dart';
import '../../models/business_network_models.dart';
import '../../services/auth_service.dart';
import '../../services/business_network_service.dart';
import '../../screens/business_network/profile_screen.dart';

class PostActions extends StatelessWidget {
  final BusinessNetworkPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback? onSave;

  const PostActions({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Items carry their own 12px vertical hit-padding now.
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // Like: the heart toggles the like; the "N likes" label opens a
          // bottom sheet listing everyone who liked this post.
          // The visual icon is 19px but the tappable area is ~44px — the old
          // ~27px target made first taps miss ("like is not working").
          InkWell(
            onTap: onLike,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Image.asset(
                post.isLiked ? 'assets/icons/like.png' : 'assets/icons/unlike.png',
                width: 19,
                height: 19,
                fit: BoxFit.contain,
              ),
            ),
          ),
          InkWell(
            onTap: () => _showLikers(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              // Reserve stable width: "1 like" vs "2 likes" otherwise changes
              // the label width and visibly shifts Comments/Share on every
              // like toggle.
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 52),
                child: Text(
                  '${_formatCount(post.likesCount)} ${post.likesCount == 1 ? 'like' : 'likes'}',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Comment: opens post details where all comments are shown.
          _ActionButton(
            iconPath: 'assets/icons/comments.png',
            label:
                '${_formatCount(post.commentsCount)} ${post.commentsCount == 1 ? 'Comment' : 'Comments'}',
            onTap: onComment,
          ),
          const SizedBox(width: 16),
          // Share Button
          _ActionButton(
            iconPath: 'assets/icons/share.png',
            label: 'Share',
            onTap: onShare,
          ),
          const Spacer(),
          // Save Button
          if (onSave != null)
            InkWell(
              onTap: onSave,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  post.isSaved ? 'assets/icons/saved.png' : 'assets/icons/save.png',
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLikers(BuildContext context) {
    // Open on the COUNT, not the embedded list — after an optimistic like the
    // list is still empty while the count already reads "1 like", and the old
    // isEmpty guard made the tap do nothing. The sheet fetches likers itself
    // when it wasn't handed any.
    if (post.likesCount <= 0 && post.postLikes.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LikersBottomSheet(
        likes: post.postLikes,
        postId: post.id,
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _ActionButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.iconPath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Image.asset(
                iconPath,
                width: 19,
                height: 19,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet that lists the users who liked a post, with a follow /
/// unfollow action on the right for each one.
class _LikersBottomSheet extends StatefulWidget {
  final List<PostLike> likes;
  final dynamic postId;

  const _LikersBottomSheet({required this.likes, this.postId});

  @override
  State<_LikersBottomSheet> createState() => _LikersBottomSheetState();
}

class _LikersBottomSheetState extends State<_LikersBottomSheet> {
  final Set<String> _busy = {}; // userUuid currently toggling
  final Map<String, bool> _followOverride = {}; // userUuid -> isFollowing
  late List<PostLike> _likes;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.likes;
    // No embedded likers (fresh optimistic like, or a feed payload without
    // the list) — pull them from the post detail endpoint.
    if (_likes.isEmpty && widget.postId != null) {
      _fetching = true;
      BusinessNetworkService.fetchPostLikes(widget.postId).then((fetched) {
        if (!mounted) return;
        setState(() {
          _likes = fetched;
          _fetching = false;
        });
      });
    }
  }

  bool _isFollowing(PostLike like) =>
      _followOverride[like.userUuid] ?? like.isFollowing;

  Future<void> _toggle(PostLike like) async {
    final uuid = like.userUuid;
    if (uuid.isEmpty || _busy.contains(uuid)) return;
    final current = _isFollowing(like);
    setState(() => _busy.add(uuid));
    final ok = await BusinessNetworkService.toggleFollow(uuid, current);
    if (!mounted) return;
    setState(() {
      _busy.remove(uuid);
      if (ok) _followOverride[uuid] = !current;
    });
  }

  @override
  Widget build(BuildContext context) {
    final likes = _likes;
    // Tapping the dimmed area above the sheet closes it: the
    // DraggableScrollableSheet fills the whole modal height, so its
    // transparent top region used to swallow the tap before it could reach
    // the modal barrier.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return GestureDetector(
            onTap: () {}, // taps on the sheet itself must not dismiss it
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Grab handle
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite,
                            color: Color(0xFFEF4444), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${likes.length} ${likes.length == 1 ? 'like' : 'likes'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _fetching
                        ? const Center(
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          )
                        : likes.isEmpty
                            ? const Center(
                                child: Text(
                                  'No likes yet',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: likes.length,
                                separatorBuilder: (_, __) => Divider(
                                    height: 1, color: Colors.grey.shade100),
                                itemBuilder: (context, index) =>
                                    _buildLikerRow(likes[index]),
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openProfile(PostLike like) {
    if (like.userUuid.isEmpty) return;
    // Close the likers sheet first, then open the profile on the same
    // navigator so back returns to the post (not a stale sheet).
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userId: like.userUuid),
      ),
    );
  }

  Widget _buildLikerRow(PostLike like) {
    final following = _isFollowing(like);
    final busy = _busy.contains(like.userUuid);
    final hasImage = like.userImage != null && like.userImage!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Avatar + name open the liker's profile.
          Expanded(
            child: InkWell(
              onTap: like.userUuid.isEmpty ? null : () => _openProfile(like),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        hasImage ? NetworkImage(like.userImage!) : null,
                    child: !hasImage
                        ? Text(
                            like.userName.isNotEmpty
                                ? like.userName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      like.userName.isNotEmpty
                          ? like.userName
                          : 'AdsyClub user',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (like.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified,
                        size: 16, color: Color(0xFF3B82F6)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Your own like: show a quiet "আপনি" tag — you can't follow yourself.
          if (like.userUuid == (AuthService.currentUser?.id ?? ''))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'আপনি',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            )
          else
            _buildFollowButton(like, following, busy),
        ],
      ),
    );
  }

  Widget _buildFollowButton(PostLike like, bool following, bool busy) {
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: busy || like.userUuid.isEmpty ? null : () => _toggle(like),
        style: OutlinedButton.styleFrom(
          backgroundColor: following ? Colors.white : const Color(0xFF2563EB),
          foregroundColor: following ? const Color(0xFF374151) : Colors.white,
          side: BorderSide(
            color: following ? Colors.grey.shade300 : const Color(0xFF2563EB),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                following ? 'Following' : 'Follow',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
