import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/id_photo_template.dart';
import '../models/pdf_file_model.dart';
import '../providers/pdf_provider.dart';
import '../services/id_photo_service.dart';
import '../widgets/modern_ui_components.dart';
import '../widgets/banner_ad_widget.dart';

/// ID Photo Maker Screen
/// Features:
/// - Take/select photo
/// - Choose country/template
/// - Auto face detection and crop
/// - Background removal and color change
/// - Generate print layouts
class IdPhotoScreen extends StatefulWidget {
  const IdPhotoScreen({super.key});

  @override
  State<IdPhotoScreen> createState() => _IdPhotoScreenState();
}

class _IdPhotoScreenState extends State<IdPhotoScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  IdPhotoTemplate? _selectedTemplate;
  String _selectedBackground = 'white';
  bool _isProcessing = false;
  String? _processedImagePath;
  String? _printLayoutPath;
  IdPhotoResult? _result;
  bool _autoCrop = true; // Toggle for auto cropping

  // Search and filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Default to popular template
    _selectedTemplate = IdPhotoTemplates.popular.first;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 95,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _processedImagePath = null;
          _printLayoutPath = null;
          _result = null;
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _processPhoto() async {
    if (_selectedImage == null || _selectedTemplate == null) {
      _showError('Please select an image and template');
      return;
    }

    setState(() {
      _isProcessing = true;
      _result = null;
    });

    try {
      final backgroundColor = IdPhotoBackgroundColors.getColor(_selectedBackground);
      
      final result = await IdPhotoService.processIdPhoto(
        imagePath: _selectedImage!.path,
        template: _selectedTemplate!,
        backgroundColor: backgroundColor,
        autoCrop: _autoCrop,
      );

      setState(() {
        _result = result;
        if (result != null && result.success) {
          _processedImagePath = result.imagePath;
        }
      });

      if (result != null && !result.success) {
        _showError(result.errorMessage ?? 'Processing failed');
      }
    } catch (e) {
      _showError('Error processing photo: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _generatePrintLayout(String layoutName) async {
    if (_processedImagePath == null || _selectedTemplate == null) {
      _showError('Please process a photo first');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final layoutPath = await IdPhotoService.generatePrintLayout(
        photoPath: _processedImagePath!,
        template: _selectedTemplate!,
        layoutName: layoutName,
      );

      setState(() {
        _printLayoutPath = layoutPath;
      });

      _showSuccess('Print layout generated! (${PrintLayouts.calculateGrid(layoutName, _selectedTemplate!)['total']} photos)');
    } catch (e) {
      _showError('Failed to generate layout: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _shareImage(String path) async {
    try {
      await Share.shareXFiles([XFile(path)]);
    } catch (e) {
      _showError('Failed to share: $e');
    }
  }

  Future<void> _saveToGallery(String path) async {
    try {
      // Add to app history
      final pdfProvider = Provider.of<PdfProvider>(context, listen: false);
      final file = File(path);
      final fileName = path.split('/').last;
      
      await pdfProvider.insertPdf(PdfFileModel(
        name: fileName,
        path: path,
        size: await file.length(),
        pageCount: 1,
        createdAt: DateTime.now(),
      ));

      _showSuccess('Saved to app history!');
    } catch (e) {
      _showError('Failed to save: $e');
    }
  }

  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  void _showSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  List<IdPhotoTemplate> get _filteredTemplates {
    if (_searchQuery.isEmpty) {
      return IdPhotoTemplates.all;
    }
    return IdPhotoTemplates.all.where((t) =>
      t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      t.country.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      t.documentType.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ID Photo Maker'),
        centerTitle: true,
        actions: [
          const HelpIconButton(
            title: 'ID Photo Maker',
            icon: Icons.photo_camera_outlined,
            iconColor: Color(0xFF14B8A6),
            helpText: 'Create ID Photos:\n\n'
                '1. Take or select a portrait photo\n'
                '2. Select your country and photo size\n'
                '3. Enable auto-crop for best results\n'
                '4. Choose a background color\n'
                '5. Generate print layout (4x6 or A4)\n\n'
                'Tip: Make sure face is clearly visible with good lighting!',
          ),
          if (_processedImagePath != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _processedImagePath = null;
                  _printLayoutPath = null;
                  _result = null;
                });
              },
              tooltip: 'Start Over',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Feature info card
            Card(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Create perfect ID photos with AI face detection & background removal - FREE!',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Step 1: Select Template
            _buildSectionTitle('1. Select Template', Icons.photo_size_select_actual),
            const SizedBox(height: 8),
            _buildTemplateSelector(),
            const SizedBox(height: 16),

            // Step 2: Take/Select Photo
            _buildSectionTitle('2. Take or Select Photo', Icons.camera_alt),
            const SizedBox(height: 8),
            _buildPhotoSelector(),
            const SizedBox(height: 16),

            // Step 3: Choose Background
            if (_selectedImage != null) ...[
              _buildSectionTitle('3. Background Color', Icons.palette),
              const SizedBox(height: 8),
              _buildBackgroundSelector(),
              const SizedBox(height: 12),

              // Auto Crop Toggle
              Card(
                child: SwitchListTile(
                  title: const Text('Auto Crop to Template Size'),
                  subtitle: Text(
                    _autoCrop 
                        ? 'Photo will be cropped to ${_selectedTemplate?.sizeText ?? "template size"}'
                        : 'Only background removal, keep original size',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _autoCrop,
                  onChanged: (value) {
                    setState(() {
                      _autoCrop = value;
                    });
                  },
                  secondary: Icon(
                    _autoCrop ? Icons.crop : Icons.crop_free,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Process Button
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _processPhoto,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: Text(_isProcessing ? 'Processing...' : 'Create ID Photo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Result Section
            if (_result != null && _result!.success) ...[
              _buildSectionTitle('4. Your ID Photo', Icons.check_circle),
              const SizedBox(height: 8),
              _buildResultCard(),
              const SizedBox(height: 16),

              // Print Layout Section
              _buildSectionTitle('5. Print Layout (Optional)', Icons.print),
              const SizedBox(height: 8),
              _buildPrintLayoutSection(),
            ],

            // Error display
            if (_result != null && !_result!.success)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _result!.errorMessage ?? 'Processing failed',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),
            
            // Banner Ad
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateSelector() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search country or document type...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        const SizedBox(height: 12),

        // Popular templates chips
        if (_searchQuery.isEmpty) ...[
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Popular:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: IdPhotoTemplates.popular.map((template) {
              final isSelected = _selectedTemplate?.id == template.id;
              return ChoiceChip(
                label: Text(template.name),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedTemplate = template;
                  });
                },
                backgroundColor: colorScheme.surface,
                selectedColor: colorScheme.primaryContainer,
              );
            }).toList(),
          ),
          const Divider(height: 24),
        ],

        // All templates list
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filteredTemplates.length,
            itemBuilder: (context, index) {
              final template = _filteredTemplates[index];
              final isSelected = _selectedTemplate?.id == template.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTemplate = template;
                  });
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryContainer
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? colorScheme.primary : Theme.of(context).dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        template.countryCode,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? colorScheme.primary
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template.documentType,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? colorScheme.primary
                              : Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          template.sizeText,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Selected template info
        if (_selectedTemplate != null)
          Card(
            margin: const EdgeInsets.only(top: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedTemplate!.country} - ${_selectedTemplate!.documentType}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Size: ${_selectedTemplate!.sizeText} | Background: ${_selectedTemplate!.backgroundColor}',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                        if (_selectedTemplate!.notes != null)
                          Text(
                            _selectedTemplate!.notes!,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoSelector() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_selectedImage != null) {
      return Card(
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.file(
                _selectedImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Retake'),
                  ),
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose Another'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Card(
            child: InkWell(
              onTap: () => _pickImage(ImageSource.camera),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.camera_alt, size: 48, color: colorScheme.primary),
                    const SizedBox(height: 8),
                    const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text('Use camera', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            child: InkWell(
              onTap: () => _pickImage(ImageSource.gallery),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.photo_library, size: 48, color: colorScheme.secondary),
                    const SizedBox(height: 8),
                    const Text('Choose Photo', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text('From gallery', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundSelector() {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: IdPhotoBackgroundColors.names.map((name) {
        final color = Color(IdPhotoBackgroundColors.getColor(name));
        final isSelected = _selectedBackground == name;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedBackground = name;
            });
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? colorScheme.primary : Colors.grey.shade400,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 8)]
                  : null,
            ),
            child: isSelected
                ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultCard() {
    if (_processedImagePath == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.file(
              File(_processedImagePath!),
              height: 250,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badges
                Row(
                  children: [
                    _buildStatusBadge(
                      'Face Detected',
                      _result?.faceDetected ?? false,
                      Icons.face,
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(
                      'BG Removed',
                      _result?.backgroundRemoved ?? false,
                      Icons.auto_fix_high,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _shareImage(_processedImagePath!),
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: colorScheme.onSecondary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _saveToGallery(_processedImagePath!),
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, bool success, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: success ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: success ? Colors.green : Colors.grey.shade400,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            success ? Icons.check_circle : icon,
            size: 14,
            color: success ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: success ? Colors.green.shade700 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintLayoutSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Layout options
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PrintLayouts.names.map((layoutName) {
            final grid = PrintLayouts.calculateGrid(layoutName, _selectedTemplate!);
            return OutlinedButton(
              onPressed: _isProcessing ? null : () => _generatePrintLayout(layoutName),
              child: Column(
                children: [
                  Text(layoutName),
                  Text(
                    '${grid['total']} photos',
                    style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ],
              ),
            );
          }).toList(),
        ),

        // Generated layout preview
        if (_printLayoutPath != null)
          Card(
            margin: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.file(
                    File(_printLayoutPath!),
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _shareImage(_printLayoutPath!),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share Layout'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _saveToGallery(_printLayoutPath!),
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('Save Layout'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
