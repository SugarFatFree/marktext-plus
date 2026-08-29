import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';
import 'package:marktext_plus/ui/widgets/format_toolbar.dart';

/// The strip of formatting commands that appears over a selection.
///
/// Upstream MarkText's `inline/format-toolbar` spec asks two things of it:
/// that it appear when text is selected, and that its buttons wrap the
/// selection. Both are checked here against the real editor rather than
/// against the widget on its own, because the parts that can go wrong —
/// whether the selection is seen, whether the overlay is taken down again —
/// are in the wiring.
void main() {
  late Directory configDir;
  var tabCounter = 0;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('fmttoolbar');
    tabCounter = 0;
  });
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<TextEditingController> open(
    WidgetTester tester,
    String initial,
  ) async {
    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: configDir.path),
          AppConfig(),
        ),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SourceEditor(
              tabId: 'tab-${tabCounter++}',
              initialContent: initial,
            ),
          ),
        ),
      ),
    );
    // The editor sets itself up over a frame; before that it ignores changes.
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    return tester.widget<TextField>(find.byType(TextField)).controller!;
  }

  testWidgets('nothing is shown while the caret is only a caret',
      (tester) async {
    final controller = await open(tester, 'hello world\n');
    controller.selection = const TextSelection.collapsed(offset: 3);
    await tester.pumpAndSettle();
    expect(find.byType(FormatToolbar), findsNothing);
  });

  testWidgets('it appears when text is selected', (tester) async {
    final controller = await open(tester, 'hello world\n');
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pumpAndSettle();
    expect(find.byType(FormatToolbar), findsOneWidget);
  });

  testWidgets('it goes away again when the selection collapses',
      (tester) async {
    final controller = await open(tester, 'hello world\n');
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pumpAndSettle();
    expect(find.byType(FormatToolbar), findsOneWidget);

    controller.selection = const TextSelection.collapsed(offset: 5);
    await tester.pumpAndSettle();
    expect(find.byType(FormatToolbar), findsNothing);
  });

  testWidgets('a selection spanning lines shows nothing', (tester) async {
    // A strip floating over a block would cover the text it is about.
    final controller = await open(tester, 'one\ntwo\n');
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 7);
    await tester.pumpAndSettle();
    expect(find.byType(FormatToolbar), findsNothing);
  });

  testWidgets('the bold button wraps the selection', (tester) async {
    final controller = await open(tester, 'hello world\n');
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.format_bold));
    await tester.pumpAndSettle();
    expect(controller.text, '**hello** world\n');
  });

  testWidgets('the italic button wraps the selection', (tester) async {
    final controller = await open(tester, 'alpha beta\n');
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.format_italic));
    await tester.pumpAndSettle();
    expect(controller.text, '*alpha* beta\n');
  });

  testWidgets('the toolbar is taken down after a command is applied',
      (tester) async {
    final controller = await open(tester, 'hello world\n');
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.format_bold));
    await tester.pumpAndSettle();
    expect(find.byType(FormatToolbar), findsNothing);
  });

  testWidgets('every button on it names a command', (tester) async {
    final controller = await open(tester, 'hello world\n');
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pumpAndSettle();
    final buttons = tester.widgetList<IconButton>(
      find.descendant(
        of: find.byType(FormatToolbar),
        matching: find.byType(IconButton),
      ),
    );
    expect(buttons, hasLength(6));
    for (final button in buttons) {
      expect(button.tooltip, isNotNull);
      expect(button.tooltip, isNotEmpty);
      expect(button.onPressed, isNotNull);
    }
  });

  testWidgets('it is placed within the editor and near the selected line',
      (tester) async {
    // Pixel-exact placement is not something a widget test can judge, but
    // "on screen, over the editor, next to the right line" is — and those are
    // the ways the arithmetic can be wrong that a reader would notice.
    final controller =
        await open(tester, 'line zero\nline one\nline two\nline three\n');
    final editorRect = tester.getRect(find.byType(TextField));

    // Select `one` on the second line.
    final at = 'line zero\nline '.length;
    controller.selection =
        TextSelection(baseOffset: at, extentOffset: at + 3);
    await tester.pumpAndSettle();

    final toolbar = tester.getRect(find.byType(FormatToolbar));
    expect(toolbar.left, greaterThanOrEqualTo(editorRect.left - 1),
        reason: '工具栏跑到编辑器左边外面了');
    expect(toolbar.right, lessThanOrEqualTo(editorRect.right + 1),
        reason: '工具栏跑到编辑器右边外面了');
    expect(toolbar.top, greaterThanOrEqualTo(0.0), reason: '工具栏跑到屏幕上方外面了');

    // The strip goes just above the selected line, or just below it when
    // there is no room above. Anything else — a strip several lines away, or
    // one sitting on top of the text it is about — is arithmetic gone wrong.
    // Read from AppConfig's own defaults rather than assumed: the editor
    // lays the text out with these two numbers, so a guess here tests nothing.
    final config = AppConfig();
    final lineHeight = config.fontSize * config.lineHeight;
    final lineTop = editorRect.top + 8 + lineHeight;
    final lineBottom = lineTop + lineHeight;
    final above = (toolbar.bottom - lineTop).abs() <= 6;
    final below = (toolbar.top - lineBottom).abs() <= 6;
    expect(above || below, isTrue,
        reason: '工具栏既没贴在这一行上方也没贴在下方：'
            '${toolbar.top}–${toolbar.bottom}，行是 $lineTop–$lineBottom');
    expect(toolbar.height, FormatToolbar.height,
        reason: '实际高度与组件导出的高度不一致，定位就会算错');
  });
}
