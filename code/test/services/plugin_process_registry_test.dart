import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_process_registry.dart';

/// Plugin processes the editor started must not outlive it.
///
/// A child process is not killed when its parent dies: killing the editor
/// outright leaves every plugin it had started running, holding whatever they
/// held, with nothing left that knows they exist. The editor therefore writes
/// down what it spawned, and looks at that list the next time it starts.
void main() {
  late Directory root;
  late PluginProcessRegistry registry;

  setUp(() {
    root = Directory.systemTemp.createTempSync('plugin_registry_');
    registry = PluginProcessRegistry(File('${root.path}/running.json'));
  });
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('a started process is written down where a later run can find it',
      () async {
    await registry.record(4242, '/plugins/demo/bin/plugin');

    expect(
      jsonDecode(File('${root.path}/running.json').readAsStringSync()),
      [
        {'pid': 4242, 'executable': '/plugins/demo/bin/plugin'}
      ],
    );
  });

  test('a process the editor stopped itself is forgotten', () async {
    await registry.record(4242, '/plugins/demo/bin/plugin');
    await registry.record(4243, '/plugins/other/bin/plugin');

    await registry.forget(4242);

    expect(
      jsonDecode(File('${root.path}/running.json').readAsStringSync()),
      [
        {'pid': 4243, 'executable': '/plugins/other/bin/plugin'}
      ],
    );
  });

  test('a plugin left running by a crash is killed on the next start',
      () async {
    await registry.record(4242, '/plugins/demo/bin/plugin');
    final killed = <int>[];

    final count = await registry.reapOrphans(
      imageOf: (pid) async => '/plugins/demo/bin/plugin',
      kill: (pid) {
        killed.add(pid);
        return true;
      },
    );

    expect(killed, [4242]);
    expect(count, 1);
  });

  test('a pid the system handed to something else is left alone', () async {
    await registry.record(4242, '/plugins/demo/bin/plugin');
    final killed = <int>[];

    await registry.reapOrphans(
      // The plugin died long ago and 4242 now belongs to the reader's browser.
      imageOf: (pid) async => '/usr/bin/firefox',
      kill: (pid) {
        killed.add(pid);
        return true;
      },
    );

    expect(killed, isEmpty,
        reason: 'pid 会被系统回收再分配，光凭编号杀进程会杀掉别人的程序');
  });

  test('a pid that is simply gone is not treated as an error', () async {
    await registry.record(4242, '/plugins/demo/bin/plugin');

    final count = await registry.reapOrphans(
      imageOf: (pid) async => null,
      kill: (pid) => fail('不该去杀一个已经不存在的进程'),
    );

    expect(count, 0);
  });

  test('the list is emptied once it has been dealt with', () async {
    await registry.record(4242, '/plugins/demo/bin/plugin');

    await registry.reapOrphans(
      imageOf: (pid) async => '/plugins/demo/bin/plugin',
      kill: (pid) => true,
    );

    expect(await registry.entries(), isEmpty);
  });

  test('a registry file a crash left half-written does not stop the editor',
      () async {
    File('${root.path}/running.json').writeAsStringSync('[{"pid": 42');

    expect(await registry.entries(), isEmpty);
    await registry.record(1, '/plugins/demo/bin/plugin');
    expect(await registry.entries(), hasLength(1));
  });

  test('a real leftover process is really killed', () async {
    if (Platform.isWindows) {
      return; // `sleep` is not a Windows command; the probe is tested above.
    }
    final child = await Process.start('sleep', ['30']);
    await registry.record(child.pid, '/bin/sleep');

    final count = await registry.reapOrphans();

    expect(count, 1);
    expect(await child.exitCode, isNot(0));
  }, timeout: const Timeout(Duration(seconds: 30)));
}
