import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends ChangeNotifier {
  static const String _keyLocale = 'locale';
  final SharedPreferences _prefs;
  late Locale _locale;

  Locale get locale => _locale;

  LocalizationService(this._prefs) {
    _loadSync();
  }

  void _loadSync() {
    final languageCode = _prefs.getString(_keyLocale);
    if (languageCode != null) {
      _locale = Locale(languageCode);
    } else {
      _locale = const Locale('en');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    await _prefs.setString(_keyLocale, locale.languageCode);
  }
}
