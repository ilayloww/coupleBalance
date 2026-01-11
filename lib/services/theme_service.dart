import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String keyThemeMode = 'theme_mode';
  static const String keyThemeColor = 'theme_color';

  final SharedPreferences _prefs;
  late ThemeMode _themeMode;
  late int _themeColorIndex;

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

  ThemeService(this._prefs) {
    _loadSync();
  }

  void _loadSync() {
    // Load Mode
    final themeIndex = _prefs.getInt(keyThemeMode);
    if (themeIndex != null &&
        themeIndex >= 0 &&
        themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    } else {
      _themeMode = ThemeMode.system;
    }

    // Load Color
    final colorIndex = _prefs.getInt(keyThemeColor);
    if (colorIndex != null &&
        colorIndex >= 0 &&
        colorIndex < availableColors.length) {
      _themeColorIndex = colorIndex;
    } else {
      _themeColorIndex = 0; // Default to first color
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs.setInt(keyThemeMode, mode.index);
  }

  Future<void> setThemeColor(int index) async {
    if (index >= 0 && index < availableColors.length) {
      if (_themeColorIndex == index) return;
      _themeColorIndex = index;
      notifyListeners();
      await _prefs.setInt(keyThemeColor, index);
    }
  }
}
