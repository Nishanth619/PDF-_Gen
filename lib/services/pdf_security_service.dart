import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/pdf_file_model.dart';

/// PDF Security Service with encryption, decryption, and permission management
/// Optimized for performance with isolate-based processing
class PdfSecurityService {
  
  /// Permission flags for PDF security
  static const List<PdfPermissionItem> availablePermissions = [
    PdfPermissionItem(
      flag: PdfPermissionsFlags.print,
      name: 'Print',
      description: 'Allow printing the document',
      icon: 'print',
    ),
    PdfPermissionItem(
      flag: PdfPermissionsFlags.copyContent,
      name: 'Copy Content',
      description: 'Allow copying text and images',
      icon: 'copy',
    ),
    PdfPermissionItem(
      flag: PdfPermissionsFlags.editContent,
      name: 'Edit Content',
      description: 'Allow modifying document content',
      icon: 'edit',
    ),
    PdfPermissionItem(
      flag: PdfPermissionsFlags.fillFields,
      name: 'Fill Forms',
      description: 'Allow filling form fields',
      icon: 'form',
    ),
    PdfPermissionItem(
      flag: PdfPermissionsFlags.editAnnotations,
      name: 'Add Annotations',
      description: 'Allow adding comments and annotations',
      icon: 'comment',
    ),
  ];

  /// Encrypts a PDF file with password and permissions
  /// Uses isolate for better performance with large files
  Future<String?> encryptPdf({
    required String pdfPath,
    required String userPassword,
    String? ownerPassword,
    List<PdfPermissionsFlags> permissions = const [PdfPermissionsFlags.print],
    Function(double)? onProgress,
  }) async {
    try {
      onProgress?.call(0.1);
      
      final File source = File(pdfPath);
      if (!await source.exists()) {
        return null;
      }

      final List<int> sourceBytes = await source.readAsBytes();
      onProgress?.call(0.3);

      // Process in isolate for better performance
      final result = await compute(_encryptInIsolate, _EncryptParams(
        sourceBytes: sourceBytes,
        userPassword: userPassword,
        ownerPassword: ownerPassword ?? userPassword,
        permissions: permissions.map((p) => p.index).toList(),
      ));
      
      onProgress?.call(0.7);

      if (result == null) return null;

      // Generate encrypted file path
      final String fileName = pdfPath.split(Platform.pathSeparator).last;
      final String directory = pdfPath.substring(0, pdfPath.lastIndexOf(Platform.pathSeparator));
      final String encryptedFileName = 'encrypted_$fileName';
      final String encryptedPath = '$directory${Platform.pathSeparator}$encryptedFileName';

      // Write encrypted bytes
      final File target = File(encryptedPath);
      await target.writeAsBytes(result, flush: true);
      
      onProgress?.call(1.0);
      
      return await target.exists() ? encryptedPath : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error encrypting PDF: $e');
      }
      return null;
    }
  }

  /// Decrypts a PDF file by removing password protection
  Future<String?> decryptPdf({
    required String pdfPath,
    required String password,
    Function(double)? onProgress,
  }) async {
    try {
      onProgress?.call(0.1);
      
      final File source = File(pdfPath);
      if (!await source.exists()) {
        return null;
      }

      final List<int> sourceBytes = await source.readAsBytes();
      onProgress?.call(0.3);

      // Process in isolate
      final result = await compute(_decryptInIsolate, _DecryptParams(
        sourceBytes: sourceBytes,
        password: password,
      ));
      
      onProgress?.call(0.7);

      if (result == null) return null;

      // Generate decrypted file path
      final String fileName = pdfPath.split(Platform.pathSeparator).last;
      final String directory = pdfPath.substring(0, pdfPath.lastIndexOf(Platform.pathSeparator));
      
      // Remove 'encrypted_' prefix if present, otherwise add 'decrypted_'
      String decryptedFileName;
      if (fileName.startsWith('encrypted_')) {
        decryptedFileName = fileName.substring(10); // Remove 'encrypted_'
      } else {
        decryptedFileName = 'decrypted_$fileName';
      }
      
      final String decryptedPath = '$directory${Platform.pathSeparator}$decryptedFileName';

      // Write decrypted bytes
      final File target = File(decryptedPath);
      await target.writeAsBytes(result, flush: true);
      
      onProgress?.call(1.0);
      
      return await target.exists() ? decryptedPath : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error decrypting PDF: $e');
      }
      return null;
    }
  }

  /// Check if a PDF is password protected
  Future<PdfSecurityInfo> checkPdfSecurity(String pdfPath) async {
    try {
      final File file = File(pdfPath);
      if (!await file.exists()) {
        return PdfSecurityInfo(
          isProtected: false,
          canOpen: false,
          errorMessage: 'File not found',
        );
      }

      final bytes = await file.readAsBytes();
      
      try {
        final PdfDocument document = PdfDocument(inputBytes: bytes);
        final security = document.security;
        
        // Check if it has any security
        final bool hasUserPassword = security.userPassword.isNotEmpty;
        final bool hasOwnerPassword = security.ownerPassword.isNotEmpty;
        
        final info = PdfSecurityInfo(
          isProtected: hasUserPassword || hasOwnerPassword,
          canOpen: true,
          hasUserPassword: hasUserPassword,
          hasOwnerPassword: hasOwnerPassword,
        );
        
        document.dispose();
        return info;
      } catch (e) {
        // PDF is encrypted and cannot be opened without password
        return PdfSecurityInfo(
          isProtected: true,
          canOpen: false,
          needsPassword: true,
        );
      }
    } catch (e) {
      return PdfSecurityInfo(
        isProtected: false,
        canOpen: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Create a PdfFileModel for the processed PDF
  PdfFileModel createPdfModel(String path) {
    final File file = File(path);
    final String fileName = path.split(Platform.pathSeparator).last;
    
    return PdfFileModel(
      name: fileName,
      path: path,
      size: file.existsSync() ? file.lengthSync() : 0,
    );
  }

  /// Calculate password strength (0.0 - 1.0)
  static PasswordStrength calculatePasswordStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength(score: 0, label: 'Enter password', color: 0xFF9E9E9E);
    }

    double score = 0;
    
    // Length scoring
    if (password.length >= 6) score += 0.15;
    if (password.length >= 8) score += 0.15;
    if (password.length >= 12) score += 0.1;
    if (password.length >= 16) score += 0.1;
    
    // Character variety
    if (password.contains(RegExp(r'[a-z]'))) score += 0.1;
    if (password.contains(RegExp(r'[A-Z]'))) score += 0.1;
    if (password.contains(RegExp(r'[0-9]'))) score += 0.15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 0.15;
    
    // Clamp to 1.0
    score = score.clamp(0.0, 1.0);

    if (score < 0.3) {
      return PasswordStrength(score: score, label: 'Weak', color: 0xFFF44336);
    } else if (score < 0.6) {
      return PasswordStrength(score: score, label: 'Fair', color: 0xFFFF9800);
    } else if (score < 0.8) {
      return PasswordStrength(score: score, label: 'Good', color: 0xFF2196F3);
    } else {
      return PasswordStrength(score: score, label: 'Strong', color: 0xFF4CAF50);
    }
  }
}

