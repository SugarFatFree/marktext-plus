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
  Future<TextEditingValue> typeValue(
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
    return controller.value;
  }

  /// The resulting text alone, for the cases where the caret does not matter.
  Future<String> type(
    WidgetTester tester,
    String character, {
    required AppConfig config,
    String initial = '',
    TextSelection? selection,
  }) async =>
      (await typeValue(tester, character,
              config: config, initial: initial, selection: selection))
          .text;

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

  group('a closing bracket types over the one already there', () {
    // Upstream's `shouldRemoveClosingChar` lists `[}\])]` alongside the
    // quotes: when the character being typed is the one already sitting after
    // the caret, the new one is dropped and the caret steps past it. Without
    // that, finishing `(x` by typing `)` — which is what a person does, the
    // auto-inserted bracket being invisible to the fingers — leaves `(x))`.
    //
    // The caret is asserted, not just the text. An unhandled key inserts
    // nothing in a widget test, so the text alone cannot tell "stepped over"
    // apart from "the editor ignored it" — both leave `(x)`.
    for (final pair in [('(', ')'), ('[', ']'), ('{', '}')]) {
      testWidgets('${pair.$2} is stepped over, not doubled', (tester) async {
        final result = await typeValue(tester, pair.$2,
            config: config(),
            initial: '${pair.$1}x${pair.$2}',
            selection: const TextSelection.collapsed(offset: 2));
        expect(result.text, '${pair.$1}x${pair.$2}',
            reason: '多出了一个 ${pair.$2}');
        expect(result.selection.baseOffset, 3,
            reason: '光标没有跨过去，说明这个键根本没被处理');
      });
    }

    testWidgets('a closing bracket elsewhere is left to the framework',
        (tester) async {
      // Only the character immediately after the caret is stepped over. A `)`
      // typed anywhere else is an ordinary character: the editor must report
      // the key unhandled and leave the caret alone, so the framework inserts
      // it as usual.
      final result = await typeValue(tester, ')', config: config(),
          initial: 'ab');
      expect(result.text, 'ab');
      expect(result.selection.baseOffset, 2, reason: '光标不该动');
    });

    testWidgets('the switch governs it: off means an ordinary character',
        (tester) async {
      final result = await typeValue(tester, ')',
          config: config(bracket: false),
          initial: '(x)',
          selection: const TextSelection.collapsed(offset: 2));
      expect(result.text, '(x)');
      expect(result.selection.baseOffset, 2,
          reason: '开关关掉后仍然跨过去了');
    });
  });

  group('pairing only where a closing character would not be in the way', () {
    // Upstream: "Only pair quotes/brackets when the cursor is at end-of-line
    // or before whitespace. Inserting `\"foo` would otherwise become `\"\"foo`
    // and force the user to immediately delete the spurious closing char."
    testWidgets('no closing character is added right before a word',
        (tester) async {
      expect(
        await type(tester, '(',
            config: config(),
            initial: 'foo',
            selection: const TextSelection.collapsed(offset: 0)),
        'foo',
        reason: '光标紧贴文字时不该配对，应交回框架只插入一个字符',
      );
    });

    testWidgets('before whitespace it still pairs', (tester) async {
      expect(
        await type(tester, '(',
            config: config(),
            initial: ' foo',
            selection: const TextSelection.collapsed(offset: 0)),
        '() foo',
      );
    });

    testWidgets('at the end of the text it still pairs', (tester) async {
      expect(
        await type(tester, '(',
            config: config(),
            initial: 'foo',
            selection: const TextSelection.collapsed(offset: 3)),
        'foo()',
      );
    });

    testWidgets('before a closing bracket it still pairs', (tester) async {
      // `(|)` — the caret between an existing pair — is not "touching a word",
      // and typing `(` there is how a nested call gets written.
      expect(
        await type(tester, '(',
            config: config(),
            initial: '()',
            selection: const TextSelection.collapsed(offset: 1)),
        '(())',
      );
    });

    testWidgets('wrapping a selection is unaffected by what follows it',
        (tester) async {
      // The rule is about a lone closing character getting in the way. When
      // there is a selection there is no lone character — both ends are being
      // written — so `hello` selected inside `hello world` still wraps.
      expect(
        await type(tester, '(',
            config: config(),
            initial: 'hello world',
            selection: const TextSelection(baseOffset: 0, extentOffset: 5)),
        '(hello) world',
      );
    });
  });
}
