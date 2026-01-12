import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to store and retrieve password hints for encrypted PDFs
class PasswordHintService {
  static const String _hintsKey = 'pdf_password_hints';
  
  /// Save a password hint for a PDF file
  static Future<void> saveHint(String pdfPath, String hint) async {
    if (hint.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final hintsJson = prefs.getString(_hintsKey);
    
    Map<String, String> hints = {};
    if (hintsJson != null) {
      hints = Map<String, String>.from(jsonDecode(hintsJson));
    }
    
    // Use the filename as key (more reliable than full path which may change)
    final fileName = _getFileName(pdfPath);
    hints[fileName] = hint;
    
    await prefs.setString(_hintsKey, jsonEncode(hints));
  }
  
  /// Get password hint for a PDF file
  static Future<String?> getHint(String pdfPath) async {
    final prefs = await SharedPreferences.getInstance();
    final hintsJson = prefs.getString(_hintsKey);
    
    if (hintsJson == null) return null;
    
    final hints = Map<String, String>.from(jsonDecode(hintsJson));
    final fileName = _getFileName(pdfPath);
    
    return hints[fileName];
  }
  
  /// Remove password hint for a PDF file (when decrypted)
  static Future<void> removeHint(String pdfPath) async {
    final prefs = await SharedPreferences.getInstance();
    final hintsJson = prefs.getString(_hintsKey);
    
    if (hintsJson == null) return;
    
    final hints = Map<String, String>.from(jsonDecode(hintsJson));
    final fileName = _getFileName(pdfPath);
    
    hints.remove(fileName);
    
    await prefs.setString(_hintsKey, jsonEncode(hints));
  }
  
  /// Check if a hint exists for a PDF
  static Future<bool> hasHint(String pdfPath) async {
    final hint = await getHint(pdfPath);
    return hint != null && hint.isNotEmpty;
  }
  
  /// Get filename from path
  static String _getFileName(String path) {
    // Handle both forward and backward slashes
    final parts = path.replaceAll('\\', '/').split('/');
    return parts.last;
  }
  
  /// Clear all stored hints
  static Future<void> clearAllHints() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hintsKey);
  }
}
