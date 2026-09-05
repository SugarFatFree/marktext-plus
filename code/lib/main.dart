import 'utils/file_utils.dart';
import 'core/constants.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'services/window_placement.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_single_instance/windows_single_instance.dart';
import 'app.dart';
import 'core/config/config_service.dart';
import 'core/diagnostics/startup_trace.dart';
import 'providers/locale_provider.dart';
import 'services/plugin_manager.dart';
import 'providers/settings_provider.dart';
import 'providers/tab_provider.dart';

ProviderContainer? _globalContainer;

List<String> _filterStartupFiles(List<dynamic> args) {
  final allowedExtensions = FileUtils.markdownExtensionsWithDot;
  return args.where((arg) {
    if (arg is! String) return false;
    final ext = p.extension(arg).toLowerCase();
    return allowedExtensions.contains(ext) && File(arg).existsSync();
  }).cast<String>().toList();
}

/// Matches kFilesChannel in linux/runner/my_application.cc and
/// AppDelegate.filesChannelName in macos/Runner/AppDelegate.swift.
const _filesChannel = MethodChannel('com.marktextplus/files');

/// Receives file paths the desktop hands to an already-running app.
///
/// On Linux, GTK forwards a second launch's arguments to the process holding
/// the application ID. On macOS nothing arrives in `argv` at all: Finder sends
/// an Apple event, which the app delegate turns into a call on this channel —
/// including for the launch that opened the app in the first place, which is
/// why the queue is drained rather than only listened to.
void _listenForFileOpens(ProviderContainer container) {
  if (!Platform.isLinux && !Platform.isMacOS) return;

  Future<void> open(List<String> paths) async {
    if (paths.isEmpty) return;
    await container.read(tabProvider.notifier).openFilesFromSecondInstance(paths);
  }

  _filesChannel.setMethodCallHandler((call) async {
    if (call.method != 'openFiles') return null;
    final paths = (call.arguments as List?)?.whereType<String>().toList();
    if (paths == null) return null;
    await open(paths);
    return null;
  });

  if (!Platform.isMacOS) return;
  // Whatever Finder delivered before this handler existed. Asking is also how
  // the native side learns that pushing is safe from now on.
  () async {
    try {
      final queued = await _filesChannel
          .invokeMethod<List<dynamic>>('drainPendingFiles');
      await open(queued?.whereType<String>().toList() ?? const []);
    } catch (_) {
      // An older build of the app bundle has no such method; a launch with no
      // document is not a reason to fail startup either way.
    }
  }();
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

  // Plugin processes an earlier run left behind. A child is not killed when
  // its parent dies, so a crash leaves every plugin process still running with
  // nothing that knows about them. Done before the window opens, and before
  // anything can start a plugin, so a new child is not mistaken for a stale
  // one. With nothing to clean up this is a single check for a missing file.
  await PluginManager(p.join(configDir, 'plugins')).reapOrphanedPlugins();
  StartupTrace.mark('orphaned plugin processes reaped');

  // Where the window may actually open, given the screens attached now.
  //
  // The stored place was put back unchecked, so a window last closed on a
  // monitor that has since been unplugged reopened there: the application
  // started, took focus, and was nowhere on screen, with nothing to drag back
  // and no way out but editing the configuration by hand.
  //
  // Asking the screens can fail — a headless session, a plugin that is not
  // there — and the answer to that is to leave the window exactly as it was
  // rather than move it on a guess.
  var placement = (
    position: Offset(config.windowX, config.windowY),
    size: Size(config.windowWidth, config.windowHeight),
  );
  try {
    final displays = await screenRetriever.getAllDisplays();
    final primary = await screenRetriever.getPrimaryDisplay();
    Rect boundsOf(Display d) =>
        (d.visiblePosition ?? Offset.zero) & (d.visibleSize ?? d.size);
    placement = WindowPlacement.fit(
      position: placement.position,
      size: placement.size,
      // Primary first: it is where a window with nowhere else to go lands.
      screens: [
        boundsOf(primary),
        for (final d in displays)
          if (d.id != primary.id) boundsOf(d),
      ],
    );
  } catch (_) {
    StartupTrace.mark('screens could not be read; window left as stored');
  }
  StartupTrace.mark('window placement decided');

  final windowOptions = WindowOptions(
    size: placement.size,
    title: AppConstants.appName,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    StartupTrace.mark('window ready to show');
    // Position and maximised state cannot travel in WindowOptions.
    //
    // Marked one call at a time. In one launch out of four this stretch took
    // 676 ms against 5, 2 and 13 ms in the others — three quarters of a
    // second of somebody's startup, spent in a window manager round trip
    // that the single mark could not name. Each of these is a call into the
    // platform and any of them can be the one that waits.
    if (config.windowX != 0 || config.windowY != 0) {
      await windowManager.setPosition(placement.position);
      StartupTrace.mark('window position set');
    }
    if (config.isMaximized) {
      await windowManager.maximize();
      StartupTrace.mark('window maximised');
    }
    await windowManager.show();
    StartupTrace.mark('window show returned');
    await windowManager.focus();
    StartupTrace.mark('window shown');
    // After the window, never before it: this is a measurement, and it costs a
    // directory walk. What Windows had to read before Dart started is the first
    // thing worth knowing when a launch takes seconds, and the program is
    // sitting in that folder.
    StartupTrace.recordInstallSize();
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
  _listenForFileOpens(container);

  StartupTrace.mark('provider container built');

  runApp(UncontrolledProviderScope(
    container: container,
    child: const MarkTextPlusApp(),
  ));
  StartupTrace.mark('runApp called');
}
