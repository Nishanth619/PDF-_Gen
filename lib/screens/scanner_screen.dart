import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../constants/strings.dart';
import '../models/pdf_file_model.dart';
import '../providers/pdf_provider.dart';
import '../utils/file_utils.dart';
import '../utils/pdf_utils.dart';
import '../utils/toast_helper.dart';

/// Screen for scanning documents using camera
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  /// Initialize camera
  Future<void> _initializeCamera() async {
    // Request camera permission
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ToastHelper.showError(context, 'Camera permission denied');
      });
      return;
    }

    // Request photos permission (for cropping) - this is optional so we don't block if denied
    final photosStatus = await Permission.photos.request();
    // We don't need to check the result here as it's optional for cropping

    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ToastHelper.showError(context, 'No camera found');
        });
        return;
      }

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(_flashMode);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ToastHelper.showError(context, 'Failed to initialize camera');
      });
    }
  }

  /// Toggle flash mode
  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    if (!_cameraController!.value.isInitialized) return;

    try {
      setState(() {
        _flashMode =
            _flashMode == FlashMode.off ? FlashMode.always : FlashMode.off;
      });
      await _cameraController!.setFlashMode(_flashMode);
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  /// Capture image
  Future<void> _captureImage() async {
    if (_isCapturing || !_isInitialized || _cameraController == null) return;
    if (!_cameraController!.value.isInitialized) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile photo = await _cameraController!.takePicture();
      final File capturedFile = File(photo.path);

      // Try to crop the image (optional)
      File? processedFile = capturedFile;

      // Check if we have photos permission, but don't request it here to avoid delay
      final photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted) {
        // Crop the image if permission granted
        final File? croppedFile = await _cropImage(capturedFile);
        if (croppedFile != null) {
          processedFile = croppedFile;
        }
      }
      // If permission is denied or not determined, we just use the original image without showing a message

      if (mounted) {
        // Copy to temp directory to ensure persistence
        final Directory tempDir = await FileUtils.getTempDirectory();
        final String fileName = FileUtils.generateFileName('scanned', '.jpg');
        final String tempPath = '${tempDir.path}/$fileName';

        final File tempFile = await processedFile.copy(tempPath);

        // Return the copied image to converter screen WITHOUT creating a PDF
        Navigator.of(context).pop(tempFile);
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ToastHelper.showError(context, 'Failed to capture image');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  /// Crop and resize captured image
  Future<File?> _cropImage(File imageFile) async {
    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust Image',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Theme.of(context).colorScheme.onPrimary,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            showCropGrid: true,
            hideBottomControls: false,
            cropFrameColor: Theme.of(context).colorScheme.primary,
            cropGridColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.5),
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.ratio3x2,
            ],
            // Enable resize options
            activeControlsWidgetColor: Theme.of(context).colorScheme.primary,
            dimmedLayerColor: Colors.black.withOpacity(0.7),
          ),
          IOSUiSettings(
            title: 'Adjust Image',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.ratio3x2,
            ],
            rectX: 0,
            rectY: 0,
            rectWidth: 0,
            rectHeight: 0,
            showActivitySheetOnDone: false,
            showCancelConfirmationDialog: true,
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return imageFile; // Return original if crop fails
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(AppStrings.scanDocument),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(
              _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
            ),
            onPressed: _toggleFlash,
            tooltip: 'Toggle Flash',
          ),
        ],
      ),
      body: _isInitialized &&
              _cameraController != null &&
              _cameraController!.value.isInitialized
          ? Stack(
              children: [
                // Camera preview
                Positioned.fill(
                  child: CameraPreview(_cameraController!),
                ),

                // Overlay guide
                Positioned.fill(
                  child: CustomPaint(
                    painter: DocumentOverlayPainter(
                      color: colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                ),

                // Instructions
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Position document within the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // Capture button
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _captureImage,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: colorScheme.primary,
                            width: 4,
                          ),
                        ),
                        child: _isCapturing
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              )
                            : Icon(
                                Icons.camera_alt,
                                size: 32,
                                color: colorScheme.primary,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

/// Custom painter for document overlay guide
class DocumentOverlayPainter extends CustomPainter {
  DocumentOverlayPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const double margin = 40;
    final Rect rect = Rect.fromLTRB(
      margin,
      size.height * 0.15,
      size.width - margin,
      size.height * 0.85,
    );

    // Draw rounded rectangle
    final RRect roundedRect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(12),
    );
    canvas.drawRRect(roundedRect, paint);

    // Draw corner markers
    const double cornerLength = 30;
    final Paint cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerLength),
      Offset(rect.left, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom - cornerLength),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
