import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../constants/strings.dart';
import '../providers/settings_provider.dart';
import '../services/biometric_service.dart';
import '../utils/file_utils.dart';
import '../utils/responsive_helper.dart';
import '../widgets/modern_ui_components.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Launch URL
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Fluttertoast.showToast(
        msg: 'Could not open link',
        backgroundColor: Colors.red,
      );
    }
  }

  /// Show about dialog
  void _showAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // App icon with gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryStart.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.picture_as_pdf,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version ${AppConstants.appVersion}',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'A powerful PDF toolkit that helps you convert, scan, edit, and secure your documents with ease.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            // Features grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildFeatureChip(Icons.image, 'Image to PDF', AppTheme.accentBlue),
                _buildFeatureChip(Icons.document_scanner, 'Scanner', AppTheme.accentTeal),
                _buildFeatureChip(Icons.security, 'Encryption', AppTheme.successGreen),
                _buildFeatureChip(Icons.merge, 'Split & Merge', AppTheme.accentOrange),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '© 2026 PDFGen. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Show clear cache dialog
  Future<void> _showClearCacheDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.cleaning_services,
                size: 32,
                color: AppTheme.warningYellow,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Clear Cache',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will delete all temporary files. Your saved PDFs will not be affected.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningYellow,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Clear', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      await settings.clearCache();
      Fluttertoast.showToast(
        msg: 'Cache cleared successfully',
        backgroundColor: Colors.green,
      );
    }
  }

  /// Show save location selection dialog
  Future<void> _showSaveLocationDialog(BuildContext context, SettingsProvider settings) async {
    final pdfDir = await FileUtils.getPdfDirectory();
    final dirSize = await _calculateDirectorySize(pdfDir.path);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.folder, color: AppTheme.accentOrange),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Storage Location',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Storage info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurfaceVariant : AppTheme.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storage, size: 20, color: AppTheme.accentBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Storage Used',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        FileUtils.getFileSize(dirSize),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pdfDir.path,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'PDFs are saved to the app documents directory for easy access and management.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _openFileManager(pdfDir.path);
                },
                icon: const Icon(Icons.folder_open, color: Colors.white),
                label: const Text('Open Folder', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Calculate directory size
  Future<int> _calculateDirectorySize(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return 0;
      
      int totalSize = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          try {
            totalSize += await entity.length();
          } catch (e) {
            // Skip files we can't access
          }
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Open file manager to show PDF directory
  Future<void> _openFileManager(String path) async {
    try {
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        Fluttertoast.showToast(
          msg: 'Unable to open file manager',
          backgroundColor: Colors.orange,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Path: $path',
        backgroundColor: Colors.blue,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return CustomScrollView(
            slivers: [
              // Modern App Bar with gradient
              SliverAppBar(
                expandedHeight: 140,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                  title: Text(
                    AppStrings.settings,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark 
                            ? [AppTheme.darkSurface, AppTheme.darkBackground]
                            : [AppTheme.primaryStart.withOpacity(0.1), AppTheme.lightBackground],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 50, right: 20),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryStart.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Settings content
              SliverToBoxAdapter(
                child: ResponsiveContentWrapper(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: ResponsiveHelper.isTablet(context) ? 16 : 0,
                    ),
                    child: Column(
                      children: [
                        // Appearance Section
                        SettingsSectionCard(
                        title: 'Appearance',
                        children: [
                          ModernSettingsTile(
                            icon: _getThemeModeIcon(settings.themeMode),
                            iconColor: AppTheme.primaryStart,
                            title: 'Theme Mode',
                            subtitle: _getThemeModeLabel(settings.themeMode),
                            onTap: () => _showThemeModeDialog(context, settings),
                            showDivider: false,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // PDF Settings Section
                      SettingsSectionCard(
                        title: 'PDF Settings',
                        children: [
                          ModernSettingsTile(
                            icon: Icons.photo_size_select_large,
                            iconColor: AppTheme.accentBlue,
                            title: AppStrings.pageSize,
                            subtitle: settings.pageSize,
                            onTap: () => _showPageSizeDialog(context, settings),
                          ),
                          ModernSettingsTile(
                            icon: Icons.high_quality,
                            iconColor: AppTheme.accentTeal,
                            title: AppStrings.imageQuality,
                            subtitle: '${(settings.imageQuality * 100).toInt()}%',
                            onTap: () => _showQualityDialog(context, settings),
                          ),
                          _buildSwitchTile(
                            context,
                            icon: Icons.compress,
                            iconColor: AppTheme.successGreen,
                            title: 'Compress PDF',
                            subtitle: 'Reduce file size',
                            value: settings.compressionEnabled,
                            onChanged: (value) => settings.setCompressionEnabled(value),
                          ),
                          _buildSwitchTile(
                            context,
                            icon: Icons.rotate_right,
                            iconColor: AppTheme.accentOrange,
                            title: AppStrings.autoRotate,
                            subtitle: 'Auto rotate images to fit',
                            value: settings.autoRotate,
                            onChanged: (value) => settings.setAutoRotate(value),
                          ),
                          _buildSwitchTile(
                            context,
                            icon: Icons.auto_fix_high,
                            iconColor: AppTheme.primaryEnd,
                            title: 'Auto Enhance',
                            subtitle: 'Improve image quality',
                            value: settings.autoEnhance,
                            onChanged: (value) => settings.setAutoEnhance(value),
                            showDivider: false,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Storage Section
                      SettingsSectionCard(
                        title: 'Storage',
                        children: [
                          ModernSettingsTile(
                            icon: Icons.folder,
                            iconColor: AppTheme.accentOrange,
                            title: AppStrings.saveLocation,
                            subtitle: 'App documents folder',
                            onTap: () => _showSaveLocationDialog(context, settings),
                          ),
                          ModernSettingsTile(
                            icon: Icons.cleaning_services,
                            iconColor: AppTheme.warningYellow,
                            title: AppStrings.clearCache,
                            subtitle: 'Remove temporary files',
                            onTap: () => _showClearCacheDialog(context),
                            showDivider: false,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Security Section
                      FutureBuilder<bool>(
                        future: BiometricService.isAvailable(),
                        builder: (context, snapshot) {
                          if (snapshot.data == true) {
                            return Column(
                              children: [
                                SettingsSectionCard(
                                  title: 'Security',
                                  children: [
                                    FutureBuilder<bool>(
                                      future: BiometricService.isEnabled(),
                                      builder: (context, enabledSnapshot) {
                                        return FutureBuilder<String>(
                                          future: BiometricService.getBiometricTypeName(),
                                          builder: (context, nameSnapshot) {
                                            return _buildSwitchTile(
                                              context,
                                              icon: Icons.fingerprint,
                                              iconColor: AppTheme.successGreen,
                                              title: 'Biometric Lock',
                                              subtitle: 'Use ${nameSnapshot.data ?? 'biometric'} to unlock',
                                              value: enabledSnapshot.data ?? false,
                                              onChanged: (value) async {
                                                await BiometricService.setEnabled(value);
                                                (context as Element).markNeedsBuild();
                                                Fluttertoast.showToast(
                                                  msg: value
                                                      ? 'Biometric lock enabled'
                                                      : 'Biometric lock disabled',
                                                  backgroundColor: Colors.green,
                                                );
                                              },
                                              showDivider: false,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // Legal Section
                      SettingsSectionCard(
                        title: 'Legal',
                        children: [
                          ModernSettingsTile(
                            icon: Icons.privacy_tip_outlined,
                            iconColor: AppTheme.accentTeal,
                            title: 'Privacy Policy',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PrivacyPolicyScreen(),
                                ),
                              );
                            },
                          ),
                          ModernSettingsTile(
                            icon: Icons.description_outlined,
                            iconColor: AppTheme.infoBlue,
                            title: 'Terms & Conditions',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TermsConditionsScreen(),
                                ),
                              );
                            },
                            showDivider: false,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // About Section
                      SettingsSectionCard(
                        title: 'About',
                        children: [
                          ModernSettingsTile(
                            icon: Icons.info_outline,
                            iconColor: AppTheme.primaryStart,
                            title: 'About App',
                            subtitle: 'Version ${AppConstants.appVersion}',
                            onTap: () => _showAboutDialog(context),
                          ),
                          ModernSettingsTile(
                            icon: Icons.star_outline,
                            iconColor: AppTheme.warningYellow,
                            title: AppStrings.rateApp,
                            subtitle: 'Rate us on Play Store',
                            onTap: () {
                              Fluttertoast.showToast(
                                msg: 'Thank you for your support!',
                              );
                            },
                          ),
                          ModernSettingsTile(
                            icon: Icons.share,
                            iconColor: AppTheme.successGreen,
                            title: AppStrings.shareApp,
                            subtitle: 'Share with friends',
                            onTap: () {
                              Fluttertoast.showToast(
                                msg: 'Share functionality coming soon!',
                              );
                            },
                            showDivider: false,
                          ),
                        ],
                      ),


                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            ],
          );
        },
      ),
    );
  }

  /// Build switch tile for settings
  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showDivider = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
          trailing: Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: iconColor,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 72,
            endIndent: 16,
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
      ],
    );
  }

  /// Build app footer
  Widget _buildAppFooter(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [AppTheme.darkSurface, AppTheme.darkSurfaceVariant]
              : [Colors.white, AppTheme.lightSurfaceVariant],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryStart.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.picture_as_pdf,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.appName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version ${AppConstants.appVersion}',
            style: TextStyle(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '© 2026 PDFGen',
            style: TextStyle(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Get theme mode label
  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  /// Get theme mode icon
  IconData _getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.auto_mode;
    }
  }

  /// Show theme mode selection dialog
  Future<void> _showThemeModeDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final result = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Choose Theme',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildThemeOption(
                context,
                icon: Icons.auto_mode,
                title: 'System Default',
                subtitle: 'Follow system preference',
                isSelected: settings.themeMode == ThemeMode.system,
                onTap: () => Navigator.pop(context, ThemeMode.system),
              ),
              _buildThemeOption(
                context,
                icon: Icons.light_mode,
                title: 'Light',
                subtitle: 'Always use light theme',
                isSelected: settings.themeMode == ThemeMode.light,
                onTap: () => Navigator.pop(context, ThemeMode.light),
              ),
              _buildThemeOption(
                context,
                icon: Icons.dark_mode,
                title: 'Dark',
                subtitle: 'Always use dark theme',
                isSelected: settings.themeMode == ThemeMode.dark,
                onTap: () => Navigator.pop(context, ThemeMode.dark),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      settings.setThemeMode(result);
    }
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected 
            ? AppTheme.primaryStart.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? AppTheme.primaryStart
              : (isDark ? Colors.white10 : Colors.grey.shade200),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryStart.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryStart, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: AppTheme.primaryStart)
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Show page size selection dialog
  Future<void> _showPageSizeDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Select Page Size',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...AppConstants.pageSizes.map((size) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: settings.pageSize == size
                    ? AppTheme.accentBlue.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: settings.pageSize == size
                      ? AppTheme.accentBlue
                      : (isDark ? Colors.white10 : Colors.grey.shade200),
                ),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.description,
                  color: settings.pageSize == size ? AppTheme.accentBlue : Colors.grey,
                ),
                title: Text(
                  size,
                  style: TextStyle(
                    fontWeight: settings.pageSize == size ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: settings.pageSize == size
                    ? Icon(Icons.check_circle, color: AppTheme.accentBlue)
                    : null,
                onTap: () => Navigator.pop(context, size),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (result != null) {
      settings.setPageSize(result);
    }
  }

  /// Show image quality selection dialog
  Future<void> _showQualityDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    double currentQuality = settings.imageQuality;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Image Quality',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentTeal.withOpacity(0.1),
                      AppTheme.accentBlue.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${(currentQuality * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentTeal,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppTheme.accentTeal,
                  thumbColor: AppTheme.accentTeal,
                  overlayColor: AppTheme.accentTeal.withOpacity(0.2),
                  inactiveTrackColor: AppTheme.accentTeal.withOpacity(0.2),
                ),
                child: Slider(
                  value: currentQuality,
                  min: 0.5,
                  max: 1.0,
                  divisions: 10,
                  label: '${(currentQuality * 100).toInt()}%',
                  onChanged: (value) {
                    setState(() {
                      currentQuality = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Higher quality = larger file size',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        settings.setImageQuality(currentQuality);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentTeal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Show default file name dialog
  Future<void> _showFileNameDialog(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final controller = TextEditingController(text: settings.defaultFileName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Default File Name',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'File name prefix',
                  hintText: 'PDF_',
                  helperText: 'Files will be named: prefix_timestamp.pdf',
                  filled: true,
                  fillColor: isDark ? AppTheme.darkSurfaceVariant : AppTheme.lightSurfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLength: 20,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          settings.setDefaultFileName(controller.text);
                          Navigator.pop(context);
                          Fluttertoast.showToast(
                            msg: 'Default file name updated',
                            backgroundColor: Colors.green,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}