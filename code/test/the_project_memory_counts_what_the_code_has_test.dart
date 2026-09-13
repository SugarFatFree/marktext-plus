import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/theme/app_theme.dart';
import 'package:marktext_plus/ui/editor/mermaid/models/diagram.dart';

/// The project's own memory, held to the code it describes.
///
/// `.claude/CLAUDE.md` is read at the start of every session and says its
/// instructions override everything else, and nothing checked it. It had gone
/// stale in the ways it warns about: "14 colour tokens" when there are sixteen
/// fields, and — in the same file that says a claim and its implementation must
/// be reconciled — a "how to verify" recipe for the diagram count that returns
/// 46 rather than 22, because the same type appears in several switches.
///
/// Only the claims that can be checked. Most of that file is judgement, which
/// is the part worth writing down and the part no test can hold.
void main() {
  /// The file, found by walking up: the tests run from `code/`, and the memory
  /// lives beside it rather than in it.
  File? memory() {
    var dir = Directory.current;
    for (var i = 0; i < 4; i++) {
      final file = File('${dir.path}/.claude/CLAUDE.md');
      if (file.existsSync()) return file;
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return null;
  }

  /// Skipped rather than failed when it cannot be found: a checkout of `code/`
  /// alone is a thing people do, and a guard that fails there teaches people to
  /// ignore it.
  String? text() => memory()?.readAsStringSync();

  test('it counts the diagram types the parser has', () {
    final source = text();
    if (source == null) return;
    final types =
        DiagramType.values.where((t) => t != DiagramType.unknown).length;
    expect(types, greaterThan(10), reason: '图型枚举读错了');
    expect(source, contains('$types 种'),
        reason: 'CLAUDE.md 没写「$types 种」——图表类型的数量变了而它没跟上');
  });

  test('it counts the themes the editor builds', () {
    final source = text();
    if (source == null) return;
    expect(source, contains('${AppTheme.themeNames.length} 个内置主题'),
        reason: '主题数量变了而 CLAUDE.md 没跟上');
  });

  test('it counts the fields a theme is made of', () {
    final source = text();
    if (source == null) return;
    // Read from the class rather than from a list written here, so adding a
    // token moves this on its own.
    final tokens = File('lib/core/theme/app_theme.dart').readAsStringSync();
    final start = tokens.indexOf('class AppThemeTokens');
    expect(start, greaterThan(0), reason: '找不到 AppThemeTokens，取法要跟着改');
    final body = tokens.substring(start, tokens.indexOf('\n}', start));
    final fields = RegExp(r'final\s+[A-Za-z<>?]+\s+\w+;').allMatches(body).length;
    expect(fields, greaterThan(5), reason: '一个字段都没数到，取法要跟着改');
    expect(source, contains('$fields 个字段'),
        reason: 'AppThemeTokens 有 $fields 个字段，CLAUDE.md 说的是别的数');
  });

  test('it counts the languages the app ships', () {
    final source = text();
    if (source == null) return;
    final arbs = Directory('lib/core/i18n/l10n')
        .listSync()
        .where((f) => f.path.endsWith('.arb'))
        .length;
    expect(source, contains('$arbs 种语言'),
        reason: '语言数量变了而 CLAUDE.md 没跟上');
  });

  test('every file and test it names is there, and the two it says are gone are gone', () {
    final source = text();
    if (source == null) return;
    final root = memory()!.parent.parent.path;

    // Paths in backticks, minus the `vX.Y.Z` template ones which name no real
    // directory on purpose.
    final missing = <String>[];
    for (final match in RegExp(r'`([A-Za-z0-9_./-]+\.(?:dart|yaml|yml|sh|arb|json|py))`')
        .allMatches(source)) {
      final path = match.group(1)!;
      if (path.contains('vX.Y.Z') || path == 'scripts/release.sh') continue;
      final exists = File('$root/$path').existsSync() ||
          File('$root/code/$path').existsSync();
      if (!exists) missing.add(path);
    }
    expect(missing, isEmpty, reason: 'CLAUDE.md 指到了不存在的文件：$missing');

    // Tests it sends the reader to, named without the extension.
    final absentTests = <String>[];
    for (final match in RegExp(r'`([a-z0-9_]*_test)`').allMatches(source)) {
      final name = match.group(1)!;
      final found = Directory('test')
          .listSync(recursive: true)
          .any((f) => f.path.endsWith('/$name.dart'));
      if (!found) absentTests.add(name);
    }
    expect(absentTests, isEmpty,
        reason: 'CLAUDE.md 指到了不存在的测试：$absentTests');

    // Two claims of absence, which are load-bearing: one tells the next person
    // not to look for a release script, the other records a container that was
    // deleted and must not come back.
    expect(File('$root/scripts/release.sh').existsSync(), isFalse,
        reason: 'release.sh 存在了，而 CLAUDE.md 说它不存在——改文档或删脚本');
    final resurrected = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains('PluginResultPanel'))
        .map((f) => f.path)
        .toList();
    expect(resurrected, isEmpty,
        reason: 'PluginResultPanel 回来了，而 CLAUDE.md 记着它已删除：$resurrected');
  });
}
