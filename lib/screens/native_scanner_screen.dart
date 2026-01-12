import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/strings.dart';
import '../utils/file_utils.dart';
import '../utils/toast_helper.dart';

/// Document scanner screen using native edge detection
/// Uses Google ML Kit Document Scanner on Android and VisionKit on iOS
class NativeScannerScreen extends StatefulWidget {
  const NativeScannerScreen({super.key});

  @override
  State<NativeScannerScreen> createState() => _NativeScannerScreenState();
}

class _NativeScannerScreenState extends State<NativeScannerScreen> {
  bool _isScanning = false;
  String _statusMessage = 'Initializing scanner...';

  @override
  void initState() {
    super.initState();
    // Automatically start scanner when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScanner();
    });
  }

  /// Start the document scanner
  Future<void> _startScanner() async {
    if (_isScanning) return;

    // Request camera permission first
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      if (mounted) {
        ToastHelper.showError(context, AppStrings.cameraPermissionRequired);
        Navigator.of(context).pop();
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _statusMessage = 'Opening scanner...';
    });

    try {
      // Try Google ML Kit Document Scanner first (Android only, better UI)
      if (Platform.isAndroid) {
        await _startGoogleMLKitScanner();
      } else {
        // iOS: Use cunning_document_scanner (uses VisionKit)
        await _startCunningScanner();
      }
    } catch (e) {
      debugPrint('Primary scanner failed: $e');
      // Fallback to cunning_document_scanner
      try {
        await _startCunningScanner();
      } catch (e2) {
        debugPrint('Fallback scanner also failed: $e2');
        if (mounted) {
          ToastHelper.showError(context, 'Failed to open scanner');
          Navigator.of(context).pop();
        }
      }
    }
  }

  /// Use Google ML Kit Document Scanner (Android only)
  /// Provides full native UI with edge detection overlay
  Future<void> _startGoogleMLKitScanner() async {
    setState(() {
      _statusMessage = 'Opening Google Document Scanner...';
    });

    // Configure the document scanner
    final documentScannerOptions = DocumentScannerOptions(
      documentFormat: DocumentFormat.jpeg,
      mode: ScannerMode.full, // Full mode with edge detection UI
      pageLimit: 1, // Single page
      isGalleryImport: true, // Allow gallery import
    );

    final documentScanner = DocumentScanner(options: documentScannerOptions);

    try {
      // Start the scanner - this opens the native Google UI
      final DocumentScanningResult result = await documentScanner.scanDocument();

      if (result.images.isNotEmpty) {
        // Got scanned image(s)
        final String scannedPath = result.images.first;
        final File scannedFile = File(scannedPath);

        if (mounted) {
          // Copy to app's temp directory for persistence
          final Directory tempDir = await FileUtils.getTempDirectory();
          final String fileName = FileUtils.generateFileName('scanned', '.jpg');
          final String tempPath = '${tempDir.path}/$fileName';
          final File tempFile = await scannedFile.copy(tempPath);

          Navigator.of(context).pop(tempFile);
        }
      } else {
        // User cancelled
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } finally {
      documentScanner.close();
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  /// Use cunning_document_scanner as fallback
  Future<void> _startCunningScanner() async {
    setState(() {
      _statusMessage = 'Opening document scanner...';
    });

    // Launch cunning document scanner
    final List<String>? scannedImages = await CunningDocumentScanner.getPictures(
      noOfPages: 1,
      isGalleryImportAllowed: true,
    );

    if (scannedImages != null && scannedImages.isNotEmpty) {
      if (mounted) {
        final File scannedFile = File(scannedImages.first);

        // Copy to app's temp directory for persistence
        final Directory tempDir = await FileUtils.getTempDirectory();
        final String fileName = FileUtils.generateFileName('scanned', '.jpg');
        final String tempPath = '${tempDir.path}/$fileName';
        final File tempFile = await scannedFile.copy(tempPath);

        Navigator.of(context).pop(tempFile);
      }
    } else {
      // User cancelled
      if (mounted) {
        Navigator.of(context).pop();
      }
    }

    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(AppStrings.scanDocument),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isScanning) ...[
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 24),
              Text(
                _statusMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  '• Position document within the frame\n'
                  '• The scanner will auto-detect edges\n'
                  '• Hold steady for auto-capture',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ] else ...[
              const Icon(
                Icons.document_scanner,
                size: 64,
                color: Colors.white54,
              ),
              const SizedBox(height: 24),
              const Text(
                'Scanner ready',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _startScanner,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Start Scanning'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
