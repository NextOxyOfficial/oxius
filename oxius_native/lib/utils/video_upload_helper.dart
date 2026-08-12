import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

import '../widgets/common/adsy_toast.dart';
import 'url_launcher_utils.dart';

/// One place for the app's video-upload rules:
///
///  • hard cap: 10 minutes, enforced at EVERY upload site;
///  • compression: best-effort re-encode (≤720p) before upload — falls back
///    to the original file if the encoder fails, never blocks the send;
///  • AdsyConnect chats ([driveHint] = true): an over-limit video shows a
///    professional "share it via Google Drive" sheet with a tap-to-open CTA
///    instead of a bare error.
class VideoUploadHelper {
  VideoUploadHelper._();

  static const int maxSeconds = 600; // 10 minutes

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

  /// Fast, context-free duration gate — the ONLY check that should run when
  /// the user picks a video. Re-encoding at pick time made selection feel like
  /// a long "upload" and could abort mid-way; compression now happens at
  /// submit ([compressOnly]) instead.
  static Future<bool> isWithinDurationLimit(String path) async {
    final duration = await getDuration(path);
    // Unreadable duration → let it through; the server still validates.
    if (duration == null) return true;
    return duration.inSeconds <= maxSeconds;
  }

  /// Best-effort ≤720p re-encode with NO BuildContext, so it can run from a
  /// background service after the composer screen is gone. Always returns a
  /// usable path (the original when the encoder fails or doesn't help).
  static Future<String> compressOnly(String path) async {
    try {
      final info = await VideoCompress.compressVideo(
        path,
        quality: VideoQuality.Res1280x720Quality,
        deleteOrigin: false,
        includeAudio: true,
      );
      final out = info?.file?.path;
      if (out != null && out.isNotEmpty) {
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

  /// Validate + compress [path]. Returns the path to upload, or null when
  /// the video was rejected (too long / unreadable).
  /// Set [compress] to false to run ONLY the duration gate and get the
  /// original path back — callers that want the re-encode to happen later
  /// (while sending/posting, rather than blocking the picker) use this and
  /// then call [compressOnly] themselves.
  static Future<String?> prepareForUpload(
    BuildContext context,
    String path, {
    bool driveHint = false,
    bool compress = true,
  }) async {
    final duration = await getDuration(path);
    if (!context.mounted) return null;
    if (duration != null && duration.inSeconds > maxSeconds) {
      if (driveHint) {
        await _showDriveSheet(context, duration);
      } else {
        AdsyToast.error(context, 'ভিডিও সর্বোচ্চ ১০ মিনিটের হতে হবে');
      }
      return null;
    }

    if (!compress) return path;

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

  /// Hard byte ceiling for a chat upload.
  ///
  /// The send has a 180s timeout; on a typical Bangladeshi mobile uplink that
  /// buys roughly 20MB. Anything past this was a guaranteed timeout — and the
  /// "Retry" it offered was guaranteed to fail the same way. Better to say so
  /// up front and point at Drive.
  static const int maxUploadBytes = 24 * 1024 * 1024;

  static Future<bool> isWithinUploadSize(String path) async {
    try {
      final len = await File(path).length();
      return len <= maxUploadBytes;
    } catch (_) {
      // Unreadable — let the server decide rather than blocking the send.
      return true;
    }
  }

  /// Public entry for "this file is too big for chat" — same Drive sheet the
  /// duration gate uses, so both limits land the user in one place.
  static Future<void> showTooLargeSheet(BuildContext context) =>
      _showDriveSheet(context, null);

  static Future<void> _showDriveSheet(
      BuildContext context, Duration? duration) {
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
                            // Derived from the one cap, so raising it can never
                            // leave this sheet quoting an old number.
                            (duration == null
                                ? 'ফাইলটি বড় — চ্যাটে সর্বোচ্চ '
                                    '${maxUploadBytes ~/ (1024 * 1024)}MB পাঠানো যায়'
                                : 'দৈর্ঘ্য ${mmss(duration)} — চ্যাটে সর্বোচ্চ '
                                    '${mmss(const Duration(seconds: maxSeconds))} মিনিট পাঠানো যায়'),
                            style: const TextStyle(
                                fontSize: 12.5, color: Color(0xFF556278))),
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
                      fontSize: 12.5, height: 1.5, color: Color(0xFF3D4759)),
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
