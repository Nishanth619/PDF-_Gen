import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Book Scanner Service
/// Features:
/// - Detect two pages in a single image
/// - Auto-split into individual pages
/// - Curved page flattening (dewarp)
/// - Batch processing support
class BookScannerService {
  /// Detect if image contains two book pages (open book scan)
  /// Returns split point (x coordinate) or null if single page
  static Future<int?> detectTwoPages(String imagePath) async {
    return await compute(_detectTwoPagesIsolate, imagePath);
  }

  static Future<int?> _detectTwoPagesIsolate(String imagePath) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(imageBytes);
    
    if (image == null) return null;

    // Look for vertical dark line (book crease) in center 40% of image
    final centerStart = (image.width * 0.3).toInt();
    final centerEnd = (image.width * 0.7).toInt();
    
    // Calculate vertical darkness profile
    Map<int, double> darknessByColumn = {};
    
    for (int x = centerStart; x < centerEnd; x++) {
      double totalDarkness = 0;
      
      // Sample every 5th row for performance
      int samples = 0;
      for (int y = 0; y < image.height; y += 5) {
        final pixel = image.getPixel(x, y);
        final brightness = (pixel.r.toInt() + pixel.g.toInt() + pixel.b.toInt()) / 3;
        totalDarkness += (255 - brightness); // Darkness = inverse of brightness
        samples++;
      }
      
      darknessByColumn[x] = totalDarkness / samples;
    }
    
    // Find the darkest column (likely the crease)
    int? darkestColumn;
    double maxDarkness = 0;
    
    darknessByColumn.forEach((x, darkness) {
      if (darkness > maxDarkness) {
        maxDarkness = darkness;
        darkestColumn = x;
      }
    });
    
    // Check if the crease is significantly darker than surroundings
    if (darkestColumn != null) {
      final avgLeft = darknessByColumn.entries
          .where((e) => e.key < darkestColumn! - 20)
          .map((e) => e.value)
          .fold<double>(0, (a, b) => a + b) / 
          darknessByColumn.entries.where((e) => e.key < darkestColumn! - 20).length;
      
      final avgRight = darknessByColumn.entries
          .where((e) => e.key > darkestColumn! + 20)
          .map((e) => e.value)
          .fold<double>(0, (a, b) => a + b) / 
          darknessByColumn.entries.where((e) => e.key > darkestColumn! + 20).length;
      
      // Crease should be at least 20% darker than average of both sides
      if (maxDarkness > (avgLeft + avgRight) / 2 * 1.2) {
        return darkestColumn;
      }
    }
    
