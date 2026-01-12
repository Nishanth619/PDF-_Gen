import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ocr_service.dart';
import '../widgets/banner_ad_widget.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key, required this.imageFile});
  final File imageFile;

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final OcrService _ocrService = OcrService();
  String _extractedText = '';
  bool _isLoading = true;
  final bool _isFeatureAvailable = true; // All features available

  @override
  void initState() {
    super.initState();
    _extractText();
  }

  Future<void> _extractText() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Extract text - all users have access now
      final text = await _ocrService.extractTextFromImage(widget.imageFile);
      if (mounted) {
        setState(() {
          _extractedText = text;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _extractedText = 'Error extracting text. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _showUpgradeDialog() {
    // Not needed since all features are free
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Text Extraction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _extractedText.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: _extractedText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Text copied to clipboard')),
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: _extractedText.isEmpty
                ? null
                : () {
                    // Save text to file
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Text saved as document')),
                    );
                  },
          ),
        ],
      ),
      body: _buildOcrContent(),
    );
  }

  Widget _buildOcrContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.file(
              widget.imageFile,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Extracted Text:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _extractedText.isEmpty
                            ? 'No text detected in the image'
                            : _extractedText,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
          ),
          
          // Banner Ad
          const SizedBox(height: 8),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildPremiumFeaturePrompt() {
    return const SizedBox.shrink();
  }
}
