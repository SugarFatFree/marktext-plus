import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/ui/widgets/mermaid_failure.dart';

/// A diagram that will not parse says why in the reader's language, on screen
/// and in what gets exported.
///
/// The Mermaid package depends on nothing but Flutter, so it cannot reach the
/// editor's translations and its own error box is English. The preview already
/// knew that and words the failure itself. The export did not: it renders each
/// diagram off screen with no `errorBuilder`, so a diagram with a typo was
/// captured as a picture of the package's English panel and embedded in the PDF,
/// the Word file and the HTML — in a document the reader then sends to somebody
/// else, whatever language they wrote it in.
///
/// The note on the package's own box said this was intended, because reaching
/// the translations would end the package's independence. It would — from inside
/// the package. The export is app code and can pass a builder exactly as the
/// preview does, so the reason did not hold for the caller it was written about.
///
/// The wording and the box are one implementation now, used by both.
void main() {
  const shapes = <String, String>{
    'empty': '   \n\n',
    'unknown type': 'grahp TD\n  A --> B',
    'header only': 'flowchart TD',
    'body that will not parse': 'graph TD\n  A--->',
  };

  group('the failure is worded for the reader', () {
    test('each shape gets a sentence, in English, none repeating', () async {
      final english = await AppLocalizations.delegate.load(const Locale('en'));
      final said = <String>{};
      for (final entry in shapes.entries) {
        final text = describeMermaidFailure(entry.value, english);
        expect(text, isNotEmpty, reason: '${entry.key} 没有句子');
        said.add(text.split('\n').first);
      }
      expect(said, hasLength(shapes.length),
          reason: '两种失败给出了同一句话，读者不知道该改什么：$said');
    });

    test('and in each of the twelve', () async {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = await AppLocalizations.delegate.load(locale);
        for (final entry in shapes.entries) {
          expect(describeMermaidFailure(entry.value, l10n), isNotEmpty,
              reason: '$locale 缺 ${entry.key}');
        }
      }
    });

    test('not in English for a reader who is not reading English', () async {
      final english = await AppLocalizations.delegate.load(const Locale('en'));
      final chinese = await AppLocalizations.delegate.load(const Locale('zh'));
      for (final entry in shapes.entries) {
        expect(
          describeMermaidFailure(entry.value, chinese),
          isNot(describeMermaidFailure(entry.value, english)),
          reason: '${entry.key} 的中文与英文相同——多半是没翻译',
        );
      }
    });

    /// The type names are what has to be typed, so they stay as they are in
    /// every language. A reader told to write `流程图` would have nowhere to
    /// write it.
    test('the diagram type names are not translated', () async {
      final chinese = await AppLocalizations.delegate.load(const Locale('zh'));
      final text = describeMermaidFailure('grahp TD\n  A --> B', chinese);
      expect(text, contains('grahp'), reason: '打错的那个词要引回给读者');
      expect(text, contains('flowchart'), reason: '可用类型的名字必须原样列出');
    });
  });

  group('and shown wherever a diagram is drawn', () {
    testWidgets('the box says it in the reader language', (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: MermaidFailureBox(code: 'grahp TD\n  A --> B'),
        ),
      ));
      await tester.pumpAndSettle();
      final english = await AppLocalizations.delegate.load(const Locale('en'));
      final shown = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(shown, isNot(contains(english.mermaidParseError)),
          reason: '标题是英文的');
      expect(shown, contains('grahp'), reason: '打错的词不见了');
    });

    /// The package's own box is English by design. Every place the app draws a
    /// diagram has to hand it a builder, or that box reaches a reader — which
    /// is how it reached the inside of an exported PDF.
    test('every diagram the app draws is given a builder', () {
      final offenders = <String>[];
      var found = 0;
      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          // The package's own widget is where the fallback lives.
          .where((f) => !f.path.contains('mermaid/widgets/'))) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          // A doc comment showing how to use the widget is not somebody using
          // it. The package's own file opens with three such examples, and
          // counting them would have this guard reporting a leak in the
          // sentences that explain the widget.
          if (lines[i].trimLeft().startsWith('//')) continue;
          if (!lines[i].contains('MermaidDiagram(')) continue;
          found++;
          final end = (i + 12 < lines.length) ? i + 12 : lines.length;
          final call = lines.sublist(i, end).join('\n');
          if (!call.contains('errorBuilder')) {
            offenders.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(found, greaterThanOrEqualTo(2),
          reason: '只找到 $found 处 MermaidDiagram(，取法要跟着改');
      expect(offenders, isEmpty,
          reason: '这些地方画图表时没给 errorBuilder，'
              '解析失败会显示包自带的英文错误框：${offenders.join(', ')}');
    });
  });
}
