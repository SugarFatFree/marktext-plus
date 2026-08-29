import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:marktext_plus/core/i18n/l10n/app_localizations.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

void main() {
  late Directory configDir;

  setUp(() {
    // createTempSync, not the async form: testWidgets runs inside a FakeAsync
    // zone where a dart:io future never completes.
    configDir = Directory.systemTemp.createTempSync('renderer_edit_test');
  });

  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<void> pumpRenderer(
    WidgetTester tester, {
    required String markdown,
    ValueChanged<String>? onSourceChanged,
  }) async {
    final configService = ConfigService(configDir: configDir.path);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(configService, AppConfig()),
          ),
        ],
        child: MaterialApp(
          // A diagram's toolbar reads its labels from here; without the
          // delegates `AppLocalizations.of` returns null and it throws.
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MarkdownRenderer(
              markdown: markdown,
              onSourceChanged: onSourceChanged,
            ),
          ),
        ),
      ),
    );
    // Not pumpAndSettle: progressive rendering schedules further frames, so
    // the tree never goes quiet on its own.
    await tester.pump();
  }

  /// Two taps close enough together to register as a double tap.
  ///
  /// The final pump runs out the recogniser's own timer; without it the test
  /// ends with a pending timer and fails.
  Future<void> doubleTap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(finder);
    await tester.pump(kDoubleTapTimeout);
  }

  /// The wrapper that gives a block its text cursor and hover wash.
  ///
  /// Not `MouseRegion` with a text cursor: the preview sits inside a
  /// SelectionArea, which installs those itself, so that predicate matches
  /// everywhere and distinguishes nothing.
  Finder editableCursors() => find.byType(PreviewEditableBlock);

  group('Saying that a block can be edited', () {
    testWidgets('a paragraph asks for the text cursor', (tester) async {
      // Double tap always worked; nothing on screen said so. The pointer
      // stayed an arrow and the block looked as inert as printed paper, which
      // is how a preview that *is* editable reads as one that is not.
      await pumpRenderer(
        tester,
        markdown: 'Just a paragraph.\n',
        onSourceChanged: (_) {},
      );

      expect(editableCursors(), findsWidgets);
    });

    testWidgets('a read-only preview does not', (tester) async {
      // No onSourceChanged means nothing can be written back, and promising an
      // edit that cannot happen is worse than promising nothing.
      await pumpRenderer(tester, markdown: 'Just a paragraph.\n');

      expect(editableCursors(), findsNothing);
    });

    testWidgets('a task list does not', (tester) async {
      // The two blocks deliberately left out of the double-tap wrapper. A task
      // list has its own tap targets, and wrapping it put a recogniser in the
      // gesture arena that held every checkbox dead for the double-tap
      // timeout. Offering a text cursor there would advertise an edit that
      // the block does not accept.
      await pumpRenderer(
        tester,
        markdown: '- [ ] first\n- [x] second\n',
        onSourceChanged: (_) {},
      );

      expect(editableCursors(), findsNothing);
    });

    testWidgets('a diagram does not', (tester) async {
      await pumpRenderer(
        tester,
        markdown: '```mermaid\nflowchart TD\n  A --> B\n```\n',
        onSourceChanged: (_) {},
      );

      expect(editableCursors(), findsNothing);
    });
  });

  group('Editing a diagram block', () {
    const diagram = '```mermaid\nflowchart TD\n  A --> B\n```\n';

    testWidgets('a diagram offers an edit button instead of a double tap',
        (tester) async {
      // Its own recogniser claims the double tap for fullscreen, and being
      // deeper in the tree it wins the arena — so a diagram was the one block
      // the preview could not edit.
      await pumpRenderer(
        tester,
        markdown: diagram,
        onSourceChanged: (_) {},
      );

      expect(find.byKey(const Key('mermaid-edit-source')), findsOneWidget);
    });

    testWidgets('the button opens the block as markdown source at once',
        (tester) async {
      // A single pump after the tap, deliberately: the diagram used to sit
      // inside the double-tap recogniser, which held the gesture arena for the
      // double-tap timeout and left every toolbar button dead for ~300ms.
      await pumpRenderer(
        tester,
        markdown: diagram,
        onSourceChanged: (_) {},
      );

      await tester.tap(find.byKey(const Key('mermaid-edit-source')));
      await tester.pump();

      // The diagram, toolbar and all, is replaced by its source.
      expect(find.byKey(const Key('mermaid-copy-source')), findsNothing);
      expect(find.byType(TextField), findsOneWidget);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '```mermaid\nflowchart TD\n  A --> B\n```');
    });

    testWidgets('a read-only preview offers no edit button', (tester) async {
      await pumpRenderer(tester, markdown: diagram);

      expect(find.byKey(const Key('mermaid-edit-source')), findsNothing);
      // The other diagram buttons are still there.
      expect(find.byKey(const Key('mermaid-copy-source')), findsOneWidget);
    });
  });

  group('In-place block editing', () {
    testWidgets('is off when no onSourceChanged is given', (tester) async {
      await pumpRenderer(tester, markdown: '# Title\n\nBody text.\n');

      await doubleTap(tester, find.textContaining('Body text'));

      expect(
        find.byType(TextField),
        findsNothing,
        reason: 'a read-only preview must not open an editor',
      );
    });

    testWidgets('double tap opens the block as markdown source',
        (tester) async {
      await pumpRenderer(
        tester,
        markdown: '# Title\n\nBody text.\n',
        onSourceChanged: (_) {},
      );

      await doubleTap(tester, find.textContaining('Body text'));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'Body text.');
    });

    testWidgets('a heading opens with its # prefix intact', (tester) async {
      await pumpRenderer(
        tester,
        markdown: '## Some heading\n\nBody.\n',
        onSourceChanged: (_) {},
      );

      await doubleTap(tester, find.textContaining('Some heading'));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(
        field.controller!.text,
        '## Some heading',
        reason: 'editing must show the source, not the parsed content',
      );
    });

    testWidgets('committing reports the whole updated document',
        (tester) async {
      String? updated;
      await pumpRenderer(
        tester,
        markdown: '# Title\n\nOld text.\n',
        onSourceChanged: (value) => updated = value,
      );

      await doubleTap(tester, find.textContaining('Old text'));
      await tester.enterText(find.byType(TextField), 'New text.');

      // Commit happens on focus loss.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      expect(updated, '# Title\n\nNew text.\n');
    });

    testWidgets('escape discards the edit', (tester) async {
      String? updated;
      await pumpRenderer(
        tester,
        markdown: '# Title\n\nOld text.\n',
        onSourceChanged: (value) => updated = value,
      );

      await doubleTap(tester, find.textContaining('Old text'));
      await tester.enterText(find.byType(TextField), 'Discarded.');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(updated, isNull, reason: 'escape must not write anything back');
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('Code block line numbers', () {
    testWidgets('a fenced block is numbered from one', (tester) async {
      await pumpRenderer(tester, markdown: '```\nalpha\nbeta\ngamma\n```\n');

      for (final n in ['1', '2', '3']) {
        expect(find.text(n), findsWidgets, reason: '缺少行号 $n');
      }
      expect(find.text('4'), findsNothing,
          reason: '尾部换行不该多出一行号');
    });

    testWidgets('the code itself is still there', (tester) async {
      await pumpRenderer(tester, markdown: '```\nalpha\nbeta\n```\n');

      expect(find.textContaining('alpha'), findsWidgets);
      expect(find.textContaining('beta'), findsWidgets);
    });
  });

  group('Blocks a list item carries', () {
    testWidgets('a code block under a step is drawn inside the preview',
        (tester) async {
      // The parser and the exports were checked when items gained blocks of
      // their own; the preview was not.
      await pumpRenderer(
        tester,
        markdown: '1. step\n\n   ```dart\n   void main() {}\n   ```\n',
      );

      expect(find.textContaining('step'), findsWidgets);
      expect(find.textContaining('void main'), findsWidgets,
          reason: '步骤携带的代码块没有画出来');
    });

    testWidgets('a quote under a step is drawn too', (tester) async {
      await pumpRenderer(tester, markdown: '- item\n\n  > quoted\n');

      expect(find.textContaining('quoted'), findsWidgets);
    });
  });

  group('Task checkboxes', () {
    testWidgets('are disabled in a read-only preview', (tester) async {
      await pumpRenderer(tester, markdown: '- [ ] first\n- [x] second\n');

      final boxes = tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .toList();
      expect(boxes.length, 2);
      expect(boxes.every((b) => b.onChanged == null), isTrue);
    });

    testWidgets('ticking one rewrites just that line', (tester) async {
      String? updated;
      await pumpRenderer(
        tester,
        markdown: '- [ ] first\n- [ ] second\n',
        onSourceChanged: (value) => updated = value,
      );

      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pump();

      expect(updated, '- [ ] first\n- [x] second\n');
    });

    testWidgets('a continuation line does not shift the box', (tester) async {
      // The toggle counted one line per item, so the second box landed on the
      // continuation line — which has no marker on it, so ticking silently
      // did nothing.
      String? updated;
      await pumpRenderer(
        tester,
        markdown: '- [ ] first\n  and more\n- [ ] second\n',
        onSourceChanged: (value) => updated = value,
      );

      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pump();

      expect(updated, '- [ ] first\n  and more\n- [x] second\n');
    });

    testWidgets('a blank line between items does not shift it either',
        (tester) async {
      String? updated;
      await pumpRenderer(
        tester,
        markdown: '- [ ] first\n\n- [ ] second\n',
        onSourceChanged: (value) => updated = value,
      );

      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pump();

      expect(updated, '- [ ] first\n\n- [x] second\n');
    });

    testWidgets('a block carried by a step does not shift it', (tester) async {
      String? updated;
      await pumpRenderer(
        tester,
        markdown: '- [ ] first\n\n  ```sh\n  run\n  ```\n\n- [ ] second\n',
        onSourceChanged: (value) => updated = value,
      );

      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pump();

      expect(updated,
          '- [ ] first\n\n  ```sh\n  run\n  ```\n\n- [x] second\n');
    });

    testWidgets('a plain item before a task does not shift it', (tester) async {
      String? updated;
      await pumpRenderer(
        tester,
        markdown: '- plain\n- [ ] task\n',
        onSourceChanged: (value) => updated = value,
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(updated, '- plain\n- [x] task\n');
    });

    testWidgets('unticking restores the empty marker', (tester) async {
      String? updated;
      await pumpRenderer(
        tester,
        markdown: '- [x] done\n',
        onSourceChanged: (value) => updated = value,
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(updated, '- [ ] done\n');
    });
  });

  group('every kind of block can be opened in the preview', () {
    // Editing in the preview is the first thing this project was asked for,
    // and the tests above cover four block kinds. A new kind added to the
    // renderer without `_wrapEditable` would be silently uneditable — the
    // block would simply not respond to a double tap, with nothing to say
    // why. This walks all of them.
    //
    // Task lists and diagrams are deliberately absent: they carry their own
    // tap targets and are exempt on purpose, which the tests above assert.
    const blocks = <String, String>{
      '标题': '# Heading\n',
      '段落': 'A paragraph.\n',
      '无序列表': '- one\n- two\n',
      '有序列表': '1. one\n2. two\n',
      '引用': '> quoted\n',
      '代码块': '```dart\nvoid main() {}\n```\n',
      '表格': '| A | B |\n| --- | --- |\n| 1 | 2 |\n',
      '数学块': '\$\$\nx = 1\n\$\$\n',
      '分隔线': '---\n',
      'front matter': '---\ntitle: x\n---\n',
      '脚注定义': '[^a]: note\n',
      'HTML 块': '<div>raw</div>\n',
    };

    blocks.forEach((name, markdown) {
      testWidgets('$name responds to a double tap', (tester) async {
        await pumpRenderer(
          tester,
          markdown: markdown,
          onSourceChanged: (_) {},
        );
        expect(editableCursors(), findsWidgets,
            reason: '$name 没有被包成可编辑块');

        await doubleTap(tester, editableCursors().first);
        await tester.pump();

        final field = find.byType(TextField);
        expect(field, findsOneWidget, reason: '$name 双击后没有打开编辑器');
        expect(
          tester.widget<TextField>(field).controller!.text.trim(),
          markdown.trim(),
          reason: '$name 打开的不是它自己的源码',
        );
      });
    });
  });

  group('the arrows carry on into the next block', () {
    // Editing one block at a time is only usable if you can leave it without
    // reaching for the mouse. Down from the last line and up from the first
    // commit and open the neighbour; anywhere else they move the caret, so a
    // block of several lines is still navigable inside itself.
    const doc = 'first paragraph\n'
        '\n'
        'second paragraph\n'
        '\n'
        'third paragraph\n';

    /// Opens the block at [index] and returns the live editor's controller.
    Future<TextEditingController> openBlock(
      WidgetTester tester,
      int index, {
      required ValueChanged<String> onChanged,
    }) async {
      await doubleTap(tester, editableCursors().at(index));
      await tester.pump();
      return tester
          .widget<TextField>(find.byType(TextField))
          .controller!;
    }

    testWidgets('down from the last line opens the block below',
        (tester) async {
      await pumpRenderer(tester, markdown: doc, onSourceChanged: (_) {});
      final controller = await openBlock(tester, 0, onChanged: (_) {});
      expect(controller.text.trim(), 'first paragraph');

      controller.selection =
          TextSelection.collapsed(offset: controller.text.length);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text.trim(),
        'second paragraph',
        reason: '↓ 没有跳到下一个块',
      );
    });

    testWidgets('up from the first line opens the block above', (tester) async {
      await pumpRenderer(tester, markdown: doc, onSourceChanged: (_) {});
      final controller = await openBlock(tester, 1, onChanged: (_) {});
      expect(controller.text.trim(), 'second paragraph');

      controller.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text.trim(),
        'first paragraph',
        reason: '↑ 没有跳到上一个块',
      );
    });

    testWidgets('up from the very first block stays where it is',
        (tester) async {
      await pumpRenderer(tester, markdown: doc, onSourceChanged: (_) {});
      final controller = await openBlock(tester, 0, onChanged: (_) {});
      controller.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text.trim(),
        'first paragraph',
        reason: '文档第一个块上面没有东西，不该跳走',
      );
    });

    testWidgets('inside a block of several lines the arrows still move the '
        'caret', (tester) async {
      const multi = '```\nline one\nline two\n```\n\nafter\n';
      await pumpRenderer(tester, markdown: multi, onSourceChanged: (_) {});
      final controller = await openBlock(tester, 0, onChanged: (_) {});
      expect(controller.text.trim(), '```\nline one\nline two\n```');

      // Caret on the first line: down must stay inside this block, which
      // means the handler declines the key and Flutter moves the caret.
      controller.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.pump();

      // Flutter's own vertical caret action throws inside a widget test —
      // `_ContextActionToActionAdapter<DirectionalCaretMovementIntent> is not
      // a subtype of Action<ExtendSelectionVerticallyToAdjacentLineIntent>`.
      // That is the framework handling the key, which is exactly what this
      // test wants to see happen; taking the exception is what lets the
      // assertion below run. It is not this editor's error, and the app does
      // not hit it.
      tester.takeException();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text.trim(),
        '```\nline one\nline two\n```',
        reason: '块中间按 ↓ 不该离开这个块',
      );
    });
  });
}
