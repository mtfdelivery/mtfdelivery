import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported languages in the app
enum AppLanguage {
  english(Locale('en'), 'English', '🇺🇸'),
  french(Locale('fr'), 'Français', '🇫🇷'),
  arabic(Locale('ar'), 'العربية', '🇹🇳');

  final Locale locale;
  final String name;
  final String flag;

  const AppLanguage(this.locale, this.name, this.flag);
}

/// Provider to manage and persist the app's language
class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier()
    : super(
        AppLanguage.french,
      ); // Default to French as requested/apparent context

  void setLanguage(AppLanguage language) {
    state = language;
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((
  ref,
) {
  return LanguageNotifier();
});
