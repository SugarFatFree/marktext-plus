import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/services/rich_copy_service.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// "Copy as HTML" hands over the same HTML the rest of the editor writes.
///
/// Four places turn a selection into HTML for the clipboard — Ctrl+C, Cut, the
/// menu's Copy, and the preview's own copy — and all four call
/// `RichCopyService.htmlForMarkdownSelection`, which parses the markdown and
/// hands the blocks to `ExportService.nodeToHtml`. The one item whose name is
/// about HTML did not: it ran a chain of regular expressions over the selected
/// text, four inline forms and six heading levels, and stopped there.
///
/// So the same selection copied two ways gave two different documents. What the
/// regular expressions left out is most of the format — lists, tables, links,
/// images, code blocks, quotes, maths, footnotes, highlight, underline, super-
/// and subscript — and what they got wrong is the same thing the source pane's
/// own patterns got wrong: no flanking rule, so `**加粗。**后面` became bold
/// where the preview draws asterisks, and a run of three came apart. They also
/// escaped nothing, so a selection holding `a < b` produced HTML that no longer
/// said `a < b`.
void main() {
  late Directory configDir;
  setUp(() => configDir = Directory.systemTemp.createTempSync('copy_html'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  var built = 0;

  /// The text handed to the clipboard when [action] runs over [text].
  Future<String?> copied(
    WidgetTester tester,
    FormatAction action, {
    required String text,
  }) async {
    String? captured;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          captured = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(editMode: EditMode.source),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SourceEditor(
              key: ValueKey('editor${built++}'),
              tabId: 't',
              initialContent: text,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final controller = container.read(editorProvider.notifier).controller!;
    controller.selection =
        TextSelection(baseOffset: 0, extentOffset: text.length);
    await tester.pump();
    container.read(editorProvider.notifier).applyFormat(action);
    await tester.pumpAndSettle();
    return captured;
  }

  /// Shapes the regular expressions could not reach, one per line so a failure
  /// names the one that broke.
  const documents = <String, String>{
    'a heading and a paragraph': '## Title\n\nA sentence.',
    'a bullet list': '- one\n- two',
    'a numbered list': '1. first\n2. second',
    'a table': '| h1 | h2 |\n|---|---|\n| a | b |',
    'a link': 'read [the manual](https://example.com) first',
    'an image': 'see ![a picture](https://example.com/p.png) here',
    'a fenced code block': '```dart\nvar a = 1;\n```',
    'a quote': '> quoted words',
    'inline maths': r'the sum $a + b$ here',
    'a footnote': 'a claim[^src] here\n\n[^src]: the source',
    'highlight and underline': 'see ==this== and ++that==',
    'super and subscript': 'area 5cm^2^ and water H~2~O',
    'a nested run': 'a ***bold and soft*** word',
    'emphasis beside Chinese punctuation': '**加粗。**后面接中文',
    'characters HTML cares about': 'a < b and c > d and AT&T',
  };

  documents.forEach((name, document) {
    testWidgets(name, (tester) async {
      final actual = await copied(tester, FormatAction.copyAsHtml,
          text: document);
      expect(
        actual,
        RichCopyService.htmlForMarkdownSelection(document, enableHtml: false),
        reason: 'Copy as HTML wrote something the rest of the editor does not',
      );
    });
  });

  /// The sibling action is about the source, not about HTML: it hands over what
  /// was selected, unchanged.
  testWidgets('copy as markdown still hands over the source', (tester) async {
    const document = '## Title\n\nA **bold** word.';
    expect(
      await copied(tester, FormatAction.copyAsMarkdown, text: document),
      document,
    );
  });
}
