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

  testWidgets('the text is drawn down the whole pane, not a strip at the top', (
    tester,
  ) async {
    await pump(
      tester,
      List.generate(400, (i) => 'line ${i + 1}').join('\n'),
      const Size(1000, 900),
    );

    final field = fieldHeight(tester);
    final editable = editableHeight(tester);
    // The room under the last line belongs *after* the last line, inside what
    // scrolls — not taken off the pane, where it is dead white at the bottom
    // of the window whatever the reader scrolls to. An InputDecoration's
    // bottom padding does the second thing: it lengthens what can be scrolled
    // and shrinks the visible box by the same amount.
    expect(
      editable,
      greaterThan(field * 0.95),
      reason: '正文区 ${editable.toStringAsFixed(0)} / ${field.toStringAsFixed(0)}，'
          '窗格底部不该有一块永远空着的白',
    );
  });

  testWidgets('the pane scrolls the whole pane, not a shortened one', (
    tester,
  ) async {
    // The measurement that found this: the source pane's viewport was 659 of
    // 900 pixels while the preview's was the full 900, so the two panes could
    // not line up however carefully the room was matched.
    await pump(
      tester,
      List.generate(400, (i) => 'line ${i + 1}').join('\n'),
      const Size(1000, 900),
    );
    final controller = tester
        .widget<TextField>(find.byType(TextField).first)
        .scrollController;
    final viewport = controller?.position.viewportDimension ??
        tester
            .widget<SingleChildScrollView>(
              find.byType(SingleChildScrollView).first,
            )
            .controller!
            .position
            .viewportDimension;
    expect(
      viewport,
      greaterThan(860),
      reason: '可视区只有 ${viewport.toStringAsFixed(0)} 像素，窗格有 900',
    );
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

    final scroll = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first)
        .controller!;
    final text = editableHeight(tester);
    // Everything below the text, once it is scrolled as far as it goes: the
    // room, and nothing else.
    final beyond = scroll.position.maxScrollExtent +
        scroll.position.viewportDimension -
        text;
    expect(
      beyond,
      greaterThan(bottomRoom(900) * 0.8),
      reason: '最后一行下面只有 ${beyond.toStringAsFixed(0)} 像素，'
          '不够把它滚到视线高度',
    );
  });

  testWidgets('the room is under the text, not taken off the pane', (
    tester,
  ) async {
    // A short document: the text stops well before the bottom, and there is
    // nothing to scroll. What must not happen is the pane reserving the room
    // anyway — that is white space at the bottom of the window, always.
    await pump(tester, 'one line', const Size(1000, 900));
    final scroll = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first)
        .controller!;
    expect(
      scroll.position.viewportDimension,
      greaterThan(860),
      reason: '可视区 ${scroll.position.viewportDimension.toStringAsFixed(0)}，'
          '窗格 900：留白不该从窗格里扣',
    );
  });

  testWidgets('a taller window gives more text, not only more blank', (
    tester,
  ) async {
    final document = List.generate(400, (i) => 'line ${i + 1}').join('\n');

    await pump(tester, document, const Size(1000, 600));
    final shortWindow = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first)
        .controller!
        .position
        .viewportDimension;

    await pump(tester, document, const Size(1000, 1200));
    final tallWindow = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first)
        .controller!
        .position
        .viewportDimension;

    // All of it, now: the room is under the text rather than subtracted from
    // the pane, so a taller window is a taller view of the document.
    expect(
      tallWindow - shortWindow,
      greaterThan(600 * 0.9),
      reason: '窗口高了 600 像素，可视区只多了 '
          '${(tallWindow - shortWindow).toStringAsFixed(0)} 像素',
    );
  });
}
