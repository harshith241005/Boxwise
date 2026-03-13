import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42D4);
  static const Color accentColor = Color(0xFF00D9A6);
  static const Color accentLight = Color(0xFF5CFFD3);
  static const Color warningColor = Color(0xFFFFB74D);
  static const Color errorColor = Color(0xFFEF5350);
  static const Color successColor = Color(0xFF66BB6A);

  // Box colors for users to pick
  static const List<Color> boxColors = [
    Color(0xFF6C63FF), // Purple
    Color(0xFF00D9A6), // Teal
    Color(0xFFFF6B6B), // Coral
    Color(0xFFFFB74D), // Amber
    Color(0xFF4FC3F7), // Sky Blue
    Color(0xFFAB47BC), // Violet
    Color(0xFF66BB6A), // Green
    Color(0xFFFF8A65), // Deep Orange
    Color(0xFF42A5F5), // Blue
    Color(0xFFEC407A), // Pink
    Color(0xFF26C6DA), // Cyan
    Color(0xFFFDD835), // Yellow
  ];

  // Dark Theme
  static ThemeData getDarkTheme(Color primary) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.dark(
        primary: primary,
        primaryContainer: primary.withAlpha(200),
        secondary: accentColor,
        secondaryContainer: accentColor.withAlpha(51),
        surface: const Color(0xFF1A1A2E),
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0F23),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A2E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withAlpha(26),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: TextStyle(
          color: Colors.white.withAlpha(102),
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1A1A2E),
        selectedItemColor: primary,
        unselectedItemColor: Colors.white.withAlpha(102),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primary.withAlpha(26),
        labelStyle: TextStyle(
          color: primary,
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2A2A4A),
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Light Theme
  static ThemeData getLightTheme(Color primary) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.light(
        primary: primary,
        primaryContainer: primary.withAlpha(200),
        secondary: accentColor,
        secondaryContainer: accentColor.withAlpha(51),
        surface: Colors.white,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: const Color(0xFF1A1A2E),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A2E),
        ),
        iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: const Color(0xFF1A1A2E).withAlpha(26),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: TextStyle(
          color: const Color(0xFF1A1A2E).withAlpha(102),
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: const Color(0xFF1A1A2E).withAlpha(102),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primary.withAlpha(26),
        labelStyle: TextStyle(
          color: primary,
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A1A2E),
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
