import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Service for OCR text extraction using Google ML Kit
class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Check if OCR is available
  Future<bool> isOcrAvailable() async {
    try {
      return true; // Always available now
    } catch (e) {
      debugPrint('OCR not available: $e');
      return false;
    }
  }

  /// Extract text from image file
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      debugPrint('Error extracting text: $e');
      return 'Error extracting text: $e';
    }
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}
