import 'package:flutter/material.dart';

import '../../models/business_network_models.dart';
import '../../services/auth_service.dart';
import '../../widgets/business_network/bottom_nav_bar.dart';
import 'create_post_screen.dart';
import 'notifications_screen.dart';
import 'profile_options.dart';
import 'shorts_player_screen.dart';

class PostMediaViewerScreen extends StatefulWidget {
  final BusinessNetworkPost post;
  final int initialIndex;

  const PostMediaViewerScreen({
    super.key,
    required this.post,
    required this.initialIndex,
  });

  @override
  State<PostMediaViewerScreen> createState() => _PostMediaViewerScreenState();
}

class _PostMediaViewerScreenState extends State<PostMediaViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;
  late BusinessNetworkPost _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _currentIndex = widget.initialIndex.clamp(0, _post.media.isEmpty ? 0 : _post.media.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openShorts(PostMedia media) {
    // ignore: discarded_futures
    _openShortsAsync(media);
  }

  Future<void> _openShortsAsync(PostMedia media) async {
    final updates = await Navigator.push<Map<int, BusinessNetworkPost>?>
    (
      context,
      MaterialPageRoute(
        builder: (context) => ShortsPlayerScreen(
          initialPost: _post,
          initialMedia: media,
        ),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) return;
    final updated = updates?[_post.id];
    if (updated != null) {
      setState(() {
        _post = updated;
      });
    }
  }

  void _handleNavTap(int index) {
    final isLoggedIn = AuthService.isAuthenticated;

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/business-network', (route) => false);
        break;
      case 1:
        if (isLoggedIn) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationsScreen()),
          );
        } else {
          Navigator.pushNamed(context, '/login');
        }
        break;
      case 2:
        if (isLoggedIn) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        } else {
          Navigator.pushNamed(context, '/login');
        }
        break;
      case 3:
        if (isLoggedIn) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileOptionsScreen()),
          );
        } else {
          Navigator.pushNamed(context, '/login');
        }
        break;
      case 4:
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        break;
    }
  }

  Widget _buildVideoPreview(PostMedia media) {
    final thumbUrl = media.bestThumbnailUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumbUrl.isNotEmpty)
          Image.network(
            thumbUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: Colors.black);
            },
          )
        else
          Container(color: Colors.black),
        Center(
          child: GestureDetector(
            onTap: () => _openShorts(media),
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 54),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(PostMedia media) {
    return InteractiveViewer(
      minScale: 0.7,
      maxScale: 4.0,
      child: Center(
        child: Image.network(
          media.bestUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                'Failed to load media',
                style: TextStyle(color: Colors.white.withOpacity(0.75)),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return PopScope<BusinessNetworkPost>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, BusinessNetworkPost? result) {
        if (didPop) return;
        Navigator.pop(context, _post);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _post.media.isEmpty
            ? Center(
                child: Text(
                  'No media',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              )
            : Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: _post.media.length,
                    onPageChanged: (i) {
                      setState(() {
                        _currentIndex = i;
                      });
                    },
                    itemBuilder: (context, index) {
                      final media = _post.media[index];
                      if (media.isVideo) {
                        return _buildVideoPreview(media);
                      }
                      return _buildImage(media);
                    },
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context, _post),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.16)),
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white.withOpacity(0.16)),
                            ),
                            child: Text(
                              '${_currentIndex + 1}/${_post.media.length}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.92),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: isMobile
            ? BusinessNetworkBottomNavBar(
                currentIndex: 0,
                isLoggedIn: AuthService.isAuthenticated,
                unreadCount: 0,
                onTap: _handleNavTap,
              )
            : null,
      ),
    );
  }
}
