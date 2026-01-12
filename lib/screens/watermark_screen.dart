import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../services/watermark_service.dart';
import '../widgets/modern_ui_components.dart';
import '../widgets/banner_ad_widget.dart';

/// Watermark Screen
/// Add text watermarks to PDF documents
class WatermarkScreen extends StatefulWidget {
  const WatermarkScreen({super.key});

  @override
  State<WatermarkScreen> createState() => _WatermarkScreenState();
}

class _WatermarkScreenState extends State<WatermarkScreen> {
  String? _selectedPdfPath;
  String? _selectedPdfName;
  final _textController = TextEditingController(text: 'CONFIDENTIAL');
  double _opacity = 0.3;
  double _fontSize = 48;
  WatermarkPosition _position = WatermarkPosition.center;
  bool _diagonal = true;
  bool _repeating = false;
  bool _isProcessing = false;
  String? _resultPath;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Watermark'),
        centerTitle: true,
        actions: const [
          HelpIconButton(
            title: 'Watermark',
            icon: Icons.water_drop_outlined,
            iconColor: Color(0xFF06B6D4),
            helpText: 'Add Watermarks to PDFs:\n\n'
                '1. Select a PDF file\n'
                '2. Enter watermark text (e.g., CONFIDENTIAL)\n'
                '3. Adjust opacity and font size\n'
                '4. Choose position or enable diagonal\n'
                '5. Enable "Repeating" to cover entire page\n'
                '6. Tap "Apply Watermark" to save\n\n'
                'Perfect for marking documents as drafts or confidential!',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select PDF
            _buildSectionTitle('1. Select PDF'),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.picture_as_pdf,
                  color: _selectedPdfPath != null ? Colors.red : Colors.grey,
                  size: 40,
                ),
                title: Text(_selectedPdfName ?? 'No PDF selected'),
                subtitle: Text(_selectedPdfPath != null ? 'Tap to change' : 'Tap to select'),
                trailing: const Icon(Icons.folder_open),
                onTap: _pickPdf,
              ),
            ),
            const SizedBox(height: 24),

            // Watermark Text
            _buildSectionTitle('2. Watermark Text'),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Watermark Text',
                border: OutlineInputBorder(),
                hintText: 'e.g., CONFIDENTIAL, DRAFT, COPY',
              ),
            ),
            const SizedBox(height: 24),

            // Watermark Options
            _buildSectionTitle('3. Options'),
            Card(
              child: Column(
                children: [
                  // Opacity
                  ListTile(
                    leading: const Icon(Icons.opacity),
                    title: const Text('Opacity'),
                    subtitle: Slider(
                      value: _opacity,
                      min: 0.1,
                      max: 0.8,
                      divisions: 7,
                      label: '${(_opacity * 100).toInt()}%',
                      onChanged: (value) => setState(() => _opacity = value),
                    ),
                    trailing: Text('${(_opacity * 100).toInt()}%'),
                  ),
                  
                  // Font Size
                  ListTile(
                    leading: const Icon(Icons.format_size),
                    title: const Text('Font Size'),
                    subtitle: Slider(
                      value: _fontSize,
                      min: 24,
                      max: 96,
                      divisions: 6,
                      label: '${_fontSize.toInt()}',
                      onChanged: (value) => setState(() => _fontSize = value),
                    ),
                    trailing: Text('${_fontSize.toInt()}'),
                  ),
                  
                  // Position
                  ListTile(
                    leading: const Icon(Icons.grid_view),
                    title: const Text('Position'),
                    trailing: DropdownButton<WatermarkPosition>(
                      value: _position,
                      onChanged: (value) {
                        if (value != null) setState(() => _position = value);
                      },
                      items: const [
                        DropdownMenuItem(value: WatermarkPosition.center, child: Text('Center')),
                        DropdownMenuItem(value: WatermarkPosition.topLeft, child: Text('Top Left')),
                        DropdownMenuItem(value: WatermarkPosition.topRight, child: Text('Top Right')),
                        DropdownMenuItem(value: WatermarkPosition.bottomLeft, child: Text('Bottom Left')),
                        DropdownMenuItem(value: WatermarkPosition.bottomRight, child: Text('Bottom Right')),
                      ],
                    ),
                  ),
                  
                  // Diagonal
                  SwitchListTile(
                    secondary: const Icon(Icons.rotate_right),
                    title: const Text('Diagonal'),
                    subtitle: const Text('Rotate watermark 45°'),
                    value: _diagonal,
                    onChanged: (value) => setState(() => _diagonal = value),
                  ),
                  
                  // Repeating
                  SwitchListTile(
                    secondary: const Icon(Icons.grid_4x4),
                    title: const Text('Repeating Pattern'),
                    subtitle: const Text('Cover entire page'),
                    value: _repeating,
                    onChanged: (value) => setState(() => _repeating = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedPdfPath == null || _isProcessing || _textController.text.isEmpty
                    ? null
                    : _applyWatermark,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.water_drop),
                label: Text(_isProcessing ? 'Processing...' : 'Apply Watermark'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ),

            // Result
            if (_resultPath != null) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Result'),
              Card(
                color: Colors.green.shade50,
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green, size: 40),
                  title: const Text('Watermark Added!'),
                  subtitle: const Text('Tap to open or share'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () => OpenFilex.open(_resultPath!),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () => Share.shareXFiles([XFile(_resultPath!)]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Banner Ad
            const SizedBox(height: 16),
            const BannerAdWidget(),
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

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedPdfPath = result.files.single.path;
        _selectedPdfName = result.files.single.name;
        _resultPath = null;
      });
    }
  }

  Future<void> _applyWatermark() async {
    if (_selectedPdfPath == null || _textController.text.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      String resultPath;
      
      if (_repeating) {
        resultPath = await WatermarkService.addRepeatingWatermark(
          pdfPath: _selectedPdfPath!,
          text: _textController.text,
          opacity: _opacity,
          fontSize: _fontSize,
        );
      } else {
        resultPath = await WatermarkService.addTextWatermark(
          pdfPath: _selectedPdfPath!,
          text: _textController.text,
          opacity: _opacity,
          fontSize: _fontSize,
          position: _position,
          diagonal: _diagonal,
        );
      }

      setState(() => _resultPath = resultPath);
      _showToast('Watermark added successfully!');
    } catch (e) {
      _showToast('Error: $e', isError: true);
    } finally {
      setState(() => _isProcessing = false);
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
