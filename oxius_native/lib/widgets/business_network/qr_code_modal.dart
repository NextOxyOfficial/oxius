import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../utils/download_open_utils.dart';
import '../common/adsy_share_sheet.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

/// Profile QR code as a clean bottom sheet: black-on-white QR (maximum
/// scanner compatibility), neutral surfaces, solid actions.
class QrCodeModal extends StatefulWidget {
  final Map<String, dynamic> user;

  const QrCodeModal({
    super.key,
    required this.user,
  });

  /// Present as a modal bottom sheet.
  static Future<void> show(BuildContext context, Map<String, dynamic> user) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QrCodeModal(user: user),
    );
  }

  @override
  State<QrCodeModal> createState() => _QrCodeModalState();
}

class _QrCodeModalState extends State<QrCodeModal> {
  final GlobalKey _qrKey = GlobalKey();

  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _line = Color(0xFFE2E8F0);

  String get userName {
    return widget.user['first_name'] ??
        widget.user['name'] ??
        widget.user['full_name'] ??
        widget.user['username'] ??
        'User';
  }

  /// Always the PUBLIC site URL — a QR is scanned by OTHER devices, so it
  /// must never encode a localhost/dev or media-CDN host.
  String get profileUrl {
    return 'https://adsyclub.com/business-network/profile/${widget.user['id']}';
  }

  Future<void> downloadQrCode() async {
    try {
      if (mounted) {
        AdsyToast.info(context, 'Generating QR code...');
      }

      await Future.delayed(const Duration(milliseconds: 100));

      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        directory ??= await getApplicationDocumentsDirectory();
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final sanitizedName =
          userName.replaceAll(RegExp(r'[^a-zA-Z0-9-_]'), '-').toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$sanitizedName-profile-qr-$timestamp.png';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        // Close the sheet first, then confirm on the underlying screen —
        // the messenger/context are captured before the pop so the
        // snackbar (and its Open action) outlive the sheet.
        final messenger = ScaffoldMessenger.of(context);
        final rootContext =
            Navigator.of(context, rootNavigator: true).context;
        Navigator.of(context).pop();
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'QR Code saved!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        fileName,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                // The sheet's context is gone after pop — use the root
                // navigator's context so Open works from the snackbar.
                DownloadOpenUtils.openFile(rootContext, filePath);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AdsyToast.error(context, 'কিছু একটা সমস্যা হয়েছে');
      }
    }
  }

  Future<void> shareProfile() async {
    await AdsyShareSheet.show(
      context,
      data: AdsyShareData(
        title: '$userName on AdsyClub',
        description: 'Check out this profile on AdsyClub Business Network.',
        url: profileUrl,
        imageUrl: widget.user['image']?.toString(),
        subject: '$userName Profile',
        eyebrow: 'Business Network Profile',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),

          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile QR Code',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded,
                    size: 22, color: _muted),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // QR card — captured for download exactly as shown.
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _line),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QrImageView(
                    data: profileUrl,
                    version: QrVersions.auto,
                    size: 216,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: _ink,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: _ink,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'AdsyClub Business Network',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: _muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          const Text(
            'Scan with any camera to open this profile',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: _muted,
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: downloadQrCode,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text(
                      'Download',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ink,
                      side: const BorderSide(color: _line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: shareProfile,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text(
                      'Share',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
