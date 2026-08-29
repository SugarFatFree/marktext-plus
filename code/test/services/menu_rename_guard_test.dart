import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/file_service.dart';

/// Renaming from the menu, and renaming from the sidebar, are one operation.
///
/// `File.rename` replaces the destination without a word. The service grew a
/// guard against that and the sidebar adopted it; the File menu kept its own
/// `File(oldPath).rename(newPath)` and so kept the bug — renaming the open
/// note onto a name already in use destroyed the note that had it, with no
/// prompt, no undo, and nothing on screen to say so.
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('menu_rename'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('nothing outside the service renames a file itself', () {
    // Checked against the source because what matters is that there is one
    // implementation, not that two implementations agree today.
    for (final path in [
      'lib/ui/widgets/app_menu_bar.dart',
      'lib/ui/widgets/side_bar.dart',
      'lib/ui/widgets/editor_tab_bar.dart',
      'lib/ui/screens/home_screen.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(RegExp(r'File\([^)]*\)\.rename\(').hasMatch(source), isFalse,
          reason: '$path 自己做了一次重命名，绕过了目标已存在的守卫');
    }
  });

  test('the guard the menu now goes through actually refuses', () async {
    final note = File('${root.path}/note.md')..writeAsStringSync('keep me');
    final taken = File('${root.path}/taken.md')..writeAsStringSync('precious');

    await expectLater(
      FileService().renameFile(note.path, taken.path),
      throwsA(isA<PathExistsException>()),
    );
    expect(taken.readAsStringSync(), 'precious',
        reason: '被覆盖了——守卫没起作用');
    expect(note.existsSync(), isTrue);
  });

  test('moving is renaming, with no second implementation to drift', () {
    // `FileService.moveFile` was an alias for `renameFile` with no callers.
    // A second name for one operation is how the two come apart later.
    final source = File('lib/services/file_service.dart').readAsStringSync();
    expect(source.contains('moveFile'), isFalse);
  });
}
