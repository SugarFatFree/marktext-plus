import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('default values are correct', () {
      final config = AppConfig();
      expect(config.sideBarVisible, true);
      expect(config.tabBarVisible, true);
      expect(config.editMode, EditMode.preview);
      expect(config.splitRatio, 0.5);
      expect(config.fontSize, 16.0);
      expect(config.locale, '');
      expect(config.themeName, 'redGraphite');
      expect(config.autoSave, true);
    });

    test('toJson produces valid map', () {
      final config = AppConfig();
      final json = config.toJson();
      expect(json['sideBarVisible'], true);
      expect(json['editMode'], 'preview');
      expect(json['fontSize'], 16.0);
    });

    test('fromJson restores config correctly', () {
      final original = AppConfig(
        sideBarVisible: false,
        editMode: EditMode.split,
        fontSize: 20.0,
        locale: 'zh_CN',
      );
      final json = original.toJson();
      final restored = AppConfig.fromJson(json);
      expect(restored.sideBarVisible, false);
      expect(restored.editMode, EditMode.split);
      expect(restored.fontSize, 20.0);
      expect(restored.locale, 'zh_CN');
    });

    test('fromJson handles missing keys with defaults', () {
      final config = AppConfig.fromJson({'fontSize': 24.0});
      expect(config.fontSize, 24.0);
      expect(config.sideBarVisible, true);
      expect(config.editMode, EditMode.preview);
    });

    test('fromJson handles invalid data with defaults', () {
      final config = AppConfig.fromJson({'editMode': 'invalid', 'fontSize': 'bad'});
      expect(config.editMode, EditMode.preview);
      expect(config.fontSize, 16.0);
    });

    test('copyWith creates modified copy', () {
      final config = AppConfig();
      final modified = config.copyWith(fontSize: 24.0, locale: 'ja_JP');
      expect(modified.fontSize, 24.0);
      expect(modified.locale, 'ja_JP');
      expect(modified.sideBarVisible, true);
    });
  });
}
