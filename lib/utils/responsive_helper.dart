import 'package:flutter/material.dart';

/// Responsive helper utility for adaptive layouts
class ResponsiveHelper {
  /// Screen size breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Get screen type based on width
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) {
      return ScreenType.mobile;
    } else if (width < tabletBreakpoint) {
      return ScreenType.tablet;
    } else if (width < desktopBreakpoint) {
      return ScreenType.largeTablet;
    } else {
      return ScreenType.desktop;
    }
  }

  /// Check if screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if screen is tablet or larger
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= mobileBreakpoint;
  }

  /// Check if screen is large tablet or larger
  static bool isLargeTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Check if screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get responsive value based on screen size
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? largeTablet,
    T? desktop,
  }) {
    final screenType = getScreenType(context);
    switch (screenType) {
      case ScreenType.desktop:
        return desktop ?? largeTablet ?? tablet ?? mobile;
      case ScreenType.largeTablet:
        return largeTablet ?? tablet ?? mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.mobile:
        return mobile;
    }
  }

  /// Get responsive grid column count
  static int getGridColumns(BuildContext context) {
    return value<int>(
      context: context,
      mobile: 2,
      tablet: 3,
      largeTablet: 3,
      desktop: 3,
    );
  }

  /// Get responsive padding
  static EdgeInsets getScreenPadding(BuildContext context) {
    return value<EdgeInsets>(
      context: context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      largeTablet: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      desktop: const EdgeInsets.symmetric(horizontal: 60, vertical: 32),
    );
  }

  /// Get max content width for centering content on large screens
  static double? getMaxContentWidth(BuildContext context) {
    return value<double?>(
      context: context,
      mobile: null,
      tablet: null,
      largeTablet: 1000,
      desktop: 1200,
    );
  }

  /// Get responsive font size multiplier
  static double getFontSizeMultiplier(BuildContext context) {
    return value<double>(
      context: context,
      mobile: 1.0,
      tablet: 1.1,
      largeTablet: 1.15,
      desktop: 1.2,
    );
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context, {double baseSize = 24}) {
    final multiplier = value<double>(
      context: context,
      mobile: 1.0,
      tablet: 1.2,
      largeTablet: 1.3,
      desktop: 1.4,
    );
    return baseSize * multiplier;
  }

  /// Get responsive card aspect ratio
  static double getCardAspectRatio(BuildContext context) {
    return value<double>(
      context: context,
      mobile: 0.95,
      tablet: 1.0,
      largeTablet: 1.05,
      desktop: 1.1,
    );
  }

  /// Get responsive spacing
  static double getSpacing(BuildContext context, {double baseSpacing = 16}) {
    final multiplier = value<double>(
      context: context,
      mobile: 1.0,
      tablet: 1.25,
      largeTablet: 1.5,
      desktop: 1.75,
    );
    return baseSpacing * multiplier;
  }

  /// Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Should use side navigation (for tablets in landscape)
  static bool shouldUseSideNavigation(BuildContext context) {
    return isTablet(context) && isLandscape(context);
  }
}

/// Screen type enum
enum ScreenType {
  mobile,
  tablet,
  largeTablet,
  desktop,
}

/// Responsive widget builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenType screenType) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenType = ResponsiveHelper.getScreenType(context);
        return builder(context, screenType);
      },
    );
  }
}

/// Responsive layout that shows different widgets based on screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? largeTablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.largeTablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenType = ResponsiveHelper.getScreenType(context);
        switch (screenType) {
          case ScreenType.desktop:
            return desktop ?? largeTablet ?? tablet ?? mobile;
          case ScreenType.largeTablet:
            return largeTablet ?? tablet ?? mobile;
          case ScreenType.tablet:
            return tablet ?? mobile;
          case ScreenType.mobile:
            return mobile;
        }
      },
    );
  }
}

/// Constrained content wrapper for large screens
class ResponsiveContentWrapper extends StatelessWidget {
  final Widget child;
  final bool centerContent;

  const ResponsiveContentWrapper({
    super.key,
    required this.child,
    this.centerContent = true,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveHelper.getMaxContentWidth(context);
    
    if (maxWidth == null) {
      return child;
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
