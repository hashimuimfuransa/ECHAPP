import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Language codes
const String languageCodeKey = 'app_language_code';
const String hasSelectedLanguageKey = 'has_selected_language';

// Supported locales
const List<Locale> supportedLocales = [
  Locale('en'), // English
  Locale('rw'), // Kinyarwanda
];

// Language names for display
const Map<String, String> languageNames = {
  'en': 'English',
  'rw': 'Kinyarwanda',
};

// Language names in native language
const Map<String, String> nativeLanguageNames = {
  'en': 'English',
  'rw': 'Ikinyarwanda',
};

// Localization notifier
class LocalizationNotifier extends StateNotifier<Locale> {
  LocalizationNotifier() : super(const Locale('en')) {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(languageCodeKey);
    debugPrint('LocalizationNotifier: Loading saved language: $languageCode');
    if (languageCode != null && _isSupportedLocale(languageCode)) {
      state = Locale(languageCode);
      debugPrint('LocalizationNotifier: Loaded locale: $state');
    } else {
      debugPrint('LocalizationNotifier: Using default locale: $state');
    }
  }

  bool _isSupportedLocale(String languageCode) {
    return supportedLocales.any((locale) => locale.languageCode == languageCode);
  }

  Future<void> setLanguage(String languageCode) async {
    debugPrint('LocalizationNotifier: setLanguage called with $languageCode, current state is $state');
    if (languageCode != state.languageCode && _isSupportedLocale(languageCode)) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(languageCodeKey, languageCode);
      state = Locale(languageCode);
      debugPrint('LocalizationNotifier: State updated to $state');
    } else {
      debugPrint('LocalizationNotifier: Language not changed (same or unsupported)');
    }
  }

  Future<void> markLanguageSelected() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(hasSelectedLanguageKey, true);
  }

  Future<bool> hasSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(hasSelectedLanguageKey) ?? false;
  }

  String get currentLanguageCode => state.languageCode;
  String get currentLanguageName => languageNames[state.languageCode] ?? 'English';
  String get currentNativeLanguageName => nativeLanguageNames[state.languageCode] ?? 'English';
}

// Provider for the current locale
final localeProvider = StateNotifierProvider<LocalizationNotifier, Locale>((ref) {
  return LocalizationNotifier();
});

// Provider to check if language has been selected
final hasSelectedLanguageProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(hasSelectedLanguageKey) ?? false;
});

// Extension to easily get translations in widgets
extension LocalizationExtension on BuildContext {
  String translate(String key, {Map<String, String>? params}) {
    // This will be replaced with proper localization when flutter_localizations is set up
    // For now, return the key as a fallback
    return key;
  }
}
