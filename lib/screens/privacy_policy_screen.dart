import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: PrivacyPolicyContent(),
      ),
    );
  }
}

class PrivacyPolicyContent extends StatelessWidget {
  const PrivacyPolicyContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy Policy',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Last Updated: January 7, 2026',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        _buildSection(
          context,
          'Introduction',
          'PDFGen ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application PDFGen (the "App").\n\n'
          'This app is developed and published by the PDFGen app developer.',
        ),
        _buildSection(
          context,
          'Information You Provide',
          '• PDF Files: Documents you create, edit, or manage using our app are stored locally on your device only.\n'
          '• Images: Photos you capture or select for PDF conversion are processed locally.\n'
          '• Contacts: When using Business Card Scanner, contact information is extracted via OCR and saved to your device contacts only with your permission.\n'
          '• Digital Signatures: Signature data you create is stored locally on your device.',
        ),
        _buildSection(
          context,
          'Automatically Collected Information',
          '• Device Information: Basic device type and operating system version for compatibility purposes.\n'
          '• Crash Reports: Anonymous crash data to improve app stability.\n'
          '• Ad Data: We use Google AdMob to display advertisements. AdMob may collect device identifiers and usage data as described in Google\'s Privacy Policy.',
        ),
        _buildSection(
          context,
          'Information We Do NOT Collect',
          '• We do NOT upload your PDF files to any server\n'
          '• We do NOT collect personal identification information\n'
          '• We do NOT track your location\n'
          '• We do NOT access your files without your explicit action\n'
          '• We do NOT share your documents with third parties',
        ),
        _buildSection(
          context,
          'Permissions We Request',
          '• Camera: Document scanning and photo capture\n'
          '• Storage/Photos: Import images and save PDF files\n'
          '• Contacts: Save scanned business card contacts (optional)\n'
          '• Internet: Display advertisements (personalized or non-personalized based on user consent and region)',
        ),
        _buildSection(
          context,
          'Data Storage and Security',
          'All PDF files, images, and documents are stored locally on your device only. We do not upload or store your files on any external servers. Your data remains under your control at all times.\n\n'
          'We implement appropriate security measures including biometric authentication option to protect your documents.',
        ),
        _buildSection(
          context,
          'Third-Party Services',
          'Our app uses the following third-party services:\n'
          '• Google AdMob: For displaying advertisements\n'
          '• Google ML Kit: For OCR text recognition and document scanning (processed on-device)',
        ),
        _buildSection(
          context,
          'Children\'s Privacy',
          'Our app is not directed to children under 13 years of age. We do not knowingly collect personal information from children under 13.',
        ),
        _buildSection(
          context,
          'Your Rights',
          '• You can delete any PDF or document created by the app at any time\n'
          '• You can revoke permissions through your device settings\n'
          '• You can uninstall the app to remove all locally stored data',
        ),
        _buildSection(
          context,
          'Regional Privacy Rights',
          'Depending on your location (such as the European Economic Area), you may have additional rights under data protection laws, including the right to access, correct, or delete your data. Since PDFGen does not store personal data on external servers, most data can be managed directly on your device.',
        ),
        _buildSection(
          context,
          'Changes to This Policy',
          'We may update this Privacy Policy from time to time. We will notify you of any changes by updating the "Last Updated" date at the top of this policy.',
        ),
        _buildSection(
          context,
          'Contact Us',
          'If you have any questions about this Privacy Policy, please contact us at:\npdfgen09@gmail.com',
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}