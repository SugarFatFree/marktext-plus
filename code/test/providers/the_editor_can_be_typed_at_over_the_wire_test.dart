import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/mcp_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:marktext_plus/services/mcp_tools.dart';

/// Formatting, stepping history, and the clipboard, over the wire.
///
/// These three exist to close the gap between what the test plan asks and what
/// a machine can do. The plan's remaining checks were "press Ctrl+B twice then
/// Ctrl+Z", "copy a heading and a list out of a browser and use Edit ▸ Paste",
/// and "undo it" — all of them the editor's own paths, none of them reachable
/// from outside.
///
/// The refusals are the part worth testing. `applyFormat` only records a
/// request; a pane picks it up on its next frame. Answering "ran bold" about a
/// request nobody took would be this interface describing an edit that never
/// happened — and leaving the request behind would make it happen later, at a
/// time nobody chose.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('mcp_typing'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  ProviderContainer boot({
    EditMode mode = EditMode.source,
    Duration patience = const Duration(milliseconds: 80),
  }) {
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(editMode: mode, autoSave: false),
          ),
        ),
        mcpProvider.overrideWith(
          (ref) => McpController(ref, formatPatience: patience),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Stands in for the pane that would take the command: a pane clears the
  /// request on the frame after it acts, and there is no pane here.
  void withAPaneThatActs(ProviderContainer container, {String? writes}) {
    container.listen<EditorState>(editorProvider, (_, next) {
      if (next.pendingFormat == null) return;
      final id = container.read(tabProvider).activeTabId;
      if (writes != null && id != null) {
        container.read(tabProvider.notifier).updateContent(id, writes);
      }
      container.read(editorProvider.notifier).clearFormat();
    });
  }

  Future<McpOutcome> ask(
    ProviderContainer container,
    String action, [
    Map<String, Object?> arguments = const {},
  ]) =>
      container.read(mcpProvider.notifier).performAction(action, arguments);

  void openATab(ProviderContainer container, [String content = 'hello']) =>
      container.read(tabProvider.notifier).addTab(
            TabInfo(id: 'one', fileName: 'one.md', content: content),
          );

  group('formatting', () {
    test('a command nobody would take is refused, and not left behind',
        () async {
      // Preview with no block open: the source pane stands aside and there is
      // no block editor, so the request would sit in the state until a pane
      // appeared and then fire into a document nobody was looking at.
      final container = boot(mode: EditMode.preview);
      openATab(container);

      final outcome = await ask(container, 'format', {'format': 'bold'});

      expect(outcome.ok, isFalse);
      expect(outcome.said, contains('preview'));
      expect(outcome.said, contains('set_view_mode'));
      expect(container.read(editorProvider).pendingFormat, isNull,
          reason: '拒绝之后不许留下一个将来会自己触发的请求');
    });

    test('a command a block in the preview would take is run', () async {
      // The other half of the same rule: in the preview a block open for
      // editing does take it, so refusing there would be wrong.
      final container = boot(mode: EditMode.preview);
      openATab(container);
      container.read(editorProvider.notifier).setPreviewBlockEditing(true);
      withAPaneThatActs(container);

      final outcome = await ask(container, 'format', {'format': 'bold'});

      expect(outcome.ok, isTrue, reason: outcome.said);
    });

    test('one that is taken says so, and what it did to the document',
        () async {
      final container = boot();
      openATab(container, 'hello');
      withAPaneThatActs(container, writes: '**hello**');

      final outcome = await ask(container, 'format', {'format': 'bold'});

      expect(outcome.ok, isTrue, reason: outcome.said);
      expect(outcome.said, contains('bold'));
      expect(outcome.said, contains('5'));
      expect(outcome.said, contains('9'));
      expect(container.read(editorProvider).pendingFormat, isNull);
    });

    test('the length it reports is the one on screen, not the copy that lags',
        () async {
      // Measured on a real machine before this was right: two bold commands
      // in a row each answered "the document is the same length" while the
      // document grew by four characters each time. Both ends were read off
      // the tab, whose copy is written on a 300 ms debounce — so a command
      // that finishes in one frame was measured against two copies of the
      // text from before it (BUG-495).
      final container = boot();
      openATab(container, 'alpha');
      final controller = TextEditingController(text: 'alpha');
      addTearDown(controller.dispose);
      container.read(editorProvider.notifier).setController(controller);
      container.listen<EditorState>(editorProvider, (_, next) {
        if (next.pendingFormat == null) return;
        // What a pane does: it writes the field. The tab catches up later.
        controller.text = '**alpha**';
        container.read(editorProvider.notifier).clearFormat();
      });

      final outcome = await ask(container, 'format', {'format': 'bold'});

      expect(outcome.ok, isTrue, reason: outcome.said);
      expect(outcome.said, contains('5'));
      expect(outcome.said, contains('9'));
      expect(outcome.said, isNot(contains('same length')),
          reason: '标签页那一份还没跟上，量它等于量了两遍改之前的文本');
      expect(container.read(tabProvider).tabs.single.content, 'alpha',
          reason: '这一条的前提就是标签页还没跟上');
    });

    test('one nothing takes in time is dropped rather than left to fire',
        () async {
      // No pane at all. The wait ends, and the request must not still be
      // there: left there it fires the moment the reader switches to source
      // mode, which is an edit out of nowhere.
      final container = boot();
      openATab(container);

      final outcome = await ask(container, 'format', {'format': 'bold'});

      expect(outcome.ok, isFalse);
      expect(outcome.said, contains('dropped'));
      expect(container.read(editorProvider).pendingFormat, isNull);
    });

    test('with no format named it says what it takes', () async {
      final outcome = await ask(boot(), 'format');
      expect(outcome.ok, isFalse);
      expect(outcome.said, contains('bold'));
      expect(outcome.said, contains('tableTidy'));
    });
  });

  group('stepping history', () {
    test('with nothing to go back to it says so', () async {
      final container = boot();
      openATab(container);
      final outcome = await ask(container, 'undo');
      expect(outcome.ok, isFalse);
      expect(outcome.said, contains('nothing to undo'));
    });

    test('with no tab at all there is nothing to step', () async {
      final outcome = await ask(boot(), 'undo');
      expect(outcome.ok, isFalse);
      expect(outcome.said, contains('no tab'));
    });

    test('it steps back and forward through the same history the menu uses',
        () async {
      final container = boot();
      openATab(container, 'one');
      final editor = container.read(editorProvider.notifier)
        ..setHistoryTab('one')
        ..pushHistory('one');
      container.read(tabProvider.notifier).updateContent('one', 'one two');
      editor.pushHistory('one two');

      final back = await ask(container, 'undo');
      expect(back.ok, isTrue, reason: back.said);
      expect(back.said, contains('3'), reason: '退回到 "one" 是 3 个字符');
      expect(container.read(tabProvider).tabs.single.content, 'one');

      final forward = await ask(container, 'redo');
      expect(forward.ok, isTrue, reason: forward.said);
      expect(container.read(tabProvider).tabs.single.content, 'one two');
    });
  });

  group('the clipboard', () {
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('com.marktextplus/clipboard'), (call) async {
        calls.add(call);
        return true;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('com.marktextplus/clipboard'), null);
    });

    test('with nothing to put on it, it says so', () async {
      final outcome = await ask(boot(), 'set_clipboard');
      expect(outcome.ok, isFalse);
      expect(outcome.said, contains('content'));
    });

    test('plain text alone goes on as plain text', () async {
      final outcome = await ask(boot(), 'set_clipboard', {'content': 'abc'});

      expect(outcome.ok, isTrue, reason: outcome.said);
      expect(calls.map((c) => c.method), contains('Clipboard.setData'));
      expect(outcome.said, contains('gone'),
          reason: '它换掉的是读者真实的剪贴板，答复里就该说出来');
    });

    test('HTML goes on beside it, the way a browser leaves both', () async {
      // This is the one the paste path reads: `readHtml` first, plain text
      // only if there is none. Without it there was no way to exercise
      // "copied out of a browser" at all.
      final outcome = await ask(boot(), 'set_clipboard', {
        'content': 'Title\nitem',
        'html': '<h1>Title</h1><ul><li>item</li></ul>',
      });

      expect(outcome.ok, isTrue, reason: outcome.said);
      expect(calls.map((c) => c.method), contains('copyWithHtml'));
      final call = calls.firstWhere((c) => c.method == 'copyWithHtml');
      expect((call.arguments as Map)['html'], contains('<h1>'));
      expect(outcome.said, contains('HTML'));
    });
  });
}
