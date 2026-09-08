import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

/// Turning inline HTML on reaches the preview without waiting for a keystroke.
///
/// The preview keeps the parsed document against the text it parsed. Inline
/// HTML is the one setting that changes how the same text is read, so the
/// cached parse has to be dropped when it changes — the code does that, and
/// the comment beside it records what happened before it did: "the preview
/// kept the old rendering until the next keystroke."
///
/// Nothing was holding it. Commenting out that one line left the whole suite
/// green, which is how a fix with no guard goes back the way it came.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('html_setting'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  testWidgets('turning inline HTML on re-reads the document', (tester) async {
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: root.path),
            AppConfig(enableHtml: false),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    // `<kbd>` is read as text with the setting off and as markup with it on,
    // so the same source says which way it was parsed.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: MarkdownRenderer(markdown: 'press <kbd>Esc</kbd> to stop\n'),
          ),
        ),
      ),
    );
    // Pumped a fixed number of times rather than settled: the preview fills
    // itself in batches from post-frame callbacks, so it never goes quiet.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    String drawn() => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.textSpan?.toPlainText() ?? t.data ?? '')
        .where((s) => s.contains('Esc'))
        .join('\n');

    expect(
      drawn(),
      contains('<kbd>'),
      reason: '起点就不对的话，后面测的是别的东西',
    );

    // Not awaited: the state changes synchronously and the await is the disk
    // write, which never completes inside the FakeAsync zone a widget test
    // runs in.
    unawaited(
      container
          .read(settingsProvider.notifier)
          .updateConfig((c) => c.copyWith(enableHtml: true)),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(
      drawn(),
      isNot(contains('<kbd>')),
      reason: '在设置里打开了行内 HTML，预览还在按旧的读法画，'
          '要等下一次敲键才更新',
    );
    expect(drawn(), contains('Esc'), reason: '文字本身不该消失');
  });
}
