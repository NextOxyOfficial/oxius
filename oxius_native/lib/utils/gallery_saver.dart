import 'package:flutter/services.dart';

/// Thin Dart wrapper around the native `com.oxius.app/media_saver` channel.
///
/// On Android it copies an already-downloaded file into the shared media
/// collection (Pictures/Movies) through MediaStore so the item shows up in the
/// phone's Gallery/Photos app, and can re-open that item in the system viewer.
class GallerySaver {
  static const MethodChannel _channel =
      MethodChannel('com.oxius.app/media_saver');

  /// Saves [sourcePath] into the device gallery and returns the resulting
  /// content:// URI, or null if the platform did not return one.
  static Future<String?> saveToGallery({
    required String sourcePath,
    required String fileName,
    required bool isVideo,
    String album = 'AdsyClub',
  }) async {
    final uri = await _channel.invokeMethod<String>('saveToGallery', {
      'sourcePath': sourcePath,
      'fileName': fileName,
      'isVideo': isVideo,
      'album': album,
    });
    return uri;
  }

  /// Opens a previously-saved gallery item (by its content:// [uri]) in the
  /// device's gallery / photo viewer.
  static Future<void> openMedia({
    required String uri,
    required bool isVideo,
  }) async {
    await _channel.invokeMethod('openMedia', {
      'uri': uri,
      'isVideo': isVideo,
    });
  }
}
