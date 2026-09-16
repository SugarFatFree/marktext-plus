import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';
import 'package:marktext_plus/ui/widgets/app_menu_bar.dart';

/// Edit → Undo and Ctrl+Z step back through the same history.
///
/// They did not go through the same code. Ctrl+Z, handled inside the source
/// editor, calls `undo()` and lets it read the field. The menu calls
/// `stepHistory`, which passed the **tab's** copy of the text — and that copy
/// is written on a 300 ms debounce, so while somebody is typing it is behind
/// the field by up to that long, and longer when a large document is being
/// redrawn and the timer runs late.
///
/// `undo` puts whatever it is told is "now" onto the redo stack before
/// stepping back. Told a stale copy, the characters typed since the last
/// debounce went nowhere: the screen lost them and redo could not bring them
/// back.
///
/// The tab's copy is still what preview mode has to use — there is no field
/// there — which is why `stepHistory` was written to pass it. It just has to
/// stop passing it when there *is* a field.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('menu_undo'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  Future<(ProviderContainer, WidgetRef)> stage(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(editMode: EditMode.source, autoSave: false),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    late WidgetRef ref;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (c, r, _) {
              ref = r;
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      ),
    );
    return (container, ref);
  }

  testWidgets('it steps back from the text in the field, not the copy that lags',
      (tester) async {
    final (container, ref) = await stage(tester);
    final editor = container.read(editorProvider.notifier);

    // The field holds "ab" and then "abc"; the tab still holds "ab", because
    // the debounce that would copy it across has not fired.
    final controller = TextEditingController(text: 'abc');
    addTearDown(controller.dispose);
    container.read(tabProvider.notifier).addTab(
          TabInfo(id: 'note', fileName: 'note.md', content: 'ab'),
        );
    editor
      ..setHistoryTab('note')
      ..setController(controller)
      ..pushHistory('a');

    AppMenuBar.stepHistory(ref, back: true);

    expect(
      editor.redo(),
      'abc',
      reason: '撤销时压进 redo 栈的必须是屏幕上那一份；'
          '压进去 "ab" 就等于把刚打的 c 丢了，而且再也拿不回来',
    );
  });

  testWidgets('with no field it still steps back from the tab, which is all '
      'there is', (tester) async {
    // The case `stepHistory` was written for: a checkbox ticked in the preview
    // changes the tab and nothing else, so the tab is the only copy of "now".
    final (container, ref) = await stage(tester);
    final editor = container.read(editorProvider.notifier);
    expect(editor.hasSourceEditor, isFalse);

    container.read(tabProvider.notifier).addTab(
          TabInfo(id: 'note', fileName: 'note.md', content: '- [x] one\n'),
        );
    editor
      ..setHistoryTab('note')
      ..pushHistory('- [ ] one\n');

    AppMenuBar.stepHistory(ref, back: true);

    expect(container.read(tabProvider).tabs.single.content, '- [ ] one\n',
        reason: '没有输入框时，撤销的结果要由调用方写回标签页');
    expect(editor.redo(), '- [x] one\n');
  });
}
