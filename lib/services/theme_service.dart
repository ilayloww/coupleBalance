import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String keyThemeMode = 'theme_mode';
  static const String keyThemeColor = 'theme_color';

  ThemeMode _themeMode = ThemeMode.system;
  int _themeColorIndex = 0; // Default to first color (Pink)

  ThemeMode get themeMode => _themeMode;
  int get themeColorIndex => _themeColorIndex;
  Color get selectedColor => availableColors[_themeColorIndex];

  static const List<Color> availableColors = [
    Colors.pinkAccent,
    Colors.blueAccent,
    Colors.green,
    Colors.orange,
    Colors.purpleAccent,
    Colors.teal,
    Colors.redAccent,
  ];

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Mode
    final themeIndex = prefs.getInt(keyThemeMode);
    if (themeIndex != null) {
      if (themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeIndex];
      }
    }

    // Load Color
    final colorIndex = prefs.getInt(keyThemeColor);
    if (colorIndex != null) {
      if (colorIndex >= 0 && colorIndex < availableColors.length) {
        _themeColorIndex = colorIndex;
      }
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyThemeMode, mode.index);
  }

  Future<void> setThemeColor(int index) async {
    if (index >= 0 && index < availableColors.length) {
      _themeColorIndex = index;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(keyThemeColor, index);
    }
  }
}
