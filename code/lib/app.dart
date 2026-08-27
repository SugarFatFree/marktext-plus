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

  /// The brightness already pushed to the window.
  ///
  /// Setting it is a platform channel call, and this used to run on every
  /// rebuild of the app root.
  static Brightness? _appliedBrightness;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only the theme name matters here. Watching the whole config rebuilt the
    // entire app whenever any setting was written — the split divider
    // position, the list of open files, the last update check.
    final themeName = ref.watch(settingsProvider.select((c) => c.themeName));
    final textDirection =
        ref.watch(settingsProvider.select((c) => c.textDirection));
    final locale = ref.watch(localeProvider);
    final tokens = AppTheme.getTokens(themeName);

    // Sync window brightness with theme
    if (_appliedBrightness != tokens.brightness) {
      _appliedBrightness = tokens.brightness;
      windowManager.setBrightness(tokens.brightness);
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MarkText Plus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(themeName),
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
        // The setting existed but nothing read it, so choosing a direction did
        // nothing. An explicit 'rtl' now wins; otherwise the language decides,
        // which keeps Arabic right-to-left by default.
        textDirection: textDirection == 'rtl' || locale.languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: const HomeScreen(),
      ),
    );
  }
}
