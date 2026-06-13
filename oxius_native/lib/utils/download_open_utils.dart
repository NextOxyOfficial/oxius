import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';

class DownloadOpenUtils {
  static Future<void> openFile(
    BuildContext context,
    String filePath,
  ) async {
    final result = await OpenFilex.open(filePath);
    if (!context.mounted) return;

    if (result.type == ResultType.done) {
      return;
    }

    AdsyToast.error(
      context,
      result.message.isNotEmpty
          ? result.message
          : 'Could not open the downloaded file.',
    );
  }
}
