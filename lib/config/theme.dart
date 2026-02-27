import 'package:flutter/material.dart';

class AppTheme {
  // --- Colors ---
  static const Color emeraldPrimary = Color(0xFF2ECC71); // Neon Green
  static const Color darkBackground = Color(
    0xFF05100A,
  ); // Deep Dark Green/Black
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color glassColor = Color(0x0DFFFFFF); // White with 5% opacity

  // --- Light Theme (Legacy/Fallback) ---
  static ThemeData lightTheme(Color seedColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
    );
  }

  // --- Dark Theme (Emerald) ---
  static ThemeData darkTheme(Color seedColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: emeraldPrimary,
        secondary: emeraldPrimary,
        surface: surfaceColor,
        onSurface: Colors.white,
        error: Colors.redAccent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // For glass effect headers
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emeraldPrimary,
          foregroundColor: Colors.black, // Dark text on bright green
          elevation: 5,
          shadowColor: emeraldPrimary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Capsule shape
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassColor,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: emeraldPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: Colors.white70, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.white60, fontSize: 14),
      ),
    );
  }
}
