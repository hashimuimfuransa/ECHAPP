import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// MaterialLocalizations delegate for Kinyarwanda locale
/// Since Flutter's GlobalMaterialLocalizations doesn't support Kinyarwanda,
/// we load English MaterialLocalizations as a fallback.
/// This is a standard pattern for unsupported locales in professional Flutter apps.
class KinyarwandaMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const KinyarwandaMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'rw';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    // Load English MaterialLocalizations for Kinyarwanda locale
    // App-specific translations (from ARB files) will still be in Kinyarwanda
    return GlobalMaterialLocalizations.delegate.load(const Locale('en'));
  }

  @override
  bool shouldReload(KinyarwandaMaterialLocalizationsDelegate old) => false;
}
