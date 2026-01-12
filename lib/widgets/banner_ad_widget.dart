import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../services/subscription_service.dart';

/// Banner Ad Widget - shows banner ads for non-premium users
class BannerAdWidget extends StatefulWidget {
  final AdSize adSize;
  
  const BannerAdWidget({
    super.key,
    this.adSize = AdSize.banner,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // Production banner ad unit ID
  static const String _adUnitId = 'ca-app-pub-4025737666505759/9931794866';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() => _isLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    // Don't show ads for premium users
    final subscriptionService = context.watch<SubscriptionService>();
    if (subscriptionService.isPremium) {
      return const SizedBox.shrink();
    }

    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

/// Adaptive Banner Ad Widget - uses adaptive banner size
class AdaptiveBannerAdWidget extends StatefulWidget {
  const AdaptiveBannerAdWidget({super.key});

  @override
  State<AdaptiveBannerAdWidget> createState() => _AdaptiveBannerAdWidgetState();
}

class _AdaptiveBannerAdWidgetState extends State<AdaptiveBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  static const String _adUnitId = 'ca-app-pub-4025737666505759/9931794866';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    if (_bannerAd != null) return;
    
    // Get adaptive banner size
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).size.width.truncate(),
    );
    
    if (size == null) {
      debugPrint('Unable to get adaptive banner size');
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() => _isLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdaptiveBannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    // Don't show ads for premium users
    final subscriptionService = context.watch<SubscriptionService>();
    if (subscriptionService.isPremium) {
      return const SizedBox.shrink();
    }

    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox(height: 50); // Placeholder height
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
