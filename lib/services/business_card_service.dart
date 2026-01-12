import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Business Card Scanner Service
/// Extracts contact information from business card images using OCR
class BusinessCardService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract contact info from a business card image
  static Future<ContactInfo> extractContactInfo(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return _parseContactInfo(recognizedText.text);
    } catch (e) {
      debugPrint('Error extracting contact info: $e');
      return ContactInfo();
    }
  }

  /// Parse text to extract contact information
  static ContactInfo _parseContactInfo(String text) {
    final contact = ContactInfo();
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    
    for (final line in lines) {
      // Extract email
      if (contact.email == null) {
        final emailMatch = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+').firstMatch(line);
        if (emailMatch != null) {
          contact.email = emailMatch.group(0);
          continue;
        }
      }
      
      // Extract phone numbers
      if (contact.phone == null) {
        final phoneMatch = RegExp(r'[\+]?[(]?[0-9]{2,4}[)]?[-\s\.]?[0-9]{2,4}[-\s\.]?[0-9]{4,6}').firstMatch(line);
        if (phoneMatch != null) {
          contact.phone = phoneMatch.group(0)?.replaceAll(RegExp(r'[^\d+]'), '');
          if (contact.phone != null && contact.phone!.length >= 10) {
            continue;
          } else {
            contact.phone = null;
          }
        }
      }
      
      // Extract website
      if (contact.website == null) {
        final websiteMatch = RegExp(r'(www\.)?[\w-]+\.(com|org|net|io|co|in|edu|gov)[\w./]*', caseSensitive: false).firstMatch(line);
        if (websiteMatch != null) {
          String website = websiteMatch.group(0)!;
          if (!website.startsWith('www.') && !website.contains('://')) {
            website = 'www.$website';
          }
          contact.website = website;
          continue;
        }
      }
      
      // Extract company name (usually has keywords)
      if (contact.company == null) {
        final companyKeywords = ['ltd', 'llc', 'inc', 'corp', 'pvt', 'private', 'limited', 'technologies', 'solutions', 'services', 'group', 'company'];
        if (companyKeywords.any((keyword) => line.toLowerCase().contains(keyword))) {
          contact.company = line;
          continue;
        }
      }
      
      // First non-matched line with 2+ words is likely the name
      if (contact.name == null && !line.contains('@') && !RegExp(r'\d{5,}').hasMatch(line)) {
        final words = line.split(' ').where((w) => w.length > 1).toList();
        if (words.length >= 2 && words.length <= 4) {
          // Check if words look like a name (capitalized)
          if (words.every((w) => w[0] == w[0].toUpperCase())) {
            contact.name = line;
            continue;
          }
        }
      }
    }
    
    // If no name found, use first reasonable line
    if (contact.name == null && lines.isNotEmpty) {
      for (final line in lines) {
        if (!line.contains('@') && 
            !RegExp(r'\d{5,}').hasMatch(line) &&
            line.length < 40) {
          contact.name = line;
          break;
        }
      }
    }
    
    contact.rawText = text;
    return contact;
  }

  /// Dispose resources
  static void dispose() {
    _textRecognizer.close();
  }
}

/// Contact information extracted from business card
class ContactInfo {
  String? name;
  String? phone;
  String? email;
  String? company;
  String? website;
  String? jobTitle;
  String? address;
  String? rawText;

  bool get isEmpty => 
      name == null && 
      phone == null && 
      email == null && 
      company == null && 
      website == null;

  @override
  String toString() {
    return '''ContactInfo(
  name: $name,
  phone: $phone,
  email: $email,
  company: $company,
  website: $website
)''';
  }
}
