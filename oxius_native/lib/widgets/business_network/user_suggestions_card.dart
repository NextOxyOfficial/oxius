import 'package:flutter/material.dart';
import 'package:oxius_native/utils/image_utils.dart';
import '../../services/user_suggestions_service.dart';
import '../../config/app_config.dart';
import '../../screens/business_network/profile_screen.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

/// "People you may know" as a horizontal discovery row — same visual system
/// as the workspace-gigs / micro-gigs cards so the feed feels consistent.
class UserSuggestionsCard extends StatefulWidget {
  final VoidCallback? onRefresh;

  const UserSuggestionsCard({
    super.key,
    this.onRefresh,
  });

  @override
  State<UserSuggestionsCard> createState() => _UserSuggestionsCardState();
}

class _UserSuggestionsCardState extends State<UserSuggestionsCard> {
  List<Map<String, dynamic>> _allSuggestions = [];
  List<Map<String, dynamic>> _displayedSuggestions = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  final Map<String, bool> _followingStates = {};
  final Map<String, bool> _followingPending = {};

  static const _accent = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoading = true);

    try {
      final suggestions = await UserSuggestionsService.getUserSuggestions();

      if (mounted) {
        setState(() {
          _allSuggestions = suggestions;
          _refreshDisplayedSuggestions();
        });
      }
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _refreshDisplayedSuggestions() {
    if (_allSuggestions.isEmpty) {
      _displayedSuggestions = [];
      return;
    }

    // Horizontal row — show up to 10, shuffled for variety.
    final shuffled = List<Map<String, dynamic>>.from(_allSuggestions)
      ..shuffle();
    _displayedSuggestions = shuffled.take(10).toList();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _refreshDisplayedSuggestions();
        _isRefreshing = false;
      });
    }
  }

  Future<void> _toggleFollow(Map<String, dynamic> user) async {
    final userId = user['id'].toString();
    final isFollowing = _followingStates[userId] ?? false;

    if (_followingPending[userId] == true) return;

    setState(() {
      _followingPending[userId] = true;
    });

    try {
      bool success;
      if (isFollowing) {
        success = await UserSuggestionsService.unfollowUser(userId);
      } else {
        success = await UserSuggestionsService.followUser(userId);
      }

      if (success && mounted) {
        setState(() {
          if (!isFollowing) {
            // Followed — mark the chip; keep the tile so the row doesn't jump.
            _followingStates[userId] = true;
          } else {
            _followingStates[userId] = false;
          }
        });
      }
    } catch (e) {
      debugPrint('Error toggling follow: $e');
    } finally {
      if (mounted) {
        setState(() {
          _followingPending[userId] = false;
        });
      }
    }
  }

  String _getUserDisplayName(Map<String, dynamic>? user) {
    if (user == null) return 'Unknown User';

    final firstName = (user['first_name'] ?? '').toString().trim();
    final lastName = (user['last_name'] ?? '').toString().trim();

    if (firstName.isEmpty && lastName.isEmpty) {
      return (user['username'] ?? 'Unknown User').toString();
    }

    return '$firstName $lastName'.trim();
  }

  String _getImageUrl(String? imageUrl) {
    return AppConfig.getAbsoluteUrl(imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading && _displayedSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF0F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — matches the discovery-card system.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 10, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded,
                      size: 15, color: _accent),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'পরিচিত হতে পারেন',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _isLoading || _isRefreshing ? null : _handleRefresh,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: _isLoading || _isRefreshing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: AdsyLoadingIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(_accent),
                            ),
                          )
                        : const Icon(Icons.refresh_rounded,
                            size: 18, color: _accent),
                  ),
                ),
              ],
            ),
          ),
          // Horizontal tiles — sized so 2 profiles fit fully and the 3rd
          // peeks in from the edge, hinting the row scrolls.
          Builder(builder: (context) {
            final screenW = MediaQuery.of(context).size.width;
            final tileW = ((screenW - 34) / 2.35).clamp(120.0, 175.0);
            final imageH = tileW * 0.81;
            return SizedBox(
              height: imageH + 100,
              child: _isLoading
                  ? _buildLoadingRow(tileW, imageH)
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _displayedSuggestions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => _buildUserTile(
                          _displayedSuggestions[i], tileW, imageH),
                    ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLoadingRow(double tileW, double imageH) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, i) => SizedBox(
        width: tileW,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: tileW,
              height: imageH,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 10,
              width: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, double tileW, double imageH) {
    final userId = (user['id'] ?? '').toString();
    final isFollowing = _followingStates[userId] ?? false;
    final isPending = _followingPending[userId] ?? false;
    final imageUrl = _getImageUrl(user['image']?.toString());
    final profession = (user['profession'] ?? '').toString().trim();
    final mutualConnections =
        int.tryParse((user['mutual_connections'] ?? 0).toString()) ?? 0;

    return SizedBox(
      width: tileW,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar — tappable to profile.
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: userId),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: tileW,
                height: imageH,
                child: imageUrl.isNotEmpty
                    ? AppImage.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        placeholder: _placeholder(),
                        errorWidget: _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _getUserDisplayName(user),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 1),
          // Always render the profession slot — an empty gap here read as a
          // layout bug, so missing data states it explicitly.
          Text(
            profession.isNotEmpty ? profession : 'No profession added',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              fontStyle:
                  profession.isNotEmpty ? FontStyle.normal : FontStyle.italic,
              color: profession.isNotEmpty
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          _buildMutualRow(user, mutualConnections),
          const Spacer(),
          // Follow button — compact pill, full tile width.
          SizedBox(
            width: double.infinity,
            height: 28,
            child: ElevatedButton(
              onPressed: isPending ? null : () => _toggleFollow(user),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isFollowing ? Colors.white : _accent,
                foregroundColor:
                    isFollowing ? _accent : Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: isFollowing
                      ? const BorderSide(color: Color(0xFFBFDBFE), width: 1.2)
                      : BorderSide.none,
                ),
              ),
              child: isPending
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: AdsyLoadingIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          isFollowing ? _accent : Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      isFollowing ? 'ফলো করছেন' : 'ফলো করুন',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mutual-connection line under the profession: a small overlapping stack
  /// of up to 3 mutual friends' photos plus "+N", or an explicit
  /// "No mutual connection" so the slot never sits empty.
  Widget _buildMutualRow(Map<String, dynamic> user, int mutualCount) {
    final previewsRaw = user['mutual_preview'];
    final previews = previewsRaw is List
        ? previewsRaw.whereType<Map>().take(3).toList()
        : const <Map>[];

    if (mutualCount <= 0) {
      return const Text(
        'No mutual connection',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.italic,
          color: Color(0xFF94A3B8),
        ),
      );
    }

    final extra = mutualCount - previews.length;
    return Row(
      children: [
        if (previews.isNotEmpty)
          SizedBox(
            height: 16,
            width: 16.0 + (previews.length - 1) * 11.0,
            child: Stack(
              children: [
                for (int i = 0; i < previews.length; i++)
                  Positioned(
                    left: i * 11.0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.2),
                        color: const Color(0xFFE2E8F0),
                      ),
                      child: ClipOval(
                        child: ((previews[i]['image'] ?? '')
                                .toString()
                                .isNotEmpty)
                            ? AppImage.network(
                                AppConfig.getAbsoluteUrl(
                                    previews[i]['image'].toString()),
                                fit: BoxFit.cover,
                                placeholder: const _MiniAvatarFallback(),
                                errorWidget: const _MiniAvatarFallback(),
                              )
                            : const _MiniAvatarFallback(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (previews.isNotEmpty) const SizedBox(width: 4),
        Flexible(
          child: Text(
            extra > 0 ? '+$extra mutual' : '$mutualCount mutual',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Icon(Icons.person_rounded,
          size: 44, color: Color(0xFF94A3B8)),
    );
  }
}

class _MiniAvatarFallback extends StatelessWidget {
  const _MiniAvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Icon(Icons.person_rounded,
          size: 10, color: Color(0xFF94A3B8)),
    );
  }
}
