import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';

/// The JSON schema the SDK publishes, held to what the editor actually reads.
///
/// A plugin author writes their manifest against that schema — many editors
/// will validate it as they type. If it names a permission the editor does not
/// grant, or omits one the editor does, the author is misled by the very file
/// that was meant to help them, and nothing here would ever notice: the schema
/// lives in a different repository and no test on either side reads both.
///
/// The SDK sits beside this checkout on the machine this was written on, and
/// nowhere on CI, so these skip rather than fail where it is absent. `test/
/// repo_dependent_tests_test.dart` enforces that.
void main() {
  const path = 'marktext-plus-plugins/marktext-plus-plugin-sdk';
  String? findRepo() {
    var directory = Directory.current;
    for (var level = 0; level < 6; level++) {
      final candidate = '${directory.path}/$path';
      if (File('$candidate/schema/manifest.schema.json').existsSync()) {
        return candidate;
      }
      final parent = directory.parent;
      if (parent.path == directory.path) break;
      directory = parent;
    }
    return null;
  }

  final repo = findRepo();
  final present = repo != null;

  Map<String, dynamic> schema() =>
      jsonDecode(File('$repo/schema/manifest.schema.json').readAsStringSync())
          as Map<String, dynamic>;

  List<String> enumAt(Map<String, dynamic> node, List<String> keys) {
    dynamic here = node;
    for (final key in keys) {
      here = (here as Map<String, dynamic>)[key];
      expect(here, isNotNull, reason: 'schema 里没有 ${keys.join('/')}，路径变了');
    }
    return ((here as Map<String, dynamic>)['enum'] as List).cast<String>();
  }

  test('the schema names the permissions the editor grants', () {
    expect(
      enumAt(schema(), ['properties', 'permissions', 'items']).toSet(),
      PluginPermission.all.toSet(),
      reason:
          'schema 与编辑器对权限的说法不一致——'
          '作者会按 schema 写，然后发现编辑器不认',
    );
  }, skip: present ? null : 'SDK 仓库不在这台机器上');

  test('the schema names the runtimes the editor can run', () {
    expect(
      enumAt(schema(), ['properties', 'runtime']).toSet(),
      PluginRuntime.values.map((r) => r.name).toSet(),
      reason: 'schema 允许的 runtime 编辑器要能跑',
    );
  }, skip: present ? null : 'SDK 仓库不在这台机器上');

  test('the schema names the settings types the editor draws', () {
    // The editor draws an unknown type as a plain field rather than refusing
    // it, so a type the schema allows and the editor has never heard of is
    // silent — which is exactly the kind of disagreement worth pinning.
    expect(
      enumAt(schema(), [
        'properties',
        'settings',
        'items',
        'properties',
        'type',
      ]).toSet(),
      {'text', 'password', 'number', 'boolean'},
      reason: 'schema 允许的字段类型，插件设置页要认得',
    );
  }, skip: present ? null : 'SDK 仓库不在这台机器上');
}
