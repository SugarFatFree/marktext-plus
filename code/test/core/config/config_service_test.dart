import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';

void main() {
  late Directory tempDir;
  late ConfigService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('config_test_');
    service = ConfigService(configDir: tempDir.path);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('ConfigService', () {
    test('load returns default config when file does not exist', () async {
      final config = await service.load();
      expect(config.fontSize, 16.0);
      expect(config.locale, '');
    });

    test('save and load round-trip preserves config', () async {
      final config = AppConfig(
        fontSize: 20.0,
        locale: 'zh_CN',
        sideBarVisible: false,
        editMode: EditMode.split,
      );
      await service.save(config);
      final loaded = await service.load();
      expect(loaded.fontSize, 20.0);
      expect(loaded.locale, 'zh_CN');
      expect(loaded.sideBarVisible, false);
      expect(loaded.editMode, EditMode.split);
    });

    test('load returns default config when file is corrupted', () async {
      final file = File('${tempDir.path}/config.json');
      file.writeAsStringSync('not valid json!!!');
      final config = await service.load();
      expect(config.fontSize, 16.0);
    });
  });
}
