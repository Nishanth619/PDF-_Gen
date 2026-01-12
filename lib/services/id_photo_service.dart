import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:local_rembg/local_rembg.dart';
import 'package:path_provider/path_provider.dart';

import '../models/id_photo_template.dart';

/// Service for ID photo processing:
/// - Face detection
/// - Background removal
/// - Auto-cropping
/// - Background color replacement
class IdPhotoService {
  static final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  static final SelfieSegmenter _segmenter = SelfieSegmenter(
    mode: SegmenterMode.single, // Single mode for better accuracy on photos
    enableRawSizeMask: true,
  );

  /// Detect faces in an image
  static Future<List<Face>> detectFaces(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final faces = await _faceDetector.processImage(inputImage);
    return faces;
  }

  /// Get segmentation mask for background removal
  static Future<SegmentationMask?> getSegmentationMask(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final mask = await _segmenter.processImage(inputImage);
    return mask;
  }

  /// Process image for ID photo:
  /// - Detect face
  /// - Remove background
  /// - Crop to template size
  /// - Apply background color
  static Future<IdPhotoResult?> processIdPhoto({
    required String imagePath,
    required IdPhotoTemplate template,
    required int backgroundColor,
    int outputDpi = 300,
    bool autoCrop = true, // Toggle for auto cropping
  }) async {
    try {
      // Load image
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      var originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        return IdPhotoResult.error('Failed to load image');
      }

      // Detect face first
      final faces = await detectFaces(imagePath);
      
      if (faces.isEmpty) {
        return IdPhotoResult.error('No face detected. Please take a clear photo of your face.');
      }

      final face = faces.first;
      final faceBounds = face.boundingBox;

      // Try local_rembg first (most accurate)
      bool backgroundRemoved = false;
      img.Image processedImage = originalImage;
      
      try {
        // Use local_rembg for accurate background removal
        final rembgResult = await LocalRembg.removeBackground(imagePath: imagePath);
        
        if (rembgResult.status == 1 && rembgResult.imageBytes != null) {
          // Successfully removed background - image has transparent background
          final bgRemovedImage = img.decodeImage(Uint8List.fromList(rembgResult.imageBytes!));
          
          if (bgRemovedImage != null) {
            // Apply the chosen background color to transparent areas
            processedImage = _applyBackgroundColorToTransparent(
              bgRemovedImage,
              backgroundColor,
            );
            backgroundRemoved = true;
            if (kDebugMode) {
              print('local_rembg: Background removed successfully');
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('local_rembg failed: $e');
        }
      }
      
      // Fallback to face-guided approach if local_rembg fails
      if (!backgroundRemoved) {
        try {
          final mask = await getSegmentationMask(imagePath);
          processedImage = _faceGuidedBackgroundRemoval(
            originalImage,
            face,
            mask,
            backgroundColor,
          );
          backgroundRemoved = true;
          if (kDebugMode) {
            print('Fallback: Using face-guided background removal');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Face-guided fallback also failed: $e');
          }
        }
      }

      // Final image - either cropped or original
      img.Image finalImage;

      if (autoCrop) {
        // Calculate crop area based on face position
        final faceHeight = faceBounds.height;
        final scale = (template.heightPixels(outputDpi) * 0.70) / faceHeight;

        // Calculate head position (face + hair = ~1.3x face height)
        final headTop = faceBounds.top - (faceHeight * 0.5);
        final headCenter = (faceBounds.left + faceBounds.right) / 2;

        // Calculate crop dimensions
        final cropWidth = template.widthPixels(outputDpi) / scale;
        final cropHeight = template.heightPixels(outputDpi) / scale;

        // Center crop on face
        var cropLeft = headCenter - (cropWidth / 2);
        var cropTop = headTop - (cropHeight * 0.15);

        // Clamp to image bounds
        cropLeft = cropLeft.clamp(0, (processedImage.width - cropWidth).toDouble()).toDouble();
        cropTop = cropTop.clamp(0, (processedImage.height - cropHeight).toDouble()).toDouble();

        // Crop the already-processed image
        var croppedImage = img.copyCrop(
          processedImage,
          x: cropLeft.toInt(),
          y: cropTop.toInt(),
          width: cropWidth.toInt(),
          height: cropHeight.toInt(),
        );

        // Resize to final size
        finalImage = img.copyResize(
          croppedImage,
          width: template.widthPixels(outputDpi),
          height: template.heightPixels(outputDpi),
          interpolation: img.Interpolation.cubic,
        );
      } else {
        // No cropping - just use the background-removed image
        finalImage = processedImage;
      }

      // Save processed image
      final outputPath = await _saveProcessedImage(finalImage, template.id);

      return IdPhotoResult.success(
        imagePath: outputPath,
        template: template,
        faceDetected: true,
        backgroundRemoved: backgroundRemoved,
      );
    } catch (e) {
      return IdPhotoResult.error('Processing failed: $e');
    }
  }

  /// Apply background color to transparent areas of an image
  static img.Image _applyBackgroundColorToTransparent(
    img.Image image,
    int backgroundColor,
  ) {
    final result = img.Image(width: image.width, height: image.height);

    final bgR = (backgroundColor >> 16) & 0xFF;
    final bgG = (backgroundColor >> 8) & 0xFF;
    final bgB = backgroundColor & 0xFF;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final alpha = pixel.a.toDouble() / 255.0;

        if (alpha < 0.01) {
          // Fully transparent - use background color
          result.setPixelRgba(x, y, bgR, bgG, bgB, 255);
        } else if (alpha > 0.99) {
          // Fully opaque - use original color
          result.setPixelRgba(x, y, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), 255);
        } else {
          // Semi-transparent - blend with background
          final r = (pixel.r.toInt() * alpha + bgR * (1 - alpha)).round().clamp(0, 255);
          final g = (pixel.g.toInt() * alpha + bgG * (1 - alpha)).round().clamp(0, 255);
          final b = (pixel.b.toInt() * alpha + bgB * (1 - alpha)).round().clamp(0, 255);
          result.setPixelRgba(x, y, r, g, b, 255);
        }
      }
    }

    return result;
  }

  /// Face-guided background removal - uses face detection to guide segmentation
  static img.Image _faceGuidedBackgroundRemoval(
    img.Image image,
    Face face,
    SegmentationMask? mask,
    int backgroundColor,
  ) {
    final result = img.Image(width: image.width, height: image.height);

    final bgR = (backgroundColor >> 16) & 0xFF;
    final bgG = (backgroundColor >> 8) & 0xFF;
    final bgB = backgroundColor & 0xFF;

    final faceBounds = face.boundingBox;
    
    // Calculate face center and person area (expand face to include body)
    final faceCenterX = (faceBounds.left + faceBounds.right) / 2;
    final faceCenterY = (faceBounds.top + faceBounds.bottom) / 2;
    final faceWidth = faceBounds.width;
    final faceHeight = faceBounds.height;

    // Person region: face area + body area below
    final personLeft = (faceCenterX - faceWidth * 1.5).clamp(0, image.width.toDouble());
    final personRight = (faceCenterX + faceWidth * 1.5).clamp(0, image.width.toDouble());
    final personTop = (faceBounds.top - faceHeight * 0.8).clamp(0, image.height.toDouble()); // Include hair
    final personBottom = image.height.toDouble(); // Full body to bottom

    // Sample background colors from corners (definitely background)
    List<List<int>> bgSamples = [];
    int sampleSize = 30;
    
    // Top-left corner
    for (int y = 0; y < sampleSize && y < image.height; y++) {
      for (int x = 0; x < sampleSize && x < image.width; x++) {
        final p = image.getPixel(x, y);
        bgSamples.add([p.r.toInt(), p.g.toInt(), p.b.toInt()]);
      }
    }
    // Top-right corner
    for (int y = 0; y < sampleSize && y < image.height; y++) {
      for (int x = image.width - sampleSize; x < image.width && x >= 0; x++) {
        final p = image.getPixel(x, y);
        bgSamples.add([p.r.toInt(), p.g.toInt(), p.b.toInt()]);
      }
    }

    // Calculate average background color from samples
    int avgBgR = 0, avgBgG = 0, avgBgB = 0;
    for (var sample in bgSamples) {
      avgBgR += sample[0];
      avgBgG += sample[1];
      avgBgB += sample[2];
    }
    if (bgSamples.isNotEmpty) {
      avgBgR = avgBgR ~/ bgSamples.length;
      avgBgG = avgBgG ~/ bgSamples.length;
      avgBgB = avgBgB ~/ bgSamples.length;
    }

    // ML Kit confidence map (if available)
    double Function(int, int)? getMlConfidence;
    if (mask != null && mask.confidences.isNotEmpty) {
      final scaleX = mask.width / image.width;
      final scaleY = mask.height / image.height;
      getMlConfidence = (int x, int y) {
        final maskX = (x * scaleX).toInt().clamp(0, mask.width - 1);
        final maskY = (y * scaleY).toInt().clamp(0, mask.height - 1);
        final idx = maskY * mask.width + maskX;
        return idx < mask.confidences.length ? mask.confidences[idx] : 0.0;
      };
    }

    // Create confidence map
    List<List<double>> confidenceMap = List.generate(
      image.height,
      (y) => List.generate(image.width, (x) {
        // 1. Distance from face center (elliptical)
        final dx = (x - faceCenterX) / (faceWidth * 2);
        final dy = (y - faceCenterY) / (faceHeight * 3); // Taller for body
        final distFromFace = dx * dx + dy * dy;
        
        // 2. Is pixel inside person region?
        final inPersonRegion = 
            x >= personLeft && x <= personRight && 
            y >= personTop && y <= personBottom;

        // 3. Color similarity to sampled background
        final pixel = image.getPixel(x.toInt(), y.toInt());
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final colorDistToBg = ((r - avgBgR).abs() + (g - avgBgG).abs() + (b - avgBgB).abs()) / 3.0;

        // Calculate confidence
        double confidence = 0.0;

        // Start with ML Kit mask if available
        if (getMlConfidence != null) {
          confidence = getMlConfidence(x.toInt(), y.toInt());
        }

        // Boost confidence for face area
        if (distFromFace < 0.3) {
          confidence = confidence.clamp(0.9, 1.0);
        } else if (distFromFace < 0.5) {
          confidence = (confidence + 0.6) / 2;
        }

        // Adjust based on being in person region
        if (inPersonRegion) {
          // If color is different from background, more likely person
          if (colorDistToBg > 50) {
            confidence = (confidence + 0.4).clamp(0.0, 1.0);
          }
        }

        // If very similar to background color, likely background
        if (colorDistToBg < 25) {
          confidence = (confidence * 0.3).clamp(0.0, 1.0);
        }

        // Corners are definitely background
        if (x < sampleSize && y < sampleSize ||
            x >= image.width - sampleSize && y < sampleSize) {
          confidence = 0.0;
        }

        return confidence.clamp(0.0, 1.0);
      }),
    );

    // Apply Gaussian blur to smooth edges (multiple passes)
    for (int pass = 0; pass < 4; pass++) {
      confidenceMap = _gaussianBlur(confidenceMap, image.width, image.height, pass < 2 ? 7 : 5);
    }

    // Apply background with alpha blending
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final confidence = confidenceMap[y][x];

        // Hermite interpolation for smooth edges
        double alpha;
        if (confidence > 0.7) {
          alpha = 1.0;
        } else if (confidence < 0.2) {
          alpha = 0.0;
        } else {
          final t = (confidence - 0.2) / 0.5;
          alpha = t * t * t * (t * (t * 6 - 15) + 10);
        }

        final r = (pixel.r.toInt() * alpha + bgR * (1 - alpha)).round().clamp(0, 255);
        final g = (pixel.g.toInt() * alpha + bgG * (1 - alpha)).round().clamp(0, 255);
        final b = (pixel.b.toInt() * alpha + bgB * (1 - alpha)).round().clamp(0, 255);

        result.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return result;
  }

  /// Apply background color with advanced edge detection and smooth removal
  static img.Image _applyBackgroundDirect(
    img.Image image,
    SegmentationMask mask,
    int backgroundColor,
  ) {
    final result = img.Image(width: image.width, height: image.height);

    final bgR = (backgroundColor >> 16) & 0xFF;
    final bgG = (backgroundColor >> 8) & 0xFF;
    final bgB = backgroundColor & 0xFF;

    // Scale factors for mask mapping
    final scaleX = mask.width / image.width;
    final scaleY = mask.height / image.height;

    // Step 1: Build initial confidence map from mask
    List<List<double>> confidenceMap = List.generate(
      image.height,
      (y) => List.generate(image.width, (x) {
        final maskX = (x * scaleX).toInt().clamp(0, mask.width - 1);
        final maskY = (y * scaleY).toInt().clamp(0, mask.height - 1);
        final idx = maskY * mask.width + maskX;
        return idx < mask.confidences.length ? mask.confidences[idx] : 0.0;
      }),
    );

    // Step 2: Morphological operations to clean up edges
    // Erode (shrink foreground slightly to remove noise)
    confidenceMap = _morphologyOp(confidenceMap, image.width, image.height, false, 1);
    // Dilate (expand back to recover edges)
    confidenceMap = _morphologyOp(confidenceMap, image.width, image.height, true, 2);

    // Step 3: Edge-aware Gaussian blur (larger kernel, more passes)
    for (int pass = 0; pass < 5; pass++) {
      final kernelSize = pass < 2 ? 5 : 3; // Larger kernel first, then smaller
      confidenceMap = _gaussianBlur(confidenceMap, image.width, image.height, kernelSize);
    }

    // Step 4: Color-based edge refinement
    confidenceMap = _colorEdgeRefinement(confidenceMap, image, bgR, bgG, bgB);

    // Step 5: Apply background with smooth alpha blending
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final confidence = confidenceMap[y][x];

        // Wider feathering zone for smoother edges
        double alpha;
        if (confidence > 0.75) {
          alpha = 1.0; // Definitely person
        } else if (confidence < 0.15) {
          alpha = 0.0; // Definitely background
        } else {
          // Smooth cubic interpolation for edge zone
          final t = (confidence - 0.15) / 0.6;
          // Hermite interpolation for very smooth transitions
          alpha = t * t * t * (t * (t * 6 - 15) + 10);
        }

        // Blend with background
        final r = (pixel.r.toInt() * alpha + bgR * (1 - alpha)).round().clamp(0, 255);
        final g = (pixel.g.toInt() * alpha + bgG * (1 - alpha)).round().clamp(0, 255);
        final b = (pixel.b.toInt() * alpha + bgB * (1 - alpha)).round().clamp(0, 255);

        result.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return result;
  }

  /// Morphological operation (erode or dilate)
  static List<List<double>> _morphologyOp(
    List<List<double>> mask,
    int width,
    int height,
    bool dilate,
    int radius,
  ) {
    final result = List.generate(height, (y) => List<double>.filled(width, 0.0));

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double extremeVal = dilate ? 0.0 : 1.0;

        for (int dy = -radius; dy <= radius; dy++) {
          for (int dx = -radius; dx <= radius; dx++) {
            if (dx * dx + dy * dy > radius * radius) continue; // Circular kernel

            final ny = (y + dy).clamp(0, height - 1);
            final nx = (x + dx).clamp(0, width - 1);

            if (dilate) {
              extremeVal = extremeVal > mask[ny][nx] ? extremeVal : mask[ny][nx];
            } else {
              extremeVal = extremeVal < mask[ny][nx] ? extremeVal : mask[ny][nx];
            }
          }
        }

        result[y][x] = extremeVal;
      }
    }

    return result;
  }

  /// Gaussian blur with specified kernel size
  static List<List<double>> _gaussianBlur(
    List<List<double>> mask,
    int width,
    int height,
    int kernelSize,
  ) {
    final result = List.generate(height, (y) => List<double>.filled(width, 0.0));
    final radius = kernelSize ~/ 2;

    // Pre-compute Gaussian weights
    final weights = <double>[];
    double weightSum = 0;
    for (int i = -radius; i <= radius; i++) {
      final w = _gaussian(i.toDouble(), radius / 2.0);
      weights.add(w);
      weightSum += w;
    }
    for (int i = 0; i < weights.length; i++) {
      weights[i] /= weightSum;
    }

    // Horizontal pass
    final temp = List.generate(height, (y) => List<double>.filled(width, 0.0));
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double sum = 0;
        for (int i = -radius; i <= radius; i++) {
          final nx = (x + i).clamp(0, width - 1);
          sum += mask[y][nx] * weights[i + radius];
        }
        temp[y][x] = sum;
      }
    }

    // Vertical pass
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double sum = 0;
        for (int i = -radius; i <= radius; i++) {
          final ny = (y + i).clamp(0, height - 1);
          sum += temp[ny][x] * weights[i + radius];
        }
        result[y][x] = sum;
      }
    }

    return result;
  }

  /// Gaussian function
  static double _gaussian(double x, double sigma) {
    return (1.0 / (sigma * 2.506628)) * 
           _expApprox(-(x * x) / (2 * sigma * sigma));
  }

  /// Fast exp approximation
  static double _expApprox(double x) {
    x = 1.0 + x / 256.0;
    for (int i = 0; i < 8; i++) x *= x;
    return x;
  }

  /// Color-based edge refinement
  static List<List<double>> _colorEdgeRefinement(
    List<List<double>> mask,
    img.Image image,
    int bgR,
    int bgG,
    int bgB,
  ) {
    final result = List.generate(
      image.height,
      (y) => List<double>.from(mask[y]),
    );

    // Refine edges based on color similarity to background
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        final confidence = mask[y][x];

        // Only process edge pixels (0.2 to 0.8)
        if (confidence > 0.2 && confidence < 0.8) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();

          // Calculate color distance to background
          final colorDist = ((r - bgR).abs() + (g - bgG).abs() + (b - bgB).abs()) / 3.0;

          // If pixel is similar to background, reduce confidence
          if (colorDist < 30) {
            result[y][x] = confidence * 0.5;
          }
          // If pixel is very different from background, increase confidence
          else if (colorDist > 100) {
            result[y][x] = confidence + (1 - confidence) * 0.3;
          }

          // Check local color variance (hair/skin has texture, bg is uniform)
          double variance = 0;
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              final np = image.getPixel(x + dx, y + dy);
              variance += ((np.r.toInt() - r).abs() + 
                          (np.g.toInt() - g).abs() + 
                          (np.b.toInt() - b).abs()) / 3.0;
            }
          }
          variance /= 9;

          // High variance = likely foreground (increase confidence)
          if (variance > 15) {
            result[y][x] = (result[y][x] + 0.2).clamp(0.0, 1.0);
          }
          // Low variance = likely background (decrease confidence)
          else if (variance < 5) {
            result[y][x] = (result[y][x] - 0.2).clamp(0.0, 1.0);
          }
        }
      }
    }

    return result;
  }

  /// Apply background color using segmentation mask with smooth edges
  static Future<img.Image> _applyBackgroundWithMask(
    img.Image image,
    SegmentationMask mask,
    int backgroundColor,
    int cropX,
    int cropY,
    int originalWidth,
    int originalHeight,
  ) async {
    // Create result image
    final result = img.Image(
      width: image.width,
      height: image.height,
    );

    // Background color components
    final bgR = (backgroundColor >> 16) & 0xFF;
    final bgG = (backgroundColor >> 8) & 0xFF;
    final bgB = backgroundColor & 0xFF;

    // Calculate mask scaling
    final maskScaleX = mask.width / originalWidth;
    final maskScaleY = mask.height / originalHeight;
    
    // Create a processed mask with smoothed edges
    // First, get all confidence values for our crop area
    List<List<double>> smoothedMask = List.generate(
      image.height,
      (_) => List.filled(image.width, 0.0),
    );

    // Fill initial mask values
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final origX = cropX + (x * (originalWidth - cropX) / image.width).toInt();
        final origY = cropY + (y * (originalHeight - cropY) / image.height).toInt();

        final maskX = (origX * maskScaleX).toInt().clamp(0, mask.width - 1);
        final maskY = (origY * maskScaleY).toInt().clamp(0, mask.height - 1);

        final maskIndex = maskY * mask.width + maskX;
        smoothedMask[y][x] = maskIndex < mask.confidences.length
            ? mask.confidences[maskIndex]
            : 0.0;
      }
    }

    // Apply Gaussian blur to smooth mask edges (3x3 kernel)
    final blurredMask = _blurMask(smoothedMask, image.width, image.height, 2);

    // Apply background with alpha blending for smooth transitions
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final confidence = blurredMask[y][x];

        // Use smooth threshold with feathering
        // confidence > 0.6 = full person
        // confidence < 0.3 = full background  
        // between = blend
        double alpha;
        if (confidence > 0.65) {
          alpha = 1.0; // Full person
        } else if (confidence < 0.25) {
          alpha = 0.0; // Full background
        } else {
          // Smooth transition zone (feathering)
          alpha = (confidence - 0.25) / 0.4; // Linear interpolation
          alpha = alpha * alpha * (3 - 2 * alpha); // Smoothstep for better curve
        }

        // Alpha blend between person and background
        final r = (pixel.r.toInt() * alpha + bgR * (1 - alpha)).round().clamp(0, 255);
        final g = (pixel.g.toInt() * alpha + bgG * (1 - alpha)).round().clamp(0, 255);
        final b = (pixel.b.toInt() * alpha + bgB * (1 - alpha)).round().clamp(0, 255);

        result.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return result;
  }

  /// Apply Gaussian blur to mask for smoother edges
  static List<List<double>> _blurMask(
    List<List<double>> mask,
    int width,
    int height,
    int passes,
  ) {
    var current = mask;

    for (int pass = 0; pass < passes; pass++) {
      final blurred = List.generate(height, (_) => List.filled(width, 0.0));

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          double sum = 0;
          double weightSum = 0;

          // 5x5 Gaussian-like kernel
          for (int ky = -2; ky <= 2; ky++) {
            for (int kx = -2; kx <= 2; kx++) {
              final nx = (x + kx).clamp(0, width - 1);
              final ny = (y + ky).clamp(0, height - 1);

              // Gaussian weight (approximate)
              final dist = (kx * kx + ky * ky).toDouble();
              final weight = 1.0 / (1.0 + dist * 0.5);

              sum += current[ny][nx] * weight;
              weightSum += weight;
            }
          }

          blurred[y][x] = sum / weightSum;
        }
      }

      current = blurred;
    }

    return current;
  }

  /// Simple background replacement without ML (fallback)
  static img.Image applyBackgroundColor(
    img.Image image,
    int backgroundColor,
  ) {
    final result = img.Image(
      width: image.width,
      height: image.height,
    );

    final bgR = (backgroundColor >> 16) & 0xFF;
    final bgG = (backgroundColor >> 8) & 0xFF;
    final bgB = backgroundColor & 0xFF;

    // Simple edge detection to identify background
    // This is a basic approach - ML segmentation works better
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        
        // Check if pixel is likely background (very bright/white-ish)
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        
        final brightness = (r + g + b) / 3;
        final isBackground = brightness > 240 || 
            (brightness > 200 && (r - g).abs() < 20 && (g - b).abs() < 20);

        if (isBackground) {
          result.setPixelRgba(x, y, bgR, bgG, bgB, 255);
        } else {
          result.setPixel(x, y, pixel);
        }
      }
    }

    return result;
  }

  /// Save processed image to temp directory
  static Future<String> _saveProcessedImage(img.Image image, String templateId) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'id_photo_${templateId}_$timestamp.jpg';
    final filePath = '${directory.path}/$fileName';

    final jpegBytes = img.encodeJpg(image, quality: 95);
    await File(filePath).writeAsBytes(jpegBytes);

    return filePath;
  }

  /// Generate print layout with multiple photos
  static Future<String> generatePrintLayout({
    required String photoPath,
    required IdPhotoTemplate template,
    required String layoutName,
    int dpi = 300,
  }) async {
    final layout = PrintLayouts.getLayout(layoutName);
    if (layout == null) throw Exception('Invalid layout: $layoutName');

    final grid = PrintLayouts.calculateGrid(layoutName, template);
    final cols = grid['cols']!;
    final rows = grid['rows']!;

    // Load processed photo
    final photoBytes = await File(photoPath).readAsBytes();
    final photo = img.decodeImage(photoBytes);
    if (photo == null) throw Exception('Failed to load photo');

    // Create layout canvas
    final layoutWidth = (layout['width']! / 25.4 * dpi).toInt();
    final layoutHeight = (layout['height']! / 25.4 * dpi).toInt();

    final canvas = img.Image(
      width: layoutWidth,
      height: layoutHeight,
    );

    // Fill with white
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

    // Calculate photo placement
    final photoWidth = template.widthPixels(dpi);
    final photoHeight = template.heightPixels(dpi);
    final spacingX = ((layoutWidth - (cols * photoWidth)) / (cols + 1)).toInt();
    final spacingY = ((layoutHeight - (rows * photoHeight)) / (rows + 1)).toInt();

    // Resize photo to target size
    final resizedPhoto = img.copyResize(
      photo,
      width: photoWidth,
      height: photoHeight,
      interpolation: img.Interpolation.cubic,
    );

    // Place photos in grid
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final x = spacingX + col * (photoWidth + spacingX);
        final y = spacingY + row * (photoHeight + spacingY);

        img.compositeImage(
          canvas,
          resizedPhoto,
          dstX: x,
          dstY: y,
        );
      }
    }

    // Save layout
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'print_layout_${layoutName}_$timestamp.jpg';
    final filePath = '${directory.path}/$fileName';

    final jpegBytes = img.encodeJpg(canvas, quality: 95);
    await File(filePath).writeAsBytes(jpegBytes);

    return filePath;
  }

  /// Dispose resources
  static void dispose() {
    _faceDetector.close();
    _segmenter.close();
  }
}

/// Result of ID photo processing
class IdPhotoResult {
  final bool success;
  final String? imagePath;
  final IdPhotoTemplate? template;
  final bool faceDetected;
  final bool backgroundRemoved;
  final String? errorMessage;

  IdPhotoResult._({
    required this.success,
    this.imagePath,
    this.template,
    this.faceDetected = false,
    this.backgroundRemoved = false,
    this.errorMessage,
  });

  factory IdPhotoResult.success({
    required String imagePath,
    required IdPhotoTemplate template,
    required bool faceDetected,
    required bool backgroundRemoved,
  }) {
    return IdPhotoResult._(
      success: true,
      imagePath: imagePath,
      template: template,
      faceDetected: faceDetected,
      backgroundRemoved: backgroundRemoved,
    );
  }

  factory IdPhotoResult.error(String message) {
    return IdPhotoResult._(
      success: false,
      errorMessage: message,
    );
  }
}
