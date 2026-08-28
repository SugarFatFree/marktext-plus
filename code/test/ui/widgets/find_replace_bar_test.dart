import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/widgets/find_replace_bar.dart';

/// Splices matches back into the document the way replace-all does, so a
/// regression in the scan shows up as corrupted text rather than a count.
///
/// The production routine, not a copy of it: this file used to carry its own
/// implementation, which meant these tests could pass while the editor did
/// something else.
String replaceAll(String text, List<TextRange> matches, String replacement) =>
    FindReplaceBar.replaceRanges(text, matches, replacement);

List<int> starts(List<TextRange> matches) => matches.map((m) => m.start).toList();

void main() {
  group('FindReplaceBar.findMatches', () {
    test('returns nothing for an empty pattern', () {
      expect(FindReplaceBar.findMatches('hello', ''), isEmpty);
    });

    test('finds plain matches in document order', () {
      expect(starts(FindReplaceBar.findMatches('abab', 'ab')), [0, 2]);
    });

    test('ignores case unless asked', () {
      expect(starts(FindReplaceBar.findMatches('AbAb', 'ab')), [0, 2]);
      expect(
        FindReplaceBar.findMatches('AbAb', 'ab', caseSensitive: true),
        isEmpty,
      );
    });

    test('matches never overlap', () {
      // "aa" in "aaaa" is two matches, not three: a one-character advance made
      // replace-all splice overlapping ranges and eat the surrounding text.
      final matches = FindReplaceBar.findMatches('aaaa', 'aa');
      expect(starts(matches), [0, 2]);
      expect(replaceAll('aaaa', matches, 'b'), 'bb');
    });

    test('whole word skips matches inside longer words', () {
      expect(
        starts(FindReplaceBar.findMatches('aaa aa', 'aa', wholeWord: true)),
        [4],
      );
      expect(
        starts(FindReplaceBar.findMatches('cat cats', 'cat', wholeWord: true)),
        [0],
      );
      expect(
        starts(FindReplaceBar.findMatches('_cat cat', 'cat', wholeWord: true)),
        [5],
      );
    });

    test('regex matches respect the case flag', () {
      expect(
        starts(FindReplaceBar.findMatches(r'a1 b22', r'\d+', useRegex: true)),
        [1, 4],
      );
      expect(
        FindReplaceBar.findMatches('ABC', 'abc', useRegex: true, caseSensitive: true),
        isEmpty,
      );
    });

    test('an invalid regex reports no matches instead of throwing', () {
      expect(FindReplaceBar.findMatches('abc', '([a-', useRegex: true), isEmpty);
    });

    test('a zero-width regex does not loop forever', () {
      expect(
        FindReplaceBar.findMatches('abc', 'x*', useRegex: true).length,
        lessThanOrEqualTo(4),
      );
    });

    test('replace-all over a real document keeps unmatched text intact', () {
      const doc = 'foo bar foo baz foofoo';
      final matches = FindReplaceBar.findMatches(doc, 'foo');
      expect(matches, hasLength(4));
      expect(replaceAll(doc, matches, 'X'), 'X bar X baz XX');
    });
  });

  group('replace-all writes only what was counted', () {
    /// A pattern that can match nothing reports a hit at every position.
    /// [FindReplaceBar.findMatches] drops those; `String.replaceAll` does not,
    /// and the regular-expression branch used to call it — so the editor wrote
    /// six replacements in a document it had shown two matches for.
    void expectAgrees(String text, String pattern, String replacement,
        int expectedMatches, String expected) {
      final matches = FindReplaceBar.findMatches(
        text,
        pattern,
        caseSensitive: true,
        useRegex: true,
      );
      expect(matches, hasLength(expectedMatches), reason: pattern);
      expect(
        FindReplaceBar.replaceRanges(text, matches, replacement),
        expected,
        reason: pattern,
      );
    }

    test('a pattern that can match nothing replaces only its real hits', () {
      expectAgrees('axbxc', 'x*', 'Y', 2, 'aYbYc');
      expectAgrees('abc', 'a?', 'Y', 1, 'Ybc');
      expectAgrees('abc', '.*', 'Y', 1, 'Y');
    });

    test('ordinary patterns are unchanged', () {
      expectAgrees('axbxc', 'x', 'Y', 2, 'aYbYc');
      expectAgrees('foo bar', r'\bfoo\b', 'Y', 1, 'Y bar');
      expectAgrees('aaaa', 'aa', 'Y', 2, 'YY');
    });

    test('a longer replacement does not disturb the ranges after it', () {
      final matches = FindReplaceBar.findMatches('a b a b', 'a');
      expect(FindReplaceBar.replaceRanges('a b a b', matches, 'LONG'),
          'LONG b LONG b');
    });

    test('an empty replacement deletes the matches', () {
      final matches = FindReplaceBar.findMatches('a-b-c', '-');
      expect(FindReplaceBar.replaceRanges('a-b-c', matches, ''), 'abc');
    });
  });

  group('replace availability', _replaceAvailability);
}

/// The Replace buttons offer only what they can do.
///
/// The expand toggle is already hidden unless the source is the target, so a
/// preview-only search never shows them. Split mode can reach the state all
/// the same: expand Replace while the search is aimed at the source, then aim
/// it at the preview. The row stays open, both buttons stay live, and both
/// return at their first line — a button that does nothing when pressed.
void _replaceAvailability() {
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required SearchTarget target,
  }) async {
    final configDir = Directory.systemTemp.createTempSync('find_bar');
    addTearDown(() {
      if (configDir.existsSync()) configDir.deleteSync(recursive: true);
    });
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(editorProvider.notifier).setSearchTarget(target);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FindReplaceBar(
              textController: TextEditingController(text: 'one two one'),
              rawContent: 'one two one',
              isSplitMode: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  /// Opens the replace row and searches for something that is there.
  Future<void> searchAndExpand(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, 'one');
    await tester.pump();
    final toggle = find.byIcon(Icons.expand_more);
    if (toggle.evaluate().isNotEmpty) {
      await tester.tap(toggle);
      await tester.pump();
    }
  }

  /// The two Replace buttons, found by their labels rather than by type:
  /// the bar has other buttons that are rightly live either way.
  List<bool> replaceButtonsLive(WidgetTester tester) => [
        for (final label in ['Replace', 'Replace All'])
          tester
                  .widget<TextButton>(find.widgetWithText(TextButton, label))
                  .onPressed !=
              null,
      ];

  testWidgets('are live while the source is the target', (tester) async {
    await pump(tester, target: SearchTarget.source);
    await searchAndExpand(tester);

    expect(replaceButtonsLive(tester), [true, true],
        reason: '源码是搜索目标且有匹配，替换应当可用');
  });

  testWidgets('go dead when the search is aimed at the preview',
      (tester) async {
    final container = await pump(tester, target: SearchTarget.source);
    await searchAndExpand(tester);

    container.read(editorProvider.notifier)
        .setSearchTarget(SearchTarget.preview);
    await tester.pump();

    expect(replaceButtonsLive(tester), [false, false],
        reason: '搜索指向预览时按钮仍可点，但按下去什么都不会发生');
  });
}
