import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/services/app_log.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

/// How long a document took to draw is a thing that can be asked.
///
/// "Loads fast, handles large files" is the first claim this editor makes,
/// and nothing recorded whether it held. Trying to time it from outside — over
/// the automation interface, on a real machine — does not work: the preview
/// fills in across frames, so a question lands in whichever frame it lands in.
/// Measured that way, 30 000 characters took three seconds and 111 000 took a
/// quarter of one, on the same machine seconds apart. Both numbers were the
/// wait for a frame boundary, not the cost of the document.
void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('preview_cost');
    AppLog.instance.clear();
  });
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  Future<void> draw(WidgetTester tester, String markdown) async {
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
    // Pumped rather than settled: the fill runs from post-frame callbacks, so
    // this never goes quiet on its own. Enough frames for the doubling to
    // cover any document this test builds.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  List<String> costLines() => AppLog.instance
      .recent(source: 'preview')
      .map((line) => line.message)
      .where((message) => message.contains('drew'))
      .toList();

  testWidgets('a document that needed filling says what it cost', (
    tester,
  ) async {
    // Over the initial batch of 50, so the progressive fill runs.
    await draw(tester, List.generate(300, (i) => 'Paragraph $i.').join('\n\n'));

    expect(costLines(), hasLength(1), reason: '画完了该留下一条，供事后查');
    expect(
      costLines().single,
      contains('300 blocks'),
      reason: '只说耗时不说规模，两次测量之间没法比',
    );
    expect(
      costLines().single,
      matches(RegExp(r'in \d+ ms')),
      reason: '要说清用了多久',
    );
  });

  testWidgets('a document drawn in one go says nothing', (tester) async {
    // Under the initial batch: there was no fill to time, and a line saying
    // "0 ms" for every short document is noise in the log a plugin shares.
    await draw(tester, List.generate(5, (i) => 'Paragraph $i.').join('\n\n'));

    expect(costLines(), isEmpty);
  });

  testWidgets('it is said once, not once a frame', (tester) async {
    await draw(tester, List.generate(300, (i) => 'Paragraph $i.').join('\n\n'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(costLines(), hasLength(1));
  });

  testWidgets('a document parsed in two goes does not report the first go', (
    tester,
  ) async {
    // Over `safePrefix`'s 1500 lines, so the document is parsed as a prefix
    // first and the whole of it after — the shape every document this
    // measurement exists for has. 800 paragraphs is 1599 lines; the prefix
    // stops at the blank line after the 750th.
    const paragraphs = 800;
    await draw(
      tester,
      List.generate(paragraphs, (i) => 'Paragraph $i.').join('\n\n'),
    );

    // Whatever it says, it must not present the prefix as the document. The
    // fill reaching the end of the prefix is not the document being drawn:
    // the other half is still on its way, and the reader of this line has no
    // way to tell the two apart.
    for (final line in costLines()) {
      expect(
        line,
        contains('$paragraphs blocks'),
        reason: '这条日志自称是整篇的耗时，报前缀的块数就是在说假话',
      );
    }
  });

  testWidgets('and it does report, once the whole document arrives', (
    tester,
  ) async {
    // The other half of the test above. Without this one, a preview that said
    // nothing at all about large documents would pass — which is the same
    // hole as reporting the prefix: the reader learns nothing either way.
    //
    // `runAsync` because the second parse runs on another isolate, and the
    // test's clock does not drive one.
    const paragraphs = 800;
    await draw(
      tester,
      List.generate(paragraphs, (i) => 'Paragraph $i.').join('\n\n'),
    );
    expect(costLines(), isEmpty, reason: '整篇还没到，此时不该有话说');

    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(costLines(), hasLength(1), reason: '整篇画完了要留下一条');
    expect(
      costLines().single,
      contains('$paragraphs blocks'),
      reason: '报的要是整篇的规模',
    );
  });
}
