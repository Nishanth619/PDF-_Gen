import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/pdf_provider.dart';
import '../widgets/modern_ui_components.dart';
import '../widgets/banner_ad_widget.dart';
import 'signature_pad_screen.dart';

/// Signature type enum
enum SignatureType { draw, type, image }

/// Signature position on the page
enum SignaturePosition {
  topLeft,
  topCenter,
  topRight,
  bottomLeft,
  bottomCenter,
  bottomRight;

  String get displayName {
    switch (this) {
      case SignaturePosition.topLeft:
        return 'Top Left';
      case SignaturePosition.topCenter:
        return 'Top Center';
      case SignaturePosition.topRight:
        return 'Top Right';
      case SignaturePosition.bottomLeft:
        return 'Bottom Left';
      case SignaturePosition.bottomCenter:
        return 'Bottom Center';
      case SignaturePosition.bottomRight:
        return 'Bottom Right';
    }
  }

  IconData get icon {
    switch (this) {
      case SignaturePosition.topLeft:
        return Icons.north_west;
      case SignaturePosition.topCenter:
        return Icons.north;
      case SignaturePosition.topRight:
        return Icons.north_east;
      case SignaturePosition.bottomLeft:
        return Icons.south_west;
      case SignaturePosition.bottomCenter:
        return Icons.south;
      case SignaturePosition.bottomRight:
        return Icons.south_east;
    }
  }
}

class DigitalSignatureScreen extends StatefulWidget {
  const DigitalSignatureScreen({super.key});

  @override
  State<DigitalSignatureScreen> createState() => _DigitalSignatureScreenState();
}

class _DigitalSignatureScreenState extends State<DigitalSignatureScreen> {
  File? _selectedPdf;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _typedSignatureController = TextEditingController();
  bool _isProcessing = false;
  
  // Signature data
  SignatureType _signatureType = SignatureType.draw;
  Uint8List? _drawnSignature;
  File? _signatureImage;
  
  // Signature style for typed signature
  String _selectedFontStyle = 'Signature';
  final List<String> _fontStyles = ['Signature', 'Formal', 'Casual', 'Elegant'];
  
  // Saved signature
  Uint8List? _savedSignature;
  
  // Signature position on PDF
  SignaturePosition _signaturePosition = SignaturePosition.bottomRight;

  @override
  void initState() {
    super.initState();
    _loadSavedSignature();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _reasonController.dispose();
    _typedSignatureController.dispose();
    super.dispose();
  }

  /// Load previously saved signature from storage
  Future<void> _loadSavedSignature() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString('saved_signature_path');
      if (savedPath != null) {
        final file = File(savedPath);
        if (await file.exists()) {
          _savedSignature = await file.readAsBytes();
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error loading saved signature: $e');
    }
  }

  /// Save current signature for future use
  Future<void> _saveSignatureForReuse(Uint8List signatureBytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tempDir = await getTemporaryDirectory();
      final signaturePath = '${tempDir.path}/saved_signature.png';
      
      final file = File(signaturePath);
      await file.writeAsBytes(signatureBytes);
      
      await prefs.setString('saved_signature_path', signaturePath);
      _savedSignature = signatureBytes;
      
      Fluttertoast.showToast(
        msg: 'Signature saved for future use!',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      debugPrint('Error saving signature: $e');
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedPdf = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error picking PDF: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  /// Open full-screen signature pad
  Future<void> _openSignaturePad() async {
    final Uint8List? signature = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (context) => const SignaturePadScreen(),
      ),
    );
    
    if (signature != null) {
      setState(() {
        _drawnSignature = signature;
        _signatureType = SignatureType.draw;
      });
    }
  }

