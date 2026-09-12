import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/core/config/app_config.dart';
import 'package:marktext_plus/core/config/config_service.dart';
import 'package:marktext_plus/providers/editor_provider.dart';
import 'package:marktext_plus/providers/settings_provider.dart';

/// The undo history is bounded by how much text it holds, not by how many steps.
///
/// Every entry is a whole copy of the document, and the bound was two hundred
/// entries. That is twenty megabytes of history for a 100 KB note, two hundred
/// for a one-megabyte document and two gigabytes for a ten-megabyte one — per
/// tab, and again for redo. The editor's first promises are a low footprint and
/// large files, and this was the largest thing in the process that nothing
/// measured.
///
/// The comment on the bound saw the shape of the risk — "each entry is a whole
/// copy of the document, so an unbounded stack would grow without limit" — and
/// then counted the wrong thing. The highlighter's cache in this same code base
/// budgets by characters for exactly this reason.
///
/// The step count stays as well, so nothing changes for a document small enough
/// that two hundred copies of it are cheap — which is almost every Markdown
/// file.
void main() {
  late Directory configDir;
  late ProviderContainer container;

  setUp(() {
    configDir = Directory.systemTemp.createTempSync('undo_bytes');
    container = ProviderContainer(overrides: [
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(
          ConfigService(configDir: configDir.path),
          AppConfig(),
        ),
      ),
    ]);
  });
  tearDown(() {
    container.dispose();
    if (configDir.existsSync()) configDir.deleteSync(recursive: true);
  });

  EditorNotifier notifier() => container.read(editorProvider.notifier);

  /// [count] distinct snapshots of [size] characters each.
  void push(int count, int size) {
    for (var i = 0; i < count; i++) {
      // Distinct, or `pushHistory` refuses the duplicate.
      notifier().pushHistory('${'x' * (size - 8)}${i.toString().padLeft(8, '0')}',
          tabId: 't');
    }
  }

  test('a small document keeps every step it used to', () {
    // 20 KB each: two hundred of them is four megabytes, which is inside the
    // budget, so the step count is what bounds it — as before.
    push(260, 20 * 1024);
    expect(notifier().historyLengthForTest('t'), EditorNotifier.maxHistory,
        reason: '小文档的撤销步数被削减了，这是回归');
  });

  test('a large document is bounded by what the history holds', () {
    // 2 MB each. Two hundred would be four hundred megabytes.
    push(30, 2 * 1024 * 1024);
    expect(notifier().historyCharsForTest('t'),
        lessThanOrEqualTo(EditorNotifier.historyCharBudget),
        reason: '撤销历史超出了字符预算');
    expect(notifier().historyLengthForTest('t'),
        lessThan(EditorNotifier.maxHistory),
        reason: '预算没有起作用，步数还是上限');
  });

  test('one undo is always possible, however large the document', () {
    // A single snapshot larger than the whole budget: dropping to nothing would
    // be worse than holding it, so two are kept.
    push(4, EditorNotifier.historyCharBudget + 1024);
    expect(notifier().historyLengthForTest('t'), greaterThanOrEqualTo(2),
        reason: '历史被削到一条，撤销键会变成什么也不做');
  });

  test('the oldest go first', () {
    push(30, 2 * 1024 * 1024);
    final newest = notifier().historyTopForTest('t');
    expect(newest, endsWith('00000029'),
        reason: '丢掉的是最近的状态，而撤销要的正是最近的过去');
  });

  test('each tab is bounded on its own', () {
    push(20, 2 * 1024 * 1024);
    for (var i = 0; i < 20; i++) {
      notifier().pushHistory('${'y' * 2048}$i', tabId: 'other');
    }
    expect(notifier().historyCharsForTest('t'),
        lessThanOrEqualTo(EditorNotifier.historyCharBudget));
    expect(notifier().historyLengthForTest('other'), 20,
        reason: '一个标签页的大文档削掉了另一个标签页的历史');
  });
}
