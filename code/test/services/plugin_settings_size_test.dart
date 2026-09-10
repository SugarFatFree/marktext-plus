import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/app_log.dart';
import 'package:marktext_plus/services/plugin_command_service.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_script_runtime.dart';

/// A plugin's settings file is read on every command, and nothing bounds it.
///
/// What a plugin keeps between two steps of its own work goes into a file in
/// its own directory, and that file is read synchronously each time a command
/// runs. So a plugin that keeps a document in there costs a stall on every use
/// of it, and leaves the document on the reader's disk for as long as it stays
/// installed. Measured on the shipped translation plugin: a 210 KB document
/// left 209 636 bytes in settings.json, and nothing cleared it.
///
/// Not refused, because refusing would break the plugin that legitimately
/// holds a document while it works through it a batch at a time — which is
/// exactly what that one does, correctly, between batches. Said instead, once
/// it is past any size that could be settings, so that somebody looking for
/// why a plugin feels slow can find out.
void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('plugin_settings_');
    AppLog.instance.clear();
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  /// A plugin whose one command writes [bytes] characters into storage.
  PluginManifest install(int bytes) {
    const id = 'com.example.hoarder';
    final dir = Directory('${root.path}/$id')..createSync(recursive: true);
    File('${dir.path}/manifest.json').writeAsStringSync(jsonEncode({
      'id': id,
      'name': 'Hoarder',
      'version': '1.0.0',
      'runtime': 'lua',
      'entrypoint': 'plugin.lua',
      'permissions': ['storage.local', 'ui.notifications'],
    }));
    File('${dir.path}/plugin.lua').writeAsStringSync('''
function on_command(ctx)
  storage.set("kept", string.rep("x", $bytes))
  return { notify = "done" }
end
''');
    return PluginManifest.fromJson(
        jsonDecode(File('${dir.path}/manifest.json').readAsStringSync())
            as Map<String, dynamic>);
  }

  Future<void> run(PluginManifest manifest, int warnAt) async {
    final service =
        PluginCommandService(root.path, settingsWarnBytes: warnAt);
    service.start(
      manifest,
      const PluginScriptContext(command: 'anything'),
    );
    await service.flush(manifest);
    service.dispose();
  }

  List<String> warnings() => AppLog.instance
      .recent()
      .where((line) => line.message.contains('hoarder'))
      .map((line) => line.message)
      .toList();

  test('a plugin that hoards is said so, with what it is hoarding', () async {
    await run(install(4096), 1024);

    expect(warnings(), hasLength(1));
    expect(warnings().single, contains('KB of settings'));
    expect(warnings().single, contains('"kept"'),
        reason: '要说清是哪个键撑大的，否则读者无从下手');
  });

  test('ordinary settings are not worth a line', () async {
    await run(install(100), 1024);

    expect(warnings(), isEmpty,
        reason: '每次都提醒的提醒等于没有提醒');
  });

  test('the default bar is above anything that is actually settings', () {
    // Four megabytes. A plugin holding a document reaches it; a plugin holding
    // its own settings does not, and the difference is the whole point.
    expect(PluginCommandService(root.path).settingsWarnBytes,
        greaterThanOrEqualTo(1024 * 1024));
  });
}
