import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Service for AI-powered image enhancement
/// Features:
/// - Auto-enhance scanned documents
/// - Shadow and glare reduction
/// - Color vs grayscale auto-detection
/// - Contrast and brightness optimization
class ImageEnhancementService {
  /// Enhance an image for document scanning
  /// Returns path to enhanced image
  static Future<String> enhanceDocument(String imagePath) async {
    // Get directory path before compute (plugins don't work in isolates)
    final directory = await getApplicationDocumentsDirectory();
    return await compute(_enhanceDocumentIsolate, _EnhanceParams(imagePath, directory.path));
  }

  static Future<String> _enhanceDocumentIsolate(_EnhanceParams params) async {
    final imageBytes = await File(params.imagePath).readAsBytes();
    var image = img.decodeImage(imageBytes);
    
    if (image == null) {
      throw Exception('Failed to load image');
    }

    // Enhanced document processing - better quality
    // Step 1: Increase contrast for sharper text
    image = img.adjustColor(image, contrast: 1.5);
    
    // Step 2: Increase brightness to clean background
    image = img.adjustColor(image, brightness: 1.15);
    
    // Step 3: Slight saturation reduction for cleaner look
    image = img.adjustColor(image, saturation: 0.9);

    // Save enhanced image with higher quality
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'enhanced_$timestamp.jpg';
    final filePath = '${params.directoryPath}/$fileName';

    final jpegBytes = img.encodeJpg(image, quality: 95);
    await File(filePath).writeAsBytes(jpegBytes);

    return filePath;
  }

