import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/business_network_models.dart';
import '../../screens/business_network/create_post_screen.dart';
import '../../services/auth_service.dart';

/// Facebook-style "What's on your mind?" composer strip: the signed-in user's
/// avatar next to a rounded prompt, with photo/video shortcuts underneath.
/// Tapping anywhere opens the create-post screen; a created post is handed
/// back through [onPostCreated] so the caller can show it without a reload.
/// Used at the top of the Business Network feed and on the user's own profile.
class FeedComposerCard extends StatelessWidget {
  final void Function(BusinessNetworkPost post)? onPostCreated;

  const FeedComposerCard({super.key, this.onPostCreated});

  Future<void> _openComposer(BuildContext context) async {
    final created = await Navigator.push<BusinessNetworkPost?>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (created != null) onPostCreated?.call(created);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    if (user == null) return const SizedBox.shrink();
    final avatar = AppConfig.getAbsoluteUrl(user.profilePicture ?? '');

    return Container(
      margin: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDF0F5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE2E8F0),
                ),
                child: ClipOval(
                  child: avatar.isNotEmpty
                      ? Image.network(avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              size: 22,
                              color: Color(0xFF94A3B8)))
                      : const Icon(Icons.person_rounded,
                          size: 22, color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => _openComposer(context),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Text(
                      'কিছু ভাবছেন? কোনো আইডিয়া থাকলে পোস্ট করে ফেলুন ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _shortcut(
                  context,
                  icon: Icons.photo_library_outlined,
                  color: const Color(0xFF16A34A),
                  label: 'ছবি',
                ),
              ),
              Expanded(
                child: _shortcut(
                  context,
                  icon: Icons.videocam_outlined,
                  color: const Color(0xFFDC2626),
                  label: 'ভিডিও',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shortcut(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return InkWell(
      onTap: () => _openComposer(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
