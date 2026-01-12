import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Utility class for image processing operations
class ImageUtils {
  /// Maximum width for resized images (to optimize memory)
  static const int maxImageWidth = 1080;

  /// Resize image to optimize memory usage
  /// Returns the resized image bytes
  static Future<Uint8List> resizeImage(File imageFile, {int quality = 85}) async {
    try {
      // Process image resizing in isolate for better performance
      final ImageResizeParams params = ImageResizeParams(
        filePath: imageFile.path,
        quality: quality,
        maxWidth: maxImageWidth,
      );
      
      return await compute(_resizeImageIsolate, params);
    } catch (e) {
      debugPrint('Error resizing image: $e');
      return await imageFile.readAsBytes();
    }
  }

  /// Resize image in isolate
  static Uint8List _resizeImageIsolate(ImageResizeParams params) {
    try {
      // Read image file
      final Uint8List imageBytes = File(params.filePath).readAsBytesSync();

      // Decode image
      final img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        return imageBytes;
      }

      // Resize if width exceeds max width
      img.Image resizedImage = image;
      if (image.width > params.maxWidth) {
        final int newHeight =
            (image.height * params.maxWidth / image.width).round();
        resizedImage = img.copyResize(
          image,
          width: params.maxWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode back to JPEG with specified quality
      final Uint8List resizedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: params.quality),
      );

      return resizedBytes;
    } catch (e) {
      debugPrint('Error resizing image in isolate: $e');
      // Return original bytes if resize fails
      try {
        return File(params.filePath).readAsBytesSync();
      } catch (e) {
        return Uint8List(0);
      }
    }
  }

  /// Auto-enhance image (brightness and contrast)
  static Future<Uint8List> enhanceImage(Uint8List imageBytes) async {
    try {
      return await compute(_enhanceImageIsolate, imageBytes);
    } catch (e) {
      debugPrint('Error enhancing image: $e');
      return imageBytes;
    }
  }

  /// Enhance image in isolate
  static Uint8List _enhanceImageIsolate(Uint8List bytes) {
    try {
      final img.Image? image = img.decodeImage(bytes);
      if (image == null) return bytes;

      // Auto-level to improve contrast
      img.Image enhanced = img.adjustColor(
        image,
        contrast: 1.2,
        brightness: 1.05,
      );

      // Sharpen slightly
      enhanced = img.convolution(
        enhanced,
        filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
      );

      return Uint8List.fromList(img.encodeJpg(enhanced, quality: 90));
    } catch (e) {
      debugPrint('Error in enhance isolate: $e');
      return bytes;
    }
  }

  /// Get image dimensions
  static Future<Map<String, int>?> getImageDimensions(File imageFile) async {
    try {
      // Process in isolate to avoid blocking UI
      return await compute(_getImageDimensionsIsolate, imageFile.path);
    } catch (e) {
      debugPrint('Error getting image dimensions: $e');
      return null;
    }
  }

  /// Get image dimensions in isolate
  static Map<String, int>? _getImageDimensionsIsolate(String filePath) {
    try {
      final Uint8List bytes = File(filePath).readAsBytesSync();
      final img.Image? image = img.decodeImage(bytes);

      if (image != null) {
        return {
          'width': image.width,
          'height': image.height,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error getting image dimensions in isolate: $e');
      return null;
    }
  }

  /// Validate if file is a valid image
  static Future<bool> isValidImage(File file) async {
    try {
      // Process validation in isolate
      return await compute(_isValidImageIsolate, file.path);
    } catch (e) {
      debugPrint('Error validating image: $e');
      return false;
    }
  }

  /// Validate image in isolate
  static bool _isValidImageIsolate(String filePath) {
    try {
      final String extension = filePath.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(extension)) {
        return false;
      }

      final Uint8List bytes = File(filePath).readAsBytesSync();
      final img.Image? image = img.decodeImage(bytes);

      return image != null;
    } catch (e) {
      debugPrint('Error validating image in isolate: $e');
      return false;
    }
  }

  /// Convert image to grayscale
  static Future<Uint8List> convertToGrayscale(Uint8List imageBytes) async {
    try {
      return await compute(_grayscaleIsolate, imageBytes);
    } catch (e) {
      debugPrint('Error converting to grayscale: $e');
      return imageBytes;
    }
  }

  /// Grayscale conversion in isolate
  static Uint8List _grayscaleIsolate(Uint8List bytes) {
    try {
      final img.Image? image = img.decodeImage(bytes);
      if (image == null) return bytes;

      final img.Image grayscale = img.grayscale(image);
      return Uint8List.fromList(img.encodeJpg(grayscale, quality: 90));
    } catch (e) {
      debugPrint('Error in grayscale isolate: $e');
      return bytes;
    }
  }
}

/// Parameters for image resizing
class ImageResizeParams {
  final String filePath;
  final int quality;
  final int maxWidth;

  ImageResizeParams({
    required this.filePath,
    required this.quality,
    required this.maxWidth,
  });
}