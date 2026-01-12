import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/pdf_provider.dart';
import '../services/book_scanner_service.dart';
import '../services/image_enhancement_service.dart';
import 'native_scanner_screen.dart';
import '../widgets/modern_ui_components.dart';
import '../widgets/banner_ad_widget.dart';

/// Available scanning modes
enum ScanMode {
  document,
  book,
  whiteboard,
  blackboard,
}

/// Advanced Scanner with multiple modes
/// - Document: Standard document scanning
/// - Book: Two-page detection, auto-split, curve flattening
/// - Whiteboard: Glare removal, text enhancement
/// - Blackboard: Color inversion, chalk enhancement
class ScannerModesScreen extends StatefulWidget {
  const ScannerModesScreen({super.key});

  @override
  State<ScannerModesScreen> createState() => _ScannerModesScreenState();
}

class _ScannerModesScreenState extends State<ScannerModesScreen> {
  final ImagePicker _picker = ImagePicker();
  ScanMode _selectedMode = ScanMode.document;
  bool _isProcessing = false;
  List<String> _scannedPages = [];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Scanner'),
        centerTitle: true,
        actions: [
          const HelpIconButton(
            title: 'Advanced Scanner',
            icon: Icons.document_scanner_outlined,
            iconColor: Color(0xFF6366F1),
            helpText: 'Scanner Modes:\n\n'
                'Document: Standard scanning with edge detection\n'
                'Book: Auto-splits open book pages into separate scans\n'
                'Whiteboard: Enhances colors for clear whiteboard capture\n'
                'Blackboard: Optimized for chalk on dark surfaces\n\n'
                'Tips: Hold device parallel to document. Good lighting helps!',
          ),
          if (_scannedPages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearPages,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: Column(
        children: [
          // Mode Selector
          _buildModeSelector(colorScheme),
          
          // Mode description
          _buildModeDescription(colorScheme),
          
          const Divider(),
          
          // Scanned pages preview
          Expanded(
            child: _scannedPages.isEmpty
                ? _buildEmptyState(colorScheme)
                : _buildPagesGrid(),
          ),
          
          // Banner Ad
          const BannerAdWidget(),
          
          // Action Buttons
          _buildActionButtons(colorScheme),
        ],
      ),
    );
  }

