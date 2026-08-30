import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'core/diagnostics/startup_trace.dart';
import 'core/i18n/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'providers/locale_provider.dart';
import 'ui/screens/home_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

/// Tells the reader that a settings change did not reach disk.
///
/// Separate wording from a document's save failure: the reader is looking at
/// a switch they have just flicked, and "could not save the file" would send
/// them looking at their document.
void reportSettingsSaveFailure(Object error) {
  final context = navigatorKey.currentContext;
  if (context == null || !context.mounted) return;
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n == null
          ? 'Could not save your settings: $error'
          : l10n.settingsSaveFailed('$error')),
    ),
  );
}

/// Tells the reader that a save did not happen.
///
/// All three save paths — the menu, Save As, and the one the tab bar uses when
/// closing — used to swallow the failure. Ctrl+S on a read-only file, or one
/// another program holds open, did nothing at all: no message, and the only
/// clue was the modified dot that stayed put. Upstream MarkText notifies on
/// every one of these.
/// Tells the reader that a file could not be opened.
///
/// The sidebar's own open has caught this for a long time and takes its
/// half-built tab back down. The File menu, Open Recent, and the link the
/// Help menu follows were the copies that did not keep up: a file that has
/// become unreadable since it was picked left no tab, no message, and
/// nothing to try again from.
void reportOpenFailure(Object error) {
  final context = navigatorKey.currentContext;
  if (context == null || !context.mounted) return;
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n == null
          ? 'Could not open the file: $error'
          : l10n.fileOpenFailed('$error')),
    ),
  );
}

/// Tells the reader that an export or a print did not happen.
///
/// The four entry points — HTML, PDF, Word and Print — all call something
/// that throws on an unwritable path, a folder where a file was expected, or
/// a document the PDF writer cannot lay out, and none of them caught it.
/// They are `async void` event handlers, so the throw escaped as an unhandled
/// asynchronous error: the reader chose a filename, pressed Export, and
/// nothing whatever happened. The save paths were given this treatment long
/// ago; the export paths were not.
void reportExportFailure(Object error) {
  final context = navigatorKey.currentContext;
  if (context == null || !context.mounted) return;
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n == null
          ? 'Could not export the document: $error'
          : l10n.exportFailed('$error')),
    ),
  );
}

void reportSaveFailure(Object error) {
  final context = navigatorKey.currentContext;
  if (context == null || !context.mounted) return;
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n == null
          ? 'Could not save the file: $error'
          : l10n.saveFailed('$error')),
    ),
  );
}

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
    // The four fields the theme depends on, as one record: `select` compares
    // with `==`, and a record of strings and a bool compares by value, so this
    // still rebuilds only when one of them actually changes.
    final (chosen, followSystem, lightChoice, darkChoice) =
        ref.watch(settingsProvider.select(
      (c) => (c.themeName, c.followSystemTheme, c.lightModeTheme,
          c.darkModeTheme),
    ));
    // Reading it here is what subscribes this widget to the operating system's
    // light/dark switch: without the dependency the app would keep whichever
    // theme it started with until the next launch.
    final systemBrightness = MediaQuery.platformBrightnessOf(context);
    final themeName = AppTheme.resolveThemeName(
      followSystem: followSystem,
      chosen: chosen,
      lightChoice: lightChoice,
      darkChoice: darkChoice,
      systemBrightness: systemBrightness,
    );
    final textDirection =
        ref.watch(settingsProvider.select((c) => c.textDirection));
    final locale = ref.watch(localeProvider);
    final tokens = AppTheme.getTokens(themeName);
    StartupTrace.markOnce('app root built (theme and locale resolved)');

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
