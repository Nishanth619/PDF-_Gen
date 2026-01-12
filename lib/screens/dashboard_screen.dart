import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import '../providers/pdf_provider.dart';
import '../services/subscription_service.dart';
import '../services/pdf_security_service.dart';
import '../services/ad_service.dart';
import '../utils/logger.dart';
import '../utils/responsive_helper.dart';
import '../widgets/premium_feature_dialog.dart';
import 'converter_screen.dart';
import 'pdf_security_screen.dart';
import 'digital_signature_screen.dart';
import 'pdf_split_merge_screen.dart';
import 'id_photo_screen.dart';
import 'scanner_modes_screen.dart';
import 'business_card_screen.dart';
import 'watermark_screen.dart';
import 'premium_screen.dart';
import '../widgets/recent_files_widget.dart';
import '../widgets/modern_ui_components.dart';

/// Main dashboard screen with feature grid
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Static ad service for tracking feature navigations
  static final AdService _adService = AdService();

  /// Navigate to a feature screen with ad tracking
  void _navigateWithAdTracking(BuildContext context, Widget screen) async {
    // Track navigation
    await _adService.trackFeatureNavigation();
    
    // Navigate to the screen
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDFGen'),
        elevation: 0,
        actions: [
          // Premium Button
          IconButton(
            icon: const Icon(Icons.workspace_premium, color: Colors.amber),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumScreen(),
                ),
              );
            },
            tooltip: 'Premium',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showAboutDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: ResponsiveContentWrapper(
          child: Padding(
            padding: ResponsiveHelper.getScreenPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                _buildWelcomeSection(context),
                SizedBox(height: ResponsiveHelper.getSpacing(context, baseSpacing: 12)),
                
                // Privacy Banner
                _buildPrivacyBanner(context),
                SizedBox(height: ResponsiveHelper.getSpacing(context)),
                
                // Features Grid
                Text(
                  'Features',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20 * ResponsiveHelper.getFontSizeMultiplier(context),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getSpacing(context)),
                _buildFeaturesGrid(context),


                SizedBox(height: ResponsiveHelper.getSpacing(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    // Time-based greeting
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning! ☀️';
    } else if (hour < 17) {
      greeting = 'Good Afternoon! 🌤️';
    } else {
      greeting = 'Good Evening! 🌙';
    }
    
    final isTablet = ResponsiveHelper.isTablet(context);
    final fontMultiplier = ResponsiveHelper.getFontSizeMultiplier(context);
    final logoSize = ResponsiveHelper.value<double>(
      context: context,
      mobile: 75,
      tablet: 90,
      largeTablet: 100,
      desktop: 110,
    );
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22 * fontMultiplier,
                      ),
                ),
                SizedBox(height: isTablet ? 12 : 8),
                Text(
                  'Convert, secure, and manage your PDFs',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14 * fontMultiplier,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: isTablet ? 24 : 16),
          Container(
            width: logoSize,
            height: logoSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: logoSize / 2,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: Image.asset(
                  'assets/logop.png',
                  width: logoSize * 2,
                  height: logoSize * 2,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.picture_as_pdf,
                      size: logoSize * 0.7,
                      color: Theme.of(context).colorScheme.primary,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade50,
            Colors.teal.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.security,
              color: Colors.green.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔒 100% Offline & Private',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your files never leave your device. No cloud, no tracking.',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    final columns = ResponsiveHelper.getGridColumns(context);
    final spacing = ResponsiveHelper.getSpacing(context, baseSpacing: 14);
    final aspectRatio = ResponsiveHelper.getCardAspectRatio(context);
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: aspectRatio,
      children: [
        AnimatedFeatureCard(
          icon: Icons.picture_as_pdf,
          title: 'Convert to PDF',
          description: 'Transform images into PDF',
          color: const Color(0xFF3B82F6),
          helpText: 'Select multiple images from your gallery or camera and convert them into a single PDF document. You can reorder pages, adjust quality, and choose page size.',
          onTap: () => _navigateWithAdTracking(context, const ConverterScreen()),
        ),
        AnimatedFeatureCard(
          icon: Icons.lock_outline,
          title: 'PDF Security',
          description: 'Encrypt & protect files',
          color: const Color(0xFFFF6B35),
          helpText: 'Add password protection to your PDF files. Set an owner password to prevent editing, and a user password to prevent opening. Perfect for sensitive documents.',
          onTap: () => _navigateWithAdTracking(context, const PdfSecurityScreen()),
        ),
        AnimatedFeatureCard(
          icon: Icons.draw_outlined,
          title: 'Digital Signature',
          description: 'Sign your documents',
          color: const Color(0xFF22C55E),
          helpText: 'Draw your signature or choose from saved signatures to sign PDF documents. Position your signature anywhere on the document with pinch-to-zoom.',
          onTap: () => _navigateWithAdTracking(context, const DigitalSignatureScreen()),
        ),
        AnimatedFeatureCard(
          icon: Icons.call_split_rounded,
          title: 'Split & Merge',
          description: 'Manage PDF pages',
          color: const Color(0xFF8B5CF6),
          helpText: 'Split a large PDF into smaller files or merge multiple PDFs into one. Extract specific pages or combine documents in any order you want.',
          onTap: () => _navigateWithAdTracking(context, const PDFSplitMergeScreen()),
        ),
        AnimatedFeatureCard(
          icon: Icons.photo_camera_outlined,
          title: 'ID Photo Maker',
          description: 'Passport & Visa photos',
          color: const Color(0xFF14B8A6),
          helpText: 'Create passport-size photos for visas, IDs, and official documents. Automatic background removal and size adjustment for different countries\' requirements.',
          onTap: () => _navigateWithAdTracking(context, const IdPhotoScreen()),
        ),
        AnimatedFeatureCard(
          icon: Icons.document_scanner_outlined,
          title: 'Advanced Scanner',
          description: 'Book & whiteboard modes',
          color: const Color(0xFF6366F1),
          helpText: 'Specialized scanning modes for books (auto page split), whiteboards (color enhancement), and documents (edge detection). Perfect for students and professionals.',
          onTap: () => _navigateWithAdTracking(context, const ScannerModesScreen()),
        ),
        AnimatedFeatureCard(
          icon: Icons.credit_card_outlined,
          title: 'Business Card',
          description: 'Scan & save contacts',
          color: const Color(0xFF7C3AED),
          helpText: 'Scan business cards and automatically extract contact information (name, phone, email, company). Save directly to your phone contacts.',
          onTap: () => _navigateWithAdTracking(context, const BusinessCardScreen()),
        ),
        AnimatedFeatureCard(
          icon: Icons.water_drop_outlined,
          title: 'Watermark',
          description: 'Add text watermarks',
          color: const Color(0xFF06B6D4),
          helpText: 'Add custom text watermarks to your PDF documents. Adjust font size, color, opacity, rotation, and position. Great for branding or marking documents as confidential.',
          onTap: () => _navigateWithAdTracking(context, const WatermarkScreen()),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    bool isComingSoon = false,
    String? badge,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          size: 28,
                          color: color,
                        ),
                      ),
                      if (isComingSoon)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Soon',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
              // Badge in top-right corner
              if (badge != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Consumer<PdfProvider>(
      builder: (context, pdfProvider, child) {
        final totalPdfs = pdfProvider.pdfHistory.length;
        final totalSize = pdfProvider.pdfHistory.fold<int>(
          0,
          (sum, pdf) => sum + pdf.size,
        );

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.picture_as_pdf,
                title: 'Total PDFs',
                value: totalPdfs.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context: context,
                icon: Icons.storage,
                title: 'Total Size',
                value: _formatFileSize(totalSize),
                color: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Tips',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTipItem(
              context,
              'Tap and hold on any PDF to select multiple files',
            ),
            const SizedBox(height: 8),
            _buildTipItem(
              context,
              'Use Split & Merge to combine multiple PDFs into one',
            ),
            const SizedBox(height: 8),
            _buildTipItem(
              context,
              'Protect your PDFs with password encryption',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String tip) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tip,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showComingSoonDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$featureName Coming Soon'),
        content: const Text('This feature is currently under development.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About PDFGen'),
        content: const Text(
          'A powerful PDF conversion and management tool.\n\n'
          'Features:\n'
          '- Convert images to PDF\n'
          '- Secure PDF files with encryption\n'
          '- Digital signatures\n'
          '- Split and merge PDFs',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
