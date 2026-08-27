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

void _handleSecondInstance(List<dynamic> newArgs) {
  final newFiles = _filterStartupFiles(newArgs);
  if (newFiles.isEmpty) return;
  _globalContainer?.read(tabProvider.notifier).openFilesFromSecondInstance(newFiles);
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize single instance on Windows
  if (Platform.isWindows) {
    await WindowsSingleInstance.ensureSingleInstance(
      args,
      "marktext_plus_instance",
      onSecondWindow: _handleSecondInstance,
    );
  }

  // Initialize window_manager
  await windowManager.ensureInitialized();

  // Filter startup file arguments
  final startupFiles = _filterStartupFiles(args);

  // Loaded before the window is configured: the saved geometry is what the
  // window should open with, and it was being written to disk and then never
  // read, so every launch reverted to the default size.
  final appSupportDir = await getApplicationSupportDirectory();
  final configDir = appSupportDir.path;
  final configService = ConfigService(configDir: configDir);
  final config = await configService.load();

  final windowOptions = WindowOptions(
    size: Size(config.windowWidth, config.windowHeight),
    title: 'MarkText Plus',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    // Position and maximised state cannot travel in WindowOptions.
    if (config.windowX != 0 || config.windowY != 0) {
      await windowManager.setPosition(Offset(config.windowX, config.windowY));
    }
    if (config.isMaximized) {
      await windowManager.maximize();
    }
    await windowManager.show();
    await windowManager.focus();
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

  runApp(UncontrolledProviderScope(
    container: container,
    child: const MarkTextPlusApp(),
  ));
}
