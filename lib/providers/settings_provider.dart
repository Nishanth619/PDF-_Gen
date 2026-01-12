import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/file_utils.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider() {
    _loadSettings();
  }
  static const String _themeModeKey = 'theme_mode';
  static const String _defaultQualityKey = 'default_quality';
  static const String _compressionKey = 'compression_enabled';
  static const String _defaultFileNameKey = 'default_file_name';
  static const String _saveLocationKey = 'save_location';
  static const String _pageSizeKey = 'page_size';
  static const String _imageQualityKey = 'image_quality';
  static const String _autoRotateKey = 'auto_rotate';
  static const String _autoEnhanceKey = 'auto_enhance';

  ThemeMode _themeMode = ThemeMode.system;
  int _defaultQuality = 85;
  bool _compressionEnabled = true;
  String _defaultFileName = 'PDF_';
  String _saveLocation = '';
  String _pageSize = 'A4';
  double _imageQuality = 0.85;
  bool _autoRotate = true;
  bool _autoEnhance = false;

  ThemeMode get themeMode => _themeMode;
  int get defaultQuality => _defaultQuality;
  bool get compressionEnabled => _compressionEnabled;
  String get defaultFileName => _defaultFileName;
  String get saveLocation => _saveLocation;
  String get pageSize => _pageSize;
  double get imageQuality => _imageQuality;
  bool get autoRotate => _autoRotate;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get autoEnhance => _autoEnhance;
  bool get compressPdf => _compressionEnabled;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme mode with proper default handling
    final themeModeIndex = prefs.getInt(_themeModeKey);
    if (themeModeIndex != null &&
        themeModeIndex >= 0 &&
        themeModeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeModeIndex];
    } else {
      _themeMode = ThemeMode.system; // Default to system theme
    }

    print('Loaded theme mode: $_themeMode (index: ${_themeMode.index})');

    _defaultQuality = prefs.getInt(_defaultQualityKey) ?? 85;
    _compressionEnabled = prefs.getBool(_compressionKey) ?? true;
    _defaultFileName = prefs.getString(_defaultFileNameKey) ?? 'PDF_';
    _saveLocation = prefs.getString(_saveLocationKey) ?? '';
    _pageSize = prefs.getString(_pageSizeKey) ?? 'A4';
    _imageQuality = prefs.getDouble(_imageQualityKey) ?? 0.85;
    _autoRotate = prefs.getBool(_autoRotateKey) ?? true;
    _autoEnhance = prefs.getBool(_autoEnhanceKey) ?? false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = mode;
    await prefs.setInt(_themeModeKey, mode.index);
    print('Set theme mode to: $mode (index: ${mode.index})');
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    await setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setDefaultQuality(int value) async {
    _defaultQuality = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultQualityKey, value);
    notifyListeners();
  }

  Future<void> setCompressionEnabled(bool value) async {
    _compressionEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_compressionKey, value);
    notifyListeners();
  }

  Future<void> setDefaultFileName(String value) async {
    _defaultFileName = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultFileNameKey, value);
    notifyListeners();
  }

  Future<void> setSaveLocation(String value) async {
    _saveLocation = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saveLocationKey, value);
    notifyListeners();
  }

  Future<void> setPageSize(String value) async {
    _pageSize = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pageSizeKey, value);
    notifyListeners();
  }

  Future<void> setImageQuality(double value) async {
    _imageQuality = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_imageQualityKey, value);
    notifyListeners();
  }

  Future<void> setAutoRotate(bool value) async {
    _autoRotate = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoRotateKey, value);
    notifyListeners();
  }

  Future<void> setAutoEnhance(bool value) async {
    _autoEnhance = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoEnhanceKey, value);
    notifyListeners();
  }

  Future<void> setCompressPdf(bool value) async {
    await setCompressionEnabled(value);
  }

  /// Clear cache method
  Future<void> clearCache() async {
    await FileUtils.clearTempDirectory();
  }
}