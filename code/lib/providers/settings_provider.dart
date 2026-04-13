import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';
import '../core/config/config_service.dart';

class SettingsNotifier extends StateNotifier<AppConfig> {
  final ConfigService _configService;

  SettingsNotifier(this._configService) : super(AppConfig()) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    state = await _configService.load();
  }

  Future<void> updateConfig(AppConfig Function(AppConfig) updater) async {
    state = updater(state);
    await _configService.save(state);
  }

  Future<void> toggleSideBar() async {
    await updateConfig((config) => config.copyWith(
      sideBarVisible: !config.sideBarVisible,
    ));
  }

  Future<void> toggleTabBar() async {
    await updateConfig((config) => config.copyWith(
      tabBarVisible: !config.tabBarVisible,
    ));
  }

  Future<void> setEditMode(EditMode mode) async {
    await updateConfig((config) => config.copyWith(editMode: mode));
  }

  Future<void> setLocale(String locale) async {
    await updateConfig((config) => config.copyWith(locale: locale));
  }

  Future<void> setTheme(String theme) async {
    await updateConfig((config) => config.copyWith(themeName: theme));
  }

  Future<void> setFontSize(double size) async {
    await updateConfig((config) => config.copyWith(fontSize: size));
  }

  Future<void> resetDefaults() async {
    state = AppConfig();
    await _configService.save(state);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppConfig>((ref) {
  throw UnimplementedError('ConfigService must be provided');
});
