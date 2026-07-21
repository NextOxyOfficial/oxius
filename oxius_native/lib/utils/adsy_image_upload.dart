import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/common/adsy_sheet.dart';
import 'image_compressor.dart';

/// THE one profile-picture / banner picking flow for the whole app:
/// AdsySheet source picker (ক্যামেরা / গ্যালারি) → crop with a confirm step
/// (rotate + lock to the given ratio) → auto-compress → ready-to-upload
/// XFile. Use this everywhere instead of hand-rolled picker code so the
/// experience never drifts between screens.
class AdsyImageUpload {
  AdsyImageUpload._();

  /// Returns a compressed, cropped [XFile], or null if the user cancelled.
  ///
  /// [ratioX]/[ratioY]: crop aspect (1:1 for avatars, ~3:1 for banners).
  /// [targetKb]: compression budget (avatars 80, banners 220 works well).
  static Future<XFile?> pick(
    BuildContext context, {
    double ratioX = 1,
    double ratioY = 1,
    String title = 'ছবি ঠিক করুন',
    int targetKb = 80,
    /// false → return the cropped FILE (real path, uncompressed) for callers
    /// that need `.path` (e.g. previews via Image.file) and compress later.
    bool compress = true,
  }) async {
    ImageSource? source;
    await AdsySheet.show(
      context,
      children: [
        AdsySheetAction(
          icon: Icons.camera_alt_outlined,
          title: 'ছবি তুলুন',
          subtitle: 'ক্যামেরা দিয়ে নতুন ছবি তুলুন',
          onTap: () => source = ImageSource.camera,
        ),
        AdsySheetAction(
          icon: Icons.photo_library_outlined,
          title: 'গ্যালারি থেকে সিলেক্ট করুন',
          subtitle: 'ডিভাইসে থাকা ছবি থেকে সিলেক্ট করুন',
          onTap: () => source = ImageSource.gallery,
        ),
      ],
    );
    if (source == null) return null;

    final XFile? image = await ImagePicker().pickImage(
      source: source!,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 96,
    );
    if (image == null) return null;

    // Crop + rotate; pressing done in the cropper IS the confirm step.
    final cropped = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: CropAspectRatio(ratioX: ratioX, ratioY: ratioY),
      compressQuality: 95,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: const Color(0xFF111827),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFF16A34A),
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: title,
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          rotateButtonsHidden: false,
        ),
      ],
    );
    if (cropped == null) return null;

    final picked = XFile(cropped.path);
    if (!compress) return picked;
    final compressed = await ImageCompressor.compressToBytes(
      picked,
      targetSize: targetKb * 1024,
    );
    if (compressed != null) {
      return XFile.fromData(
        compressed,
        name: 'upload.jpg',
        mimeType: 'image/jpeg',
      );
    }
    return picked;
  }
}
