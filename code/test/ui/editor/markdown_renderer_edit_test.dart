import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
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
  Future<void> doubleTap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(finder);
    await tester.pump();
  }

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
