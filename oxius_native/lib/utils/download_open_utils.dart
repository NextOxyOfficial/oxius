import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

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

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message.isNotEmpty
              ? result.message
              : 'Could not open the downloaded file.',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
