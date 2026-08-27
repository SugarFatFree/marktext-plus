import 'dart:convert';
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

    test('leaves no temporary file behind', () async {
      await service.save(AppConfig(fontSize: 20.0));

      expect(File('${tempDir.path}/config.json.tmp').existsSync(), isFalse);
    });

    test('overlapping saves leave a complete file', () async {
      // Dragging the split divider or opening a file fires several saves in a
      // row, and each carries the whole config. Written in place they could
      // interleave and truncate each other, and a truncated config parses as
      // nothing — which reverts every setting to its default.
      await Future.wait([
        for (var i = 0; i < 20; i++) service.save(AppConfig(fontSize: 10.0 + i)),
      ]);

      final decoded =
          jsonDecode(File('${tempDir.path}/config.json').readAsStringSync());
      expect(decoded, isA<Map<String, dynamic>>());
      expect((await service.load()).fontSize, 29.0);
    });

    test('an unreadable config is set aside rather than overwritten', () async {
      // Falling back to defaults already loses every setting the user chose;
      // overwriting the file loses the evidence too.
      final file = File('${tempDir.path}/config.json');
      file.writeAsStringSync('{ "fontSize": 20,');

      await service.load();

      final kept = File('${tempDir.path}/config.json.corrupt');
      expect(kept.existsSync(), isTrue);
      expect(kept.readAsStringSync(), '{ "fontSize": 20,');
    });

    test('saving still works after a corrupt config was set aside', () async {
      File('${tempDir.path}/config.json').writeAsStringSync('not json');
      await service.load();

      await service.save(AppConfig(fontSize: 22.0));
      expect((await service.load()).fontSize, 22.0);
    });
  });
}
