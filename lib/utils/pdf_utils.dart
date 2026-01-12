import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../constants/app_constants.dart';
import '../models/pdf_file_model.dart';
import 'file_utils.dart';
import 'image_utils.dart';

class PdfMetadata {

  PdfMetadata({
    required this.pageCount,
    required this.fileSize,
  });
  final int pageCount;
  final int fileSize;
}

/// Utility class for PDF operations
class PdfUtils {
  /// Convert list of images to PDF
  /// Returns the created PDF file model or null if failed
  static Future<PdfFileModel?> createPdfFromImages({
    required List<File> imageFiles,
    required String fileName,
    bool autoEnhance = false,
    bool autoRotate = true,
    String pageSize = 'A4',
    double imageQuality = 0.85,
    String saveLocation = '', // Add save location parameter
    Function(double)? onProgress,
  }) async {
    try {
      // Create PDF document
      final pw.Document pdf = pw.Document();

      // Get page format based on user settings
      final PdfPageFormat pageFormat = _getPageFormat(pageSize);

      // Process each image with better multi-threading
      for (int i = 0; i < imageFiles.length; i++) {
        // Update progress
        onProgress?.call((i / imageFiles.length) * 0.8);

        // Process image with enhanced multi-threading
        final ProcessedImageResult result = await compute(
          _processImageForPdf,
          _ImageProcessingParams(
            imageFile: imageFiles[i],
            quality: (imageQuality * 100).toInt(),
            autoEnhance: autoEnhance,
            autoRotate: autoRotate,
            pageFormat: pageFormat,
          ),
        );

        if (result.imageBytes.isEmpty) continue;

        // Create PDF image
        final pw.ImageProvider pdfImage = pw.MemoryImage(result.imageBytes);

        // Add page with image
        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: const pw.EdgeInsets.all(0),
            build: (pw.Context context) {
              pw.Widget imageWidget = pw.Image(pdfImage);
              
              // Apply rotation if needed
              if (result.shouldRotate) {
                imageWidget = pw.Transform.rotate(
                  angle: 1.5708, // 90 degrees in radians
                  child: imageWidget,
                );
              }
              
              return pw.Center(
                child: imageWidget,
              );
            },
          ),
        );
      }

      // Update progress - saving
      onProgress?.call(0.9);

      // Save PDF to file
      Directory pdfDir;
      if (saveLocation.isNotEmpty) {
        // Use custom save location
        pdfDir = Directory(saveLocation);
        if (!await pdfDir.exists()) {
          await pdfDir.create(recursive: true);
        }
      } else {
        // Use default PDF directory
        pdfDir = await FileUtils.getPdfDirectory();
      }
      
      final String pdfPath = '${pdfDir.path}/$fileName.pdf';
      final File pdfFile = File(pdfPath);

      // Write PDF bytes
      final Uint8List pdfBytes = await pdf.save();
      await pdfFile.writeAsBytes(pdfBytes);

      // Update progress - complete
      onProgress?.call(1);

      // Create PDF file model
      final PdfFileModel pdfModel = PdfFileModel(
        name: fileName,
        path: pdfPath,
        size: await FileUtils.getFileSizeFromPath(pdfPath),
        pageCount: imageFiles.length,
      );

