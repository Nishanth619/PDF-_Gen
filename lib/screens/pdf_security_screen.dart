import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../providers/pdf_provider.dart';
import '../services/pdf_security_service.dart';
import '../services/password_hint_service.dart';
import '../widgets/modern_ui_components.dart';
import '../widgets/banner_ad_widget.dart';

/// Enhanced PDF Security Screen with Encrypt/Decrypt tabs
class PdfSecurityScreen extends StatefulWidget {
  const PdfSecurityScreen({super.key});

  @override
  State<PdfSecurityScreen> createState() => _PdfSecurityScreenState();
}

class _PdfSecurityScreenState extends State<PdfSecurityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Encrypt tab state
  File? _encryptPdf;
  final _encryptPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureEncryptPassword = true;
  bool _obscureConfirmPassword = true;
  PasswordStrength _passwordStrength = PasswordStrength(score: 0, label: 'Enter password', color: 0xFF9E9E9E);
  final _hintController = TextEditingController();
  
  // Permission toggles
  Map<PdfPermissionsFlags, bool> _permissions = {
    PdfPermissionsFlags.print: true,
    PdfPermissionsFlags.copyContent: false,
    PdfPermissionsFlags.editContent: false,
    PdfPermissionsFlags.fillFields: true,
    PdfPermissionsFlags.editAnnotations: false,
  };
  
  // Decrypt tab state
  File? _decryptPdf;
  final _decryptPasswordController = TextEditingController();
  bool _obscureDecryptPassword = true;
  PdfSecurityInfo? _pdfSecurityInfo;
  String? _decryptPasswordHint;
  
  // Common state
  bool _isProcessing = false;
  double _progress = 0;
  
  final PdfSecurityService _securityService = PdfSecurityService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _encryptPasswordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _encryptPasswordController.removeListener(_onPasswordChanged);
    _encryptPasswordController.dispose();
    _confirmPasswordController.dispose();
    _decryptPasswordController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {
      _passwordStrength = PdfSecurityService.calculatePasswordStrength(
        _encryptPasswordController.text,
      );
    });
  }

  Future<void> _pickPdfForEncrypt() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _encryptPdf = File(result.files.single.path!);
        });
      }
    } catch (e) {
      _showError('Error picking PDF: $e');
    }
  }

  Future<void> _pickPdfForDecrypt() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        setState(() {
          _decryptPdf = file;
          _pdfSecurityInfo = null;
        });
        
        // Check if PDF is protected
        final info = await _securityService.checkPdfSecurity(file.path);
        
        // Load password hint if available
        final hint = await PasswordHintService.getHint(file.path);
        
        setState(() {
          _pdfSecurityInfo = info;
          _decryptPasswordHint = hint;
        });
        
        if (!info.isProtected && info.canOpen) {
          _showError('This PDF is not password protected');
        }
      }
    } catch (e) {
      _showError('Error picking PDF: $e');
    }
  }

  Future<void> _encryptPdfFile() async {
    if (_encryptPdf == null) {
      _showError('Please select a PDF file first');
      return;
    }

    if (_encryptPasswordController.text.isEmpty) {
      _showError('Please enter a password');
      return;
    }

    if (_encryptPasswordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    if (_encryptPasswordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isProcessing = true;
      _progress = 0;
    });

    try {
      // Get enabled permissions
      final enabledPermissions = _permissions.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final encryptedPath = await _securityService.encryptPdf(
        pdfPath: _encryptPdf!.path,
        userPassword: _encryptPasswordController.text,
        permissions: enabledPermissions,
        onProgress: (progress) {
          setState(() => _progress = progress);
        },
      );

      if (encryptedPath != null && mounted) {
        // Save password hint if provided
        if (_hintController.text.isNotEmpty) {
          await PasswordHintService.saveHint(encryptedPath, _hintController.text);
        }
        
        await context.read<PdfProvider>().addPdfFile(File(encryptedPath));
        
        Fluttertoast.showToast(
          msg: 'PDF encrypted successfully!',
          backgroundColor: Colors.green,
        );

        setState(() {
          _encryptPdf = null;
          _encryptPasswordController.clear();
          _confirmPasswordController.clear();
          _hintController.clear();
        });
      } else {
        _showError('Failed to encrypt PDF');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _progress = 0;
        });
      }
    }
  }

  Future<void> _decryptPdfFile() async {
    if (_decryptPdf == null) {
      _showError('Please select a PDF file first');
      return;
    }

    if (_decryptPasswordController.text.isEmpty) {
      _showError('Please enter the password');
      return;
    }

    setState(() {
      _isProcessing = true;
      _progress = 0;
    });

    try {
      final decryptedPath = await _securityService.decryptPdf(
        pdfPath: _decryptPdf!.path,
        password: _decryptPasswordController.text,
        onProgress: (progress) {
          setState(() => _progress = progress);
        },
      );

      if (decryptedPath != null && mounted) {
        await context.read<PdfProvider>().addPdfFile(File(decryptedPath));
        
        Fluttertoast.showToast(
          msg: 'PDF decrypted successfully!',
          backgroundColor: Colors.green,
        );

        setState(() {
          _decryptPdf = null;
          _decryptPasswordController.clear();
          _pdfSecurityInfo = null;
        });
      } else {
        _showError('Failed to decrypt PDF. Check your password.');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _progress = 0;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      Fluttertoast.showToast(
        msg: message,
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Security'),
        elevation: 0,
        actions: const [
          HelpIconButton(
            title: 'PDF Security',
            icon: Icons.lock_outline,
            iconColor: Color(0xFFFF6B35),
            helpText: 'Encrypt Tab:\n'
                '1. Select a PDF file to protect\n'
                '2. Enter a strong password\n'
                '3. Optionally add a password hint\n'
                '4. Choose permissions (print, copy, edit)\n'
                '5. Tap Encrypt to secure your file\n\n'
                'Decrypt Tab:\n'
                '1. Select a password-protected PDF\n'
                '2. Enter the password\n'
                '3. Tap Decrypt to remove protection',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.lock), text: 'Encrypt'),
            Tab(icon: Icon(Icons.lock_open), text: 'Decrypt'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEncryptTab(colorScheme),
          _buildDecryptTab(colorScheme),
        ],
      ),
    );
  }

  Widget _buildEncryptTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
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
                  Icon(Icons.security, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Protect your PDF with password encryption (AES 256-bit)',
                      style: TextStyle(color: colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Password Hint Tip
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tip: To see password hints, always open encrypted PDFs through this app.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Select PDF Button
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _pickPdfForEncrypt,
            icon: const Icon(Icons.file_upload),
            label: const Text('Select PDF to Encrypt'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),

          // Selected File Display
          if (_encryptPdf != null) _buildFileCard(_encryptPdf!, () {
            setState(() => _encryptPdf = null);
          }),
          
          const SizedBox(height: 24),

          // Password Section
          Text(
            'Set Password',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          // Password field with strength indicator
          TextField(
            controller: _encryptPasswordController,
            obscureText: _obscureEncryptPassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter password (min 6 characters)',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscureEncryptPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureEncryptPassword = !_obscureEncryptPassword),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          
          // Password strength indicator
          const SizedBox(height: 8),
          _buildPasswordStrengthIndicator(),
          
          const SizedBox(height: 16),

          // Confirm password
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Re-enter password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Password hint field
          TextField(
            controller: _hintController,
            decoration: InputDecoration(
              labelText: 'Password Hint (Optional)',
              hintText: 'E.g., "My pet name + birth year"',
              prefixIcon: const Icon(Icons.lightbulb_outline),
              helperText: 'This hint will be shown if you forget your password',
              helperStyle: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
              border: const OutlineInputBorder(),
            ),
            maxLength: 100,
          ),
          
          const SizedBox(height: 16),

          // Permissions Section
          Text(
            'Permissions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Control what users can do with the PDF',
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12),
          ),
          const SizedBox(height: 12),
          
          // Permission toggles
          ...PdfSecurityService.availablePermissions.map((permission) {
            final isEnabled = _permissions[permission.flag] ?? false;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: SwitchListTile(
                value: isEnabled,
                onChanged: _isProcessing ? null : (value) {
                  setState(() {
                    _permissions[permission.flag] = value;
                  });
                },
                title: Text(permission.name),
                subtitle: Text(
                  permission.description,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
                secondary: Icon(
                  _getPermissionIcon(permission.icon),
                  color: isEnabled ? colorScheme.primary : Colors.grey,
                ),
              ),
            );
          }),
          
          const SizedBox(height: 24),

          // Progress indicator
          if (_isProcessing) ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text(
              'Encrypting... ${(_progress * 100).round()}%',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 16),
          ],

          // Encrypt Button
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _encryptPdfFile,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.lock),
            label: Text(_isProcessing ? 'Encrypting...' : 'Encrypt PDF'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
          
          // Banner Ad
          const SizedBox(height: 16),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildDecryptTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info Card
          Card(
            color: colorScheme.secondaryContainer.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.lock_open, color: colorScheme.secondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Remove password protection from an encrypted PDF',
                      style: TextStyle(color: colorScheme.secondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Select PDF Button
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _pickPdfForDecrypt,
            icon: const Icon(Icons.file_upload),
            label: const Text('Select Encrypted PDF'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),

          // Selected File Display
          if (_decryptPdf != null) ...[
            _buildFileCard(_decryptPdf!, () {
              setState(() {
                _decryptPdf = null;
                _pdfSecurityInfo = null;
              });
            }),
            
            // Security info
            if (_pdfSecurityInfo != null) ...[
              const SizedBox(height: 12),
              _buildSecurityInfoCard(),
            ],
          ],
          
          const SizedBox(height: 24),

          // Password field
          if (_pdfSecurityInfo?.isProtected == true) ...[
            Text(
              'Enter Password',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _decryptPasswordController,
              obscureText: _obscureDecryptPassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter the PDF password',
                prefixIcon: const Icon(Icons.key),
                suffixIcon: IconButton(
                  icon: Icon(_obscureDecryptPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureDecryptPassword = !_obscureDecryptPassword),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            
            // Password Hint Display
            if (_decryptPasswordHint != null && _decryptPasswordHint!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildPasswordHintCard(),
            ],
            
            const SizedBox(height: 24),

            // Progress indicator
            if (_isProcessing) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text(
                'Decrypting... ${(_progress * 100).round()}%',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
              ),
              const SizedBox(height: 16),
            ],

            // Decrypt Button
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _decryptPdfFile,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.lock_open),
              label: Text(_isProcessing ? 'Decrypting...' : 'Remove Password'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: colorScheme.secondary,
              ),
            ),
          ],
          
          // Banner Ad
          const SizedBox(height: 16),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildFileCard(File file, VoidCallback onRemove) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
        title: Text(
          file.path.split(Platform.pathSeparator).last,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onRemove,
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _passwordStrength.score,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation(Color(_passwordStrength.color)),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _passwordStrength.label,
              style: TextStyle(
                color: Color(_passwordStrength.color),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        if (_encryptPasswordController.text.isNotEmpty && _passwordStrength.score < 0.6) ...[
          const SizedBox(height: 4),
          Text(
            'Tip: Use uppercase, numbers, and special characters',
            style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ],
      ],
    );
  }

  Widget _buildSecurityInfoCard() {
    final info = _pdfSecurityInfo!;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      color: info.isProtected 
          ? Colors.orange.shade50 
          : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              info.isProtected ? Icons.lock : Icons.lock_open,
              color: info.isProtected ? Colors.orange : Colors.green,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.isProtected ? 'Password Protected' : 'Not Protected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: info.isProtected ? Colors.orange.shade800 : Colors.green.shade800,
                    ),
                  ),
                  if (info.needsPassword)
                    Text(
                      'Enter the password to unlock',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordHintCard() {
    return Card(
      color: Colors.blue.shade50,
      child: ExpansionTile(
        leading: Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
        title: Text(
          'Forgot Password?',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.blue.shade700,
          ),
        ),
        subtitle: Text(
          'Tap to reveal your password hint',
          style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates, color: Colors.amber.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Hint:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _decryptPasswordHint!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPermissionIcon(String iconName) {
    switch (iconName) {
      case 'print':
        return Icons.print;
      case 'copy':
        return Icons.copy;
      case 'edit':
        return Icons.edit;
      case 'form':
        return Icons.edit_note;
      case 'comment':
        return Icons.comment;
      default:
        return Icons.check;
    }
  }
}
