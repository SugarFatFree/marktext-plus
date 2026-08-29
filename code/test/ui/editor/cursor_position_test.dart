import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';
import 'dart:io';

/// Where the caret is, and what it costs to find out.
///
/// The readout used to be computed as `text.substring(0, offset).split('\n')`
/// — a copy of everything before the caret and a list of one string per line,
/// to read two numbers off it. On a five megabyte document that is 61 ms on
/// every cursor move, with the gutter's own newline count adding 33 ms more.
/// A line-start index built once per edit answers both in well under a
/// microsecond.
void main() {
  late Directory configDir;

  setUp(() =>
      configDir = Directory.systemTemp.createTempSync('cursor_position'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<ProviderContainer> pump(WidgetTester tester, String text) async {
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
          home: Scaffold(body: SourceEditor(tabId: 'tab', initialContent: text)),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  Future<void> caretAt(WidgetTester tester, int offset) async {
    final field = tester.widget<TextField>(find.byType(TextField));
    field.controller!.selection = TextSelection.collapsed(offset: offset);
    await tester.pump();
  }

  testWidgets('the first character is line 0, column 0', (tester) async {
    final container = await pump(tester, 'alpha\nbeta\ngamma\n');
    await caretAt(tester, 0);
    expect(container.read(editorProvider).cursorLine, 0);
    expect(container.read(editorProvider).cursorCol, 0);
  });

  testWidgets('a caret in the middle of the third line reads as such',
      (tester) async {
    const text = 'alpha\nbeta\ngamma\n';
    final container = await pump(tester, text);
    await caretAt(tester, text.indexOf('gamma') + 3);
    expect(container.read(editorProvider).cursorLine, 2);
    expect(container.read(editorProvider).cursorCol, 3);
  });

  testWidgets('a caret just after a newline is at the start of the next line',
      (tester) async {
    const text = 'alpha\nbeta\n';
    final container = await pump(tester, text);
    await caretAt(tester, 6);
    expect(container.read(editorProvider).cursorLine, 1);
    expect(container.read(editorProvider).cursorCol, 0);
  });

  testWidgets('the very end of a document ending in a newline is its own line',
      (tester) async {
    const text = 'alpha\nbeta\n';
    final container = await pump(tester, text);
    await caretAt(tester, text.length);
    expect(container.read(editorProvider).cursorLine, 2);
    expect(container.read(editorProvider).cursorCol, 0);
  });

  testWidgets('the readout agrees with the obvious way of computing it',
      (tester) async {
    // The index is the fast way; this is the slow, plainly-correct way it
    // replaced. They must agree at every offset, including the awkward ones.
    const text = 'one\n\nthree\nfour\n\n';
    final container = await pump(tester, text);
    for (var offset = 0; offset <= text.length; offset++) {
      await caretAt(tester, offset);
      final lines = text.substring(0, offset).split('\n');
      expect(container.read(editorProvider).cursorLine, lines.length - 1,
          reason: 'offset $offset 的行号');
      expect(container.read(editorProvider).cursorCol, lines.last.length,
          reason: 'offset $offset 的列号');
    }
  });
}
