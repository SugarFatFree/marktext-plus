import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/json_store.dart';
import 'package:marktext_plus/services/keybinding_service.dart';

/// One way of keeping a small JSON file the reader must not lose.
///
/// The settings file was written through a temporary file and renamed into
/// place, and an unreadable one was set aside so it could be recovered. The
/// keybindings file was written in place and, when it failed to parse, was
/// silently replaced by the defaults — every customised shortcut gone without
/// a word, and the file that held them overwritten on the next save.
void main() {
  late Directory dir;
  String at(String name) => '${dir.path}/$name';

  setUp(() => dir = Directory.systemTemp.createTempSync('json_store'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  group('the store', () {
    test('a missing file reads as nothing, not as an error', () async {
      expect(await JsonStore(at('none.json')).read(), isNull);
    });

    test('what was written comes back', () async {
      final store = JsonStore(at('a.json'));
      await store.write({'k': 'v'});
      expect(await store.read(), {'k': 'v'});
    });

    test('an unreadable file is kept, not overwritten', () async {
      final store = JsonStore(at('a.json'));
      File(at('a.json')).writeAsStringSync('{ this is not json');

      expect(await store.read(), isNull);
      expect(File(store.quarantinePath).readAsStringSync(),
          '{ this is not json',
          reason: '损坏的文件必须留下来，否则用户的设置就真的没了');
      expect(File(at('a.json')).existsSync(), isFalse);
    });

    test('the write leaves no half-written file behind', () async {
      final store = JsonStore(at('a.json'));
      await store.write({'k': 'v'});
      expect(File('${at('a.json')}.tmp').existsSync(), isFalse,
          reason: '临时文件应当被 rename 掉，而不是留在原地');
    });

    test('a directory that does not exist yet is created', () async {
      final store = JsonStore(at('nested/deeper/a.json'));
      await store.write({'k': 'v'});
      expect(await store.read(), {'k': 'v'});
    });
  });

  group('keybindings', () {
    test('a corrupt file is set aside rather than silently reset', () async {
      final service = KeybindingService();
      service.configDirectory = dir.path;

      final path = at('keybindings.json');
      File(path).writeAsStringSync('{ truncated');

      await service.load();

      expect(File('$path.corrupt').existsSync(), isTrue,
          reason: '自定义快捷键被无声丢弃且原文件没保留');
    });

    test('what was saved survives a reload', () async {
      final service = KeybindingService();
      service.configDirectory = dir.path;
      await service.load();

      final path = at('keybindings.json');
      await JsonStore(path).write({'save': 'Control+Alt+S'});

      final reloaded = KeybindingService();
      reloaded.configDirectory = dir.path;
      await reloaded.load();

      final stored = jsonDecode(File(path).readAsStringSync())
          as Map<String, dynamic>;
      expect(stored['save'], 'Control+Alt+S');
    });
  });
}
