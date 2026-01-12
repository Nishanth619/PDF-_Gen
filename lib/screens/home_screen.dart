import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_theme.dart';
import '../constants/strings.dart';
import '../providers/pdf_provider.dart';
import '../utils/responsive_helper.dart';
import '../widgets/banner_ad_widget.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'terms_screen.dart';

/// Main home screen with bottom navigation (mobile) or side navigation (tablet)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: AppStrings.homeTab,
    ),
    NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history),
      label: AppStrings.historyTab,
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: AppStrings.settingsTab,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkTermsAccepted();
    // Load PDF files when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PdfProvider>().loadPdfFiles();
    });
  }

  Future<void> _checkTermsAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    final bool termsAccepted = prefs.getBool('terms_accepted') ?? false;
    
    // If terms not accepted, redirect to terms screen
    if (!termsAccepted && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TermsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use side navigation for tablets in landscape
    final useSideNav = ResponsiveHelper.shouldUseSideNavigation(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    
    if (useSideNav) {
      return _buildTabletLayout();
    }
    
    return _buildMobileLayout(isTablet);
  }

  /// Mobile layout with bottom navigation
  Widget _buildMobileLayout(bool isTablet) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner Ad - hidden for premium users
          const BannerAdWidget(),
          // Bottom Navigation
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            labelBehavior: isTablet 
                ? NavigationDestinationLabelBehavior.alwaysShow
                : NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: _destinations,
          ),
        ],
      ),
    );
  }

  /// Tablet layout with side navigation rail
  Widget _buildTabletLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLargeTablet = ResponsiveHelper.isLargeTablet(context);
    
    return Scaffold(
      body: Row(
        children: [
          // Side Navigation Rail
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            extended: isLargeTablet, // Expand labels on large tablets
            minWidth: 72,
            minExtendedWidth: 200,
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: isLargeTablet 
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'PDFGen',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
            ),
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: const Text(AppStrings.homeTab),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.history_outlined),
                selectedIcon: const Icon(Icons.history),
                label: const Text(AppStrings.historyTab),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: const Text(AppStrings.settingsTab),
              ),
            ],
          ),
          // Divider
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Expanded screen content
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
                // Banner ad at bottom
                const BannerAdWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}