  /// Detect if image is primarily grayscale (document mode)
  static bool _detectGrayscale(img.Image image) {
    int colorPixels = 0;
    int totalPixels = 0;
    
    // Sample pixels across the image
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        
        // Check if pixel has significant color
        final maxDiff = [
          (r - g).abs(),
          (g - b).abs(),
          (r - b).abs(),
        ].reduce((a, b) => a > b ? a : b);
        
        if (maxDiff > 30) {
          colorPixels++;
        }
        totalPixels++;
      }
    }
    
    // If less than 20% of pixels are colorful, it's likely a document
    return colorPixels / totalPixels < 0.2;
  }

  /// Enhance contrast using adaptive histogram equalization
  static img.Image _enhanceContrast(img.Image image) {
    // Calculate histogram
    final histogram = List<int>.filled(256, 0);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final brightness = ((pixel.r + pixel.g + pixel.b) / 3).round();
        histogram[brightness.clamp(0, 255)]++;
      }
    }
    
    // Calculate CDF (Cumulative Distribution Function)
    final cdf = List<int>.filled(256, 0);
    cdf[0] = histogram[0];
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + histogram[i];
    }
    
    // Find min CDF value
    int cdfMin = cdf.firstWhere((v) => v > 0, orElse: () => 0);
    
    // Apply histogram equalization
    final totalPixels = image.width * image.height;
    final result = img.Image(width: image.width, height: image.height);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        
        // Calculate equalized value for each channel
        final avgBrightness = ((r + g + b) / 3).round().clamp(0, 255);
        final scale = ((cdf[avgBrightness] - cdfMin) * 255) / 
                      ((totalPixels - cdfMin).clamp(1, totalPixels));
        
        // Apply subtle enhancement (blend with original)
        final factor = 0.5; // 50% enhancement
        final newR = (r + (scale - avgBrightness) * factor).round().clamp(0, 255);
        final newG = (g + (scale - avgBrightness) * factor).round().clamp(0, 255);
        final newB = (b + (scale - avgBrightness) * factor).round().clamp(0, 255);
        
        result.setPixelRgba(x, y, newR, newG, newB, 255);
      }
    }
    
    return result;
  }

  /// Reduce shadows in the image
  static img.Image _reduceShadows(img.Image image) {
    // Apply gamma correction to lift shadows
    const gamma = 1.2; // Slightly lift shadows
    
    final result = img.Image(width: image.width, height: image.height);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        
        // Apply gamma correction
        final newR = (255 * _pow(r / 255, 1 / gamma)).round().clamp(0, 255);
        final newG = (255 * _pow(g / 255, 1 / gamma)).round().clamp(0, 255);
        final newB = (255 * _pow(b / 255, 1 / gamma)).round().clamp(0, 255);
        
        result.setPixelRgba(x, y, newR, newG, newB, 255);
      }
    }
    
    return result;
  }

  /// Power function for gamma correction
  static double _pow(double base, double exponent) {
    if (base <= 0) return 0;
    return base == 0 ? 0 : (base > 0 ? 
      (exponent * (base - 1).abs() < 0.1 ? base : _expApprox(exponent * _logApprox(base))) 
      : 0);
  }

  static double _expApprox(double x) {
    // Taylor series approximation
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 10; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }

  static double _logApprox(double x) {
    if (x <= 0) return 0;
    // Natural log approximation
    double result = 0;
    double y = (x - 1) / (x + 1);
    double term = y;
    for (int i = 1; i <= 15; i += 2) {
      result += term / i;
      term *= y * y;
    }
    return 2 * result;
  }

  /// Sharpen text for better readability
  static img.Image _sharpen(img.Image image) {
    // Unsharp mask kernel
    final kernel = [
      0, -1, 0,
      -1, 5, -1,
      0, -1, 0,
    ];
    
    final result = img.Image(width: image.width, height: image.height);
    
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        int r = 0, g = 0, b = 0;
        int idx = 0;
        
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = image.getPixel(x + kx, y + ky);
            r += (pixel.r.toInt() * kernel[idx]);
            g += (pixel.g.toInt() * kernel[idx]);
            b += (pixel.b.toInt() * kernel[idx]);
            idx++;
          }
        }
        
        result.setPixelRgba(
          x, y,
          r.clamp(0, 255),
          g.clamp(0, 255),
          b.clamp(0, 255),
          255,
        );
      }
    }
    
    // Copy edge pixels
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

  /// Apply document mode (high contrast B&W)
  static Future<String> applyDocumentMode(String imagePath) async {
    // Get directory path before compute (plugins don't work in isolates)
    final directory = await getApplicationDocumentsDirectory();
    return await compute(_applyDocumentModeIsolate, _EnhanceParams(imagePath, directory.path));
  }

  static Future<String> _applyDocumentModeIsolate(_EnhanceParams params) async {
    final imageBytes = await File(params.imagePath).readAsBytes();
    var image = img.decodeImage(imageBytes);
    
    if (image == null) {
      throw Exception('Failed to load image');
    }

    // Fast B&W processing using built-in functions
    // Convert to grayscale
    image = img.grayscale(image);
    
    // Increase contrast for clean B&W
    image = img.adjustColor(image, contrast: 1.5);

    // Save
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'document_$timestamp.jpg';
    final filePath = '${params.directoryPath}/$fileName';

    final jpegBytes = img.encodeJpg(image, quality: 90);
    await File(filePath).writeAsBytes(jpegBytes);

    return filePath;
  }

  /// Quick enhance modes
  static Future<String> quickEnhance(String imagePath, EnhanceMode mode) async {
    final imageBytes = await File(imagePath).readAsBytes();
    var image = img.decodeImage(imageBytes);
    
    if (image == null) {
      throw Exception('Failed to load image');
    }

    switch (mode) {
      case EnhanceMode.auto:
        image = _enhanceContrast(image);
        image = _reduceShadows(image);
        image = _sharpen(image);
        break;
      case EnhanceMode.brighten:
        image = img.adjustColor(image, brightness: 1.2);
        break;
      case EnhanceMode.contrast:
        image = img.adjustColor(image, contrast: 1.3);
        break;
      case EnhanceMode.sharpen:
        image = _sharpen(image);
        break;
      case EnhanceMode.grayscale:
        image = img.grayscale(image);
        break;
      case EnhanceMode.document:
        return await applyDocumentMode(imagePath);
      case EnhanceMode.whiteboard:
        return await enhanceWhiteboard(imagePath);
      case EnhanceMode.blackboard:
        return await enhanceBlackboard(imagePath);
    }

    // Save
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${mode.name}_$timestamp.jpg';
    final filePath = '${directory.path}/$fileName';

    final jpegBytes = img.encodeJpg(image, quality: 95);
    await File(filePath).writeAsBytes(jpegBytes);

    return filePath;
  }

  /// Enhance whiteboard scan
  /// Removes glare, boosts contrast, cleans background
  static Future<String> enhanceWhiteboard(String imagePath) async {
    // Get directory path before compute (plugins don't work in isolates)
    final directory = await getApplicationDocumentsDirectory();
    return await compute(_enhanceWhiteboardIsolate, _EnhanceParams(imagePath, directory.path));
  }

  static Future<String> _enhanceWhiteboardIsolate(_EnhanceParams params) async {
    final imageBytes = await File(params.imagePath).readAsBytes();
    var image = img.decodeImage(imageBytes);
    
    if (image == null) throw Exception('Failed to load image');

    // Fast processing using built-in functions
    // Step 1: Increase brightness to wash out background
    image = img.adjustColor(image, brightness: 1.1);
    
    // Step 2: Increase contrast to make text pop
    image = img.adjustColor(image, contrast: 1.4);
    
    // Step 3: Slightly desaturate for cleaner look
    image = img.adjustColor(image, saturation: 0.8);

    // Save using provided directory path
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${params.directoryPath}/whiteboard_$timestamp.jpg';
    
    await File(filePath).writeAsBytes(img.encodeJpg(image, quality: 90));
    return filePath;
  }

  /// Enhance blackboard/chalkboard scan
  /// Inverts colors, enhances chalk visibility
  static Future<String> enhanceBlackboard(String imagePath) async {
    // Get directory path before compute (plugins don't work in isolates)
    final directory = await getApplicationDocumentsDirectory();
    return await compute(_enhanceBlackboardIsolate, _EnhanceParams(imagePath, directory.path));
  }

  static Future<String> _enhanceBlackboardIsolate(_EnhanceParams params) async {
    final imageBytes = await File(params.imagePath).readAsBytes();
    var image = img.decodeImage(imageBytes);
    
    if (image == null) throw Exception('Failed to load image');

    // Fast processing using built-in functions
    // Step 1: Invert colors (black becomes white, chalk becomes dark)
    image = img.invert(image);
    
    // Step 2: Convert to grayscale for cleaner look
    image = img.grayscale(image);
    
    // Step 3: Increase contrast for better visibility
    image = img.adjustColor(image, contrast: 1.5);

    // Save using provided directory path
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${params.directoryPath}/blackboard_$timestamp.jpg';
    
    await File(filePath).writeAsBytes(img.encodeJpg(image, quality: 90));
    return filePath;
  }

  /// Remove glare from whiteboard (bright reflective spots)
  static img.Image _removeGlare(img.Image image) {
    final result = img.Image(width: image.width, height: image.height);
    
    // Calculate average brightness
    double avgBrightness = 0;
    int count = 0;
    for (int y = 0; y < image.height; y += 5) {
      for (int x = 0; x < image.width; x += 5) {
        final pixel = image.getPixel(x, y);
        avgBrightness += (pixel.r.toInt() + pixel.g.toInt() + pixel.b.toInt()) / 3;
        count++;
      }
    }
    avgBrightness /= count;
    
    // Clamp very bright pixels (glare)
    final glareThreshold = 240;
    final targetBrightness = avgBrightness.clamp(200, 230);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final brightness = (r + g + b) / 3;
        
        if (brightness > glareThreshold) {
          // This is a glare spot - reduce brightness
          final scale = targetBrightness / brightness;
          result.setPixelRgba(
            x, y,
            (r * scale).round().clamp(0, 255),
            (g * scale).round().clamp(0, 255),
            (b * scale).round().clamp(0, 255),
            255,
          );
        } else {
          result.setPixel(x, y, pixel);
        }
      }
    }
    
    return result;
  }

  /// Clean whiteboard background to pure white
  static img.Image _cleanWhiteBackground(img.Image image) {
    final result = img.Image(width: image.width, height: image.height);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final brightness = (r + g + b) / 3;
        
        // If pixel is light (background), push to white
        if (brightness > 180) {
          // Lighten background
          final newR = ((r + 255) / 2).round().clamp(240, 255);
          final newG = ((g + 255) / 2).round().clamp(240, 255);
          final newB = ((b + 255) / 2).round().clamp(240, 255);
          result.setPixelRgba(x, y, newR, newG, newB, 255);
        } else {
          result.setPixel(x, y, pixel);
        }
      }
    }
    
    return result;
  }

  /// Boost dark colors (marker text) for better visibility
  static img.Image _boostDarkColors(img.Image image) {
    final result = img.Image(width: image.width, height: image.height);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final brightness = (r + g + b) / 3;
        
        // If pixel is dark (text), make it darker
        if (brightness < 150) {
          // Darken text
          final scale = 0.7; // Make darker
          result.setPixelRgba(
            x, y,
            (r * scale).round().clamp(0, 255),
            (g * scale).round().clamp(0, 255),
            (b * scale).round().clamp(0, 255),
            255,
          );
        } else {
          result.setPixel(x, y, pixel);
        }
      }
    }
    
    return result;
  }

  /// Clean up noise from chalkboard (after inversion)
  static img.Image _cleanChalkNoise(img.Image image) {
    final result = img.Image(width: image.width, height: image.height);
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final brightness = pixel.r.toInt(); // Grayscale, so R=G=B
        
        // Push light grays to white, dark grays to darker
        if (brightness > 200) {
          result.setPixelRgba(x, y, 255, 255, 255, 255);
        } else if (brightness < 50) {
          result.setPixelRgba(x, y, 0, 0, 0, 255);
        } else {
          // Increase contrast in mid-tones
          final newVal = ((brightness - 125) * 1.5 + 125).round().clamp(0, 255);
          result.setPixelRgba(x, y, newVal, newVal, newVal, 255);
        }
      }
    }
    
    return result;
  }
}

enum EnhanceMode {
  auto,
  brighten,
  contrast,
  sharpen,
  grayscale,
  document,
  whiteboard,
  blackboard,
}

/// Parameters for enhancement operations with directory path
class _EnhanceParams {
  final String imagePath;
  final String directoryPath;
  
  _EnhanceParams(this.imagePath, this.directoryPath);
}
