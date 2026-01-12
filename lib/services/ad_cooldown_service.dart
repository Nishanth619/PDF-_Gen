import 'package:shared_preferences/shared_preferences.dart';

/// Ad Cooldown Service
/// Prevents ad fatigue by enforcing a cooldown period between ads
/// Only shows ads after completed conversions, not during workflow
class AdCooldownService {
  static const String _lastAdTimeKey = 'last_ad_time';
  static const Duration _cooldownDuration = Duration(minutes: 3);
  
  static DateTime? _lastAdTime;
  static bool _initialized = false;
  
  /// Initialize the service - call once at app start
  static Future<void> initialize() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final lastAdMillis = prefs.getInt(_lastAdTimeKey);
    
    if (lastAdMillis != null) {
      _lastAdTime = DateTime.fromMillisecondsSinceEpoch(lastAdMillis);
    }
    
    _initialized = true;
  }
  
  /// Check if enough time has passed to show another ad
  static bool canShowAd() {
    if (_lastAdTime == null) return true;
    
    final timeSinceLastAd = DateTime.now().difference(_lastAdTime!);
    return timeSinceLastAd >= _cooldownDuration;
  }
  
  /// Record that an ad was shown - call this after ad is displayed
  static Future<void> recordAdShown() async {
    _lastAdTime = DateTime.now();
    
    // Persist to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastAdTimeKey, _lastAdTime!.millisecondsSinceEpoch);
  }
  
  /// Get remaining cooldown time (for UI if needed)
  static Duration getRemainingCooldown() {
    if (_lastAdTime == null) return Duration.zero;
    
    final timeSinceLastAd = DateTime.now().difference(_lastAdTime!);
    final remaining = _cooldownDuration - timeSinceLastAd;
    
    return remaining.isNegative ? Duration.zero : remaining;
  }
  
  /// Reset cooldown (for testing or special cases)
  static Future<void> resetCooldown() async {
    _lastAdTime = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastAdTimeKey);
  }
}
