import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/business_network_service.dart';
import '../../widgets/login_prompt_dialog.dart';

/// Follow / Following control shown beside an advertiser's name on ad surfaces.
///
/// Ads carry a real BN profile, so the name was tappable but there was no way to
/// actually follow the advertiser without leaving the feed. One widget is used
/// everywhere an ad shows a profile name, so feed and shorts stay consistent.
///
/// Renders nothing when there is no advertiser, or when the viewer IS the
/// advertiser — nobody should be offered "follow yourself".
class AdFollowButton extends StatefulWidget {
  final String advertiserId;
  final bool initiallyFollowing;

  /// Shorts sit on video, so the light-on-dark variant is needed there.
  final bool onDark;

  const AdFollowButton({
    super.key,
    required this.advertiserId,
    this.initiallyFollowing = false,
    this.onDark = false,
  });

  @override
  State<AdFollowButton> createState() => _AdFollowButtonState();
}

class _AdFollowButtonState extends State<AdFollowButton> {
  late bool _following;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _following = widget.initiallyFollowing;
  }

  @override
  void didUpdateWidget(AdFollowButton old) {
    super.didUpdateWidget(old);
    // A recycled card can be handed a different advertiser.
    if (old.advertiserId != widget.advertiserId ||
        old.initiallyFollowing != widget.initiallyFollowing) {
      _following = widget.initiallyFollowing;
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    if (AuthService.currentUser == null) {
      LoginPromptDialog.show(context, action: 'follow this advertiser');
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
        ? await BusinessNetworkService.unfollowUser(widget.advertiserId)
        : await BusinessNetworkService.followUser(widget.advertiserId);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) _following = wasFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = AuthService.currentUser?.id;
    if (widget.advertiserId.isEmpty || widget.advertiserId == me) {
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
