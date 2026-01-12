import 'dart:io' show exit;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolledToBottom = false;

  // Terms and conditions text
  final String _termsText = '''
PDFGen Terms and Conditions

Last Updated: January 7, 2026

1. Acceptance of Terms
By downloading, installing, or using the PDFGen mobile application ("App"), you agree to be bound by these Terms and Conditions. If you do not agree to these Terms, please do not use the App.

The App is developed and published by the PDFGen app developer.

2. Description of Service
PDFGen provides PDF conversion, document scanning, OCR text extraction, PDF security, digital signatures, watermarking, split/merge, ID photo creation, and business card scanning services.

3. License Grant
Subject to your compliance with these Terms, we grant you a limited, non-exclusive, non-transferable, revocable license to download, install, and use the App for personal or professional document management purposes.

4. User Responsibilities
When using the App, you agree to:
• Use the App in compliance with all applicable laws and regulations
• Not use the App for any illegal, harmful, or unauthorized purposes
• Not attempt to reverse engineer, decompile, or modify the App
• Not use the App to create, distribute, or store any illegal content
• Take responsibility for the content of documents you create

5. User Content
You retain all rights to your PDF files and documents. All documents are stored locally on your device only. We do not upload or access your files.

6. Privacy Policy
Our Privacy Policy explains how we handle your information. By using the App, you consent to our privacy practices. Key points:
• All files are stored locally on your device
• We do not upload your documents to any server
• We use Google AdMob for advertisements

7. Advertisements
The free version displays advertisements via Google AdMob. Advertisements may be personalized or non-personalized depending on user consent, device settings, and applicable laws.

8. No Professional Advice
The App is provided for general document management purposes only. PDFGen does not provide legal, financial, or professional advice. Users are responsible for verifying the accuracy and suitability of documents created.

9. Disclaimer of Warranties
THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND. WE DO NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED OR ERROR-FREE.

10. Limitation of Liability
PDFGen shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the App.

11. Governing Law
These Terms shall be governed by the laws of India. Any disputes shall be subject to the exclusive jurisdiction of the courts in India.

12. Contact Information
If you have any questions, please contact us at: pdfgen09@gmail.com

By accepting these terms, you acknowledge that you have read, understood, and agreed to be bound by these Terms and Conditions.
''';

  @override
  void initState() {
    super.initState();
    // Add listener to check if user has scrolled to bottom
    _scrollController.addListener(_checkIfScrolledToBottom);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkIfScrolledToBottom);
    _scrollController.dispose();
    super.dispose();
  }

  void _checkIfScrolledToBottom() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!_isScrolledToBottom) {
        setState(() {
          _isScrolledToBottom = true;
        });
      }
    }
  }

  Future<void> _acceptTerms() async {
    // Check if user has scrolled to bottom or if it's a short text
    if (!_isScrolledToBottom && 
        _scrollController.position.maxScrollExtent > 0) {
      // Show dialog asking user to read terms
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please scroll to the bottom of the terms before accepting'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save that user has accepted terms
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('terms_accepted', true);
      
      if (mounted) {
        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving preference')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _declineTerms() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Decline Terms'),
          content: const Text(
              'Are you sure you want to decline the Terms and Conditions? The application will close.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Decline'),
              onPressed: () {
                Navigator.of(context).pop();
                // Close the application
                exit(0);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return WillPopScope(
      onWillPop: () async {
        // Prevent going back to splash screen
        return false;
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text(
            'Terms and Conditions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primary.withOpacity(0.05),
                colorScheme.surface,
              ],
            ),
          ),
          child: Column(
            children: [
              // Header section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.description,
                      size: 50,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Please read our Terms and Conditions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Terms content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Scrollbar(
                        controller: _scrollController,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Text(
                            _termsText,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Scroll reminder
                    if (!_isScrolledToBottom && 
                        (_scrollController.hasClients && 
                         _scrollController.position.maxScrollExtent > 0))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_downward, size: 16, color: Colors.orange),
                            const SizedBox(width: 5),
                            Text(
                              'Scroll to bottom to accept',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _acceptTerms,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Accept',
                                        style: TextStyle(
                                          fontSize: 18, 
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _declineTerms,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Decline',
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'By accepting, you agree to our Terms and Conditions',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}