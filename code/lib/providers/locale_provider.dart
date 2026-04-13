import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(String savedLocale) : super(_parseLocale(savedLocale));

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

  static Locale _parseLocale(String code) {
    final parts = code.split('_');
    if (parts.length >= 2) {
      return Locale(parts[0], parts[1]);
    }
    return const Locale('en', 'US');
  }

  static Locale detectSystemLocale() {
    final systemLocale = Platform.localeName;
    final parsed = _parseLocale(systemLocale);
    for (final supported in supportedLocales) {
      if (supported.languageCode == parsed.languageCode) {
        return supported;
      }
    }
    return const Locale('en', 'US');
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier('en_US');
});
