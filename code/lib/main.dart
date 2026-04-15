import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'app.dart';
import 'core/config/config_service.dart';
import 'providers/locale_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configDir = p.join(Platform.environment['HOME'] ?? '.', '.marktext-plus');
  final configService = ConfigService(configDir: configDir);
  final config = await configService.load();
  final initialLocale = LocaleNotifier.parseLocale(config.locale);

  final container = ProviderContainer(
    overrides: [
      settingsProvider.overrideWith((ref) => SettingsNotifier(configService)),
      localeProvider.overrideWith((ref) => LocaleNotifier(initialLocale)),
    ],
  );

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