    return null; // Single page or no clear crease detected
  }

  /// Split a two-page scan into left and right pages
  static Future<List<String>> splitPages(String imagePath, {int? splitPoint}) async {
    // Get directory path before compute (plugins don't work in isolates)
    final directory = await getApplicationDocumentsDirectory();
    final params = _SplitParams(imagePath, splitPoint, directory.path);
    return await compute(_splitPagesIsolate, params);
  }

  static Future<List<String>> _splitPagesIsolate(_SplitParams params) async {
    final imageBytes = await File(params.imagePath).readAsBytes();
    final image = img.decodeImage(imageBytes);
    
    if (image == null) return [params.imagePath];

    // Use provided split point or detect automatically
    int splitX = params.splitPoint ?? (image.width ~/ 2);
    
    // If no split point provided, try to detect
    if (params.splitPoint == null) {
      final detected = await _detectTwoPagesIsolate(params.imagePath);
      if (detected != null) {
        splitX = detected;
      }
    }

    // Create left page
    final leftPage = img.copyCrop(
      image,
      x: 0,
      y: 0,
      width: splitX,
      height: image.height,
    );

    // Create right page
    final rightPage = img.copyCrop(
      image,
      x: splitX,
      y: 0,
      width: image.width - splitX,
      height: image.height,
    );

    // Save both pages using provided directory path
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    final leftPath = '${params.directoryPath}/book_left_$timestamp.jpg';
    final rightPath = '${params.directoryPath}/book_right_$timestamp.jpg';
    
    await File(leftPath).writeAsBytes(img.encodeJpg(leftPage, quality: 95));
    await File(rightPath).writeAsBytes(img.encodeJpg(rightPage, quality: 95));
    
    return [leftPath, rightPath];
  }

  /// Flatten curved book page (dewarp)
  /// Uses cylindrical unwarp algorithm
  static Future<String> flattenCurvedPage(String imagePath) async {
    // Get directory path before compute (plugins don't work in isolates)
    final directory = await getApplicationDocumentsDirectory();
    return await compute(_flattenCurvedPageIsolate, _ImageParams(imagePath, directory.path));
  }

  static Future<String> _flattenCurvedPageIsolate(_ImageParams params) async {
    final imageBytes = await File(params.imagePath).readAsBytes();
    final image = img.decodeImage(imageBytes);
    
    if (image == null) throw Exception('Failed to load image');

    // Detect text lines to estimate curve
    final curveProfile = _estimatePageCurve(image);
    
    // Apply dewarp transformation
    final result = _applyDewarp(image, curveProfile);

    // Save using provided directory path
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${params.directoryPath}/flattened_$timestamp.jpg';
    
    await File(filePath).writeAsBytes(img.encodeJpg(result, quality: 95));
    
    return filePath;
  }

  /// Estimate the vertical curve of the page
  static List<double> _estimatePageCurve(img.Image image) {
    List<double> curve = [];
    
    // Sample columns across the image
    for (int x = 0; x < image.width; x += image.width ~/ 50) {
      // Find the topmost and bottommost text in this column
      int topY = 0;
      int bottomY = image.height - 1;
      
      // Find top text boundary
      for (int y = 0; y < image.height ~/ 2; y++) {
        final pixel = image.getPixel(x.clamp(0, image.width - 1), y);
        final brightness = (pixel.r.toInt() + pixel.g.toInt() + pixel.b.toInt()) / 3;
        if (brightness < 200) { // Dark pixel = text
          topY = y;
          break;
        }
      }
      
      // Find bottom text boundary
      for (int y = image.height - 1; y > image.height ~/ 2; y--) {
        final pixel = image.getPixel(x.clamp(0, image.width - 1), y);
        final brightness = (pixel.r.toInt() + pixel.g.toInt() + pixel.b.toInt()) / 3;
        if (brightness < 200) {
          bottomY = y;
          break;
        }
      }
      
      // Curve offset is based on text position
      curve.add((topY + bottomY) / 2.0);
    }
    
    // Smooth the curve
    List<double> smoothedCurve = [];
    for (int i = 0; i < curve.length; i++) {
      double sum = 0;
      int count = 0;
      for (int j = math.max(0, i - 2); j <= math.min(curve.length - 1, i + 2); j++) {
        sum += curve[j];
        count++;
      }
      smoothedCurve.add(sum / count);
    }
    
    return smoothedCurve;
  }

  /// Apply dewarp transformation to flatten the page
  static img.Image _applyDewarp(img.Image image, List<double> curveProfile) {
    if (curveProfile.isEmpty) return image;
    
    // Calculate the average center
    final avgCenter = curveProfile.reduce((a, b) => a + b) / curveProfile.length;
    
    // Create result image
    final result = img.Image(width: image.width, height: image.height);
    
    // Fill with white background
    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        result.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }
    
    // Apply dewarp by shifting rows
    final curveStep = image.width / curveProfile.length;
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        // Get curve offset for this x position
        final curveIndex = (x / curveStep).clamp(0, curveProfile.length - 1).toInt();
        final offset = curveProfile[curveIndex] - avgCenter;
        
        // Calculate source y position
        final srcY = (y + offset).round().clamp(0, image.height - 1);
        
        // Copy pixel
        final pixel = image.getPixel(x, srcY);
        result.setPixel(x, y, pixel);
      }
    }
    
    return result;
  }

  /// Enhance book page for better readability
  static Future<String> enhanceBookPage(String imagePath) async {
    // Get directory path before compute (plugins don't work in isolates)
    final directory = await getApplicationDocumentsDirectory();
    return await compute(_enhanceBookPageIsolate, _ImageParams(imagePath, directory.path));
  }

  static Future<String> _enhanceBookPageIsolate(_ImageParams params) async {
    final imageBytes = await File(params.imagePath).readAsBytes();
    var image = img.decodeImage(imageBytes);
    
    if (image == null) throw Exception('Failed to load image');

    // Fast processing using built-in functions
    // Step 1: Increase brightness to reduce shadows
    image = img.adjustColor(image, brightness: 1.1);
    
    // Step 2: Increase contrast for text
    image = img.adjustColor(image, contrast: 1.3);

    // Save using provided directory path
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${params.directoryPath}/enhanced_book_$timestamp.jpg';
    
    await File(filePath).writeAsBytes(img.encodeJpg(image, quality: 90));
    
    return filePath;
  }

  /// Remove shadows (especially from book crease)
  static img.Image _removeShadows(img.Image image) {
    // Apply adaptive gamma correction
    final result = img.Image(width: image.width, height: image.height);
    
    // Calculate average brightness per column (shadows are usually darker)
    List<double> columnBrightness = [];
    for (int x = 0; x < image.width; x++) {
      double sum = 0;
      for (int y = 0; y < image.height; y += 5) {
        final pixel = image.getPixel(x, y);
        sum += (pixel.r.toInt() + pixel.g.toInt() + pixel.b.toInt()) / 3;
      }
      columnBrightness.add(sum / (image.height / 5));
    }
    
    // Find max brightness (assume this is the correct level)
    final maxBrightness = columnBrightness.reduce((a, b) => a > b ? a : b);
    
    // Apply per-column brightness correction
    for (int x = 0; x < image.width; x++) {
      final correction = columnBrightness[x] > 0 
          ? maxBrightness / columnBrightness[x] 
          : 1.0;
      
      for (int y = 0; y < image.height; y++) {
        final pixel = image.getPixel(x, y);
        final r = (pixel.r.toInt() * correction).round().clamp(0, 255);
        final g = (pixel.g.toInt() * correction).round().clamp(0, 255);
        final b = (pixel.b.toInt() * correction).round().clamp(0, 255);
        result.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    
    return result;
  }

  /// Boost text contrast for better readability
  static img.Image _boostTextContrast(img.Image image) {
    // Apply CLAHE-like contrast enhancement
    final result = img.Image(width: image.width, height: image.height);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        
        // Increase contrast
        const factor = 1.3;
        final newR = (((r / 255.0 - 0.5) * factor + 0.5) * 255).round().clamp(0, 255);
        final newG = (((g / 255.0 - 0.5) * factor + 0.5) * 255).round().clamp(0, 255);
        final newB = (((b / 255.0 - 0.5) * factor + 0.5) * 255).round().clamp(0, 255);
        
        result.setPixelRgba(x, y, newR, newG, newB, 255);
      }
    }
    
    return result;
  }

  /// Sharpen text for better readability
  static img.Image _sharpenText(img.Image image) {
    // Unsharp mask kernel
    final kernel = [
      0.0, -1.0, 0.0,
      -1.0, 5.0, -1.0,
      0.0, -1.0, 0.0,
    ];
    
    final result = img.Image(width: image.width, height: image.height);
    
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        double r = 0, g = 0, b = 0;
        int idx = 0;
        
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = image.getPixel(x + kx, y + ky);
            r += pixel.r.toInt() * kernel[idx];
            g += pixel.g.toInt() * kernel[idx];
            b += pixel.b.toInt() * kernel[idx];
            idx++;
          }
        }
        
        result.setPixelRgba(
          x, y,
          r.round().clamp(0, 255),
          g.round().clamp(0, 255),
          b.round().clamp(0, 255),
          255,
        );
      }
    }
    
    // Copy edges
    for (int y = 0; y < image.height; y++) {
      result.setPixel(0, y, image.getPixel(0, y));
      result.setPixel(image.width - 1, y, image.getPixel(image.width - 1, y));
    }
    for (int x = 0; x < image.width; x++) {
      result.setPixel(x, 0, image.getPixel(x, 0));
      result.setPixel(x, image.height - 1, image.getPixel(x, image.height - 1));
    }
    
    return result;
  }
}

/// Parameters for split operation
class _SplitParams {
  final String imagePath;
  final int? splitPoint;
  final String directoryPath;
  
  _SplitParams(this.imagePath, this.splitPoint, this.directoryPath);
}

/// Parameters for image operations with directory
class _ImageParams {
  final String imagePath;
  final String directoryPath;
  
  _ImageParams(this.imagePath, this.directoryPath);
}
