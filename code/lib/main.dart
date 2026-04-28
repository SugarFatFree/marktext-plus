import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    title: 'MarkText Plus',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Filter startup file arguments
  final startupFiles = _filterStartupFiles(args);

  final appSupportDir = await getApplicationSupportDirectory();
  final configDir = appSupportDir.path;
  final configService = ConfigService(configDir: configDir);
  final config = await configService.load();
  final initialLocale = LocaleNotifier.parseLocale(config.locale);

  final container = ProviderContainer(
    overrides: [
      settingsProvider.overrideWith((ref) => SettingsNotifier(configService)),
      localeProvider.overrideWith((ref) => LocaleNotifier(initialLocale)),
      startupFilesProvider.overrideWith((ref) => startupFiles),
    ],
  );

  _globalContainer = container;

  runApp(UncontrolledProviderScope(
    container: container,
    child: _AppLifecycleWrapper(
      container: container,
      child: const MarkTextPlusApp(),
    ),
  ));
}

class _AppLifecycleWrapper extends StatefulWidget {
  final ProviderContainer container;
  final Widget child;

  const _AppLifecycleWrapper({
    required this.container,
    required this.child,
  });

  @override
  State<_AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<_AppLifecycleWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    await _saveWindowState();
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _saveWindowState();
    }
  }

  Future<void> _saveWindowState() async {
    try {
      final view = ui.PlatformDispatcher.instance.views.first;
      final size = view.physicalSize / view.devicePixelRatio;

      // Save window state (position not available without platform channel)
      widget.container.read(settingsProvider.notifier).saveWindowState(
        width: size.width,
        height: size.height,
        x: 0,
        y: 0,
        isMaximized: false,
      );
    } catch (_) {
      // Ignore errors during shutdown
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
