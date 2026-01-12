import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Biometric Authentication Service
/// Handles fingerprint/face ID authentication for app security
class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _enabledKey = 'biometric_enabled';
  
  /// Check if biometric authentication is available on device
  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }
  
  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error getting biometric types: $e');
      return [];
    }
  }
  
  /// Check if biometric lock is enabled by user
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }
  
  /// Enable or disable biometric lock
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }
  
  /// Authenticate user with biometrics
  /// Returns true if authenticated successfully
  static Future<bool> authenticate({
    String reason = 'Authenticate to access PDF Converter',
  }) async {
    try {
      // Check if available
      final available = await isAvailable();
      if (!available) {
        debugPrint('Biometric not available');
        return true; // Allow access if biometric not available
      }
      
      // Check if enabled
      final enabled = await isEnabled();
      if (!enabled) {
        return true; // Allow access if not enabled
      }
      
      // Authenticate
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/pattern as fallback
        ),
      );
      
      return authenticated;
    } catch (e) {
      debugPrint('Error during biometric authentication: $e');
      return true; // Allow access on error
    }
  }
  
  /// Get biometric type name for UI
  static Future<String> getBiometricTypeName() async {
    final types = await getAvailableBiometrics();
    
    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'Biometric';
    }
  }
}
