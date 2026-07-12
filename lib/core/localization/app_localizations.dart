import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/auth_storage.dart';
import 'i18n/es.dart';
import 'i18n/en.dart';
import 'i18n/fr.dart';

/// Manages multi-language dictionaries for Spanish, English, and French.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'es': esKeys,
    'en': enKeys,
    'fr': frKeys,
  };

  String translate(String key) {
    final langCode = locale.languageCode;
    return _localizedValues[langCode]?[key] ?? key;
  }
}

/// Flutter Localizations Delegate for AppLocalizations.
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['es', 'en', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

/// Shorthand translation extension for BuildContext.
extension LocalizationExtension on BuildContext {
  String tr(String key) {
    return AppLocalizations.of(this)?.translate(key) ?? key;
  }
}

/// Provider to manage language state, persistence, and HTTP headers configuration.
class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('es');

  Locale get locale => _locale;
  String get currentLanguageCode => _locale.languageCode;

  LanguageProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final savedCode = await AuthStorage.getLocale();
    _locale = Locale(savedCode);
    ApiConfig.activeLocale = savedCode;
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (_locale.languageCode != languageCode) {
      _locale = Locale(languageCode);
      ApiConfig.activeLocale = languageCode;
      await AuthStorage.saveLocale(languageCode);
      notifyListeners();
    }
  }
}
