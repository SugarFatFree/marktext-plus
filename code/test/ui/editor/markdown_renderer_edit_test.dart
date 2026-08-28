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
}
