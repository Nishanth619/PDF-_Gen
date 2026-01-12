import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../constants/strings.dart';
import '../providers/pdf_provider.dart';
import '../services/image_enhancement_service.dart';
import '../utils/file_utils.dart';
import '../utils/toast_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/progress_dialog.dart';
import 'native_scanner_screen.dart';
import '../widgets/modern_ui_components.dart';
import '../services/ad_service.dart';
import '../widgets/banner_ad_widget.dart';

/// Screen for selecting and converting images to PDF
class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  /// Request storage permission
  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await Permission.storage.status;

      if (androidInfo.isGranted) {
        return true;
      }

      // For Android 13+, use photos permission
      if (await Permission.photos.isGranted) {
        return true;
      }

      final result = await Permission.photos.request();
      if (result.isGranted) {
        return true;
      }

      // Fallback to storage permission
      final storageResult = await Permission.storage.request();
      return storageResult.isGranted;
    }
    return true;
  }

  /// Pick images from gallery
  Future<void> _pickImages() async {
    final bool hasPermission = await _requestPermission();
    if (!hasPermission) {
      if (mounted) {
        ToastHelper.showError(context, 'Storage permission required');
      }
      return;
    }

    try {
      final List<XFile> pickedFiles = await ImagePicker().pickMultiImage();
      if (pickedFiles.isNotEmpty && mounted) {
        final List<File> files = pickedFiles.map((file) => File(file.path)).toList();
        context.read<PdfProvider>().addImages(files);
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Failed to pick images');
      }
    }
  }

  /// Open scanner
  Future<void> _openScanner() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      ToastHelper.showError(context, AppStrings.cameraPermissionRequired);
      return;
    }

    if (mounted) {
      final File? scannedImage = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => const NativeScannerScreen(),
        ),
      );

      if (scannedImage != null && mounted) {
        context.read<PdfProvider>().addImages([scannedImage]);
        ToastHelper.showSuccess(context, 'Scanned image added');
      }
    }
  }

  /// Enhance a single image
  Future<void> _enhanceImage(int index, EnhanceMode mode) async {
    final provider = context.read<PdfProvider>();
    final image = provider.selectedImages[index];

    try {
      ToastHelper.showInfo(context, 'Enhancing image...');
      
      final enhancedPath = await ImageEnhancementService.quickEnhance(
        image.path,
        mode,
      );

      // Replace the image in the list
      provider.replaceImage(index, File(enhancedPath));
      
      if (mounted) {
        ToastHelper.showSuccess(context, 'Image enhanced!');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Enhancement failed: $e');
      }
    }
  }

  /// Enhance all images
  Future<void> _enhanceAllImages(EnhanceMode mode) async {
    final provider = context.read<PdfProvider>();
    if (provider.selectedImages.isEmpty) return;

    try {
      ToastHelper.showInfo(context, 'Enhancing all images...');

      for (int i = 0; i < provider.selectedImages.length; i++) {
        final image = provider.selectedImages[i];
        final enhancedPath = await ImageEnhancementService.quickEnhance(
          image.path,
          mode,
        );
        provider.replaceImage(i, File(enhancedPath));
      }

      if (mounted) {
        ToastHelper.showSuccess(context, 'All images enhanced!');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showError(context, 'Enhancement failed: $e');
      }
    }
  }

  /// Convert images to PDF
  Future<void> _convertToPdf() async {
    final provider = context.read<PdfProvider>();

    if (provider.selectedImages.isEmpty) {
      ToastHelper.showError(context, AppStrings.selectAtLeastOne);
      return;
    }

    // Generate filename
    final String fileName = FileUtils.generateUniqueFilename();

    // Show progress dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Consumer<PdfProvider>(
          builder: (context, provider, child) {
            return ProgressDialog(
              progress: provider.conversionProgress,
              message: AppStrings.converting,
            );
          },
        ),
      );
    }

    // Convert
    final result = await provider.convertToPdf(fileName, context); // Pass context

    // Hide progress dialog
    if (mounted) {
      Navigator.of(context).pop();
    }

    // Show result
    if (result != null) {
      // Insert PDF to database
      final inserted = await provider.insertPdf(result);
      if (inserted) {
        // Add to recent activity
        await provider.addRecentActivity(result.id, 'created');

        // Clear selected images after successful conversion
        provider.clearImages();
        ToastHelper.showSuccess(context, AppStrings.conversionSuccess);
        
        // Show interstitial ad after successful conversion
        AdService().trackFeatureCompletion();
      } else {
        ToastHelper.showError(context, 'Failed to save PDF to history');
      }
    } else {
      ToastHelper.showError(context, AppStrings.conversionFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        centerTitle: true,
        actions: [
          const HelpIconButton(
            title: 'Convert to PDF',
            icon: Icons.picture_as_pdf,
            iconColor: Color(0xFF3B82F6),
            helpText: 'How to convert images to PDF:\n\n'
                '1. Tap "Select Images" to pick from gallery\n'
                '2. Or tap "Camera" to take photos\n'
                '3. Reorder images by long-pressing and dragging\n'
                '4. Tap "Convert" to create your PDF\n\n'
                'Tip: You can also enhance images before converting!',
          ),
          Consumer<PdfProvider>(
            builder: (context, provider, child) {
              if (provider.selectedImages.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.clear_all),
                tooltip: AppStrings.clear,
                onPressed: () {
                  provider.clearImages();
                  ToastHelper.showInfo(context, 'All images cleared');
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<PdfProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Image count header
              if (provider.selectedImages.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: colorScheme.primaryContainer,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${provider.selectedImages.length} ${provider.selectedImages.length == 1 ? 'image' : 'images'} selected',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          provider.clearImages();
                          ToastHelper.showInfo(context, 'All images cleared');
                        },
                        child: Text(
                          AppStrings.clear,
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Image preview grid
              if (provider.selectedImages.isNotEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: provider.selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(provider.selectedImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => provider.removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

              // Empty state
              if (provider.selectedImages.isEmpty)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.picture_as_pdf_outlined,
                        size: 64,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.noImagesSelected,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.tapToSelect,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.outline,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              // Enhancement options (when images are selected)
              if (provider.selectedImages.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_fix_high, size: 16, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'AI Enhance',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildEnhanceChip(
                            'Auto',
                            Icons.auto_awesome,
                            () => _enhanceAllImages(EnhanceMode.auto),
                            colorScheme,
                          ),
                          _buildEnhanceChip(
                            'Sharpen',
                            Icons.blur_linear,
                            () => _enhanceAllImages(EnhanceMode.sharpen),
                            colorScheme,
                          ),
                          _buildEnhanceChip(
                            'Brighten',
                            Icons.wb_sunny,
                            () => _enhanceAllImages(EnhanceMode.brighten),
                            colorScheme,
                          ),
                          _buildEnhanceChip(
                            'Document',
                            Icons.description,
                            () => _enhanceAllImages(EnhanceMode.document),
                            colorScheme,
                          ),
                          _buildEnhanceChip(
                            'B&W',
                            Icons.filter_b_and_w,
                            () => _enhanceAllImages(EnhanceMode.grayscale),
                            colorScheme,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            onPressed: _pickImages,
                            text: AppStrings.selectImages,
                            icon: Icons.add_photo_alternate_outlined,
                            isOutlined: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            onPressed: _openScanner,
                            text: AppStrings.scanDocument,
                            icon: Icons.camera_alt_outlined,
                            isOutlined: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        onPressed: _convertToPdf,
                        text: AppStrings.convertToPdf,
                        icon: Icons.picture_as_pdf,
                        isLoading: provider.isLoading,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Banner Ad at bottom
              const BannerAdWidget(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEnhanceChip(
    String label,
    IconData icon,
    VoidCallback onTap,
    ColorScheme colorScheme,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: colorScheme.primary),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: colorScheme.primaryContainer.withOpacity(0.3),
      side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
    );
  }
}