import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';

/// Undo, for an edit made in the preview.
///
/// The preview is not read-only: a checkbox can be ticked in it and a block can
/// be edited in place. In preview-only mode no source editor is built at all —
/// `DeferredEditorBuilder` only builds the mode on screen — and every
/// `pushHistory` in the application is in the source editor, so the undo stack
/// for that tab was empty and Ctrl+Z did nothing whatever.
///
/// The mechanism for it was already there and waiting: `hasSourceEditor` exists
/// so undo knows to write its answer to the tab instead of into a field, and its
/// doc comment says "in preview mode there is not, and the caller has to write
/// the result to the tab instead". What it never had was a snapshot to go back
/// to. Both plugin paths that rewrite a document — the Apply button and a
/// plugin's replace — push one explicitly; the preview's own edits did not.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late ProviderContainer container;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('previewundo');
    container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: dir.path),
          AppConfig(autoSave: false, editMode: EditMode.preview),
        ),
      ),
    ]);
  });
  tearDown(() {
    container.dispose();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  const before = '- [ ] one\n- [ ] two\n';
  const after = '- [x] one\n- [ ] two\n';

  /// The application's own path for an edit made in the preview — the method
  /// both `home_screen` and the split hand it to. Driving that rather than a
  /// copy of it here: the first version of this test pushed the snapshot itself
  /// and passed before anything was fixed, which is a test of its own helper.
  void tickACheckbox(String id, String now) {
    final tabs = container.read(tabProvider.notifier);
    tabs.recordExternalEdit(id, now);
    tabs.updateContent(id, now);
  }

  test('a ticked checkbox can be undone', () async {
    container.read(tabProvider.notifier).addTab(
          TabInfo(id: 'note', fileName: 'note.md', content: before),
        );

    tickACheckbox('note', after);
    expect(container.read(tabProvider).tabs.single.content, after);

    final editor = container.read(editorProvider.notifier);
    final restored = editor.undo(current: after);
    expect(restored, before,
        reason: '预览里的编辑撤不回来——那一栏的撤销栈是空的，'
            'Ctrl+Z 什么也不做');
  });

  test('undo has somewhere to write it when there is no source editor', () {
    // The other half of the same mechanism, and the reason `stepHistory` asks:
    // with no field to restore into, the caller writes the answer to the tab.
    expect(container.read(editorProvider.notifier).hasSourceEditor, isFalse);
  });

  test('ticking a second box is its own step back', () async {
    // In the split this was coarse rather than absent: the stack held the
    // source pane's snapshots, so one press stepped back past however many
    // boxes had been ticked since the last of them.
    const both = '- [x] one\n- [x] two\n';
    container.read(tabProvider.notifier).addTab(
          TabInfo(id: 'note', fileName: 'note.md', content: before),
        );

    tickACheckbox('note', after);
    tickACheckbox('note', both);

    final editor = container.read(editorProvider.notifier);
    expect(editor.undo(current: both), after,
        reason: '一次 Ctrl+Z 应当只取消最后一个勾选');
    expect(editor.undo(current: after), before);
  });

  test('an edit that changes nothing leaves no step to take back', () {
    // Committing a block editor without having changed anything reaches here.
    // `pushHistory` refuses a snapshot equal to the one on top, so this is not
    // only that check — with nothing on the stack at all there is nothing to
    // compare against, and a restore point identical to the present would make
    // the reader press Ctrl+Z twice to go back one step.
    container.read(tabProvider.notifier).addTab(
          TabInfo(id: 'note', fileName: 'note.md', content: before),
        );
    container.read(tabProvider.notifier).recordExternalEdit('note', before);
    expect(container.read(editorProvider).canUndo, isFalse,
        reason: '什么都没改却留下一个撤销点，读者要按两次才退一步');
  });
}