  Future<void> _pickSignatureImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _signatureImage = File(image.path);
          _signatureType = SignatureType.image;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error picking image: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  /// Get signature bytes based on current type
  Future<Uint8List?> _getSignatureBytes() async {
    switch (_signatureType) {
      case SignatureType.draw:
        if (_drawnSignature == null) {
          Fluttertoast.showToast(
            msg: 'Please draw your signature',
            backgroundColor: Colors.red,
          );
          return null;
        }
        return _drawnSignature;
        
      case SignatureType.type:
        if (_typedSignatureController.text.isEmpty) {
          Fluttertoast.showToast(
            msg: 'Please type your signature',
            backgroundColor: Colors.red,
          );
          return null;
        }
        return await _textToImage(_typedSignatureController.text);
        
      case SignatureType.image:
        if (_signatureImage == null) {
          Fluttertoast.showToast(
            msg: 'Please select a signature image',
            backgroundColor: Colors.red,
          );
          return null;
        }
        return await _signatureImage!.readAsBytes();
    }
  }

  /// Convert text to PNG image for signature
  Future<Uint8List?> _textToImage(String text) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      const width = 400.0;
      const height = 100.0;

      // Draw white background
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, width, height),
        Paint()..color = Colors.white,
      );

      // Draw text
      final textSpan = TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black,
          fontSize: _selectedFontStyle == 'Signature' ? 48 : 36,
          fontStyle: _selectedFontStyle == 'Elegant' ? FontStyle.italic : FontStyle.normal,
          fontWeight: _selectedFontStyle == 'Formal' ? FontWeight.bold : FontWeight.normal,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: width - 40);
      
      final offsetX = (width - textPainter.width) / 2;
      final offsetY = (height - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(offsetX, offsetY));

      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error converting text to image: $e');
      return null;
    }
  }

  Future<void> _addDigitalSignature() async {
    if (_selectedPdf == null) {
      Fluttertoast.showToast(
        msg: 'Please select a PDF file first',
        backgroundColor: Colors.red,
      );
      return;
    }

    if (_nameController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter your name',
        backgroundColor: Colors.red,
      );
      return;
    }

    // Get signature bytes
    final signatureBytes = await _getSignatureBytes();
    if (signatureBytes == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Read the existing PDF
      final List<int> pdfBytes = await _selectedPdf!.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);

      // Add signature on the last page
      final PdfPage lastPage = document.pages[document.pages.count - 1];
      
      // Create signature image from bytes
      final PdfBitmap signatureImage = PdfBitmap(signatureBytes);
      
      // Calculate signature position based on user selection
      const double sigWidth = 150;
      const double sigHeight = 50;
      const double margin = 50;
      
      double sigX;
      double sigY;
      
      // Calculate X position
      switch (_signaturePosition) {
        case SignaturePosition.topLeft:
        case SignaturePosition.bottomLeft:
          sigX = margin;
          break;
        case SignaturePosition.topCenter:
        case SignaturePosition.bottomCenter:
          sigX = (lastPage.size.width - sigWidth) / 2;
          break;
        case SignaturePosition.topRight:
        case SignaturePosition.bottomRight:
          sigX = lastPage.size.width - sigWidth - margin;
          break;
      }
      
      // Calculate Y position
      switch (_signaturePosition) {
        case SignaturePosition.topLeft:
        case SignaturePosition.topCenter:
        case SignaturePosition.topRight:
          sigY = margin + 50; // Extra space for header
          break;
        case SignaturePosition.bottomLeft:
        case SignaturePosition.bottomCenter:
        case SignaturePosition.bottomRight:
          sigY = lastPage.size.height - sigHeight - 100;
          break;
      }
      
      // Draw signature image
      lastPage.graphics.drawImage(
        signatureImage,
        Rect.fromLTWH(sigX, sigY, sigWidth, sigHeight),
      );
      
      // Draw signature line
      lastPage.graphics.drawLine(
        PdfPen(PdfColor(0, 0, 0), width: 0.5),
        Offset(sigX, sigY + sigHeight + 5),
        Offset(sigX + sigWidth, sigY + sigHeight + 5),
      );
      
      // Add signer name below signature
      final PdfFont smallFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
      lastPage.graphics.drawString(
        _nameController.text,
        smallFont,
        brush: PdfSolidBrush(PdfColor(0, 0, 0)),
        bounds: Rect.fromLTWH(sigX, sigY + sigHeight + 10, sigWidth, 15),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
      
      // Add date
      final String dateStr = DateTime.now().toString().split(' ')[0];
      lastPage.graphics.drawString(
        dateStr,
        smallFont,
        brush: PdfSolidBrush(PdfColor(100, 100, 100)),
        bounds: Rect.fromLTWH(sigX, sigY + sigHeight + 25, sigWidth, 15),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );

      // Save and close the document
      final List<int> bytes = await document.save();
      document.dispose();

      // Save to a new file
      final outputDir = await getTemporaryDirectory();
      final String baseName = path.basenameWithoutExtension(_selectedPdf!.path);
      final String fileName =
          'signed_${baseName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final String filePath = path.join(outputDir.path, fileName);
      final File file = File(filePath);
      await file.writeAsBytes(bytes);

      // Add to provider
      if (mounted) {
        await context.read<PdfProvider>().addPdfFile(file);

        Fluttertoast.showToast(
          msg: 'Digital signature added successfully!',
          backgroundColor: Colors.green,
        );

        // Ask to save signature for reuse
        _showSaveSignatureDialog(signatureBytes);

        // Clear form
        setState(() {
          _selectedPdf = null;
          _nameController.clear();
          _titleController.clear();
          _reasonController.clear();
          _typedSignatureController.clear();
          _signatureImage = null;
          _drawnSignature = null;
        });
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error adding digital signature: $e',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showSaveSignatureDialog(Uint8List signatureBytes) {
    if (_savedSignature != null) return; // Already has saved signature
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Signature?'),
        content: const Text(
          'Would you like to save this signature for future use?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveSignatureForReuse(signatureBytes);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _useSavedSignature() {
    if (_savedSignature != null) {
      setState(() {
        _drawnSignature = _savedSignature;
        _signatureType = SignatureType.draw;
      });
      Fluttertoast.showToast(
        msg: 'Using saved signature',
        backgroundColor: Colors.blue,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Signature'),
        elevation: 0,
        actions: const [
          HelpIconButton(
            title: 'Digital Signature',
            icon: Icons.draw_outlined,
            iconColor: Color(0xFF22C55E),
            helpText: 'How to sign a PDF:\n\n'
                '1. Select a PDF file to sign\n'
                '2. Choose signature type: Draw, Type, or Image\n'
                '3. Create or select your signature\n'
                '4. Choose position (first, last, or all pages)\n'
                '5. Tap "Apply Signature" to sign\n\n'
                'Tip: Your signatures are saved for quick reuse!',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add your signature to PDF documents',
                        style: TextStyle(color: colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Select PDF Button
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _pickPdf,
              icon: const Icon(Icons.file_upload),
              label: const Text('Select PDF File'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            // Selected File Display
            if (_selectedPdf != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text(
                    _selectedPdf!.path.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${(_selectedPdf!.lengthSync() / 1024).toStringAsFixed(1)} KB',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedPdf = null;
                      });
                    },
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Signature Section
            Text(
              'Create Your Signature',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            
            // Saved signature quick action
            if (_savedSignature != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: _useSavedSignature,
                  icon: const Icon(Icons.history),
                  label: const Text('Use Saved Signature'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                ),
              ),

            // Signature options - 3 cards
            // Option 1: Draw signature (opens full screen)
            _buildSignatureOptionCard(
              icon: Icons.draw,
              title: 'Draw Signature',
              subtitle: 'Use your finger or stylus to sign',
              isSelected: _signatureType == SignatureType.draw && _drawnSignature != null,
              onTap: _openSignaturePad,
              preview: _drawnSignature != null
                  ? Image.memory(_drawnSignature!, height: 60, fit: BoxFit.contain)
                  : null,
            ),
            const SizedBox(height: 12),

            // Option 2: Type signature
            _buildSignatureOptionCard(
              icon: Icons.keyboard,
              title: 'Type Signature',
              subtitle: 'Type your name with a signature font',
              isSelected: _signatureType == SignatureType.type,
              onTap: () {
                setState(() => _signatureType = SignatureType.type);
                _showTypeSignatureDialog();
              },
              preview: _signatureType == SignatureType.type && _typedSignatureController.text.isNotEmpty
                  ? Text(
                      _typedSignatureController.text,
                      style: TextStyle(
                        fontSize: 24,
                        fontStyle: _selectedFontStyle == 'Elegant' ? FontStyle.italic : FontStyle.normal,
                        fontWeight: _selectedFontStyle == 'Formal' ? FontWeight.bold : FontWeight.normal,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),

            // Option 3: Upload image
            _buildSignatureOptionCard(
              icon: Icons.image,
              title: 'Upload Image',
              subtitle: 'Use an existing signature image',
              isSelected: _signatureType == SignatureType.image && _signatureImage != null,
              onTap: _pickSignatureImage,
              preview: _signatureImage != null
                  ? Image.file(_signatureImage!, height: 60, fit: BoxFit.contain)
                  : null,
            ),
            const SizedBox(height: 24),

            // Signature Position Selector
            Text(
              'Signature Position',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            
            // Visual position grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: Column(
                children: [
                  // PDF representation
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Top row
                        Expanded(
                          child: Row(
                            children: [
                              _buildPositionCell(SignaturePosition.topLeft),
                              _buildPositionCell(SignaturePosition.topCenter),
                              _buildPositionCell(SignaturePosition.topRight),
                            ],
                          ),
                        ),
                        // PDF content indicator (middle)
                        Container(
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(height: 3, color: Colors.grey.shade300),
                              const SizedBox(height: 4),
                              Container(height: 3, color: Colors.grey.shade300),
                              const SizedBox(height: 4),
                              Container(height: 3, width: 80, color: Colors.grey.shade300),
                            ],
                          ),
                        ),
                        // Bottom row
                        Expanded(
                          child: Row(
                            children: [
                              _buildPositionCell(SignaturePosition.bottomLeft),
                              _buildPositionCell(SignaturePosition.bottomCenter),
                              _buildPositionCell(SignaturePosition.bottomRight),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to select position: ${_signaturePosition.displayName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Signer Details
            Text(
              'Signer Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title (Optional)',
                hintText: 'Your position or title',
                prefixIcon: Icon(Icons.work),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                hintText: 'Reason for signing',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            // Sign Button
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _addDigitalSignature,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.edit),
              label: Text(_isProcessing
                  ? 'Adding Signature...'
                  : 'Add Digital Signature'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            // Banner Ad
            const SizedBox(height: 16),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? preview,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? colorScheme.primary : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? colorScheme.primary : null,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: colorScheme.primary),
                ],
              ),
              if (preview != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: preview),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPositionCell(SignaturePosition position) {
    final isSelected = _signaturePosition == position;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _signaturePosition = position;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: isSelected 
                ? Border.all(color: colorScheme.primary, width: 2)
                : null,
          ),
          child: Center(
            child: isSelected
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.draw,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sign',
                        style: TextStyle(
                          fontSize: 8,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Icon(
                    position.icon,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
          ),
        ),
      ),
    );
  }

  void _showTypeSignatureDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Type Your Signature'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _typedSignatureController,
                autofocus: true,
                style: TextStyle(
                  fontSize: 24,
                  fontStyle: _selectedFontStyle == 'Elegant' ? FontStyle.italic : FontStyle.normal,
                  fontWeight: _selectedFontStyle == 'Formal' ? FontWeight.bold : FontWeight.normal,
                ),
                decoration: const InputDecoration(
                  labelText: 'Your signature',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _fontStyles.map((style) {
                  final isSelected = _selectedFontStyle == style;
                  return ChoiceChip(
                    label: Text(style),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setDialogState(() {
                          _selectedFontStyle = style;
                        });
                        setState(() {});
                      }
                    },
                  );
                }).toList(),
              ),
              if (_typedSignatureController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _typedSignatureController.text,
                    style: TextStyle(
                      fontSize: 28,
                      fontStyle: _selectedFontStyle == 'Elegant' ? FontStyle.italic : FontStyle.normal,
                      fontWeight: _selectedFontStyle == 'Formal' ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _typedSignatureController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _typedSignatureController.text.isEmpty
                  ? null
                  : () {
                      setState(() {});
                      Navigator.pop(context);
                    },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
