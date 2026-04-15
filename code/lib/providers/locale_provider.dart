import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(super.initial);

  static const supportedLocales = [
    Locale('en', 'US'),
    Locale('zh', 'CN'),
    Locale('ja', 'JP'),
    Locale('ko', 'KR'),
    Locale('de', 'DE'),
    Locale('fr', 'FR'),
    Locale('it', 'IT'),
    Locale('ru', 'RU'),
    Locale('es', 'ES'),
    Locale('pt', 'PT'),
    Locale('ar', 'SA'),
    Locale('pt', 'BR'),
  ];

  void setLocale(Locale locale) {
    state = locale;
  }

  bool get isRtl => state.languageCode == 'ar';

  static Locale parseLocale(String code) {
    if (code.isEmpty) return detectSystemLocale();
    final parts = code.split('_');
    final lang = parts[0];
    final country = parts.length >= 2 ? parts[1] : null;
    // Match against supported locales
    for (final supported in supportedLocales) {
      if (supported.languageCode == lang) {
        if (country != null && supported.countryCode == country) {
          return supported;
        }
      }
    }
    // Fallback: match by language code only
    for (final supported in supportedLocales) {
      if (supported.languageCode == lang) {
        return supported;
      }
    }
    return const Locale('en', 'US');
  }

  static Locale detectSystemLocale() {
    final systemLocale = Platform.localeName;
    return parseLocale(systemLocale);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  throw UnimplementedError('localeProvider must be overridden');
});
