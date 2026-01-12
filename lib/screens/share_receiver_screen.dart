import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../providers/pdf_provider.dart';
import 'converter_screen.dart';

/// Share Receiver Screen
/// Handles files shared from other apps
class ShareReceiverScreen extends StatefulWidget {
  final List<SharedMediaFile> sharedFiles;
  
  const ShareReceiverScreen({
    super.key,
    required this.sharedFiles,
  });

  @override
  State<ShareReceiverScreen> createState() => _ShareReceiverScreenState();
}

class _ShareReceiverScreenState extends State<ShareReceiverScreen> {
  bool _isProcessing = false;
  late List<File> _imageFiles;
  late List<File> _pdfFiles;

  @override
  void initState() {
    super.initState();
    _categorizeFiles();
  }

  void _categorizeFiles() {
    _imageFiles = [];
    _pdfFiles = [];
    
    for (final file in widget.sharedFiles) {
      if (file.path != null) {
        final path = file.path!;
        if (_isImageFile(path)) {
          _imageFiles.add(File(path));
        } else if (path.toLowerCase().endsWith('.pdf')) {
          _pdfFiles.add(File(path));
        }
      }
    }
  }

  bool _isImageFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalFiles = _imageFiles.length + _pdfFiles.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Files'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Icon(
              Icons.share,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Received $totalFiles file(s)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_imageFiles.length} images, ${_pdfFiles.length} PDFs',
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),

            // File List
            Expanded(
              child: ListView(
                children: [
                  if (_imageFiles.isNotEmpty) ...[
                    _buildSectionTitle('Images'),
                    ...List.generate(_imageFiles.length, (i) => _buildFileItem(
                      _imageFiles[i],
                      Icons.image,
                      Colors.blue,
                    )),
                    const SizedBox(height: 16),
                  ],
                  if (_pdfFiles.isNotEmpty) ...[
                    _buildSectionTitle('PDFs'),
                    ...List.generate(_pdfFiles.length, (i) => _buildFileItem(
                      _pdfFiles[i],
                      Icons.picture_as_pdf,
                      Colors.red,
                    )),
                  ],
                ],
              ),
            ),

            // Action Buttons
            const SizedBox(height: 16),
            if (_imageFiles.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _convertToPdf,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf),
                  label: Text(_isProcessing 
                      ? 'Converting...' 
                      : 'Convert ${_imageFiles.length} Image(s) to PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildFileItem(File file, IconData icon, Color color) {
    final name = file.path.split('/').last;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: FutureBuilder<int>(
          future: file.length(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(_formatFileSize(snapshot.data!));
            }
            return const Text('...');
          },
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _convertToPdf() async {
    if (_imageFiles.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final provider = Provider.of<PdfProvider>(context, listen: false);
      
      // Add images to provider
      provider.addImages(_imageFiles);

      // Navigate to converter screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ConverterScreen(),
          ),
        );
      }

      _showToast('${_imageFiles.length} images added! Ready to convert.');
    } catch (e) {
      _showToast('Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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