  Widget _buildModeSelector(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ScanMode.values.map((mode) {
          final isSelected = _selectedMode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedMode = mode),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : Theme.of(context).dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getModeIcon(mode),
                      color: isSelected
                          ? colorScheme.primary
                          : Theme.of(context).iconTheme.color,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getModeName(mode),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? colorScheme.primary
                            : Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModeDescription(ColorScheme colorScheme) {
    String description;
    IconData icon;
    Color color;

    switch (_selectedMode) {
      case ScanMode.document:
        description = 'Standard document scanning with auto-enhancement';
        icon = Icons.description;
        color = Colors.blue;
        break;
      case ScanMode.book:
        description = 'Scan two pages at once, auto-split & flatten curves';
        icon = Icons.menu_book;
        color = Colors.orange;
        break;
      case ScanMode.whiteboard:
        description = 'Remove glare, enhance text & clean background';
        icon = Icons.dashboard;
        color = Colors.green;
        break;
      case ScanMode.blackboard:
        description = 'Invert colors, enhance chalk writing visibility';
        icon = Icons.square;
        color = Colors.grey.shade800;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getModeIcon(_selectedMode),
            size: 80,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No pages scanned yet',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the camera button to start scanning',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _scannedPages.length,
      itemBuilder: (context, index) {
        return _buildPageCard(index);
      },
    );
  }

  Widget _buildPageCard(int index) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(_scannedPages[index]),
            fit: BoxFit.cover,
          ),
          // Page number badge
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Page ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Delete button
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.8),
                padding: const EdgeInsets.all(4),
              ),
              iconSize: 18,
              onPressed: () => _removePage(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Camera button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _scanWithCamera,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(_isProcessing ? 'Processing...' : 'Scan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Gallery button
            ElevatedButton(
              onPressed: _isProcessing ? null : _pickFromGallery,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
              ),
              child: const Icon(Icons.photo_library),
            ),
            if (_scannedPages.isNotEmpty) ...[
              const SizedBox(width: 12),
              // Create PDF button
              ElevatedButton(
                onPressed: _isProcessing ? null : _createPdf,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Icon(Icons.picture_as_pdf),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getModeIcon(ScanMode mode) {
    switch (mode) {
      case ScanMode.document:
        return Icons.description;
      case ScanMode.book:
        return Icons.menu_book;
      case ScanMode.whiteboard:
        return Icons.dashboard;
      case ScanMode.blackboard:
        return Icons.square;
    }
  }

  String _getModeName(ScanMode mode) {
    switch (mode) {
      case ScanMode.document:
        return 'Document';
      case ScanMode.book:
        return 'Book';
      case ScanMode.whiteboard:
        return 'Whiteboard';
      case ScanMode.blackboard:
        return 'Blackboard';
    }
  }

  Future<void> _scanWithCamera() async {
    final result = await Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (_) => const NativeScannerScreen()),
    );

    if (result != null) {
      await _processScannedImage(result.path);
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 95,
    );

    if (image != null) {
      await _processScannedImage(image.path);
    }
  }

  Future<void> _processScannedImage(String imagePath) async {
    setState(() => _isProcessing = true);

    try {
      List<String> processedPaths = [];

      switch (_selectedMode) {
        case ScanMode.document:
          // Standard document enhancement
          final enhanced = await ImageEnhancementService.enhanceDocument(imagePath);
          processedPaths.add(enhanced);
          break;

        case ScanMode.book:
          // Book scanning - detect and split pages
          final splitPoint = await BookScannerService.detectTwoPages(imagePath);
          
          if (splitPoint != null) {
            // Two pages detected - split them
            final pages = await BookScannerService.splitPages(imagePath, splitPoint: splitPoint);
            
            // Just enhance each page (skip slow curve flattening for speed)
            for (final page in pages) {
              final processed = await BookScannerService.enhanceBookPage(page);
              processedPaths.add(processed);
            }
            
            _showToast('Split into ${pages.length} pages!');
          } else {
            // Single page - just enhance
            final enhanced = await BookScannerService.enhanceBookPage(imagePath);
            processedPaths.add(enhanced);
          }
          break;

        case ScanMode.whiteboard:
          // Whiteboard enhancement
          final enhanced = await ImageEnhancementService.enhanceWhiteboard(imagePath);
          processedPaths.add(enhanced);
          break;

        case ScanMode.blackboard:
          // Blackboard enhancement
          final enhanced = await ImageEnhancementService.enhanceBlackboard(imagePath);
          processedPaths.add(enhanced);
          break;
      }

      setState(() {
        _scannedPages.addAll(processedPaths);
      });

      _showToast('Page(s) added successfully!');
    } catch (e) {
      _showToast('Error processing image: $e', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _removePage(int index) {
    setState(() {
      _scannedPages.removeAt(index);
    });
  }

  void _clearPages() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Pages?'),
        content: const Text('This will remove all scanned pages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _scannedPages.clear());
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _createPdf() async {
    if (_scannedPages.isEmpty) return;

    // Show filename dialog
    final fileName = await _showFileNameDialog();
    if (fileName == null || fileName.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final provider = Provider.of<PdfProvider>(context, listen: false);
      
      // Add scanned pages to provider
      final files = _scannedPages.map((path) => File(path)).toList();
      provider.addImages(files);
      
      // Create PDF directly
      final result = await provider.convertToPdf(fileName, context);
      
      if (result != null) {
        // Insert to database
        await provider.insertPdf(result);
        await provider.addRecentActivity(result.id, 'created');
        
        // Clear images after success
        provider.clearImages();
        
        // Show success dialog with options
        if (mounted) {
          _showPdfCreatedDialog(result.path, result.name);
        }
        
        // Clear scanned pages
        setState(() => _scannedPages.clear());
      } else {
        _showToast('Failed to create PDF', isError: true);
      }
    } catch (e) {
      _showToast('Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<String?> _showFileNameDialog() async {
    final now = DateTime.now();
    final controller = TextEditingController(
      text: 'Scan_${now.day}_${now.month}_${now.year}_${now.hour}${now.minute}${now.second}',
    );
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save PDF'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_scannedPages.length} page(s) will be saved'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'File Name',
                border: OutlineInputBorder(),
                suffixText: '.pdf',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, controller.text),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Create PDF'),
          ),
        ],
      ),
    );
  }

  void _showPdfCreatedDialog(String pdfPath, String pdfName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('PDF Created!'),
        content: Text('$pdfName.pdf has been saved successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _sharePdf(pdfPath);
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openPdf(pdfPath);
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open'),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePdf(String pdfPath) async {
    try {
      await Share.shareXFiles([XFile(pdfPath)]);
    } catch (e) {
      _showToast('Error sharing: $e', isError: true);
    }
  }

  Future<void> _openPdf(String pdfPath) async {
    try {
      await OpenFilex.open(pdfPath);
    } catch (e) {
      _showToast('Error opening: $e', isError: true);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
    );
  }
}
