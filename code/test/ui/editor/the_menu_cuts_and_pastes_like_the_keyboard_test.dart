import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// The Edit menu's Cut and Paste do what the keyboard's do.
///
/// The menu carried out both itself. Its paste read only the plain flavour of
/// the clipboard and wrote it straight in, while Ctrl+V goes on to replace what
/// landed with the HTML flavour converted to Markdown — or with a link, when a
/// web address was pasted over some words. So a page copied out of a browser
/// kept its headings and lists through the keyboard and lost them through the
/// menu: one editor with two pastes.
///
/// Neither of the menu's two writes recorded a restore point either, which is
/// BUG-478 in a third place: a bulk edit has to be one press of Ctrl+Z.
void main() {
  late Directory configDir;
  const channel = MethodChannel('com.marktextplus/clipboard');

  /// What the native side will answer for each flavour of the clipboard.
  ///
  /// Answered by mock handlers rather than by `Clipboard.setData`: awaiting a
  /// platform channel from a test body never returns under the fake clock
  /// `testWidgets` runs on. The editor's own awaits are fine — `tester.pump`
  /// drives them.
  String? htmlOnClipboard;
  String? plainOnClipboard;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('menu_edit');
    htmlOnClipboard = null;
    plainOnClipboard = null;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'readHtml') return htmlOnClipboard;
      if (call.method == 'copyWithHtml') return true;
      return null;
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return plainOnClipboard == null
            ? null
            : <String, dynamic>{'text': plainOnClipboard};
      }
      // Everything else the editor may ask the platform for — setting the
      // clipboard, the system UI — is answered with nothing rather than left to
      // throw.
      return null;
    });
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  /// A source editor holding [content], with the clipboard's plain flavour set
  /// to [clipboard].
  Future<(ProviderContainer, TextEditingController)> pump(
    WidgetTester tester,
    String content, {
    String? clipboard,
  }) async {
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            // A source pane on screen: format actions are only acted on where
            // there is one, and the default mode is preview — where the menu's
            // Cut and Paste did nothing before this change either, because no
            // controller exists to write to.
            AppConfig(editMode: EditMode.source),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    plainOnClipboard = clipboard;

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
    // The editor registers its controller in a post-frame callback.
    await tester.pump();
    final controller = container.read(editorProvider.notifier).controller!;
    return (container, controller);
  }

  /// Asks for [action] the way the Edit menu does, and lets it land.
  Future<void> ask(
    WidgetTester tester,
    ProviderContainer container,
    FormatAction action,
  ) async {
    container.read(editorProvider.notifier).applyFormat(action);
    await tester.pump();
    // Paste reads the clipboard asynchronously.
    await tester.pump(const Duration(milliseconds: 10));
  }

  void select(TextEditingController controller, int start, int end) =>
      controller.selection = TextSelection(baseOffset: start, extentOffset: end);

  group('paste', () {
    testWidgets('puts the clipboard in at the caret', (tester) async {
      final (c, controller) = await pump(tester, 'one \n', clipboard: 'two');
      select(controller, 4, 4);

      await ask(tester, c, FormatAction.paste);

      expect(controller.text, 'one two\n');
    });

    testWidgets('converts the HTML flavour the way Ctrl+V does', (tester) async {
      // The reason this exists: the menu used to write the plain flavour and
      // throw the structure away.
      htmlOnClipboard = '<h1>Title</h1><p>Body</p>';
      final (c, controller) =
          await pump(tester, '', clipboard: 'TitleBody');
      select(controller, 0, 0);

      await ask(tester, c, FormatAction.paste);

      expect(controller.text, contains('# Title'),
          reason: '菜单的粘贴没有把 HTML 转成 Markdown，和 Ctrl+V 不一致');
    });

    testWidgets('a web address over some words becomes a link', (tester) async {
      final (c, controller) =
          await pump(tester, 'the docs\n', clipboard: 'https://example.test');
      select(controller, 0, 8);

      await ask(tester, c, FormatAction.paste);

      expect(controller.text, '[the docs](https://example.test)\n');
    });

    testWidgets('two in a row come back one at a time', (tester) async {
      // Two, because one would pass either way: the editor puts the document's
      // first state on the stack when it is built, and undo adds whatever is on
      // screen before stepping — so a single paste comes back even with nothing
      // recorded. What the snapshot is for is the *second* one, before the
      // typing debounce has closed the first.
      final (c, controller) = await pump(tester, 'a\n', clipboard: 'x');
      select(controller, 1, 1);
      await ask(tester, c, FormatAction.paste);
      select(controller, 2, 2);
      await ask(tester, c, FormatAction.paste);
      expect(controller.text, 'axx\n');

      c.read(editorProvider.notifier).undo();
      await tester.pump();
      expect(controller.text, 'ax\n', reason: '一次退回了两次粘贴');

      c.read(editorProvider.notifier).undo();
      await tester.pump();
      expect(controller.text, 'a\n');
    });
  });

  group('cut', () {
    testWidgets('takes the selection out', (tester) async {
      final (c, controller) = await pump(tester, 'one two\n');
      select(controller, 3, 7);

      await ask(tester, c, FormatAction.cut);

      expect(controller.text, 'one\n');
    });

    testWidgets('two in a row come back one at a time', (tester) async {
      // The same reason as the paste pair above: one cut comes back whether or
      // not anything was recorded.
      final (c, controller) = await pump(tester, 'abcd\n');
      select(controller, 3, 4);
      await ask(tester, c, FormatAction.cut);
      select(controller, 2, 3);
      await ask(tester, c, FormatAction.cut);
      expect(controller.text, 'ab\n');

      c.read(editorProvider.notifier).undo();
      await tester.pump();
      expect(controller.text, 'abc\n', reason: '一次退回了两次剪切');

      c.read(editorProvider.notifier).undo();
      await tester.pump();
      expect(controller.text, 'abcd\n');
    });

    testWidgets('does nothing with no selection', (tester) async {
      final (c, controller) = await pump(tester, 'one two\n');
      select(controller, 3, 3);

      await ask(tester, c, FormatAction.cut);

      expect(controller.text, 'one two\n');
    });
  });
}
