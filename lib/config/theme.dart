import 'package:flutter/material.dart';

class AppTheme {
  // --- Light Theme ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.pinkAccent,
      brightness: Brightness.light,
      primary: Colors.pinkAccent,
      secondary: Colors.blueAccent,
      surface: Colors.white,
      onSurface: Colors.black87,
      surfaceContainerHighest: Colors.grey[100], // Light grey backgrounds
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
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        borderSide: const BorderSide(color: Colors.pinkAccent, width: 2),
      ),
    ),
  );

  // --- Dark Theme ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.pinkAccent,
      brightness: Brightness.dark,
      primary: Colors.pinkAccent[200]!, // Potentially lighter for dark mode
      secondary: Colors.blueAccent[200]!,
      surface: const Color(0xFF121212), // Dark grey surface
      onSurface: Colors.white,
      surfaceContainerHighest: const Color(
        0xFF1E1E1E,
      ), // Slightly lighter grey for inputs
    ),
    scaffoldBackgroundColor: Colors.black, // True black background
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
        backgroundColor: Colors.pinkAccent[200], // Lighter pink for visibility
        foregroundColor: Colors.black, // Dark text on light accent
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        borderSide: BorderSide(color: Colors.pinkAccent[200]!, width: 2),
      ),
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
