import 'package:flutter/material.dart';

class AppTheme {
  // --- Light Theme ---
  static ThemeData lightTheme(Color seedColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
        primary: seedColor,
        secondary: Colors.blueAccent,
        surface: Colors.white,
        onSurface: Colors.black87,
        surfaceContainerHighest: Colors.grey[100],
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: seedColor, width: 2),
        ),
      ),
      textTheme: const TextTheme(
        bodySmall: TextStyle(color: Colors.black54),
        bodyMedium: TextStyle(color: Colors.black87),
      ),
    );
  }

  // --- Dark Theme ---
  static ThemeData darkTheme(Color seedColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
        primary:
            seedColor, // Potentially lighter for dark mode? Let Material3 handle it mostly.
        secondary: Colors.blueAccent[200]!,
        surface: const Color(0xFF121212),
        onSurface: Colors.white,
        surfaceContainerHighest: const Color(0xFF1E1E1E),
      ),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF121212),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor.withValues(alpha: 0.8), // Slightly muted?
          foregroundColor:
              Colors.black, // Dark text on light accent? Or white on dark?
          // Material 3 defaults are usually good. Let's force seed color but ensure text contrast.
          // If seed is pink (bright), black text might be better. If dark purple, white.
          // For simplicity, let's keep it consistent with previous:
          // Previous was pinkAccent[200] (light pink) + black text.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        hintStyle: TextStyle(color: Colors.grey[400]),
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: seedColor, width: 2),
        ),
      ),
      textTheme: const TextTheme(
        bodySmall: TextStyle(color: Colors.white70),
        bodyMedium: TextStyle(color: Colors.white),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF121212),
        modalBackgroundColor: Color(0xFF121212),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF121212),
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF333333),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}
