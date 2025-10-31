import 'package:flutter/material.dart';
import '../../models/business_network_models.dart';
import '../../utils/time_utils.dart';
import '../../screens/business_network/profile_screen.dart';
import '../../config/app_config.dart';

class PostHeader extends StatelessWidget {
  final BusinessNetworkPost post;
  final VoidCallback? onFollowToggle;
  final VoidCallback? onMorePressed;

  const PostHeader({
    super.key,
    required this.post,
    this.onFollowToggle,
    this.onMorePressed,
  });
  
  void _navigateToProfile(BuildContext context) {
    final userId = post.user.uuid ?? post.user.id.toString();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }

  Widget _buildUserAvatar() {
    // Priority: image > avatar (matching profile_screen.dart behavior)
    final rawAvatarUrl = post.user.image ?? post.user.avatar;
    
    // Convert relative URLs to absolute using AppConfig
    final avatarUrl = AppConfig.getAbsoluteUrl(rawAvatarUrl);
    
    // Debug logging
    if (avatarUrl.isEmpty) {
      print('⚠️ No avatar for ${post.user.name} - image: ${post.user.image}, avatar: ${post.user.avatar}');
    } else {
      print('✅ Avatar URL for ${post.user.name}: $avatarUrl');
    }
    
    if (avatarUrl.isNotEmpty) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade100,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading avatar for ${post.user.name}: $error');
          return _buildDefaultAvatar();
        },
      );
    }
    
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey.shade100,
      child: Icon(
        Icons.person,
        color: Colors.grey.shade400,
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          // User Avatar
          GestureDetector(
            onTap: () => _navigateToProfile(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _buildUserAvatar(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _navigateToProfile(context),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: post.user.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                        if (post.user.isVerified) ...[
                          const TextSpan(text: ' '),
                          const WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(
                              Icons.verified,
                              size: 15,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimeAgo(post.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Follow/Unfollow Button
          if (onFollowToggle != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onFollowToggle,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: post.user.isFollowing 
                    ? Colors.grey.shade200 
                    : const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                post.user.isFollowing ? 'Unfollow' : 'Follow',
                style: TextStyle(
                  fontSize: 12,
                  color: post.user.isFollowing 
                      ? Colors.grey.shade700 
                      : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          // More Button
          IconButton(
            onPressed: onMorePressed,
            icon: Icon(
              Icons.more_horiz,
              color: Colors.grey.shade600,
              size: 20,
            ),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(String dateString) {
    return formatTimeAgo(dateString);
  }
}
