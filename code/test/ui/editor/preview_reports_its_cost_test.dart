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
}
