import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'terms_screen.dart';
import 'home_screen.dart';
import '../providers/pdf_provider.dart';
import '../providers/settings_provider.dart';
import '../services/biometric_service.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigate();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    // Perform initialization tasks in background
    await _initializeApp();

    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      final bool termsAccepted = prefs.getBool('terms_accepted') ?? false;

      // Check biometric authentication if enabled
      final biometricEnabled = await BiometricService.isEnabled();
      if (biometricEnabled) {
        final authenticated = await BiometricService.authenticate(
          reason: 'Authenticate to access PDFGen',
        );

        if (!authenticated) {
          // Failed authentication - show error and don't proceed
          if (mounted) {
            _showAuthFailedDialog();
          }
          return;
        }
      }

      if (termsAccepted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TermsScreen()),
        );
      }
    }
  }

  void _showAuthFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.fingerprint, color: Colors.red, size: 48),
        title: const Text('Authentication Failed'),
        content: const Text('Please authenticate to access PDFGen.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigate(); // Try again
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// Initialize app in background with multi-threading
  Future<void> _initializeApp() async {
    try {
      // Perform heavy initialization tasks in isolate
      await compute(_initializeInBackground, '');

      // Also initialize providers in parallel
      await Future.wait([
        _initializeProviders(),
      ]);
    } catch (e) {
      debugPrint('Error during app initialization: $e');
    }
  }

  /// Initialize heavy tasks in isolate
  static Future<String> _initializeInBackground(String _) async {
    try {
      // Perform any CPU-intensive initialization tasks here
      await Future.delayed(const Duration(milliseconds: 500));
      return 'initialized';
    } catch (e) {
      debugPrint('Error in background initialization: $e');
      return 'error';
    }
  }

  /// Initialize providers
  Future<void> _initializeProviders() async {
    try {
      // Initialize PDF provider
      final pdfProvider = Provider.of<PdfProvider>(context, listen: false);
      await pdfProvider.initialize();

      // Initialize settings provider
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);
      // Any settings initialization can go here
    } catch (e) {
      debugPrint('Error initializing providers: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEA5B31), // Match logo color
      body: Container(
        // Solid orange background - matches logo background
        color: const Color(0xFFEA5B31), // Logo orange color
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

                // Logo with animation and shadow
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    // Responsive logo size
                    final logoSize = ResponsiveHelper.value<double>(
                      context: context,
                      mobile: 180,
                      tablet: 220,
                      largeTablet: 260,
                      desktop: 300,
                    );
                    
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        // Container with shadow to elevate the logo
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/logop.png',
                            width: logoSize,
                            height: logoSize,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.picture_as_pdf,
                                size: logoSize * 0.6,
                                color: Colors.white,
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // App name with slide animation
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // App Name
                        const Text(
                          'PDFGen',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tagline
                        Text(
                          'Convert • Secure • Manage',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w400,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Loading indicator
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.9),
                          ),
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Preparing your workspace...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // Version at bottom
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}