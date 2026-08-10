import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/business_network_service.dart';
import '../login_prompt_dialog.dart';

/// Follow / Following control shown beside a name, inline with it.
///
/// Used wherever the feed shows someone the viewer might not follow yet — a
/// post header, an ad, a short. One widget everywhere so the wording, the
/// optimistic update and the rollback behave the same in all three, and so a
/// name that is tappable is never the only thing offered.
///
/// Renders nothing when there is no user, or when the viewer IS that user —
/// nobody should be offered "follow yourself".
class InlineFollowButton extends StatefulWidget {
  final String userId;
  final bool initiallyFollowing;

  /// Shorts sit on video, so the light-on-dark variant is needed there.
  final bool onDark;

  const InlineFollowButton({
    super.key,
    required this.userId,
    this.initiallyFollowing = false,
    this.onDark = false,
  });

  @override
  State<InlineFollowButton> createState() => _InlineFollowButtonState();
}

class _InlineFollowButtonState extends State<InlineFollowButton> {
  late bool _following;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _following = widget.initiallyFollowing;
  }

  @override
  void didUpdateWidget(InlineFollowButton old) {
    super.didUpdateWidget(old);
    // A recycled card can be handed a different advertiser.
    if (old.userId != widget.userId ||
        old.initiallyFollowing != widget.initiallyFollowing) {
      _following = widget.initiallyFollowing;
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    if (AuthService.currentUser == null) {
      LoginPromptDialog.show(context, action: 'follow');
      return;
    }
    final wasFollowing = _following;
    // Optimistic: the button is the only feedback the user gets, so it has to
    // move immediately — and roll back if the call fails.
    setState(() {
      _busy = true;
      _following = !wasFollowing;
    });
    final ok = wasFollowing
        ? await BusinessNetworkService.unfollowUser(widget.userId)
        : await BusinessNetworkService.followUser(widget.userId);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) _following = wasFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = AuthService.currentUser?.id;
    if (widget.userId.isEmpty || widget.userId == me) {
      return const SizedBox.shrink();
    }

    final accent =
        widget.onDark ? Colors.white : const Color(0xFF2563EB);
    final muted = widget.onDark
        ? Colors.white.withValues(alpha: 0.65)
        : const Color(0xFF94A3B8);

    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          _following ? 'ফলোয়িং' : 'ফলো',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: _following ? muted : accent,
          ),
        ),
      ),
    );
  }
}
