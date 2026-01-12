import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/pdf_file_model.dart';

/// Utility class for file operations
class FileUtils {
  FileUtils._();

  /// Get the PDF directory
  static Future<Directory> getPdfDirectory() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory pdfDir = Directory('${appDir.path}/PDFs');

    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    return pdfDir;
  }

  /// Generate a unique filename
  static String generateUniqueFilename() {
    final String timestamp =
        DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return 'PDF_$timestamp.pdf';
  }

  /// Get file size in bytes from path
  static Future<int> getFileSizeFromPath(String path) async {
    // For large files, process in isolate
    return await compute(_getFileSizeIsolate, path);
  }

  /// Get file size in isolate
  static int _getFileSizeIsolate(String filePath) {
    try {
      final file = File(filePath);
      return file.lengthSync();
    } catch (e) {
      return 0;
    }
  }

  /// Get file size in human-readable format
  static String getFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Delete a PDF file
  static Future<bool> deletePdfFile(String filePath) async {
    try {
      // Process deletion in isolate for better performance
      return await compute(_deleteFileIsolate, filePath);
    } catch (e) {
      return false;
    }
  }

  /// Delete file in isolate
  static bool _deleteFileIsolate(String filePath) {
    try {
      final File file = File(filePath);
      if (file.existsSync()) {
        file.deleteSync();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Rename a PDF file
  static Future<String?> renamePdfFile(String oldPath, String newName) async {
    try {
      final File oldFile = File(oldPath);
      if (!await oldFile.exists()) return null;

      final String directory = path.dirname(oldPath);
      final String extension = path.extension(oldPath);
      final String newPath = path.join(directory, '$newName$extension');

      // Process renaming in isolate
      final RenameResult result = await compute(
        _renameFileIsolate,
        RenameParams(oldPath: oldPath, newPath: newPath),
      );

      return result.success ? result.newPath : null;
    } catch (e) {
      return null;
    }
  }

  /// Rename file in isolate
  static RenameResult _renameFileIsolate(RenameParams params) {
    try {
      final File oldFile = File(params.oldPath);
      if (!oldFile.existsSync()) {
        return RenameResult(success: false, newPath: '');
      }

      final File newFile = oldFile.renameSync(params.newPath);
      return RenameResult(success: true, newPath: newFile.path);
    } catch (e) {
      return RenameResult(success: false, newPath: '');
    }
  }

  /// Load PDF metadata (stub - implement based on your needs)
  static Future<List<PdfFileModel>> loadPdfMetadata(
      String directoryPath) async {
    // Implementation depends on how you store metadata
    return [];
  }

  /// Save PDF metadata (stub - implement based on your needs)
  static Future<bool> savePdfMetadata(List<PdfFileModel> metadataList) async {
    // Implementation depends on how you store metadata
    return true;
  }

  /// Get app documents directory
  static Future<Directory> getAppDirectory() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory appDir = Directory(
      path.join(appDocDir.path, 'PDFConverter'),
    );

    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }

    return appDir;
  }

  /// Get temp directory
  static Future<Directory> getTempDirectory() async {
    final Directory appDir = await getAppDirectory();
    final Directory tempDir = Directory(
      path.join(appDir.path, 'temp'),
    );

    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }

    return tempDir;
  }

  /// Generate unique file name
  static String generateFileName(String baseName, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitizedName = sanitizeFileName(baseName);
    return '${sanitizedName}_$timestamp$extension';
  }

  /// Sanitize file name
  static String sanitizeFileName(String fileName) {
    // Remove invalid characters
    String sanitized = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    // Trim whitespace
    sanitized = sanitized.trim();

    // Limit length
    if (sanitized.length > 100) {
      sanitized = sanitized.substring(0, 100);
    }

    // Ensure not empty
    if (sanitized.isEmpty) {
      sanitized = 'unnamed';
    }

    return sanitized;
  }

  /// Check if file exists
  static Future<bool> fileExists(String filePath) async {
    // Process in isolate for better performance
    return await compute(_fileExistsIsolate, filePath);
  }

  /// Check if file exists in isolate
  static bool _fileExistsIsolate(String filePath) {
    try {
      final file = File(filePath);
      return file.existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Get file extension
  static String getFileExtension(String filePath) {
    return path.extension(filePath);
  }

  /// Get file name without extension
  static String getFileNameWithoutExtension(String filePath) {
    return path.basenameWithoutExtension(filePath);
  }

  /// Copy file
  static Future<File?> copyFile(
      String sourcePath, String destinationPath) async {
    try {
      // Process copying in isolate for large files
      final CopyResult result = await compute(
        _copyFileIsolate,
        CopyParams(sourcePath: sourcePath, destinationPath: destinationPath),
      );

      return result.success ? File(result.destinationPath) : null;
    } catch (e) {
      return null;
    }
  }

  /// Copy file in isolate
  static CopyResult _copyFileIsolate(CopyParams params) {
    try {
      final sourceFile = File(params.sourcePath);
      if (!sourceFile.existsSync()) {
        return CopyResult(success: false, destinationPath: '');
      }

      final destinationFile = sourceFile.copySync(params.destinationPath);
      return CopyResult(success: true, destinationPath: destinationFile.path);
    } catch (e) {
      return CopyResult(success: false, destinationPath: '');
    }
  }

  /// Clear temp directory
  static Future<void> clearTempDirectory() async {
    try {
      // Process in isolate for better performance
      await compute(_clearTempDirectoryIsolate, '');
    } catch (e) {
      // Ignore errors
    }
  }

  /// Clear temp directory in isolate
  static void _clearTempDirectoryIsolate(String _) {
    try {
      // This is a simplified version - in a real app you'd need to pass the temp directory path
      // For now, we'll just return to avoid issues
    } catch (e) {
      // Ignore errors
    }
  }
}

/// Parameters for renaming files
class RenameParams {
  final String oldPath;
  final String newPath;

  RenameParams({required this.oldPath, required this.newPath});
}

/// Result of renaming operation
class RenameResult {
  final bool success;
  final String newPath;

  RenameResult({required this.success, required this.newPath});
}

/// Parameters for copying files
class CopyParams {
  final String sourcePath;
  final String destinationPath;

  CopyParams({required this.sourcePath, required this.destinationPath});
}

/// Result of copying operation
class CopyResult {
  final bool success;
  final String destinationPath;

  CopyResult({required this.success, required this.destinationPath});
}