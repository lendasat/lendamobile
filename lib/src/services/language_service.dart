import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';

  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  static const Map<String, String> languageNames = {
    'en': 'English',
    'es': 'Spanish',
    'de': 'German',
    'it': 'Italian',
    'fr': 'French',
    'zh': 'Chinese',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'ja': 'Japanese',
    'id': 'Indonesian',
    'ur': 'Urdu',
  };

  static const Map<String, String> languageFlags = {
    'en': '🇬🇧',
    'es': '🇪🇸',
    'de': '🇩🇪',
    'it': '🇮🇹',
    'fr': '🇫🇷',
    'zh': '🇨🇳',
    'ar': '🇸🇦',
    'hi': '🇮🇳',
    'ja': '🇯🇵',
    'id': '🇮🇩',
    'ur': '🇵🇰',
  };

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('de'),
    Locale('it'),
    Locale('fr'),
    Locale('zh'),
    Locale('ar'),
    Locale('hi'),
    Locale('ja'),
    Locale('id'),
    Locale('ur'),
  ];

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);

    if (languageCode != null) {
      _currentLocale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (!languageNames.containsKey(languageCode)) {
      throw ArgumentError('Unsupported language code: $languageCode');
    }

    _currentLocale = Locale(languageCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);

    notifyListeners();
  }

  String getLanguageName(String languageCode) {
    return languageNames[languageCode] ?? languageCode;
  }

  String getLanguageFlag(String languageCode) {
    return languageFlags[languageCode] ?? '🏳️';
  }
}
