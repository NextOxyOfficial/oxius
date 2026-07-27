import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// A video the user picked, available to the UI before its file is.
class PickedVideo {
  /// Poster frame path, ready immediately — this is what the composer tile
  /// draws while the bytes are still being copied. Null when the platform
  /// could not produce one; the tile then extracts its own frame from [file].
  final String? thumbPath;

  /// Clip length, when the platform knows it up front (0 = unknown, check
  /// after [file] resolves).
  final int durationMs;

  /// The file on disk. Completes when the copy finishes — usually while the
  /// user is still writing the caption. Null if the copy failed.
  final Future<String?> file;

  /// Already on disk when picked (the image_picker path).
  final String? immediatePath;

  const PickedVideo({
    required this.file,
    this.thumbPath,
    this.durationMs = 0,
    this.immediatePath,
  });
}

/// Picks a video WITHOUT waiting for the platform to hand over the file.
///
/// `image_picker` returns only once iOS has exported the asset — a full
/// transcode for the HEVC clips modern iPhones record — so the composer stayed
/// empty for many seconds after the sheet closed. On iOS this goes through a
/// PHPicker bridge (see ios/Runner/AdsyVideoPicker.swift) that answers with a
/// poster frame straight away and copies the original bytes in the background.
///
/// Everywhere else — and whenever the bridge is missing, busy or fails — it
/// falls back to `image_picker`, so this can never be the reason a user cannot
/// attach a video.
class InstantVideoPicker {
  InstantVideoPicker._();

  static const MethodChannel _channel = MethodChannel('adsyclub/video_picker');
  static final ImagePicker _fallback = ImagePicker();

  /// Whether the fast path is even worth trying on this platform.
  static bool get _nativeAvailable {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// Returns null when the user cancels.
  static Future<PickedVideo?> pick({Duration? maxDuration}) async {
    if (_nativeAvailable) {
      try {
        final res = await _channel.invokeMapMethod<String, dynamic>('pick');
        if (res == null) return null;      // cancelled
        final token = res['token']?.toString() ?? '';
        if (token.isNotEmpty) {
          return PickedVideo(
            thumbPath: (res['thumb'] as String?)?.trim().isEmpty ?? true
                ? null
                : res['thumb'] as String,
            durationMs: (res['durationMs'] as num?)?.toInt() ?? 0,
            file: _resolve(token),
          );
        }
      } on MissingPluginException {
        // Older build without the bridge — fall through.
      } catch (e) {
        debugPrint('[picker] native pick failed, using image_picker: $e');
      }
    }

    final x = await _fallback.pickVideo(
      source: ImageSource.gallery,
      maxDuration: maxDuration,
    );
    if (x == null) return null;
    return PickedVideo(
      file: Future<String?>.value(x.path),
      immediatePath: x.path,
    );
  }

  static Future<String?> _resolve(String token) async {
    try {
      return await _channel.invokeMethod<String>('resolve', {'token': token});
    } catch (e) {
      debugPrint('[picker] resolve failed for $token: $e');
      return null;
    }
  }
}