      return pdfModel;
    } catch (e) {
      debugPrint('Error converting images to PDF: $e');
      return null;
    }
  }

  /// Process image for PDF in isolate
  static ProcessedImageResult _processImageForPdf(_ImageProcessingParams params) {
    try {
      // Read image file
      final Uint8List imageBytes = params.imageFile.readAsBytesSync();

      // Decode image
      final img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        return ProcessedImageResult(Uint8List(0), false);
      }

      // Resize if width exceeds max width
      img.Image processedImage = image;
      if (image.width > ImageUtils.maxImageWidth) {
        final int newHeight =
            (image.height * ImageUtils.maxImageWidth / image.width).round();
        processedImage = img.copyResize(
          image,
          width: ImageUtils.maxImageWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      // Auto-enhance if enabled
      if (params.autoEnhance) {
        // Auto-level to improve contrast
        processedImage = img.adjustColor(
          processedImage,
          contrast: 1.2,
          brightness: 1.05,
        );

        // Sharpen slightly
        processedImage = img.convolution(
          processedImage,
          filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
        );
      }

      // Determine if image should be rotated
      bool shouldRotate = false;
      if (params.autoRotate) {
        shouldRotate = _shouldRotateImage(processedImage, params.pageFormat);
      }

      // Encode back to JPEG
      final Uint8List processedBytes = Uint8List.fromList(
        img.encodeJpg(processedImage, quality: params.quality),
      );

      return ProcessedImageResult(processedBytes, shouldRotate);
    } catch (e) {
      debugPrint('Error processing image for PDF: $e');
      return ProcessedImageResult(Uint8List(0), false);
    }
  }

  /// Save PDF file in isolate
  static String _savePdfFile(_PdfSaveParams params) {
    try {
      // Save PDF to file
      Directory pdfDir;
      if (params.saveLocation.isNotEmpty) {
        // Use custom save location
        pdfDir = Directory(params.saveLocation);
        if (!pdfDir.existsSync()) {
          pdfDir.createSync(recursive: true);
        }
      } else {
        // Use default PDF directory (simplified for isolate)
        pdfDir = Directory.systemTemp; // In a real app, you'd need to pass the proper directory
      }
      
      final String pdfPath = '${pdfDir.path}/${params.fileName}.pdf';
      final File pdfFile = File(pdfPath);

      // For isolates, we need to handle the async save differently
      // Let's simplify this and do the save in the main thread for now
      // and focus on other multi-threading improvements
      
      // Return empty string to indicate this approach won't work in isolate
      return '';
    } catch (e) {
      debugPrint('Error saving PDF file: $e');
      return '';
    }
  }

  /// Get page format based on page size string
  static PdfPageFormat _getPageFormat(String pageSize) {
    final dimensions = AppConstants.pageSizeDimensions[pageSize];
    if (dimensions != null && dimensions.length >= 2) {
      return PdfPageFormat(dimensions[0], dimensions[1], marginAll: 0);
    }
    // Default to A4 if not found
    return PdfPageFormat.a4;
  }

  /// Determine if image should be rotated based on dimensions and page format
  static bool _shouldRotateImage(img.Image image, PdfPageFormat pageFormat) {
    final bool isImageLandscape = image.width > image.height;
    final bool isPageLandscape = pageFormat.width > pageFormat.height;
    
    // Rotate if image orientation doesn't match page orientation
    return isImageLandscape != isPageLandscape;
  }

  /// Get PDF page count
  static Future<int> getPdfPageCount(String pdfPath) async {
    try {
      return await compute(_getPdfPageCountIsolate, pdfPath);
    } catch (e) {
      debugPrint('Error getting PDF page count: $e');
      return 0;
    }
  }

  /// Get PDF page count in isolate
  static int _getPdfPageCountIsolate(String pdfPath) {
    try {
      final File pdfFile = File(pdfPath);
      if (!pdfFile.existsSync()) return 0;

      // This is a simple implementation
      // For accurate page count, you'd need a PDF parsing library
      return 1;
    } catch (e) {
      debugPrint('Error getting PDF page count in isolate: $e');
      return 0;
    }
  }

  /// Load PDF metadata
  static Future<PdfMetadata?> loadPdfMetadata(String pdfPath) async {
    try {
      // Process metadata loading in isolate
      return await compute(_loadPdfMetadataIsolate, pdfPath);
    } catch (e) {
      debugPrint('Error loading PDF metadata: $e');
      return null;
    }
  }

  /// Load PDF metadata in isolate
  static PdfMetadata? _loadPdfMetadataIsolate(String pdfPath) {
    try {
      final File pdfFile = File(pdfPath);
      if (!pdfFile.existsSync()) return null;
      
      final int fileSize = pdfFile.lengthSync();
      final int pageCount = 1; // Simplified - in a real app you'd parse the PDF
      
      return PdfMetadata(pageCount: pageCount, fileSize: fileSize);
    } catch (e) {
      debugPrint('Error loading PDF metadata in isolate: $e');
      return null;
    }
  }

  /// Validate PDF file
  static Future<bool> validatePdfFile(String pdfPath) async {
    try {
      return await compute(_validatePdfFileIsolate, pdfPath);
    } catch (e) {
      debugPrint('Error validating PDF file: $e');
      return false;
    }
  }

  /// Validate PDF file in isolate
  static bool _validatePdfFileIsolate(String pdfPath) {
    try {
      final File pdfFile = File(pdfPath);
      if (!pdfFile.existsSync()) return false;

      // Read first few bytes to check PDF signature
      final Uint8List bytes = pdfFile.readAsBytesSync();
      if (bytes.length < 4) return false;

      // Check for PDF signature (%PDF)
      return bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46;
    } catch (e) {
      debugPrint('Error validating PDF file in isolate: $e');
      return false;
    }
  }
}

/// Parameters for image processing
class _ImageProcessingParams {
  final File imageFile;
  final int quality;
  final bool autoEnhance;
  final bool autoRotate;
  final PdfPageFormat pageFormat;

  _ImageProcessingParams({
    required this.imageFile,
    required this.quality,
    required this.autoEnhance,
    required this.autoRotate,
    required this.pageFormat,
  });
}

/// Result of image processing
class ProcessedImageResult {
  final Uint8List imageBytes;
  final bool shouldRotate;

  ProcessedImageResult(this.imageBytes, this.shouldRotate);
}

/// Parameters for PDF saving
class _PdfSaveParams {
  final pw.Document pdf;
  final String fileName;
  final String saveLocation;

  _PdfSaveParams({
    required this.pdf,
    required this.fileName,
    required this.saveLocation,
  });
}