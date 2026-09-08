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

  test('the schema names the menu conditions the editor honours', () {
    // Missed when the three above were written: `when` is a fourth enum in
    // the same file. An unknown value falls back to `always`, so a condition
    // the schema allows and the editor never heard of shows the command
    // everywhere instead of refusing to install — silent, and wrong.
    expect(
      enumAt(schema(), [
        'properties',
        'menus',
        'items',
        'properties',
        'when',
      ]).toSet(),
      PluginMenuCondition.values.map((c) => c.name).toSet(),
      reason: 'schema 允许的 when，编辑器要认得',
    );
  }, skip: present ? null : 'SDK 仓库不在这台机器上');

  /// The SDK's own translations, held to its English README.
  ///
  /// `readme_images_exist_test` does this for the editor's twelve. Its comment
  /// names the SDK as the repository that shipped a release with all of them
  /// rewritten from an older copy — and the guard was built for the editor
  /// only, so the repository the lesson came from was the one not watched.
  ///
  /// Wording differs by design, so a diff says nothing. The count of headings
  /// and fenced blocks does.
  (int, int, int) shape(File file) {
    final text = file.readAsStringSync();
    return (
      RegExp(r'^## ', multiLine: true).allMatches(text).length,
      RegExp(r'^### ', multiLine: true).allMatches(text).length,
      '```'.allMatches(text).length ~/ 2,
    );
  }

  test('the SDK translations have the same shape as its English README', () {
    final english = shape(File('$repo/README.md'));
    expect(
      english.$1,
      greaterThan(3),
      reason: 'SDK 的英文 README 只数出 ${english.$1} 个二级标题，八成是没读对',
    );

    final off = <String>[];
    for (final file
        in Directory('$repo/docs/i18n')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.md'))) {
      final theirs = shape(file);
      if (theirs != english) {
        off.add('${file.uri.pathSegments.last}: $theirs ≠ $english');
      }
    }

    expect(off, isEmpty, reason: '这几份 SDK 翻译和英文版结构对不上：$off');
  }, skip: present ? null : 'SDK 仓库不在这台机器上');

  test('there are eleven translations to check', () {
    // Guards the guard: a directory that stopped being found leaves the loop
    // above with nothing to disagree with.
    expect(
      Directory('$repo/docs/i18n')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .length,
      11,
    );
  }, skip: present ? null : 'SDK 仓库不在这台机器上');
}
