import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/business_network_models.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';
import 'download_open_utils.dart';
import 'gallery_saver.dart';

class BusinessNetworkMediaDownloader {
  static Future<void> download(
    BuildContext context,
    PostMedia media, {
    String? ownerName,
  }) async {
    final url = media.bestUrl;
    if (url.isEmpty) {
      _showError(context, 'No downloadable media found');
      return;
    }

    AdsyToast.info(context, 'Downloading media...');

    try {
      final fileName = _fileNameFor(url, media, ownerName: ownerName);

      // Always download to an app-private cache file first — this never needs a
      // storage permission. We then hand the file to the platform so it can be
      // copied into the phone gallery (Android) or opened directly (other OSes).
      final cacheDir = await getTemporaryDirectory();
      await cacheDir.create(recursive: true);
      final cachePath =
          '${cacheDir.path}${Platform.pathSeparator}$fileName';

      await Dio().download(
        url,
        cachePath,
        options: Options(
          headers: const {'User-Agent': 'OxiUsFlutter/1.0'},
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

      if (!context.mounted) return;

      if (Platform.isAndroid) {
        // Copy into the device gallery (Pictures/Movies) via MediaStore so the
        // item is visible in the phone's Gallery/Photos app.
        final uri = await GallerySaver.saveToGallery(
          sourcePath: cachePath,
          fileName: fileName,
          isVideo: media.isVideo,
        );
        if (!context.mounted) return;
        _showSavedToGallery(context, uri, media.isVideo, cachePath);
        return;
      }

      // iOS / other platforms: keep the file in a stable Downloads location and
      // let the user open it from the success banner.
      final directory = await _downloadDirectory();
      if (directory == null) {
        throw Exception('Could not access storage directory');
      }
      await directory.create(recursive: true);
      final filePath = '${directory.path}${Platform.pathSeparator}$fileName';
      await File(cachePath).copy(filePath);
      if (!context.mounted) return;
      _showSavedToFile(context, fileName, filePath);
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Download failed: $e');
    }
  }

  static void _showSavedToGallery(
    BuildContext context,
    String? galleryUri,
    bool isVideo,
    String fallbackPath,
  ) {
    AdsyToast.dismiss();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('Saved to Gallery')),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Open',
          textColor: Colors.white,
          onPressed: () async {
            // Prefer opening the gallery item directly; fall back to the cached
            // file if the platform did not return a content URI.
            if (galleryUri != null && galleryUri.isNotEmpty) {
              try {
                await GallerySaver.openMedia(uri: galleryUri, isVideo: isVideo);
                return;
              } catch (_) {
                // Fall through to the file-based open below.
              }
            }
            if (context.mounted) {
              DownloadOpenUtils.openFile(context, fallbackPath);
            }
          },
        ),
      ),
    );
  }

  static void _showSavedToFile(
    BuildContext context,
    String fileName,
    String filePath,
  ) {
    AdsyToast.dismiss();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Saved: $fileName', overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Open',
          textColor: Colors.white,
          onPressed: () {
            DownloadOpenUtils.openFile(context, filePath);
          },
        ),
      ),
    );
  }

  static Future<Directory?> _downloadDirectory() async {
    if (Platform.isAndroid) {
      final publicDownloads = Directory('/storage/emulated/0/Download');
      if (await publicDownloads.exists()) return publicDownloads;
      return getExternalStorageDirectory();
    }

    if (Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    }

    final downloads = await getDownloadsDirectory();
    if (downloads != null) return downloads;
    return getApplicationDocumentsDirectory();
  }

  static String _fileNameFor(
    String url,
    PostMedia media, {
    String? ownerName,
  }) {
    final uri = Uri.tryParse(url);
    final pathName =
        uri?.pathSegments.isNotEmpty == true ? uri!.pathSegments.last : '';
    final pathExtension = _extensionFromName(pathName);
    final extension = pathExtension.isNotEmpty
        ? pathExtension
        : media.isVideo
            ? 'mp4'
            : 'jpg';
    final baseName = ownerName == null || ownerName.trim().isEmpty
        ? 'business-network'
        : ownerName.trim();
    final sanitizedBase =
        baseName.replaceAll(RegExp(r'[^a-zA-Z0-9-_]+'), '-').toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return '$sanitizedBase-media-${media.id}-$timestamp.$extension';
  }

  static String _extensionFromName(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == name.length - 1) return '';
    final extension = name.substring(dotIndex + 1).toLowerCase();
    if (!RegExp(r'^[a-z0-9]{2,5}$').hasMatch(extension)) return '';
    return extension;
  }

  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    AdsyToast.error(context, message);
  }
}
