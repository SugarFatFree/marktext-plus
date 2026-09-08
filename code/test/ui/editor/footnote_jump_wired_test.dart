import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/services/markdown_parser.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

/// Tapping the marker asks the editor to go to the note.
///
/// `lineForFootnote` being right is not the same as it being reached. This
/// repository has had a run of things written and never called, and the
/// marker's own history is exactly that: drawn to look clickable, wired to
/// nothing.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('footnote_jump'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  Future<ProviderContainer> show(WidgetTester tester, String markdown) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) =>
              SettingsNotifier(ConfigService(configDir: root.path), AppConfig()),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: MarkdownRenderer(markdown: markdown)),
        ),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    return container;
  }

  testWidgets('tapping a marker asks to scroll to its note', (tester) async {
    final container = await show(tester, '''
# Notes

A claim[^1].

Text.

[^1]: The source.
''');

    // Watched rather than read afterwards: the preview listens for this and
    // clears it once it has scrolled, so by the time a test looks the request
    // is gone. What matters is that one was made.
    final asked = <int?>[];
    container.listen(
      editorProvider.select((s) => s.targetScrollLine),
      (_, next) => asked.add(next),
    );

    expect(
      MarkdownParser.lineForFootnote('''
# Notes

A claim[^1].

Text.

[^1]: The source.
''', '1'),
      7,
      reason: '纯函数先得对，否则下面点了也没用',
    );

    // Tapped through the detector rather than the text: the marker is drawn
    // inside a `WidgetSpan`, and a tap aimed at the `Text` lands on the
    // paragraph that contains it. The definition at the bottom draws its own
    // marker too, so this is the first of them.
    final markers = find.byKey(MarkdownRenderer.footnoteMarkerKey('1'));
    expect(markers, findsWidgets, reason: '脚注标记没有可点的部分');

    // Called rather than tapped. The marker is a `WidgetSpan` a few
    // characters wide inside a paragraph, and hit-testing one from a test is
    // a fight with layout that proves nothing about the wiring — which is
    // what this is here to prove.
    final detector = tester.widget<GestureDetector>(markers.first);
    expect(detector.onTap, isNotNull, reason: '这个标记根本没接 onTap');
    detector.onTap!();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(
      asked,
      contains(7),
      reason: '点了脚注标记，该被要求滚到定义那一行（从 1 数起）；'
          '实际请求过：$asked',
    );
  });

  testWidgets('a marker whose note is not written asks for nothing', (
    tester,
  ) async {
    // Writing the marker first is how footnotes get written. Scrolling
    // somewhere arbitrary, or saying something, would both be worse than
    // staying put.
    final container = await show(tester, 'A claim[^later].\n');

    final asked = <int?>[];
    container.listen(
      editorProvider.select((s) => s.targetScrollLine),
      (_, next) => asked.add(next),
    );

    tester
        .widget<GestureDetector>(
          find.byKey(MarkdownRenderer.footnoteMarkerKey('later')),
        )
        .onTap!();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(asked.whereType<int>(), isEmpty, reason: '不该请求滚到任何地方');
  });
}
