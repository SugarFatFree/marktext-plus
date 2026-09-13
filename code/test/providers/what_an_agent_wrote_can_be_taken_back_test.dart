import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/models/tab_info.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/mcp_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';
import 'package:marktext_plus/providers/tab_provider.dart';

/// What an agent wrote can be taken back.
///
/// Found by reading the siblings of the branch BUG-470 fixed. Five places write
/// a document's content: a plugin's rewrite being accepted, a plugin command's
/// result, the editing panes reporting through the screen, undo and redo putting
/// their answer back, and the automation interface. The first two record a
/// restore point, the third is the path typing takes and the source editor
/// records its own, the fourth must not — and the fifth did not.
///
/// So an agent could rewrite the document and Ctrl+Z would either do nothing
/// or step back past it to whatever the reader last typed. The reader did not
/// type this; taking back what you did not do is the whole of what undo is for.
///
/// What is deliberately *not* tested here: that a write of the text already
/// there records nothing. [TabNotifier.recordExternalEdit] checks for it, and
/// the check is right to be there, but it cannot be shown to matter — `undo`
/// needs two entries before it will step anywhere and `pushHistory` drops a
/// snapshot equal to the top of the stack, so every arrangement I could build
/// behaves the same with the check removed. Two nets over one hole; a test
/// asserting it would pass whether or not the code was there.
void main() {
  late Directory configDir;

  setUp(() => configDir = Directory.systemTemp.createTempSync('mcp_undo'));
  tearDown(() {
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  ProviderContainer boot() {
    final container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith(
          (ref) => SettingsNotifier(
            ConfigService(configDir: configDir.path),
            AppConfig(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// A tab holding [content], with the history pointed at it the way a source
  /// editor would have.
  ProviderContainer withTab(String content) {
    final c = boot();
    c.read(tabProvider.notifier).addTab(
          TabInfo(id: 'note', fileName: 'note.md', content: content),
        );
    return c;
  }

  String contentOf(ProviderContainer c) =>
      c.read(tabProvider).tabs.firstWhere((t) => t.id == 'note').content;

  Future<void> write(ProviderContainer c, String content) async {
    final outcome = await c
        .read(mcpProvider.notifier)
        .performAction('set_content', {'tabId': 'note', 'content': content});
    expect(outcome.ok, isTrue, reason: outcome.said);
  }

  /// Undo the way the menu does it: the notifier answers with the text when no
  /// source editor is holding the document, and the caller writes it back.
  void undo(ProviderContainer c) {
    final text =
        c.read(editorProvider.notifier).undo(current: contentOf(c));
    expect(text, isNotNull, reason: '撤销没有东西可退——还原点没被压进去');
    c.read(tabProvider.notifier).updateContent('note', text!, external: true);
  }

  test('an agent write can be undone', () async {
    final c = withTab('what the reader wrote\n');
    await write(c, 'what the agent wrote\n');
    expect(contentOf(c), 'what the agent wrote\n');

    undo(c);

    expect(contentOf(c), 'what the reader wrote\n');
  });

  test('two writes come back one at a time', () async {
    final c = withTab('nothing yet\n');
    await write(c, 'first\n');
    await write(c, 'second\n');

    undo(c);
    expect(contentOf(c), 'first\n', reason: '一次退回了两步');
    undo(c);
    expect(contentOf(c), 'nothing yet\n');
  });

}
