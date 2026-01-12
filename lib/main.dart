import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/app_theme.dart';
import 'providers/pdf_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/terms_screen.dart';
import 'screens/home_screen.dart';
import 'services/subscription_service.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Mobile Ads SDK
  await MobileAds.instance.initialize();
  debugPrint('MobileAds SDK initialized');

  // Initialize AdService singleton (pre-loads interstitial ads)
  await AdService().initialize();

  // Initialize app in background for faster startup
  _initializeApp();

  runApp(const MyApp());
}

/// Initialize app in background
Future<void> _initializeApp() async {
  try {
    // Perform any heavy initialization tasks here
    await Future.delayed(Duration(milliseconds: 100)); // Simulate async work
  } catch (e) {
    // Log error but don't crash the app
    debugPrint('Error initializing app: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PdfProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionService()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'PDFGen',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}