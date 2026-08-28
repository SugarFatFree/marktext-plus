import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/app_config.dart';
import '../core/config/config_service.dart';

class SettingsNotifier extends StateNotifier<AppConfig> {
  final ConfigService _configService;

  SettingsNotifier(this._configService, AppConfig initialConfig) : super(initialConfig);

  /// Called when writing the settings to disk fails.
  ///
  /// A static hook rather than something passed in, so that every existing
  /// construction of this notifier — the app's own and a dozen tests' — stays
  /// as it is, and there is still exactly one place where a failed write is
  /// noticed. `main` wires it to the snackbar.
  ///
  /// Until this existed the error was recorded on the ConfigService and read
  /// by nothing but a test: a read-only config directory meant the reader
  /// changed a setting, watched it take effect, and found it reverted on the
  /// next launch, with nothing ever having said why.
  static void Function(Object error)? onSaveFailed;

  /// The last failure already reported, so a directory that stays unwritable
  /// does not put a snackbar on screen for every toggle.
  Object? _reportedError;

  Future<void> updateConfig(AppConfig Function(AppConfig) updater) async {
    state = updater(state);
    await _configService.save(state);

    final error = _configService.lastSaveError;
    if (error == null) {
      _reportedError = null;
      return;
    }
    if (error.toString() == _reportedError?.toString()) return;
    _reportedError = error;
    onSaveFailed?.call(error);
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

  Future<void> toggleFocusMode() async {
    await updateConfig((config) => config.copyWith(
      focusMode: !config.focusMode,
    ));
  }

  Future<void> toggleTypewriterMode() async {
    await updateConfig((config) => config.copyWith(
      typewriterMode: !config.typewriterMode,
    ));
  }

  Future<void> resetDefaults() async {
    state = AppConfig();
    await _configService.save(state);
  }

  Future<void> addRecentFile(String path) async {
    final files = List<String>.from(state.recentFiles);
    files.remove(path);
    files.insert(0, path);
    if (files.length > 10) {
      files.removeRange(10, files.length);
    }
    await updateConfig((config) => config.copyWith(recentFiles: files));
  }

  Future<void> saveWindowState({
    required double width,
    required double height,
    required double x,
    required double y,
    required bool isMaximized,
  }) async {
    await updateConfig((config) => config.copyWith(
      windowWidth: width,
      windowHeight: height,
      windowX: x,
      windowY: y,
      isMaximized: isMaximized,
    ));
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppConfig>((ref) {
  throw UnimplementedError('ConfigService must be provided');
});
