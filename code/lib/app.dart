import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'core/diagnostics/startup_trace.dart';
import 'core/i18n/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'providers/locale_provider.dart';
import 'ui/screens/home_screen.dart';
import 'services/window_capture.dart';

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
/// Tells the reader that a tab would not close because its file changed.
///
/// Reuses the wording the save-conflict dialog uses, so the same situation is
/// named the same way wherever it comes up.
void reportDiskConflict(String fileName) {
  final context = navigatorKey.currentContext;
  if (context == null || !context.mounted) return;
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n == null
          ? 'File changed on disk: $fileName'
          : '${l10n.saveConflictTitle}: $fileName'),
    ),
  );
}

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

/// Runs an export, saying so while it runs and saying where it went after.
///
/// Exporting used to be silent both ways: the window sat there while the file
/// was written — three seconds for a hundred kilobyte document, longer for a
/// large one — and then nothing was said, so there was no way to tell a
/// finished export from one that had not started. Only failure spoke.
///
/// The barrier is honest about what it can do: the heavy part of a PDF export
/// runs on this isolate, so the spinner will not turn while it does. What the
/// reader gets is a window that says what it is busy with rather than one that
/// has apparently died.
Future<void> runExport(String fileName, Future<void> Function() export) async {
  final context = navigatorKey.currentContext;
  if (context == null || !context.mounted) {
    // No window to report to; the export still has to happen.
    try {
      await export();
    } catch (e) {
      reportExportFailure(e);
    }
    return;
  }

  final l10n = AppLocalizations.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Flexible(child: Text(l10n?.exportInProgress ?? 'Exporting…')),
          ],
        ),
      ),
    ),
  );
  // One frame, so the dialog is on screen before the work begins.
  await Future<void>.delayed(Duration.zero);

  Object? failure;
  try {
    await export();
  } catch (e) {
    failure = e;
  }

  navigatorKey.currentState?.pop();
  if (failure != null) {
    reportExportFailure(failure);
    return;
  }

  final after = navigatorKey.currentContext;
  if (after == null || !after.mounted) return;
  final done = AppLocalizations.of(after);
  ScaffoldMessenger.of(after).showSnackBar(
    SnackBar(
      content: Text(done == null
          ? 'Exported to $fileName'
          : done.exportSucceeded(fileName)),
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
      title: AppConstants.appName,
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
        // Wrapped so a picture of the window can be taken without anything
        // else knowing it is being watched. A RepaintBoundary that nobody
        // photographs costs a layer that would very likely exist anyway.
        child: RepaintBoundary(
          key: WindowCapture.boundary,
          child: const HomeScreen(),
        ),
      ),
    );
  }
}
