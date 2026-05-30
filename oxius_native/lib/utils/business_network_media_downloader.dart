import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/business_network_models.dart';
import '../widgets/common/adsy_loading.dart';

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

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            SizedBox(
              width: 20,
              height: 20,
              child: AdsyLoadingIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Downloading media...'),
          ],
        ),
        duration: const Duration(minutes: 1),
      ),
    );

    try {
      final directory = await _downloadDirectory();
      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      await directory.create(recursive: true);
      final fileName = _fileNameFor(url, media, ownerName: ownerName);
      final filePath = '${directory.path}${Platform.pathSeparator}$fileName';

      await Dio().download(
        url,
        filePath,
        options: Options(
          headers: const {'User-Agent': 'OxiUsFlutter/1.0'},
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Saved: $fileName',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Download failed: $e');
    }
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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
