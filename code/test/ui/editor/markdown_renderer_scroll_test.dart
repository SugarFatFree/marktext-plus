import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

void main() {
  late Directory configDir;

  setUp(() {
    // createTempSync, not the async form: testWidgets runs inside a FakeAsync
    // zone where a dart:io future never completes.
    configDir = Directory.systemTemp.createTempSync('renderer_scroll_test');
  });

  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  ProviderContainer makeContainer() {
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
    return container;
  }

  Future<void> pumpRenderer(
    WidgetTester tester,
    ProviderContainer container,
    String markdown,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: MarkdownRenderer(markdown: markdown)),
        ),
      ),
    );
    // Not pumpAndSettle: progressive rendering schedules further frames, so
    // the tree never goes quiet on its own.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  const document = '''
# First

Body of the first section.

## Second

Body of the second section, on line seven.
''';

  testWidgets('a target requested before the preview exists is honoured', (
    tester,
  ) async {
    final container = makeContainer();
    container.read(editorProvider.notifier).scrollToLine(5);

    await pumpRenderer(tester, container, document);

    // The target is only cleared inside the handler, so a null here is the
    // evidence the pending request was acted on.
    expect(container.read(editorProvider).targetScrollLine, isNull);
  });

  testWidgets('an ordinary line falls back to the heading above it', (
    tester,
  ) async {
    // Only headings carry a key, so line 7 — plain prose — has none of its
    // own. Handling it at all is the point: it used to do nothing.
    final container = makeContainer();
    await pumpRenderer(tester, container, document);

    container.read(editorProvider.notifier).scrollToLine(7);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(container.read(editorProvider).targetScrollLine, isNull);
  });

  testWidgets('a line before every heading clears the target too', (
    tester,
  ) async {
    final container = makeContainer();
    await pumpRenderer(tester, container, '\n\n# Only heading\n');

    container.read(editorProvider.notifier).scrollToLine(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(container.read(editorProvider).targetScrollLine, isNull);
  });
}
