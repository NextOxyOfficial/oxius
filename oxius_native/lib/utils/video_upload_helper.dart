import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

import '../widgets/common/adsy_toast.dart';
import 'url_launcher_utils.dart';

/// One place for the app's video-upload rules:
///
///  • hard cap: 3 minutes, enforced at EVERY upload site;
///  • compression: best-effort re-encode (≤720p) before upload — falls back
///    to the original file if the encoder fails, never blocks the send;
///  • AdsyConnect chats ([driveHint] = true): an over-limit video shows a
///    professional "share it via Google Drive" sheet with a tap-to-open CTA
///    instead of a bare error.
class VideoUploadHelper {
  VideoUploadHelper._();

  static const int maxSeconds = 180; // 3 minutes

  static Future<Duration?> getDuration(String path) async {
    VideoPlayerController? c;
    try {
      c = VideoPlayerController.file(File(path));
      await c.initialize();
      return c.value.duration;
    } catch (_) {
      return null;
    } finally {
      await c?.dispose();
    }
  }

  /// Validate + compress [path]. Returns the path to upload, or null when
  /// the video was rejected (too long / unreadable).
  static Future<String?> prepareForUpload(
    BuildContext context,
    String path, {
    bool driveHint = false,
  }) async {
    final duration = await getDuration(path);
    if (!context.mounted) return null;
    if (duration != null && duration.inSeconds > maxSeconds) {
      if (driveHint) {
        await _showDriveSheet(context, duration);
      } else {
        AdsyToast.error(context, 'ভিডিও সর্বোচ্চ ৩ মিনিটের হতে হবে');
      }
      return null;
    }

    // Best-effort compression — capped at 720p, original kept on disk.
    try {
      final info = await VideoCompress.compressVideo(
        path,
        quality: VideoQuality.Res1280x720Quality,
        deleteOrigin: false,
        includeAudio: true,
      );
      final out = info?.file?.path;
      if (out != null && out.isNotEmpty) {
        // Only use the re-encode when it actually got smaller.
        final original = File(path);
        final compressed = File(out);
        if (await compressed.exists() &&
            (await compressed.length()) < (await original.length())) {
          return out;
        }
      }
    } catch (_) {
      // Encoder unavailable/failed — upload the original.
    }
    return path;
  }

  static Future<void> _showDriveSheet(
      BuildContext context, Duration duration) {
    String mmss(Duration d) =>
        '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF7ED),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.videocam_off_rounded,
                        color: Color(0xFFEA580C), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ভিডিওটি অনেক বড়',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Text(
                            'দৈর্ঘ্য ${mmss(duration)} — চ্যাটে সর্বোচ্চ ৩:০০ মিনিট পাঠানো যায়',
                            style: const TextStyle(
                                fontSize: 12.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'বড় ভিডিও Google Drive-এ আপলোড করে লিংকটি চ্যাটে পাঠান — রিসিভার এক ট্যাপে দেখতে পারবেন।',
                  style: TextStyle(
                      fontSize: 12.5, height: 1.5, color: Color(0xFF475569)),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    UrlLauncherUtils.launchExternalUrl(
                        'https://drive.google.com');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_to_drive_rounded, size: 19),
                  label: const Text('Google Drive খুলুন',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 42,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('বাতিল',
                      style: TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
