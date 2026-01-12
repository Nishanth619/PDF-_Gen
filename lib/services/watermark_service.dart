import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Watermark Service
/// Add text or image watermarks to PDF documents
class WatermarkService {
  /// Add text watermark to PDF
  static Future<String> addTextWatermark({
    required String pdfPath,
    required String text,
    double opacity = 0.3,
    double fontSize = 48,
    WatermarkPosition position = WatermarkPosition.center,
    bool diagonal = true,
  }) async {
    try {
      final bytes = await File(pdfPath).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      // Create watermark brush with opacity
      final PdfBrush brush = PdfSolidBrush(
        PdfColor(128, 128, 128, (opacity * 255).toInt()),
      );
      
      // Create font
      final PdfFont font = PdfStandardFont(
        PdfFontFamily.helvetica,
        fontSize,
        style: PdfFontStyle.bold,
      );
      
      // Add watermark to each page
      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage page = document.pages[i];
        final PdfGraphics graphics = page.graphics;
        final Size pageSize = page.getClientSize();
        
        // Calculate text size
        final Size textSize = font.measureString(text);
        
        // Save graphics state
        graphics.save();
        
        // Calculate position
        double x, y;
        switch (position) {
          case WatermarkPosition.topLeft:
            x = 50;
            y = 50;
            break;
          case WatermarkPosition.topRight:
            x = pageSize.width - textSize.width - 50;
            y = 50;
            break;
          case WatermarkPosition.bottomLeft:
            x = 50;
            y = pageSize.height - 50;
            break;
          case WatermarkPosition.bottomRight:
            x = pageSize.width - textSize.width - 50;
            y = pageSize.height - 50;
            break;
          case WatermarkPosition.center:
          default:
            x = (pageSize.width - textSize.width) / 2;
            y = (pageSize.height - textSize.height) / 2;
        }
        
        // Apply rotation for diagonal watermark
        if (diagonal && position == WatermarkPosition.center) {
          graphics.translateTransform(pageSize.width / 2, pageSize.height / 2);
          graphics.rotateTransform(-45);
          graphics.drawString(
            text,
            font,
            brush: brush,
            bounds: Rect.fromLTWH(
              -textSize.width / 2,
              -textSize.height / 2,
              textSize.width,
              textSize.height,
            ),
          );
        } else {
          graphics.drawString(
            text,
            font,
            brush: brush,
            bounds: Rect.fromLTWH(x, y, textSize.width, textSize.height),
          );
        }
        
        graphics.restore();
      }
      
      // Save
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${directory.path}/watermarked_$timestamp.pdf';
      
      final List<int> outputBytes = await document.save();
      document.dispose();
      
      await File(outputPath).writeAsBytes(outputBytes);
      
      return outputPath;
    } catch (e) {
      debugPrint('Error adding watermark: $e');
      rethrow;
    }
  }
  
  /// Add watermark to all pages with repeating pattern
  static Future<String> addRepeatingWatermark({
    required String pdfPath,
    required String text,
    double opacity = 0.15,
    double fontSize = 36,
  }) async {
    try {
      final bytes = await File(pdfPath).readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      final PdfBrush brush = PdfSolidBrush(
        PdfColor(128, 128, 128, (opacity * 255).toInt()),
      );
      
      final PdfFont font = PdfStandardFont(
        PdfFontFamily.helvetica,
        fontSize,
        style: PdfFontStyle.bold,
      );
      
      for (int i = 0; i < document.pages.count; i++) {
        final PdfPage page = document.pages[i];
        final PdfGraphics graphics = page.graphics;
        final Size pageSize = page.getClientSize();
        
        final Size textSize = font.measureString(text);
        
        // Draw repeating pattern
        for (double y = 0; y < pageSize.height; y += textSize.height + 100) {
          for (double x = 0; x < pageSize.width; x += textSize.width + 100) {
            graphics.save();
            graphics.translateTransform(x + textSize.width / 2, y + textSize.height / 2);
            graphics.rotateTransform(-30);
            graphics.drawString(
              text,
              font,
              brush: brush,
              bounds: Rect.fromLTWH(
                -textSize.width / 2,
                -textSize.height / 2,
                textSize.width * 2,
                textSize.height * 2,
              ),
            );
            graphics.restore();
          }
        }
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${directory.path}/watermarked_$timestamp.pdf';
      
      final List<int> outputBytes = await document.save();
      document.dispose();
      
      await File(outputPath).writeAsBytes(outputBytes);
      
      return outputPath;
    } catch (e) {
      debugPrint('Error adding repeating watermark: $e');
      rethrow;
    }
  }
}

/// Watermark position options
enum WatermarkPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
}
