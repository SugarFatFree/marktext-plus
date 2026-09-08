import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

/// A document that is still being parsed must not present itself as drawn.
///
/// A document over 1500 lines is parsed twice: a prefix so the top is on
/// screen, then the whole of it. Two things in the preview say "that is all of
/// it" — the spinner going away, and the place to click below the text to keep
/// writing appearing. Both were decided by comparing against the length of the
/// node list that exists *now*, which while only the prefix is parsed is the
/// prefix. So for a large document both fired early, at the end of the first
/// sixth of it, with the rest still coming.
///
/// Sibling of the same mistake in the cost log, which reported the prefix's
/// block count as the document's (BUG-361).
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('preview_unfinished'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  /// 800 paragraphs is 1599 lines, over `safePrefix`'s 1500; the prefix stops
  /// at the blank line after the 750th.
  const twoPassDocument = 800;

  Future<void> draw(
    WidgetTester tester, {
    required int paragraphs,
    bool editable = false,
  }) async {
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
          home: Scaffold(
            body: MarkdownRenderer(
              markdown: List.generate(
                paragraphs,
                (i) => 'Paragraph $i.',
              ).join('\n\n'),
              onSourceChanged: editable ? (_) {} : null,
            ),
          ),
        ),
      ),
    );
    // Pumped rather than settled: the fill runs from post-frame callbacks and
    // never goes quiet on its own.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('the spinner stays while the rest of the document is coming', (
    tester,
  ) async {
    await draw(tester, paragraphs: twoPassDocument);

    expect(
      find.byType(CircularProgressIndicator),
      findsOneWidget,
      reason: '前缀画完不是文档画完，此时收起指示器就是说画完了',
    );
  });

  testWidgets('a document parsed in one go does take the spinner away', (
    tester,
  ) async {
    // The other half: a preview that never stopped spinning would pass the
    // test above. 300 paragraphs is under the 1500 lines, so it is parsed
    // whole and there is genuinely nothing left to wait for.
    await draw(tester, paragraphs: 300);

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('nowhere to append until the end of the document is known', (
    tester,
  ) async {
    await draw(tester, paragraphs: twoPassDocument, editable: true);

    // The append target is the only opaque full-width gesture detector the
    // preview adds; blocks get their own editable wrappers instead.
    final targets = find.byWidgetPredicate(
      (w) => w is GestureDetector && w.behavior == HitTestBehavior.opaque,
    );
    expect(
      targets,
      findsNothing,
      reason: '落点画在前缀末尾，就是把文档的中间当成了末尾',
    );
  });
}
