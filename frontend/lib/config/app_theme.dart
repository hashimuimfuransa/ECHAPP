import 'package:flutter/material.dart';

class AppTheme {
  /* =========================
     MODERN COLOR PALETTE
     ========================= */

  // Primary brand colors (Enhanced Emerald / Teal)
  static const Color primary = Color(0xFF10B981); // Emerald 500
  static const Color primaryDark = Color(0xFF047857); // Emerald 700
  static const Color primarySoft = Color(0xFFD1FAE5); // Emerald 100
  static const Color primaryLight = Color(0xFF6EE7B7); // Emerald 300

  // Accent (Modern Blue)
  static const Color accent = Color(0xFF3B82F6); // Blue 500
  static const Color accentSoft = Color(0xFFDBEAFE); // Blue 100

  // Neutrals
  // Legacy color aliases for backward compatibility
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color blackColor = Color(0xFF0A0A0A);
  static const Color greyColor = Color(0xFF6B7280);
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color white70 = Color(0xB3FFFFFF); // 70% opacity white
  static const Color white60 = Color(0x99FFFFFF); // 60% opacity white
  
  static const Color white = Color(0xFFFFFFFF); // Pure white
  static const Color black = Color(0xFF0A0A0A); // Rich black
  static const Color grey = Color(0xFF6B7280); // Stone gray
  static const Color borderGrey = Color(0xFFD1D5DB); // Light border
  static const Color surface = Color(0xFFF8FAFC); // Soft surface
  static const Color card = Color(0xFFFFFFFF); // Card background

  // Theme-aware color getters
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
      ? darkTextPrimary 
      : blackColor;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
      ? darkTextSecondary 
      : greyColor;
  }

  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
      ? darkBg 
      : surface;
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
      ? darkCard 
      : card;
  }

  static Color getIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
      ? darkTextPrimary 
      : blackColor;
  }

  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
      ? Colors.red.shade300  // Lighter red for dark mode
      : errorColor;          // Original red for light mode
  }

  // Dark mode neutrals - Enhanced for better visual appeal
  static const Color darkBg = Color(0xFF0F1419); // Deep space black with subtle blue undertone
  static const Color darkSurface = Color(0xFF1A202C); // Rich dark blue-gray
  static const Color darkCard = Color(0xFF2D3748); // Slightly lighter for better contrast
  static const Color darkTextPrimary = Color(0xFFE2E8F0); // Soft white with warm undertone
  static const Color darkTextSecondary = Color(0xFFA0AEC0); // Warm gray for better readability

  /* =========================
     GRADIENTS (MODERN)
     ========================= */

  static const List<Color> primaryGradient = [
    Color(0xFF10B981),
    Color(0xFF047857),
  ];

  static const List<Color> accentGradient = [
    Color(0xFF3B82F6),
    Color(0xFF1D4ED8),
  ];

  static const List<Color> softBackgroundGradient = [
    Color(0xFFF9FAFB),
    Color(0xFFF1F5F9),
  ];

  // Additional gradients
  static const List<Color> oceanGradient = [
    Color(0xFF4facfe),
    Color(0xFF00f2fe),
  ];
  
  static const List<Color> sunsetGradient = [
    Color(0xFFFF9a9e),
    Color(0xFFfecfef),
    Color(0xFFfecfef),
  ];
  
  // Modern gradients for UI components
  static const List<Color> modernCardGradient = [
    Color(0xFFF8FAFC),
    Color(0xFFFFFFFF),
  ];
  
  static const List<Color> darkCardGradient = [
    Color(0xFF1E293B),
    Color(0xFF334155),
  ];
  
  static const List<Color> accentGradientModern = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];

  // Additional colors
  static const Color lightGreen = Color(0xFFE0F2E9);
  static const Color successColor = Color(0xFF10B981); // Green for success
  static const Color errorColor = Color(0xFFEF4444); // Red for errors
  static const Color warningColor = Color(0xFFF59E0B); // Amber for warnings
  static const Color infoColor = Color(0xFF3B82F6); // Blue for info
  
  // Modern UI colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundDark = Color(0xFF1F2937);
  static const Color elevatedSurface = Color(0xFFF9FAFB);
  static const Color elevatedSurfaceDark = Color(0xFF111827);

  /* =========================
     LIGHT THEME
     ========================= */

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: surface,

    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: surface,
      onSurface: blackColor,
      onPrimary: Colors.white,
      // Enhanced color scheme
      surfaceVariant: elevatedSurface,
      onSurfaceVariant: greyColor,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: blackColor, // Clearer text
      elevation: 0,
      centerTitle: true,
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: blackColor,
        letterSpacing: -0.8,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: blackColor,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: blackColor,
        height: 1.4,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: blackColor,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: blackColor,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: blackColor,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: greyColor,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: greyColor,
        height: 1.4,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card, // Clean input background
      hintStyle: const TextStyle(color: greyColor), // Clear hint text
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),

    cardTheme: CardThemeData(
      color: cardBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.all(12),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 6,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  /* =========================
     DARK THEME
     ========================= */

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    
    // Enhanced color scheme for dark mode
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: Color(0xFF4FD1C7), // Turquoise accent for better contrast
      surface: darkSurface,
      onSurface: darkTextPrimary,
      onPrimary: Colors.white,
      surfaceVariant: elevatedSurfaceDark,
      onSurfaceVariant: darkTextSecondary,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: darkTextPrimary, // Clearer text
      elevation: 0,
      centerTitle: true,
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: darkTextPrimary,
        letterSpacing: -0.8,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: darkTextPrimary,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
        height: 1.4,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: darkTextPrimary,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: darkTextPrimary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: darkTextSecondary,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: darkTextSecondary,
        height: 1.4,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      hintStyle: const TextStyle(color: darkTextSecondary), // Clearer hint text
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),

    cardTheme: CardThemeData(
      color: cardBackgroundDark,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.all(12),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: primary,
      unselectedItemColor: darkTextSecondary, // Clearer unselected text
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  static const List<Color> secondaryGradient = [
    Color(0xFF8B5CF6), // Purple 500
    Color(0xFF7C3AED), // Purple 600
  ];
}
