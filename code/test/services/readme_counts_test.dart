import 'dart:convert';
import 'dart:io';

import '../support/cost_limits.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/core/theme/app_theme.dart';
import 'package:marktext_plus/ui/editor/mermaid/mermaid.dart';
import 'package:marktext_plus/ui/editor/syntax_highlighter.dart';

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

  /// The test count, as a floor rather than a figure that rots.
  ///
  /// It had rotted into three different answers at once: the English README
  /// said 2777, all eleven translations said 2432, and the suite reported
  /// 3005. A number that changes with every commit and lives in twelve files
  /// cannot be kept exact by hand, and nobody tried after the first drift.
  ///
  /// So it is a floor now, and a floor is checkable: adding tests never makes
  /// it false, and only taking a large number away does. What is counted here
  /// is `test(` and `testWidgets(` calls in the source, which is fewer than
  /// the suite reports — a call inside a `for` becomes several tests — so the
  /// floor this proves is a floor of the real figure too.
  test('every README states a test count the suite can back up', () {
    var declared = 0;
    for (final file in Directory('test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_test.dart'))) {
      declared += RegExp(r'(?<![\w.])(test|testWidgets)\s*\(')
          .allMatches(file.readAsStringSync())
          .length;
    }
    expect(declared, greaterThan(1000), reason: '读出的测试太少，取法要跟着改');

    for (final readme in readmes()) {
      // Written without a thousands separator in every language on purpose:
      // 2.600, 2 600 and 2,600 are all correct somewhere, and a guard that
      // has to know which is a guard that reports a missing number where
      // there is one.
      final claimed = RegExp(r'\b2600\b').allMatches(readme.readAsStringSync());
      expect(claimed, hasLength(1),
          reason: '${readme.path} 里没有那个下限数字，或者出现了不止一次');
    }
    expect(2600, lessThanOrEqualTo(declared),
        reason: 'README 说的下限已经高于实际写下的测试数了');
  });

  /// Twelve translations describe the same set of capabilities.
  ///
  /// A capability the editor grew and the front page never mentioned is a
  /// capability nobody uses: `sdk.ui` — a plugin answering with a tree of
  /// controls the editor draws — was documented in the SDK in twelve
  /// languages and absent from every README, which still said a plugin
  /// "supplies data, never widgets". Four translations once lost the side
  /// panel the same way, and the shape guard on the SDK could not see it
  /// because that section has neither a heading nor a fenced block.
  ///
  /// Emoji are what the rows are keyed by here: they open every row, they are
  /// the same character in every language, and a row dropped in translation
  /// takes its emoji with it.
  test('the feature tables list the same rows in every language', () {
    final rows = <String, Set<String>>{};
    for (final readme in readmes()) {
      rows[readme.path] = readme
          .readAsLinesSync()
          .where((line) => line.startsWith('| **'))
          .map((line) => RegExp(
                r'[\u{1F300}-\u{1FAFF}\u{2190}-\u{2BFF}\u{2600}-\u{27BF}]',
                unicode: true,
              ).firstMatch(line)?.group(0))
          .whereType<String>()
          .toSet();
    }

    final english = rows['${repo.path}/README.md'];
    expect(english, isNotNull, reason: '找不到英文 README，取法要跟着改');
    expect(english!.length, greaterThan(15), reason: '读出的行太少，取法要跟着改');

    rows.forEach((path, theirs) {
      expect(english.difference(theirs).toList()..sort(), isEmpty,
          reason: '$path 少了英文版有的能力行——读这份语言的人不知道有这个能力');
    });
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

  test('the front page quotes the cost budget the suite enforces', () {
    // The English row said the test fails above six times the work. It fails
    // above eight: the limit was raised after a CI run came in at 6.05, and
    // the sentence a reader judges the project by stayed where it was. A
    // promise about performance stricter than the test enforcing it is the
    // kind of thing a contributor finds out by trusting it.
    //
    // English only, deliberately: the eleven translations describe the budget
    // without quoting numbers, and a sentence that says less cannot say
    // something false. If one of them ever states the figures, it joins this.
    const words = {
      2: 'two', 3: 'three', 4: 'four', 5: 'five', 6: 'six',
      7: 'seven', 8: 'eight', 9: 'nine', 10: 'ten', 12: 'twelve',
    };
    final span = words[costSpan];
    final limit = words[costGrowthLimit];
    expect(span, isNotNull,
        reason: 'costSpan 变成了 $costSpan，这张词表要跟着加');
    expect(limit, isNotNull,
        reason: 'costGrowthLimit 变成了 $costGrowthLimit，这张词表要跟着加');

    final row = File('../README.md')
        .readAsLinesSync()
        .firstWhere((line) => line.contains('Large files'),
            orElse: () => '');
    expect(row, isNotEmpty, reason: 'README 里找不到大文件那一行');

    expect(row, contains('$span times the document'),
        reason: '测试用的是 $costSpan 倍文档，README 说的是别的');
    expect(row, contains('$limit times the work'),
        reason: '测试的上限是 $costGrowthLimit 倍，README 说的是别的');

    // The third number in the same row, and it was not checked. The sentence
    // promises that highlighting "stops above 128 KB" and that "a test holds
    // that limit where it is" — a test does, and nothing held the sentence to
    // the test. Two numbers out of the row were compared and the third was
    // read past.
    final kilobytes = IncrementalMarkdownHighlighter.maxHighlightedLength ~/ 1024;
    expect(row, contains('stops above $kilobytes KB'),
        reason: '高亮的上限是 $kilobytes KB，README 说的是别的');
  });

  test('every README counts the interface languages the app ships', () {
    // The third countable claim on the front page, and the one nothing was
    // comparing: adding a thirteenth language leaves twelve files saying
    // twelve, and the first person to notice is someone who counted.
    final locales = AppLocalizations.supportedLocales;
    expect(locales.length, greaterThan(5), reason: 'locale 表读错了');

    final wrong = <String>[];
    for (final file in readmes()) {
      final name = file.uri.pathSegments.last;
      final text = file.readAsStringSync();

      // The globe is the same character in every translation while the word
      // for "languages" is not, so the emoji is what the count is found by —
      // the trick this file already uses for the feature rows.
      final globe = text.indexOf('🌍');
      if (globe < 0) {
        wrong.add('$name: 找不到 🌍 那一行');
      } else {
        final near = text.substring(
            globe, globe + 24 > text.length ? text.length : globe + 24);
        final said = RegExp(r'\d+').firstMatch(near)?.group(0);
        if (said != '${locales.length}') {
          wrong.add('$name: 🌍 那行写的是 $said');
        }
      }

      // And again in the comparison table, which says it a second time and
      // could go stale on its own. The row is found by the number beside it —
      // MarkText's ten, which is not ours to change and is not translated.
      for (final row in RegExp(r'\|\s*(\d+)\s*\|\s*10\s*\|').allMatches(text)) {
        if (row.group(1) != '${locales.length}') {
          wrong.add('$name: 对比表里写的是 ${row.group(1)}');
        }
      }
    }
    expect(
      wrong,
      isEmpty,
      reason: '应用支持 ${locales.length} 种界面语言，这几份 README 没跟上：\n'
          '${wrong.join('\n')}',
    );
  });

  test('every README shows every theme, on the right side of the table', () {
    // The count was checked and the names were not, so renaming a theme, or
    // moving one between the light and dark columns, changed nothing here —
    // and a reader picking from the "Light Themes" column would have got a
    // dark one. The pictures are the anchor: their filenames are the theme
    // ids in kebab-case and are not translated, while the headings are.
    String kebab(String id) => id
        .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'),
            (m) => '${m[1]}-${m[2]}')
        .toLowerCase();

    final light = AppTheme.lightThemeNames.map(kebab).toList();
    final dark = AppTheme.darkThemeNames.map(kebab).toList();
    expect(light.length + dark.length, AppTheme.themeNames.length);

    final wrong = <String>[];
    for (final file in readmes()) {
      final name = file.uri.pathSegments.last;
      final text = file.readAsStringSync();

      // The table, not the whole file: the front-page screenshot is a theme
      // picture too and stands outside it.
      final table = RegExp(r'<table>[\s\S]*?</table>')
          .allMatches(text)
          .map((m) => m.group(0)!)
          .where((t) => t.contains('picture/theme/'))
          .toList();
      if (table.length != 1) {
        wrong.add('$name: 找到 ${table.length} 张主题表，取法要跟着改');
        continue;
      }

      final shown = RegExp(r'picture/theme/([a-z0-9-]+)\.png')
          .allMatches(table.single)
          .map((m) => m.group(1)!)
          .toList();

      final missing = [...light, ...dark].where((t) => !shown.contains(t));
      if (missing.isNotEmpty) {
        wrong.add('$name: 表里没有这些主题的图 $missing');
      }
      final extra = shown.where((t) => !light.contains(t) && !dark.contains(t));
      if (extra.isNotEmpty) {
        wrong.add('$name: 表里有编辑器没有的主题 ${extra.toList()}');
      }

      // Two cells to a row, light first — which is what the two headings say.
      for (var i = 0; i < shown.length; i++) {
        final expected = i.isEven ? light : dark;
        final other = i.isEven ? dark : light;
        if (other.contains(shown[i]) && !expected.contains(shown[i])) {
          wrong.add('$name: ${shown[i]} 画在了'
              '${i.isEven ? "浅色" : "深色"}那一列，而它是'
              '${i.isEven ? "深色" : "浅色"}主题');
        }
      }
    }
    expect(wrong, isEmpty, reason: '主题表与编辑器对不上：\n${wrong.join('\n')}');
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
