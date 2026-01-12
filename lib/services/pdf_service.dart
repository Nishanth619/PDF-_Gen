import 'dart:io';

import 'package:open_filex/open_filex.dart';

import '../utils/logger.dart';

class PdfService {
  // ... rest of the code remains the same until openPdf method

  /// Open PDF file
  static Future<bool> openPdf(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        Logger.e('File does not exist: $filePath');
        return false;
      }

      final result =
          await OpenFilex.open(filePath); // Changed from OpenFile to OpenFilex
      Logger.i('Open file result: ${result.message}');
      return result.type == ResultType.done;
    } catch (e, stackTrace) {
      Logger.e('Error opening PDF', e, stackTrace);
      return false;
    }
  }

  // ... rest of the code remains the same
}
