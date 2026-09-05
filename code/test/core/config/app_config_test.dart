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

    test('the code font size survives a round trip', () {
      // Code was fixed at 14 whatever the body font was set to, so anyone who
      // enlarged the text got large prose and small code.
      final restored =
          AppConfig.fromJson(AppConfig(codeFontSize: 22.0).toJson());
      expect(restored.codeFontSize, 22.0);
      expect(AppConfig.fromJson(const {}).codeFontSize, 14.0);
      expect(AppConfig.fromJson(const {'codeFontSize': 'bad'}).codeFontSize,
          14.0);
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

    test('one field of the wrong type does not throw away the rest', () {
      // A configuration file is JSON on disk, in a directory the reader can
      // open. `fontSize` and `editMode` were already read forgivingly; every
      // bool, int and string was read with `as`, which throws rather than
      // returning null — and ConfigService catches that by starting from a
      // default configuration. So one mistyped value silently reset the
      // theme, the fonts, the key bindings and everything else.
      final config = AppConfig.fromJson({
        'sideBarVisible': 'yes',
        'autoSaveDelay': '5000',
        'fontFamily': 42,
        'fontSize': 24.0,
        'themeName': 'nord',
      });

      expect(config.fontSize, 24.0, reason: '好的字段要留下');
      expect(config.themeName, 'nord', reason: '好的字段要留下');
      expect(config.sideBarVisible, true, reason: '坏的字段各自回到默认');
      expect(config.autoSaveDelay, 5000);
      expect(config.fontFamily, 'monospace');
    });

    test('a whole number written as a decimal is still a number', () {
      // JSON has one number type: a delay saved as 8000 can come back as
      // 8000.0, and `as int?` throws on it.
      //
      // Not 5000.0, which is the default — an assertion that a wrong reading
      // and a right one both satisfy proves nothing, and the first version of
      // this test used exactly that number.
      final config = AppConfig.fromJson({'autoSaveDelay': 8000.0});
      expect(config.autoSaveDelay, 8000);
    });

    test('a saved list holding something that is not a path', () {
      // `cast<String>()` is lazy: this used to be accepted here and throw
      // later, when something walked the list, with nothing to connect the
      // crash back to the file.
      final config = AppConfig.fromJson({
        'recentFiles': ['a.md', 42, 'b.md'],
        'sessionTabs': 'not a list',
        'sideBarOpenedFiles': ['c.md'],
      });

      expect(config.recentFiles, ['a.md', 'b.md']);
      expect(config.sessionTabs, isEmpty);
      expect(config.sideBarOpenedFiles, ['c.md']);
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
