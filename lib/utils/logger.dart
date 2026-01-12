
import 'package:flutter/foundation.dart';

/// Simple logger utility
class Logger {
  static const String _tag = 'PDFConverter';

  /// Log debug message
  static void d(String message, [String? tag]) {
    if (kDebugMode) {
      print('DEBUG [${tag ?? _tag}]: $message');
    }
  }

  /// Log info message
  static void i(String message, [String? tag]) {
    if (kDebugMode) {
      print('INFO [${tag ?? _tag}]: $message');
    }
  }

  /// Log warning message
  static void w(String message, [String? tag]) {
    if (kDebugMode) {
      print('WARNING [${tag ?? _tag}]: $message');
    }
  }

  /// Log error message
  static void e(String message, [dynamic error, StackTrace? stackTrace, String? tag]) {
    if (kDebugMode) {
      print('ERROR [${tag ?? _tag}]: $message');
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }
}
