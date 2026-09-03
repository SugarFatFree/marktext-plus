import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// The source editor shows text down the whole pane it was given.
///
/// Room under the last line — so it can be scrolled up to where the eye is
/// rather than staying pinned to the bottom edge — was implemented as bottom
/// `contentPadding` on the text field. Padding inside a decoration does not
/// extend what can be scrolled; it shrinks the area the text is drawn in. At
/// 60% of the pane height that left the text in a strip across the top, the
/// rest of the window blank, and only that strip scrolling.
void main() {
  late Directory configDir;

  setUp(() => configDir =
      Directory.systemTemp.createTempSync('source_editor_viewport'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<void> pump(WidgetTester tester, String content, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: configDir.path),
          AppConfig(),
        ),
      ),
    ]);
    addTearDown(container.dispose);

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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// The height of the area text is actually drawn in.
  double editableHeight(WidgetTester tester) {
    final editable = tester.renderObject<RenderBox>(
      find.byType(EditableText).first,
    );
    return editable.size.height;
  }

  double fieldHeight(WidgetTester tester) =>
      tester.renderObject<RenderBox>(find.byType(TextField).first).size.height;

  testWidgets('text is drawn down the whole pane, not a strip at the top',
      (tester) async {
    await pump(
      tester,
      List.generate(400, (i) => 'line ${i + 1}').join('\n'),
      const Size(1000, 900),
    );

    final field = fieldHeight(tester);
    final editable = editableHeight(tester);

    expect(
      editable,
      greaterThan(field * 0.9),
      reason: '正文区只有 ${editable.toStringAsFixed(0)} / ${field.toStringAsFixed(0)} '
          '像素高，剩下的是死白',
    );
  });

  testWidgets('a taller window gives more text, not more blank',
      (tester) async {
    final document = List.generate(400, (i) => 'line ${i + 1}').join('\n');

    await pump(tester, document, const Size(1000, 600));
    final shortWindow = editableHeight(tester);

    await pump(tester, document, const Size(1000, 1200));
    final tallWindow = editableHeight(tester);

    expect(tallWindow - shortWindow, greaterThan(500),
        reason: '窗口高了 600 像素，能看到的正文只多了 '
            '${(tallWindow - shortWindow).toStringAsFixed(0)} 像素');
  });
}
