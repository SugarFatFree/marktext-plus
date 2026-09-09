import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/theme/app_theme.dart';
import 'package:marktext_plus/ui/editor/mermaid/mermaid.dart';

/// The numbers the README puts in front of a reader are the real ones.
///
/// "22 diagram types" and "8 themes" are the two countable claims on the front
/// page, repeated in eleven translations. Nothing compared them with anything:
/// adding a diagram type or a theme leaves twelve files saying the old number,
/// and the first person to notice is someone who counted.
///
/// This is the third debugging view in the project's own notes — a list
/// published outward, a list that is the implementation, and nobody comparing
/// them — applied to the most outward list there is.
void main() {
  final repo = Directory.current.parent;

  List<File> readmes() => [
    File('${repo.path}/README.md'),
    ...Directory('${repo.path}/docs/i18n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md')),
  ];

  test('there are twelve READMEs to check', () {
    // Guards the guard: a directory that stopped being found would leave the
    // loops below with nothing to disagree with.
    expect(readmes(), hasLength(12));
  });

  test('every README counts the diagram types the parser has', () {
    final types = DiagramType.values.where((t) => t != DiagramType.unknown);
    expect(types.length, greaterThan(10), reason: '图型枚举读错了');

    final wrong = <String>[];
    for (final file in readmes()) {
      final text = file.readAsStringSync();
      // The number is written as digits in every language — the surrounding
      // words are translated and the count is not.
      if (!text.contains('${types.length}')) {
        wrong.add(file.uri.pathSegments.last);
      }
    }
    expect(
      wrong,
      isEmpty,
      reason: '这几份 README 里找不到 ${types.length} 这个数——'
          '图型数量变了而它们没跟上：$wrong',
    );
  });

  test('every README counts the themes the editor builds', () {
    final themes = AppTheme.themeNames;
    expect(themes, hasLength(8), reason: '主题数量变了，下面每份 README 都要跟着改');
    expect(
      {...AppTheme.lightThemeNames, ...AppTheme.darkThemeNames},
      themes.toSet(),
      reason: '明暗两张表加起来不等于总表，设置页会漏掉或重复某个主题',
    );

    final wrong = <String>[];
    for (final file in readmes()) {
      if (!file.readAsStringSync().contains('${themes.length}')) {
        wrong.add(file.uri.pathSegments.last);
      }
    }
    expect(wrong, isEmpty, reason: '这几份 README 没有说出主题数：$wrong');
  });

  test('the English README names every diagram type it counts', () {
    // The number and the list beside it are two claims, and only one of them
    // is a number. A type added to the parser and to the count but not to the
    // list reads as an editor that draws twenty-two and can name twenty-one.
    final text = File('${repo.path}/README.md').readAsStringSync();
    final types = DiagramType.values.where((t) => t != DiagramType.unknown);

    // The feature table's row, not the bullet further up: only the row lists
    // the types, and both say the number.
    final row = const LineSplitter()
        .convert(text)
        .where((line) => line.contains('**${types.length} diagram types**'))
        .toList();
    expect(row, hasLength(1), reason: 'README 里那一行改写了，这条检查的取法要跟着改');

    // The written names differ from the enum's spelling by design — "ER"
    // rather than `erDiagram`, "XY chart" rather than `xyChart` — so this
    // counts them rather than matching them one by one.
    final named = row.single
        .split(':')
        .last
        .split(RegExp(r',| and '))
        .map((name) => name.replaceAll('|', '').trim())
        .where((name) => name.isNotEmpty)
        .length;
    expect(
      named,
      types.length,
      reason: '这一行数出 $named 个名字，而解析器有 ${types.length} 种',
    );
  });
}
