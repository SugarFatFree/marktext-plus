import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/utils/file_reveal.dart';

/// Showing something in the system file manager is written once.
///
/// It had been written twice — the tab bar's "reveal" and the menu bar's
/// "show log file" — and the two copies had already drifted: one spawned
/// `explorer`, the other `explorer.exe`, one awaited the result and the other
/// did not. A third caller would have been a third copy.
void main() {
  group('selecting a file', () {
    test('Windows asks Explorer to highlight the file itself', () {
      expect(
        FileReveal.selectCommand(r'C:\notes\todo.md', os: 'windows'),
        [r'explorer.exe', r'/select,', r'C:\notes\todo.md'],
      );
    });

    test('macOS asks Finder to reveal the file itself', () {
      expect(
        FileReveal.selectCommand('/Users/a/todo.md', os: 'macos'),
        ['open', '-R', '/Users/a/todo.md'],
      );
    });

    test('Linux has no reveal, so it opens the containing folder', () {
      expect(
        FileReveal.selectCommand('/home/a/notes/todo.md', os: 'linux'),
        ['xdg-open', '/home/a/notes'],
        reason: 'xdg-open 没有"选中某个文件"的说法，只能打开它所在的目录',
      );
    });
  });

  group('opening a folder', () {
    test('every platform opens the folder itself, not its parent', () {
      expect(FileReveal.openCommand(r'C:\plugins\demo', os: 'windows'),
          [r'explorer.exe', r'C:\plugins\demo']);
      expect(FileReveal.openCommand('/Users/a/plugins/demo', os: 'macos'),
          ['open', '/Users/a/plugins/demo']);
      expect(FileReveal.openCommand('/home/a/plugins/demo', os: 'linux'),
          ['xdg-open', '/home/a/plugins/demo']);
    });

    test('a folder is not passed through the file-selecting form', () {
      final open = FileReveal.openCommand('/home/a/plugins/demo', os: 'linux');
      final select = FileReveal.selectCommand('/home/a/plugins/demo', os: 'linux');
      expect(open.last, '/home/a/plugins/demo');
      expect(select.last, '/home/a/plugins',
          reason: '把目录当文件处理会打开它的上一级，读者看不到自己要的那个目录');
    });
  });
}
