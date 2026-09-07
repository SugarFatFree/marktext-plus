import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/markdown_renderer.dart';

/// Changing the code font reaches the preview.
///
/// The preview caches each block it has drawn and reuses it until a signature
/// changes. The code font settings were not in that signature, so setting the
/// size to 24 left the code at 14 — the widget rebuilt, the block came back
/// from the cache, and the style that would have read the new value was never
/// asked for.
///
/// The guard in `block_cache_signature_test` checks the list. This checks the
/// thing the list is for, because a list can be right and the mechanism still
/// broken.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('code_font'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  testWidgets('a new code font size is drawn', (tester) async {
    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: root.path),
          AppConfig(codeFontSize: 14),
        ),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: MarkdownRenderer(markdown: '```dart\nvoid main() {}\n```\n'),
        ),
      ),
    ));
    // Pumped a fixed number of times rather than settled: the preview fills
    // itself in batches from post-frame callbacks, so it never goes quiet.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    double? drawnCodeSize() {
      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        final span = text.textSpan;
        if (span is! TextSpan) continue;
        if (!span.toPlainText().contains('void main')) continue;
        if (span.style?.fontSize != null) return span.style!.fontSize;
        for (final child in span.children ?? const <InlineSpan>[]) {
          if (child is TextSpan && child.style?.fontSize != null) {
            return child.style!.fontSize;
          }
        }
      }
      return null;
    }

    expect(drawnCodeSize(), 14, reason: '起点就不对的话，后面测的是别的东西');

    // Not awaited: the state changes synchronously and the await is the disk
    // write, which never completes inside the FakeAsync zone a widget test
    // runs in.
    unawaited(container
        .read(settingsProvider.notifier)
        .updateConfig((c) => c.copyWith(codeFontSize: 24)));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(drawnCodeSize(), 24,
        reason: '在设置里改了代码字号，预览里的代码块必须跟着变');
  });
}
