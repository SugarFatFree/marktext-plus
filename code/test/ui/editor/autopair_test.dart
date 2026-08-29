import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// Auto-pairing, and the three switches that govern it.
///
/// The behaviours are upstream MarkText's, taken from its own end-to-end test
/// `options/autopair.spec.ts`: each switch pairs its own characters, all three
/// off means nothing pairs, and typing a pair character over a selection wraps
/// the selection rather than replacing it.
///
/// When a switch is off the editor does not handle the key at all and the
/// framework inserts the character itself — which a widget test does not
/// simulate. "Off" therefore reads here as "the text was left alone", which is
/// exactly what the editor is responsible for.
void main() {
  late Directory configDir;
  var tabCounter = 0;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('autopair');
    tabCounter = 0;
  });
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  /// Types [character] into a fresh editor built with [config], starting from
  /// [initial] and with [selection] in place, and returns the resulting text.
  Future<String> type(
    WidgetTester tester,
    String character, {
    required AppConfig config,
    String initial = '',
    TextSelection? selection,
  }) async {
    final container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: configDir.path),
          config,
        ),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            // A fresh tab id each time: the editor keeps a controller per
            // tab, so reusing one would carry the previous test's text over.
            body: SourceEditor(
              tabId: 'tab-${tabCounter++}',
              initialContent: initial,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(TextField));
    await tester.pump();

    final controller =
        tester.widget<TextField>(find.byType(TextField)).controller!;
    // Set explicitly rather than trusting `initialContent`: pumping the same
    // widget type at the same position updates the existing State, so the
    // controller — and its text — survives from the previous call.
    controller.value = TextEditingValue(
      text: initial,
      selection: selection ??
          TextSelection.collapsed(offset: initial.length),
    );
    await tester.pump();

    await simulateKeyDownEvent(LogicalKeyboardKey.keyA, character: character);
    await simulateKeyUpEvent(LogicalKeyboardKey.keyA);
    await tester.pump();
    return controller.text;
  }

  AppConfig config({bool bracket = true, bool quote = true, bool md = true}) =>
      AppConfig()
        ..autoPairBracket = bracket
        ..autoPairQuote = quote
        ..autoPairMarkdownSyntax = md;

  testWidgets('each switch pairs its own characters', (tester) async {
    expect(await type(tester, '(', config: config()), '()');
    expect(await type(tester, '"', config: config()), '""');
    expect(await type(tester, '*', config: config()), '**');
  });

  testWidgets('a switch that is off leaves its character to the framework',
      (tester) async {
    expect(await type(tester, '(', config: config(bracket: false)), '');
    expect(await type(tester, '"', config: config(quote: false)), '');
    expect(await type(tester, '*', config: config(md: false)), '');
  });

  testWidgets('one switch off does not turn the others off', (tester) async {
    // Three independent settings; sharing one would be invisible until
    // someone turned exactly one of them off.
    final noBrackets = config(bracket: false);
    expect(await type(tester, '"', config: noBrackets), '""');
    expect(await type(tester, '*', config: noBrackets), '**');
  });

  testWidgets('all three off means nothing is paired', (tester) async {
    final none = config(bracket: false, quote: false, md: false);
    for (final character in ['(', '"', '*']) {
      expect(await type(tester, character, config: none), '',
          reason: character);
    }
  });

  testWidgets('typing a pair character over a selection wraps it',
      (tester) async {
    expect(
      await type(tester, '(',
          config: config(),
          initial: 'hello',
          selection: const TextSelection(baseOffset: 0, extentOffset: 5)),
      '(hello)',
      reason: '选中的文字被替换掉了，而不是被包起来',
    );
    expect(
      await type(tester, '*',
          config: config(),
          initial: '重点',
          selection: const TextSelection(baseOffset: 0, extentOffset: 2)),
      '*重点*',
    );
  });
}
