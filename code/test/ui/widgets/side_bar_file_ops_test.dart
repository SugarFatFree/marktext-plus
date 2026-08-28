import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The sidebar's five file operations — new file, new folder, rename, and the
/// two deletes — all used to be a bare `await` on a provider call. A name
/// Windows rejects, a read-only folder, a file another program holds open: the
/// dialog closed and nothing happened at all, because an unhandled exception in
/// an async callback is silent in a release build. Upstream MarkText notifies
/// on each of these ("Error while deleting", "Error in Side Bar").
///
/// These assertions are on the source because the operations sit inside a
/// `showMenu` callback that a widget test cannot reach without driving the
/// whole sidebar, and what matters is only that none of the five is left
/// unwrapped.
void main() {
  late String source;

  setUpAll(() {
    source = File('lib/ui/widgets/side_bar.dart').readAsStringSync();
  });

  test('every file-system call goes through the reporting wrapper', () {
    // Each of the four provider calls appears exactly once, and each is an
    // argument to _runFileOp rather than a statement of its own.
    for (final call in [
      'createNode(p.join(parentDir, name))',
      'createNode(p.join(parentDir, name), isDirectory: true)',
      'renameNode(node.path, newPath)',
      'deleteNode(node.path)',
      'deleteNode(file.filePath)',
    ]) {
      expect(source, contains(call), reason: '$call 不见了，测试需要更新');
      expect(
        RegExp(r'await\s+ref\s*\.?\s*\n?\s*\.?read\(fileProvider\.notifier\)\s*\.?\s*\n?\s*\.?' +
                RegExp.escape(call.split('(').first))
            .hasMatch(source),
        isFalse,
        reason: '$call 是直接 await 的，失败时会被静默吞掉',
      );
    }
    expect('_runFileOp('.allMatches(source).length, 6,
        reason: '一处声明加五处调用');
  });

  test('the two deletes share one implementation', () {
    // The opened-files menu deleted the file itself with File().delete(), which
    // skipped deleteNode's tree refresh: the file it had just removed stayed
    // visible in the folder below, and clicking it opened a document that no
    // longer existed.
    expect(source, isNot(contains('File(file.filePath).delete()')));
    expect('deleteNode('.allMatches(source).length, 2);
  });

  test('follow-up state changes are skipped when the operation failed', () {
    // Moving the tabs after a failed rename would point them at a path that
    // does not exist, and the next save would write the old file back out.
    for (final guard in [
      'if (!renamed) return;',
      'pathDeleted(node.path)',
      'pathDeleted(file.filePath)',
    ]) {
      expect(source, contains(guard));
    }
    // Both deletes bail out before touching the tabs when the delete failed.
    for (final path in ['node.path', 'file.filePath']) {
      final from = source.indexOf('deleteNode($path)');
      final to = source.indexOf('pathDeleted($path)');
      expect(from, greaterThan(-1));
      expect(to, greaterThan(from));
      expect(source.substring(from, to), contains('return;'),
          reason: 'deleteNode($path) 失败后仍然会去动标签页');
    }
  });

  test('the failure is reported to the reader, not just swallowed', () {
    expect(source, contains('fileOperationFailed'));
    expect(source, contains('ScaffoldMessenger.of(context).showSnackBar'));
  });
}
