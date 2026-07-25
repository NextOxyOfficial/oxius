import 'package:flutter/material.dart';

import '../../models/business_network_models.dart';
import '../../services/post_upload_service.dart';

/// Slim "posting…" strip shown at the top of the Business Network feed while
/// [PostUploadService] works in the background.
///
/// The composer closes the moment Post is pressed, so this is the only place
/// the user sees progress — it must stay legible and never block scrolling.
class PostUploadStrip extends StatefulWidget {
  /// Called once with the created post so the feed can insert it.
  final void Function(BusinessNetworkPost post)? onPosted;

  const PostUploadStrip({super.key, this.onPosted});

  @override
  State<PostUploadStrip> createState() => _PostUploadStripState();
}

class _PostUploadStripState extends State<PostUploadStrip> {
  String? _handledPostId;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PostUploadState?>(
      valueListenable: PostUploadService.instance.state,
      builder: (context, s, _) {
        if (s == null) return const SizedBox.shrink();

        // Hand the finished post to the feed exactly once.
        if (s.stage == PostUploadStage.success && s.post != null) {
          final id = s.post!.id.toString();
          if (_handledPostId != id) {
            _handledPostId = id;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onPosted?.call(s.post!);
              // Clear the strip shortly after so it doesn't linger.
              Future.delayed(const Duration(seconds: 2), () {
                PostUploadService.instance.clear();
              });
            });
          }
        }

        final failed = s.stage == PostUploadStage.failed;
        final done = s.stage == PostUploadStage.success;
        final accent = failed
            ? const Color(0xFFDC2626)
            : (done ? const Color(0xFF16A34A) : const Color(0xFF2563EB));

        return Container(
          margin: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: done
                        ? Icon(Icons.check_circle, size: 16, color: accent)
                        : failed
                            ? Icon(Icons.error_outline, size: 16, color: accent)
                            : CircularProgressIndicator(
                                strokeWidth: 2, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  if (s.progress != null && s.stage == PostUploadStage.uploading)
                    Text(
                      '${(s.progress! * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  if (failed || done)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close_rounded,
                          size: 16, color: Color(0xFF94A3B8)),
                      onPressed: PostUploadService.instance.clear,
                    ),
                ],
              ),
              if (s.isBusy) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    // Indeterminate while compressing (no byte count yet).
                    value: s.stage == PostUploadStage.uploading
                        ? s.progress
                        : null,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
