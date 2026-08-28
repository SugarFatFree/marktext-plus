import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/file_service.dart';
import 'package:marktext_plus/utils/file_utils.dart';

/// What belongs in the sidebar's tree.
///
/// It used to list everything a directory held. Opening a project folder
/// therefore arrived with `.git`, `node_modules`, images and binaries in it —
/// and tapping one of those opened it as a text tab full of mojibake, one
/// stray keystroke away from an auto-save writing that mojibake back over the
/// original file. Upstream MarkText shows directories and markdown documents
/// and nothing else.
void main() {
  late Directory root;
  String at(String name) => '${root.path}/$name';

  setUp(() => root = Directory.systemTemp.createTempSync('tree_filter'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  Future<List<String>> names() async =>
      (await FileService().listDirectory(root.path)).map((n) => n.name).toList();

  test('a binary that cannot be opened is not offered', () async {
    File(at('note.md')).writeAsStringSync('# hi');
    File(at('photo.png')).writeAsBytesSync([0x89, 0x50, 0x4E, 0x47]);
    File(at('report.pdf')).writeAsBytesSync([0x25, 0x50, 0x44, 0x46]);

    expect(await names(), ['note.md']);
  });

  test('every markdown type the app opens is shown', () async {
    for (final ext in FileUtils.markdownExtensions) {
      File(at('doc.$ext')).writeAsStringSync('');
    }
    final shown = await names();
    expect(shown, hasLength(FileUtils.markdownExtensions.length));
  });

  test('directories full of things the editor cannot open are hidden',
      () async {
    Directory(at('.git')).createSync();
    Directory(at('node_modules')).createSync();
    Directory(at('notes')).createSync();
    File(at('a.md')).writeAsStringSync('');

    expect(await names(), ['notes', 'a.md']);
  });

  test('the tree and the folder search skip the same directories', () {
    // The search had this list and the tree had none, which is how a project
    // folder could fill the sidebar with `node_modules` while a search of the
    // same folder correctly stepped over it.
    final sidebar = File('lib/ui/widgets/side_bar.dart').readAsStringSync();
    expect(sidebar.contains("'node_modules'"), isFalse,
        reason: '侧边栏又自己留了一份排除清单');
    expect(sidebar, contains('FileUtils.isSkippedDirectory'));

    for (final name in ['node_modules', '.git', 'dist']) {
      expect(FileUtils.isSkippedDirectory(name), isTrue, reason: name);
    }
    expect(FileUtils.isSkippedDirectory('notes'), isFalse);
  });

  test('a dot-prefixed markdown file is still a document', () async {
    // Hiding *directories* that start with a dot is about `.git`; a note
    // someone chose to name `.todo.md` is still their note.
    File(at('.todo.md')).writeAsStringSync('');
    expect(await names(), ['.todo.md']);
  });
}
