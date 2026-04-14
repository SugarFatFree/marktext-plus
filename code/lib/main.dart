import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'core/config/config_service.dart';
import 'providers/locale_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  final configDir = p.join(Platform.environment['HOME'] ?? '.', '.marktext-plus');
  final configService = ConfigService(configDir: configDir);
  final config = await configService.load();
  final initialLocale = LocaleNotifier.parseLocale(config.locale);

  final windowOptions = WindowOptions(
    size: Size(config.windowWidth, config.windowHeight),
    minimumSize: const Size(800, 600),
    center: config.windowX == 0 && config.windowY == 0,
    title: 'MarkText Plus',
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    if (config.windowX != 0 || config.windowY != 0) {
      await windowManager.setPosition(Offset(config.windowX, config.windowY));
    }
    if (config.isMaximized) {
      await windowManager.maximize();
    }
    await windowManager.show();
  });

  final container = ProviderContainer(
    overrides: [
      settingsProvider.overrideWith((ref) => SettingsNotifier(configService)),
      localeProvider.overrideWith((ref) => LocaleNotifier(initialLocale)),
    ],
  );

  windowManager.setPreventClose(true);
  windowManager.addListener(_WindowListener(container));

  runApp(UncontrolledProviderScope(
    container: container,
    child: const MarkTextPlusApp(),
  ));
}

class _WindowListener extends WindowListener {
  final ProviderContainer _container;

  _WindowListener(this._container);

  @override
  void onWindowClose() async {
    final isMaximized = await windowManager.isMaximized();
    final position = await windowManager.getPosition();
    final size = await windowManager.getSize();
    _container.read(settingsProvider.notifier).saveWindowState(
      width: size.width,
      height: size.height,
      x: position.dx,
      y: position.dy,
      isMaximized: isMaximized,
    );
    await windowManager.destroy();
  }
}
