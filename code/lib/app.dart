import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'core/i18n/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'providers/locale_provider.dart';
import 'ui/screens/home_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class MarkTextPlusApp extends ConsumerWidget {
  const MarkTextPlusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(settingsProvider);
    final locale = ref.watch(localeProvider);
    final tokens = AppTheme.getTokens(config.themeName);

    // Sync window brightness with theme
    windowManager.setBrightness(tokens.brightness);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MarkText Plus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(config.themeName),
      themeMode: tokens.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      themeAnimationDuration: Duration.zero,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Directionality(
        textDirection: locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: const HomeScreen(),
      ),
    );
  }
}
