import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

void main() {
  late Directory configDir;

  setUp(() {
    // createTempSync, not the async form: testWidgets runs inside a FakeAsync
    // zone where a dart:io future never completes.
    configDir = Directory.systemTemp.createTempSync('source_editor_scroll');
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

  Future<void> pumpEditor(
    WidgetTester tester,
    ProviderContainer container,
    String content,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SourceEditor(tabId: 'tab', initialContent: content),
          ),
        ),
      ),
    );
    // The editor registers its scroll listener in a post-frame callback.
    await tester.pump();
    // Run out the scroll animation so the test does not end with it pending.
    await tester.pump(const Duration(milliseconds: 600));
  }

  final longDocument = List.generate(200, (i) => 'line ${i + 1}').join('\n');

  testWidgets('a scroll target requested before the editor exists is honoured', (
    tester,
  ) async {
    // This is the search panel's case: it opens a file and asks for the
    // matching line in the same breath, so the request lands before the editor
    // for that file has been built and its listener never sees it change.
    final container = makeContainer();
    container.read(editorProvider.notifier).scrollToLine(120);

    await pumpEditor(tester, container, longDocument);

    // The target is only cleared inside the handler, so a null here is the
    // evidence that the pending request was acted on.
    expect(container.read(editorProvider).targetScrollLine, isNull);
  });

  testWidgets('a scroll target requested afterwards is still honoured', (
    tester,
  ) async {
    final container = makeContainer();
    await pumpEditor(tester, container, longDocument);

    container.read(editorProvider.notifier).scrollToLine(80);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(container.read(editorProvider).targetScrollLine, isNull);
  });

  testWidgets('no pending target leaves the editor alone', (tester) async {
    final container = makeContainer();
    await pumpEditor(tester, container, longDocument);

    expect(container.read(editorProvider).targetScrollLine, isNull);
    expect(find.byType(SourceEditor), findsOneWidget);
  });
}
