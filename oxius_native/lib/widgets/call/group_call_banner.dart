import 'package:flutter/material.dart';

/// The strip a group chat shows while its group is on a call.
///
/// A group call used to be enterable only by answering the ring for it: let
/// the phone ring out, or join the group afterwards, and the call carried on
/// with no way in. This is the way in.

/// What the banner says about who is talking.
///
/// "Rahim and 2 others are on a call" is worth saying; "a call is happening"
/// is barely worth the row it occupies — the whole reason to join is knowing
/// who is in there.
///
/// [participantCount] is everyone on the call, which is usually more than the
/// handful of [names] the server sends.
String groupCallBannerLabel({
  required List<String> names,
  required int participantCount,
  required bool isVideo,
}) {
  final known = names.map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
  if (known.isEmpty) {
    return isVideo ? 'Video call in progress' : 'Audio call in progress';
  }

  final others = participantCount - 1;
  if (others <= 0) return '${known.first} is on a call';
  return '${known.first} and $others ${others == 1 ? 'other' : 'others'} '
      'on a call';
}

class GroupCallJoinBanner extends StatelessWidget {
  const GroupCallJoinBanner({
    super.key,
    required this.call,
    required this.joining,
    required this.onJoin,
  });

  /// The server's description of the live call, or null for no banner.
  final Map<String, dynamic>? call;
  final bool joining;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final call = this.call;
    if (call == null) return const SizedBox.shrink();

    final isVideo = (call['call_type'] ?? '').toString() == 'video';
    final label = groupCallBannerLabel(
      names: ((call['participants'] as List?) ?? const [])
          .whereType<Map>()
          .map((p) => (p['name'] ?? '').toString())
          .toList(),
      participantCount: (call['participant_count'] as num?)?.toInt() ?? 0,
      isVideo: isVideo,
    );
    final full = call['is_full'] == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
      decoration: const BoxDecoration(
        color: Color(0xFFECFDF5),
        border: Border(bottom: BorderSide(color: Color(0xFFD1FAE5))),
      ),
      child: Row(
        children: [
          Icon(isVideo ? Icons.videocam_rounded : Icons.call_rounded,
              size: 17, color: const Color(0xFF059669)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF065F46),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (full)
            const Text('Call is full',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)))
          else
            TextButton(
              onPressed: joining ? null : onJoin,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF6EE7B7),
                minimumSize: const Size(0, 30),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: const StadiumBorder(),
                textStyle:
                    const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              child: joining
                  ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Join'),
            ),
        ],
      ),
    );
  }
}
