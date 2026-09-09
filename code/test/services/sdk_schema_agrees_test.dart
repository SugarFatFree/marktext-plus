import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/plugin_manifest.dart';
import 'package:marktext_plus/services/plugin_ui.dart';
import 'package:marktext_plus/ui/widgets/plugin_icons.dart';

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

  /// The fields themselves, not only the values inside them.
  ///
  /// The eleven checks below hold the *contents* of the schema to the editor
  /// — which permissions, which runtimes, which icons. Nothing held the list
  /// of fields, and the schema says `additionalProperties: false`, so the two
  /// ways of getting this wrong land on the author from opposite directions:
  /// a field the editor reads and the schema omits is reported to them as an
  /// invalid manifest for using a real feature; a field the schema allows and
  /// the editor ignores is one they write and nothing happens.
  ///
  /// The editor's side is read out of `PluginManifest.fromJson`'s own
  /// arguments, so it cannot drift from a list typed here.
  test('the schema names the fields the editor reads, and only those', () {
    final source =
        File('lib/services/plugin_manifest.dart').readAsStringSync();
    final start = source.indexOf('factory PluginManifest.fromJson');
    expect(start, isNot(-1), reason: '找不到 fromJson，取法要跟着改');
    final constructed = RegExp(r'^\s+([a-zA-Z]+):', multiLine: true)
        .allMatches(source.substring(start, source.indexOf('\n  }', start)))
        .map((m) => m.group(1)!)
        .toSet();
    expect(constructed.length, greaterThan(10),
        reason: '读出的字段太少，取法要跟着改');

    final declared = (schema()['properties'] as Map<String, dynamic>).keys.toSet();

    expect(
      declared.difference(constructed).toList()..sort(),
      isEmpty,
      reason: 'schema 允许的字段编辑器不读——作者写了不会有任何反应',
    );
    expect(
      constructed.difference(declared).toList()..sort(),
      isEmpty,
      reason: '编辑器读的字段 schema 没声明——additionalProperties 为 false，'
          '作者用真实功能反而被判无效',
    );
  }, skip: present ? null : 'SDK 仓库不在这台机器上');

  /// Which way a lone pane is divided, in all twelve languages.
  ///
  /// The rule changed on 2026-09-07: a single pane used to sit beside the
  /// document whatever slot it claimed, and now `bottom` puts it underneath.
  /// `plugin_panes_layout_test` holds the editor to that. Nothing held the
  /// SDK, so all twelve READMEs went on stating the abandoned rule —
  /// "one pane is one pane whichever slot it claimed" — while the official
  /// plugins were already relying on the new one. A third-party author
  /// filling only `bottom` was told they would get a pane beside the
  /// document and got one below it.
  ///
  /// Counted rather than read, because the sentence is in eleven languages
  /// and the guard cannot be. `bottom` is an identifier and does not
  /// translate: the paragraph names it once as a slot, and a second time
  /// saying which way that slot goes. One mention means the direction
  /// sentence is missing.
  test('every language says which way a lone bottom pane goes', () {
    if (!present) return;

    for (final file in [
      File('$repo/README.md'),
      ...Directory('$repo/docs/i18n')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md')),
    ]) {
      final named = file
          .readAsStringSync()
          .split('\n\n')
          .where((p) =>
              p.contains('`right`') &&
              p.contains('`bottom`') &&
              p.contains('`corner`'))
          .toList();

      expect(named.length, greaterThanOrEqualTo(2),
          reason: '${file.path} 找不到讲槽位名的那两段，取法要跟着改');
      expect(
        '`bottom`'.allMatches(named[1]).length,
        greaterThanOrEqualTo(2),
        reason: '${file.path} 只把 bottom 当名字列了一次，'
            '没说填它会把窗格放到文档下面',
      );
    }
  }, skip: present ? null : 'SDK 仓库不在这台机器上');

  /// The twelve READMEs name the same things.
  ///
  /// Identifiers do not translate, which makes them the one part of a
  /// document in eleven languages a guard can compare. Two went wrong at
  /// once and in opposite directions: the English README said there is no
  /// `require` while five other places in the same file explained how to use
  /// it — the sandbox list was written before the module loader and never
  /// updated, and the translations had been. And `ctx.view`, which tells a
  /// script whether the reader is in source, preview or split, was documented
  /// in seven languages and missing from English, German, Japanese, Korean
  /// and Chinese. The same four translations once lost the side panel.
  ///
  /// Backticked words only, and code fences dropped first: prose differs by
  /// language and examples repeat, while what a plugin author types does not
  /// change with the language they read.
  test('the twelve READMEs name the same identifiers', () {
    if (!present) return;

    Set<String> named(File file) {
      final prose = file
          .readAsStringSync()
          .replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
      return RegExp(r'`([A-Za-z_][A-Za-z0-9_.]*)`')
          .allMatches(prose)
          .map((m) => m.group(1)!)
          .toSet();
    }

    final english = named(File('$repo/README.md'));
    expect(english.length, greaterThan(50),
        reason: '英文里读出的标识符太少，取法要跟着改');

    for (final file in Directory('$repo/docs/i18n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))) {
      final theirs = named(file);
      expect(english.difference(theirs).toList()..sort(), isEmpty,
          reason: '${file.path} 没提英文提到的这些——这份语言的作者不知道有它们');
      expect(theirs.difference(english).toList()..sort(), isEmpty,
          reason: '${file.path} 提了英文没提的——英文才是要补的那一份');
    }
  }, skip: present ? null : 'SDK 仓库不在这台机器上');

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

  test('the SDK quotes the editor own limits on a plugin interface', () {
    // A plugin author reads these numbers and builds to them. They live in
    // `plugin_ui.dart` here and in prose in twelve files there, and nothing
    // tied the two together — the same shape as the dependency count, which
    // was wrong in nineteen places by the time anyone looked.
    //
    // Both limits are named in one sentence, so the paragraph holding one has
    // to hold the other. By paragraph rather than by line: the English
    // sentence wraps between them.
    //
    // Arabic spells its numbers out — اثنتي عشرة for twelve, خمسمئة for five
    // hundred — which is ordinary in formal prose. Assuming digits travel
    // untranslated made this test report that file as missing the limits
    // entirely, when it states them as carefully as any other.
    const arabic = (depth: 'اثنتي عشرة', nodes: 'خمسمئة');

    final files = [
      File('$repo/README.md'),
      ...Directory('$repo/docs/i18n')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md')),
    ];
    expect(files.length, 12, reason: 'SDK 的英文一份加十一份翻译');

    final wrong = <String>[];
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      final isArabic = name.contains('ar-SA');
      final nodes = isArabic ? arabic.nodes : '${PluginUiLimits.maxNodes}';
      final depth = isArabic ? arabic.depth : '${PluginUiLimits.maxDepth}';

      final paragraphs = file
          .readAsStringSync()
          .split('\n\n')
          .where((p) => p.contains(nodes))
          .toList();

      if (paragraphs.isEmpty) {
        wrong.add('$name: 不再提节点上限（$nodes）');
        continue;
      }
      for (final paragraph in paragraphs) {
        if (!paragraph.contains(depth)) {
          wrong.add('$name: 说了节点上限却没说深度上限（$depth）');
        }
      }
    }

    expect(
      wrong,
      isEmpty,
      reason:
          '编辑器的上限是 ${PluginUiLimits.maxDepth} 层 / '
          '${PluginUiLimits.maxNodes} 个节点，SDK 文档说的是别的：\n'
          '${wrong.join('\n')}',
    );
  }, skip: present ? null : 'SDK 仓库不在这台机器上');

  test('the schema names the icons the editor can draw', () {
    // A panel must name an icon, and until now the schema said only that it
    // is a non-empty string. An author had forty names to guess from and no
    // list to guess out of; a wrong one falls back to a generic plugin square
    // with nothing said, so the mistake looks like the editor ignoring them.
    //
    // With the names in the schema, an editor writing the manifest offers
    // them and refuses the rest. That is worth having only if the two stay
    // in step, which is what this checks.
    expect(
      enumAt(schema(), [
        'properties',
        'panels',
        'items',
        'properties',
        'icon',
      ]).toSet(),
      PluginIcons.names.toSet(),
      reason: 'schema 列的图标名，编辑器要画得出来',
    );
  }, skip: present ? null : 'SDK 仓库不在这台机器上');

  test('every contribution the schema allows is described in every language',
      () {
    // `panels` was described in eight of the twelve. Four — German, Japanese,
    // Korean, Chinese — did not contain the word at all, so a plugin author
    // reading those did not know the right side bar existed.
    //
    // The shape guard could not see it: that section carries no heading and no
    // fenced block of its own, so twelve files with the same counts had one
    // capability in eight of them. Field names are not translated, which is
    // what makes this checkable at all.
    final fields = (schema()['properties'] as Map<String, dynamic>).keys
        .where((name) => const {
              'menus',
              'commands',
              'toolbar',
              'panels',
              'pages',
              'settings',
              'permissions',
              'entrypoints',
            }.contains(name))
        .toList();
    expect(fields, hasLength(8), reason: 'schema 的贡献点变了，这条守卫要跟着改');

    final files = [
      File('$repo/README.md'),
      ...Directory('$repo/docs/i18n')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md')),
    ];

    final missing = <String>[];
    for (final file in files) {
      final text = file.readAsStringSync();
      for (final field in fields) {
        if (!text.contains(field)) {
          missing.add('${file.uri.pathSegments.last}: 不提 `$field`');
        }
      }
    }

    expect(
      missing,
      isEmpty,
      reason: '这些语言的读者不知道有这个能力：\n${missing.join('\n')}',
    );
  }, skip: present ? null : 'SDK 仓库不在这台机器上');

  test('neither plugin repository writes a changelog section twice', () {
    // The editor's own is checked in `repository_documents_test`; these two
    // are here because this file already knows how to skip when the sibling
    // checkouts are absent, which they are on CI.
    //
    // Both had grown a second `### Fixed` inside `[Unreleased]` — entries
    // appended under a new heading instead of into the one above — and one a
    // second `### Added` as well. A reader looking for what was fixed finds
    // the first list and stops.
    final files = [
      File('$repo/CHANGELOG.md'),
      File('${repo!.replaceAll('plugin-sdk', 'ai-translate-plugin')}'
          '/CHANGELOG.md'),
    ].where((f) => f.existsSync()).toList();
    expect(files, hasLength(2), reason: '两个插件仓库的 CHANGELOG 都要读到');

    final doubled = <String>[];
    for (final file in files) {
      final name = file.parent.uri.pathSegments
          .where((p) => p.isNotEmpty)
          .last;
      for (final section in file
          .readAsStringSync()
          .split(RegExp(r'^## ', multiLine: true))
          .skip(1)) {
        final version = section.split('\n').first.trim();
        final seen = <String>{};
        for (final match
            in RegExp(r'^### (.+)$', multiLine: true).allMatches(section)) {
          final heading = match.group(1)!.trim();
          if (!seen.add(heading)) {
            doubled.add('$name $version: 「$heading」出现了两次');
          }
        }
      }
    }
    expect(doubled, isEmpty, reason: doubled.join('\n'));
  }, skip: present ? null : 'SDK 仓库不在这台机器上');

  test('every language says what a panel is asked on a second round', () {
    // A command run from a panel can be run again with the reader asking for
    // the answer to be changed, and the editor says so by handing the script
    // its own last answer as `ctx.selection`. A plugin that reads the
    // selection as "the part to work on" needs nothing; one that ignores it
    // rewrites the whole document every round. Nobody can act on that without
    // being told, and being told in English only is the shape of BUG-353.
    //
    // The shape guard next door counts headings, so it already insists every
    // translation carries the section. What it cannot see is whether the
    // section says this — which is what the two field names are for, since
    // field names are not translated.
    //
    // Looked for *inside that section*: both appear eight and twelve times
    // across the file, so asking whether the file contains them proves
    // nothing at all.
    final files = [
      File('$repo/README.md'),
      ...Directory('$repo/docs/i18n')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md')),
    ];
    expect(files, hasLength(12), reason: '读到 ${files.length} 份 README，取法坏了');

    /// The fifth `###` section, which is this one in every language.
    String section(String text) {
      final heads = RegExp(r'^### ', multiLine: true).allMatches(text).toList();
      if (heads.length < 6) return '';
      return text.substring(heads[4].start, heads[5].start);
    }

    // Guards the guard: if a `###` is added earlier the index moves, and this
    // would go on checking some other section and passing for the wrong
    // reason. The English heading is the anchor.
    expect(
      section(File('$repo/README.md').readAsStringSync()),
      contains('asked again'),
      reason: '第五个三级标题不再是「面板会被再问一次」，这条守卫的取法要跟着改',
    );

    final missing = <String>[];
    for (final file in files) {
      final body = section(file.readAsStringSync());
      for (final field in ['ctx.selection', 'ctx.answer']) {
        if (!body.contains(field)) {
          missing.add('${file.uri.pathSegments.last}: $field');
        }
      }
    }

    expect(
      missing,
      isEmpty,
      reason: '这几份 SDK 文档没有说明追加一轮时脚本会收到什么：$missing',
    );
  }, skip: present ? null : 'SDK 仓库不在这台机器上');
}
