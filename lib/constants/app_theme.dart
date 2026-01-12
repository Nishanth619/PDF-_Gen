import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Application theme configuration - Modern 2024 Design
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // ============================================
  // COLOR PALETTE
  // ============================================
  
  // Primary gradient colors (Purple-Violet)
  static const Color primaryStart = Color(0xFF667EEA);
  static const Color primaryEnd = Color(0xFF764BA2);
  
  // Secondary accent colors
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accentTeal = Color(0xFF2DD4BF);
  static const Color accentBlue = Color(0xFF3B82F6);
  
  // Semantic colors
  static const Color successGreen = Color(0xFF22C55E);
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF3B82F6);
  
  // Light mode surfaces
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  
  // Dark mode surfaces (True black for AMOLED)
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF171717);
  static const Color darkSurfaceVariant = Color(0xFF262626);
  
  // ============================================
  // GRADIENTS
  // ============================================
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryStart, primaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentOrange, Color(0xFFFF8C42)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [successGreen, Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ============================================
  // LIGHT THEME
  // ============================================
  
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    
    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.light(
        primary: primaryStart,
        secondary: accentTeal,
        tertiary: accentOrange,
        surface: lightSurface,
        surfaceContainerHighest: lightSurfaceVariant,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFF1E293B),
        onSurfaceVariant: const Color(0xFF64748B),
      ),
      textTheme: _buildTextTheme(base.textTheme, isDark: false),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        backgroundColor: lightBackground,
        foregroundColor: const Color(0xFF1E293B),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          backgroundColor: primaryStart,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: BorderSide(color: primaryStart.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryStart, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: primaryStart,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: lightSurface,
        selectedItemColor: primaryStart,
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: lightSurface,
        indicatorColor: primaryStart.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: primaryStart);
          }
          return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600);
        }),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurfaceVariant,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1E293B),
      ),
      dialogTheme: DialogThemeData(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
  
  // ============================================
  // DARK THEME
  // ============================================

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    
    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF818CF8), // Slightly lighter purple for dark
        secondary: accentTeal,
        tertiary: accentOrange,
        surface: darkSurface,
        surfaceContainerHighest: darkSurfaceVariant,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFFE2E8F0),
        onSurfaceVariant: const Color(0xFF94A3B8),
      ),
      textTheme: _buildTextTheme(base.textTheme, isDark: true),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        backgroundColor: darkBackground,
        foregroundColor: const Color(0xFFE2E8F0),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFE2E8F0),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          backgroundColor: const Color(0xFF818CF8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: BorderSide(color: const Color(0xFF818CF8).withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: Color(0xFF818CF8),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: darkSurface,
        selectedItemColor: const Color(0xFF818CF8),
        unselectedItemColor: Colors.grey.shade500,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: darkSurface,
        indicatorColor: const Color(0xFF818CF8).withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF818CF8));
          }
          return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade500);
        }),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.1),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceVariant,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: darkSurfaceVariant,
      ),
      dialogTheme: DialogThemeData(
        elevation: 8,
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: darkSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
  
  // ============================================
  // TYPOGRAPHY
  // ============================================
  
  static TextTheme _buildTextTheme(TextTheme base, {required bool isDark}) {
    final textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    
    return TextTheme(
      // Display styles
      displayLarge: GoogleFonts.outfit(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: textColor,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textColor,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: textColor,
      ),
      
      // Headline styles
      headlineLarge: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      
      // Title styles
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      
      // Body styles
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: subtitleColor,
      ),
      
      // Label styles
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: subtitleColor,
      ),
    );
  }
  
  // ============================================
  // HELPER WIDGETS
  // ============================================
  
  /// Creates a gradient container decoration
  static BoxDecoration gradientDecoration({
    LinearGradient? gradient,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      gradient: gradient ?? primaryGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: (gradient?.colors.first ?? primaryStart).withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  /// Creates a glass morphism effect
  static BoxDecoration glassDecoration({
    Color? color,
    double borderRadius = 16,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: (color ?? (isDark ? Colors.white : Colors.black)).withOpacity(0.05),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
      ),
    );
  }
}
