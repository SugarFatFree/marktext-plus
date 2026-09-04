import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/bottom_room.dart';
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

  testWidgets('the text fills the pane, minus the room under the last line', (
    tester,
  ) async {
    await pump(
      tester,
      List.generate(400, (i) => 'line ${i + 1}').join('\n'),
      const Size(1000, 900),
    );

    final field = fieldHeight(tester);
    final editable = editableHeight(tester);
    // The room under the last line is deliberate and shared with the preview,
    // so the text area is shorter than the pane by exactly that much. What
    // would be a fault is the text occupying a strip at the top with the rest
    // dead white — the earlier version of this measured 40%.
    final room = bottomRoom(900);
    expect(
      editable,
      greaterThan(field - room - 32),
      reason: '正文区 ${editable.toStringAsFixed(0)} / ${field.toStringAsFixed(0)}，'
          '留白应当只有 ${room.toStringAsFixed(0)}',
    );
    expect(editable, greaterThan(field * 0.6));
  });

  testWidgets('the end of the document can be scrolled up to eye level', (
    tester,
  ) async {
    // What the room is for. Without it the last line sits pinned to the bottom
    // edge and cannot be brought anywhere more comfortable to read.
    await pump(
      tester,
      List.generate(400, (i) => 'line ${i + 1}').join('\n'),
      const Size(1000, 900),
    );

    final scrollable = tester
        .widget<TextField>(find.byType(TextField).first)
        .scrollController!;
    final content = editableHeight(tester);
    expect(
      scrollable.position.maxScrollExtent,
      greaterThan(content - 900 + bottomRoom(900) - 32),
      reason: '可滚动的范围要把最后一行送到视线高度',
    );
  });

  testWidgets('a taller window gives more text, not only more blank', (
    tester,
  ) async {
    final document = List.generate(400, (i) => 'line ${i + 1}').join('\n');

    await pump(tester, document, const Size(1000, 600));
    final shortWindow = editableHeight(tester);

    await pump(tester, document, const Size(1000, 1200));
    final tallWindow = editableHeight(tester);

    final gained = tallWindow - shortWindow;
    // 600 more pixels of window, a quarter of which goes to the room under the
    // last line — so most of it, not all of it, becomes text.
    expect(
      gained,
      greaterThan(600 * 0.6),
      reason: '窗口高了 600 像素，能看到的正文只多了 ${gained.toStringAsFixed(0)} 像素',
    );
  });
}
