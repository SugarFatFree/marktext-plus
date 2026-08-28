import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_single_instance/windows_single_instance.dart';
import 'app.dart';
import 'core/config/config_service.dart';
import 'core/diagnostics/startup_trace.dart';
import 'providers/locale_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/tab_provider.dart';

ProviderContainer? _globalContainer;

List<String> _filterStartupFiles(List<dynamic> args) {
  const allowedExtensions = {'.md', '.markdown', '.txt'};
  return args.where((arg) {
    if (arg is! String) return false;
    final ext = p.extension(arg).toLowerCase();
    return allowedExtensions.contains(ext) && File(arg).existsSync();
  }).cast<String>().toList();
}

/// Matches kFilesChannel in linux/runner/my_application.cc.
const _linuxFilesChannel = MethodChannel('com.marktextplus/files');

/// Receives file paths from a second launch on Linux.
///
/// GTK forwards them to the process already holding the application ID, which
/// pushes them over this channel rather than starting another window.
void _listenForLinuxFileOpens(ProviderContainer container) {
  if (!Platform.isLinux) return;

  _linuxFilesChannel.setMethodCallHandler((call) async {
    if (call.method != 'openFiles') return null;
    final paths = (call.arguments as List?)?.whereType<String>().toList();
    if (paths == null || paths.isEmpty) return null;
    await container.read(tabProvider.notifier).openFilesFromSecondInstance(paths);
    return null;
  });
}

/// Brings the running window forward.
///
/// Launching the program while it is already running did nothing visible: with
/// a file, the file opened into a tab behind whatever the reader was looking
/// at; without one — clicking the shortcut again — the handler returned
/// immediately and the window stayed hidden. Both read as the program having
/// ignored the double click. Upstream MarkText calls `bringToFront()` in the
/// same place, and in the no-files case that is the *only* thing it does.
Future<void> _bringWindowForward() async {
  try {
    if (await windowManager.isMinimized()) {
      await windowManager.restore();
    }
    await windowManager.show();
    await windowManager.focus();
  } catch (_) {
    // Never let surfacing the window be the reason a file fails to open.
  }
}

void _handleSecondInstance(List<dynamic> newArgs) async {
  final newFiles = _filterStartupFiles(newArgs);
  final notifier = _globalContainer?.read(tabProvider.notifier);

  if (newFiles.isNotEmpty && notifier != null) {
    final openedHere = await notifier.openFilesFromSecondInstance(newFiles);
    // Sent to a new window on purpose; this one should stay as it was.
    if (!openedHere) return;
  }

  await _bringWindowForward();
}

void main(List<String> args) async {
  // Before the first mark, so the runner's own timings head the trace.
  StartupTrace.readRunnerArguments(args);
  WidgetsFlutterBinding.ensureInitialized();
  StartupTrace.mark('flutter binding ready');

  // Initialize single instance on Windows
  if (Platform.isWindows) {
    await WindowsSingleInstance.ensureSingleInstance(
      args,
      "marktext_plus_instance",
      onSecondWindow: _handleSecondInstance,
    );
    StartupTrace.mark('single instance check');
  }

  // Initialize window_manager
  await windowManager.ensureInitialized();
  StartupTrace.mark('window manager ready');

  // Filter startup file arguments
  final startupFiles = _filterStartupFiles(args);
  StartupTrace.mark('startup args filtered (${startupFiles.length} file(s))');

  // Loaded before the window is configured: the saved geometry is what the
  // window should open with, and it was being written to disk and then never
  // read, so every launch reverted to the default size.
  final appSupportDir = await getApplicationSupportDirectory();
  final configDir = appSupportDir.path;
  StartupTrace.useDirectory(configDir);
  StartupTrace.mark('config directory resolved');
  final configService = ConfigService(configDir: configDir);
  // One place learns that a settings write failed; this is where it is said
  // out loud. Without it a read-only config directory reverted every change
  // on the next launch and never explained itself.
  SettingsNotifier.onSaveFailed = reportSettingsSaveFailure;
  final config = await configService.load();
  StartupTrace.mark('config loaded');

  final windowOptions = WindowOptions(
    size: Size(config.windowWidth, config.windowHeight),
    title: 'MarkText Plus',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    StartupTrace.mark('window ready to show');
    // Position and maximised state cannot travel in WindowOptions.
    if (config.windowX != 0 || config.windowY != 0) {
      await windowManager.setPosition(Offset(config.windowX, config.windowY));
    }
    if (config.isMaximized) {
      await windowManager.maximize();
    }
    await windowManager.show();
    await windowManager.focus();
    StartupTrace.mark('window shown');
  });
  final initialLocale = LocaleNotifier.parseLocale(config.locale);

  final container = ProviderContainer(
    overrides: [
      settingsProvider.overrideWith((ref) => SettingsNotifier(configService, config)),
      localeProvider.overrideWith((ref) => LocaleNotifier(initialLocale)),
      startupFilesProvider.overrideWith((ref) => startupFiles),
    ],
  );

  _globalContainer = container;
  _listenForLinuxFileOpens(container);

  StartupTrace.mark('provider container built');

  runApp(UncontrolledProviderScope(
    container: container,
    child: const MarkTextPlusApp(),
  ));
  StartupTrace.mark('runApp called');
}
