import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/business_card_service.dart';
import 'native_scanner_screen.dart';
import '../widgets/modern_ui_components.dart';
import '../widgets/banner_ad_widget.dart';

/// Business Card Scanner Screen
/// Scan business cards and extract contact information
class BusinessCardScreen extends StatefulWidget {
  const BusinessCardScreen({super.key});

  @override
  State<BusinessCardScreen> createState() => _BusinessCardScreenState();
}

class _BusinessCardScreenState extends State<BusinessCardScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  ContactInfo? _extractedContact;
  String? _scannedImagePath;
  
  // Controllers for editable fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Card Scanner'),
        centerTitle: true,
        actions: [
          const HelpIconButton(
            title: 'Business Card Scanner',
            icon: Icons.credit_card_outlined,
            iconColor: Color(0xFF7C3AED),
            helpText: 'Scan Business Cards:\n\n'
                '1. Capture or select a business card image\n'
                '2. Contact info is automatically extracted\n'
                '3. Edit any details if needed\n'
                '4. Tap "Save to Contacts" to save\n\n'
                'Extracted: Name, Phone, Email, Company, Website',
          ),
          if (_extractedContact != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _clearData,
              tooltip: 'Clear',
            ),
        ],
      ),
      body: _extractedContact == null
          ? _buildScanPrompt(colorScheme)
          : _buildContactEditor(colorScheme),
      floatingActionButton: _extractedContact == null
          ? FloatingActionButton.extended(
              onPressed: _isProcessing ? null : _showScanOptions,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(_isProcessing ? 'Processing...' : 'Scan Card'),
            )
          : null,
    );
  }

  Widget _buildScanPrompt(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card,
              size: 100,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Scan a Business Card',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Take a photo or select from gallery to extract contact information automatically',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
            ),
            const SizedBox(height: 32),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                _buildFeatureChip(Icons.person, 'Name'),
                _buildFeatureChip(Icons.phone, 'Phone'),
                _buildFeatureChip(Icons.email, 'Email'),
                _buildFeatureChip(Icons.business, 'Company'),
                _buildFeatureChip(Icons.language, 'Website'),
              ],
            ),
            const SizedBox(height: 32),
            
            // Banner Ad
            const SizedBox(height: 16),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Chip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }

  Widget _buildContactEditor(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scanned Image Preview
          if (_scannedImagePath != null)
            Card(
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: Image.file(
                  File(_scannedImagePath!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 16),
          
          // Contact Fields
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Extracted Contact',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _nameController,
                    label: 'Name',
                    icon: Icons.person,
                  ),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _buildTextField(
                    controller: _companyController,
                    label: 'Company',
                    icon: Icons.business,
                  ),
                  _buildTextField(
                    controller: _websiteController,
                    label: 'Website',
                    icon: Icons.language,
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveToContacts,
                  icon: const Icon(Icons.contacts),
                  label: const Text('Save to Contacts'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _scanAgain,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Scan Another'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
          
          // Raw Text (for debugging)
          if (_extractedContact?.rawText != null) ...[
            const SizedBox(height: 24),
            ExpansionTile(
              title: const Text('Raw Extracted Text'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _extractedContact!.rawText!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void _showScanOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _scanWithCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanWithCamera() async {
    final result = await Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (_) => const NativeScannerScreen()),
    );

    if (result != null) {
      await _processBusinessCard(result.path);
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
      await _processBusinessCard(image.path);
    }
  }

  Future<void> _processBusinessCard(String imagePath) async {
    setState(() => _isProcessing = true);

    try {
      final contact = await BusinessCardService.extractContactInfo(imagePath);
      
      setState(() {
        _extractedContact = contact;
        _scannedImagePath = imagePath;
        
        // Populate controllers
        _nameController.text = contact.name ?? '';
        _phoneController.text = contact.phone ?? '';
        _emailController.text = contact.email ?? '';
        _companyController.text = contact.company ?? '';
        _websiteController.text = contact.website ?? '';
      });

      if (contact.isEmpty) {
        _showToast('No contact info found. Please try again.', isError: true);
      } else {
        _showToast('Contact info extracted!');
      }
    } catch (e) {
      _showToast('Error processing card: $e', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveToContacts() async {
    // Request permission
    var permission = await Permission.contacts.status;
    
    if (!permission.isGranted) {
      // Request permission
      permission = await Permission.contacts.request();
      
      if (!permission.isGranted) {
        // Show dialog to open settings
        if (mounted) {
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              icon: const Icon(Icons.contacts, color: Colors.orange, size: 48),
              title: const Text('Contact Permission Required'),
              content: const Text(
                'To save business card contacts, please grant contact permission in app settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
          
          if (shouldOpenSettings == true) {
            await openAppSettings();
          }
        }
        return;
      }
    }

    try {
      final contact = Contact()
        ..name.first = _nameController.text.split(' ').first
        ..name.last = _nameController.text.split(' ').skip(1).join(' ')
        ..phones = _phoneController.text.isNotEmpty
            ? [Phone(_phoneController.text)]
            : []
        ..emails = _emailController.text.isNotEmpty
            ? [Email(_emailController.text)]
            : []
        ..organizations = _companyController.text.isNotEmpty
            ? [Organization(company: _companyController.text)]
            : []
        ..websites = _websiteController.text.isNotEmpty
            ? [Website(_websiteController.text)]
            : [];

      await FlutterContacts.insertContact(contact);
      
      _showToast('Contact saved successfully!');
      
      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text('Contact Saved!'),
            content: Text('${_nameController.text} has been added to your contacts.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearData();
                },
                child: const Text('Scan Another'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showToast('Error saving contact: $e', isError: true);
    }
  }

  void _scanAgain() {
    _clearData();
    _showScanOptions();
  }

  void _clearData() {
    setState(() {
      _extractedContact = null;
      _scannedImagePath = null;
      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _companyController.clear();
      _websiteController.clear();
    });
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
    );
  }
}
