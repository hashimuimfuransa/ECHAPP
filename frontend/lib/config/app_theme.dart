import 'package:flutter/material.dart';

class AppTheme {
  /* =========================
     MODERN COLOR PALETTE
     ========================= */

  // Primary brand colors (Emerald / Teal)
  static const Color primary = Color(0xFF10B981); // Emerald 500
  static const Color primaryDark = Color(0xFF047857); // Emerald 700
  static const Color primarySoft = Color(0xFFD1FAE5); // Emerald 100

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

  // Dark mode neutrals
  static const Color darkBg = Color(0xFF0F172A); // Midnight blue
  static const Color darkSurface = Color(0xFF1E293B); // Deep blue-gray
  static const Color darkCard = Color(0xFF1E293B); // Consistent with surface
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // White text
  static const Color darkTextSecondary = Color(0xFFCBD5E1); // Light gray text

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

  // Additional colors
  static const Color lightGreen = Color(0xFFE0F2E9);

  /* =========================
     LIGHT THEME
     ========================= */

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: surface, // Better background

    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: surface, // Updated surface color
      onSurface: blackColor, // Clear text on surface
      onPrimary: Colors.white,
      background: surface, // Consistent background
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: blackColor, // Clearer text
      elevation: 0,
      centerTitle: true,
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: blackColor, // Clearer headline
        letterSpacing: -0.6,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: blackColor, // Clearer headline
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: blackColor, // Clearer title
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: blackColor, // Clearer body text
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: greyColor, // Clearer secondary text
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

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    cardTheme: CardThemeData(
      color: card, // Cleaner card background
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.all(12),
    ),
  );

  /* =========================
     DARK THEME
     ========================= */

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,

    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: darkSurface,
      onSurface: darkTextPrimary, // Clearer text
      onPrimary: Colors.white,
      background: darkBg, // Consistent background
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: darkTextPrimary, // Clearer text
      elevation: 0,
      centerTitle: true,
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: darkTextPrimary, // Clearer headline
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: darkTextPrimary, // Clearer headline
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary, // Clearer title
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: darkTextPrimary, // Clearer body text
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: darkTextSecondary, // Clearer secondary text
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
      color: darkCard, // Consistent card background
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shadowColor: Colors.black12,
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
}
