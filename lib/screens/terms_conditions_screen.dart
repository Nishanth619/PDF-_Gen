import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: TermsConditionsContent(),
      ),
    );
  }
}

class TermsConditionsContent extends StatelessWidget {
  const TermsConditionsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terms & Conditions',
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
          '1. Acceptance of Terms',
          'By downloading, installing, or using the PDFGen mobile application ("App"), you agree to be bound by these Terms and Conditions ("Terms"). If you do not agree to these Terms, please do not use the App.\n\n'
          'The App is developed and published by the PDFGen app developer.',
        ),
        _buildSection(
          context,
          '2. Description of Service',
          'PDFGen provides the following services:\n'
          '• Convert images to PDF documents\n'
          '• Scan documents using your device camera\n'
          '• Extract text from images using OCR\n'
          '• Add password protection to PDF files\n'
          '• Add digital signatures to PDF documents\n'
          '• Add watermarks to PDF files\n'
          '• Split and merge PDF documents\n'
          '• Create ID/passport photos\n'
          '• Scan business cards and save contacts',
        ),
        _buildSection(
          context,
          '3. License Grant',
          'Subject to your compliance with these Terms, we grant you a limited, non-exclusive, non-transferable, revocable license to download, install, and use the App for personal or professional document management purposes.',
        ),
        _buildSection(
          context,
          '4. User Responsibilities',
          'When using the App, you agree to:\n'
          '• Use the App in compliance with all applicable laws and regulations\n'
          '• Not use the App for any illegal, harmful, or unauthorized purposes\n'
          '• Not attempt to reverse engineer, decompile, or modify the App\n'
          '• Not use the App to create, distribute, or store any illegal content\n'
          '• Take responsibility for the content of documents you create',
        ),
        _buildSection(
          context,
          '5. User Content',
          'You retain all rights to the PDF files, images, and documents you create using the App. We do not claim any ownership rights to your content.\n\n'
          'All your documents are stored locally on your device. We do not upload, access, or store your files on any external servers.',
        ),
        _buildSection(
          context,
          '6. In-App Purchases',
          'The App may offer premium features through in-app purchases. All purchases are processed through Google Play and are subject to Google Play\'s terms of service.\n'
          '• Prices are displayed in your local currency before purchase\n'
          '• Purchases are non-refundable except as required by applicable law\n'
          '• Premium features are tied to your Google account',
        ),
        _buildSection(
          context,
          '7. Advertisements',
          'The free version of the App displays advertisements provided by Google AdMob. Advertisements may be personalized or non-personalized depending on user consent, device settings, and applicable laws.',
        ),
        _buildSection(
          context,
          '8. Intellectual Property',
          'The App and its original content, features, and functionality are owned by PDFGen and are protected by international copyright, trademark, and other intellectual property laws.',
        ),
        _buildSection(
          context,
          '9. Disclaimer of Warranties',
          'THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. WE DO NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED OR ERROR-FREE.',
        ),
        _buildSection(
          context,
          '10. Limitation of Liability',
          'TO THE MAXIMUM EXTENT PERMITTED BY LAW, PDFGEN SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING FROM YOUR USE OF THE APP, INCLUDING:\n'
          '• Loss of data or documents\n'
          '• Loss of profits or business opportunities\n'
          '• Any unauthorized access to your device\n'
          '• Any errors or omissions in the App\'s functionality',
        ),
        _buildSection(
          context,
          '11. No Professional Advice',
          'The App is provided for general document management purposes only. PDFGen does not provide legal, financial, or professional advice. Users are responsible for verifying the accuracy and suitability of documents created using the App.',
        ),
        _buildSection(
          context,
          '12. Modifications',
          'We reserve the right to modify, suspend, or discontinue the App at any time without notice. We will not be liable for any modification, suspension, or discontinuance of the App.',
        ),
        _buildSection(
          context,
          '13. Changes to Terms',
          'We reserve the right to modify these Terms at any time. We will notify users of significant changes through the App or by updating the "Last Updated" date. Continued use of the App after changes constitutes acceptance of the new Terms.',
        ),
        _buildSection(
          context,
          '14. Governing Law',
          'These Terms shall be governed by and construed in accordance with the laws of India, without regard to its conflict of law provisions. Any disputes arising from these Terms shall be subject to the exclusive jurisdiction of the courts in India.',
        ),
        _buildSection(
          context,
          '15. Severability',
          'If any provision of these Terms is found to be unenforceable, the remaining provisions will continue to be valid and enforceable.',
        ),
        _buildSection(
          context,
          '16. Entire Agreement',
          'These Terms, together with our Privacy Policy, constitute the entire agreement between you and PDFGen regarding the use of the App.',
        ),
        _buildSection(
          context,
          'Contact Us',
          'If you have any questions about these Terms and Conditions, please contact us at:\npdfgen09@gmail.com',
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