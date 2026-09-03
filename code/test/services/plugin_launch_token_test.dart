import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:marktext_plus/services/plugin_manager.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';

/// A compiled plugin can tell whether the editor started it.
///
/// It used to be told by a fixed argument, which anyone can type: someone
/// running the executable by hand could hand it the same string and the plugin
/// would believe it. A token generated for that one launch cannot be typed by
/// anyone who was not given it.
///
/// Nothing here stops a file on the reader's disk from being executed — no
/// program can — so what is being made unforgeable is the plugin's answer to
/// "was I started by the editor", not the launch itself.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('plugin_token_'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  PluginManifest install(String script) {
    final manifest = PluginManifest.fromJson({
      'id': 'com.example.native',
      'name': 'Native',
      'version': '1.0.0',
      'runtime': 'process',
      'entrypoints': {
        PluginManager.currentPlatform.split('-').first: 'bin/probe',
      },
    });
    final file = File(p.join(root.path, manifest.id, 'bin', 'probe'))
      ..createSync(recursive: true)
      ..writeAsStringSync(script);
    Process.runSync('chmod', ['+x', file.path]);
    return manifest;
  }

  test('every launch gets a token of its own', () {
    final first = PluginManager.newLaunchToken();
    final second = PluginManager.newLaunchToken();

    expect(first, isNot(second));
    expect(first.length, greaterThanOrEqualTo(32),
        reason: '短到能猜出来的令牌等于没有');
    expect(first, matches(RegExp(r'^[0-9a-f]+$')));
  });

  test('the plugin is handed the token, and not on the command line',
      () async {
    // argv is readable by anything that can run `ps`; the environment of
    // another process is not, on any platform this ships to.
    final manifest = install(
      '#!/bin/sh\n'
      'printf "argv=%s env=%s" "\$*" "\$MARKTEXT_PLUS_PLUGIN_TOKEN" > "\$0.seen"\n'
      'sleep 5\n',
    );

    final host = await PluginManager(root.path).startPlugin(manifest);
    addTearDown(host.stop);

    final seen = File(p.join(root.path, manifest.id, 'bin', 'probe.seen'));
    for (var attempt = 0; attempt < 100; attempt++) {
      if (seen.existsSync() && seen.readAsStringSync().isNotEmpty) {
        final text = seen.readAsStringSync();
        final token = text.split('env=').last;
        expect(token, isNotEmpty, reason: '插件没拿到令牌');
        expect(text.split(' env=').first, 'argv=',
            reason: '令牌不该出现在命令行参数里');
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    fail('插件没有被启动');
  }, skip: Platform.isWindows ? 'shell script fixture is POSIX-only' : null);
}
