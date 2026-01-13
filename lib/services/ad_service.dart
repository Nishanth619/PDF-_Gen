import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_cooldown_service.dart';

/// Service for handling ads in the app - Singleton pattern
class AdService {
  // Singleton instance
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  static const String _bannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111'; // Test Banner ID
  static const String _interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712'; // Test Interstitial ID

  // Feature navigation tracking
  int _featureNavigationCount = 0;
  static const int _navigationsBeforeAd = 3; // Show ad after 3 navigations

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isInitialized = false;

  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  BannerAd? get bannerAd => _bannerAd;

  /// Initialize the ad service (call once at app start)
  Future<void> initialize() async {
    if (_isInitialized) return; // Prevent double initialization
    
    try {
      // Initialize cooldown service
      await AdCooldownService.initialize();
      
      // Initialize banner ad
      await _loadBannerAd();

      // Pre-load interstitial ad
      await _loadInterstitialAd();
      
      _isInitialized = true;
      debugPrint('AdService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing ad service: $e');
    }
  }

  /// Load banner ad
  Future<void> _loadBannerAd() async {
    try {
      _bannerAd = BannerAd(
        adUnitId: _bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _isBannerAdLoaded = true;
            debugPrint('Banner ad loaded successfully');
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            _isBannerAdLoaded = false;
            debugPrint('Banner ad failed to load: $error');
          },
        ),
      );

      await _bannerAd!.load();
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
    }
  }

  /// Load interstitial ad
  Future<void> _loadInterstitialAd() async {
    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
            debugPrint('Interstitial ad loaded successfully');
          },
          onAdFailedToLoad: (error) {
            _isInterstitialAdLoaded = false;
            debugPrint('Interstitial ad failed to load: $error');
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading interstitial ad: $e');
    }
  }

  /// Track feature navigation and show ad if threshold reached
  /// Call this when user navigates to a feature screen
  Future<bool> trackFeatureNavigation() async {
    _featureNavigationCount++;
    debugPrint('Feature navigation count: $_featureNavigationCount');
    
    if (_featureNavigationCount >= _navigationsBeforeAd) {
      _featureNavigationCount = 0; // Reset counter
      return await showInterstitialAdWithCooldown();
    }
    return false;
  }

  /// Track feature transaction completion and show ad
  /// Call this when user successfully completes a feature (e.g., PDF created, converted, etc.)
  Future<bool> trackFeatureCompletion() async {
    debugPrint('Feature completed - showing interstitial ad');
    _featureNavigationCount = 0; // Reset navigation counter on completion
    return await showInterstitialAdWithCooldown();
  }

  /// Show interstitial ad with cooldown check (recommended)
  /// Returns true if ad was shown, false if in cooldown
  Future<bool> showInterstitialAdWithCooldown() async {
    // Check cooldown first
    if (!AdCooldownService.canShowAd()) {
      debugPrint('Ad cooldown active. Remaining: ${AdCooldownService.getRemainingCooldown().inSeconds}s');
      return false;
    }
    
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      await _interstitialAd!.show();
      
      // Record that ad was shown
      await AdCooldownService.recordAdShown();
      
      // Load a new interstitial ad for next time
      await _loadInterstitialAd();
      return true;
    } else {
      debugPrint('Interstitial ad is not ready yet');
      // Try to load one for next time
      await _loadInterstitialAd();
      return false;
    }
  }

  /// Show interstitial ad (legacy - no cooldown check)
  Future<void> showInterstitialAd() async {
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      await _interstitialAd!.show();
      
      // Record that ad was shown
      await AdCooldownService.recordAdShown();
      
      // Load a new interstitial ad for next time
      await _loadInterstitialAd();
    } else {
      debugPrint('Interstitial ad is not ready yet');
    }
  }

  /// Reset navigation counter (call when appropriate, e.g., on app restart)
  void resetNavigationCount() {
    _featureNavigationCount = 0;
  }

  /// Get current navigation count (for debugging)
  int get navigationCount => _featureNavigationCount;

  /// Dispose ads
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }
}