/// Isolate function for encryption
List<int>? _encryptInIsolate(_EncryptParams params) {
  try {
    final PdfDocument document = PdfDocument(inputBytes: params.sourceBytes);
    
    final PdfSecurity security = document.security;
    security.userPassword = params.userPassword;
    security.ownerPassword = params.ownerPassword;
    security.algorithm = PdfEncryptionAlgorithm.aesx256Bit;
    
    // Set permissions
    security.permissions.clear();
    for (final permIndex in params.permissions) {
      security.permissions.add(PdfPermissionsFlags.values[permIndex]);
    }
    
    final List<int> bytes = document.saveSync();
    document.dispose();
    
    return bytes;
  } catch (e) {
    return null;
  }
}

/// Isolate function for decryption
List<int>? _decryptInIsolate(_DecryptParams params) {
  try {
    // Load with password
    final PdfDocument document = PdfDocument(
      inputBytes: params.sourceBytes,
      password: params.password,
    );
    
    // Remove security
    document.security.userPassword = '';
    document.security.ownerPassword = '';
    document.security.permissions.clear();
    // Add all permissions back
    document.security.permissions.addAll([
      PdfPermissionsFlags.print,
      PdfPermissionsFlags.copyContent,
      PdfPermissionsFlags.editContent,
      PdfPermissionsFlags.fillFields,
      PdfPermissionsFlags.editAnnotations,
    ]);
    
    final List<int> bytes = document.saveSync();
    document.dispose();
    
    return bytes;
  } catch (e) {
    return null;
  }
}

/// Parameters for encryption isolate
class _EncryptParams {
  final List<int> sourceBytes;
  final String userPassword;
  final String ownerPassword;
  final List<int> permissions;

  _EncryptParams({
    required this.sourceBytes,
    required this.userPassword,
    required this.ownerPassword,
    required this.permissions,
  });
}

/// Parameters for decryption isolate
class _DecryptParams {
  final List<int> sourceBytes;
  final String password;

  _DecryptParams({
    required this.sourceBytes,
    required this.password,
  });
}

/// Permission item definition
class PdfPermissionItem {
  final PdfPermissionsFlags flag;
  final String name;
  final String description;
  final String icon;

  const PdfPermissionItem({
    required this.flag,
    required this.name,
    required this.description,
    required this.icon,
  });
}

/// PDF security information
class PdfSecurityInfo {
  final bool isProtected;
  final bool canOpen;
  final bool hasUserPassword;
  final bool hasOwnerPassword;
  final bool needsPassword;
  final List<String> permissions;
  final String? errorMessage;

  PdfSecurityInfo({
    required this.isProtected,
    required this.canOpen,
    this.hasUserPassword = false,
    this.hasOwnerPassword = false,
    this.needsPassword = false,
    this.permissions = const [],
    this.errorMessage,
  });
}

/// Password strength result
class PasswordStrength {
  final double score;
  final String label;
  final int color;

  PasswordStrength({
    required this.score,
    required this.label,
    required this.color,
  });
}