import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/utils/file_utils.dart';

/// One list of what counts as a markdown document.
///
/// Drag and drop kept a private copy holding three of the seven extensions
/// the rest of the program accepts, so dropping a `.mmd` or a `.mdown` on the
/// window did nothing whatever — and said nothing either.
void main() {
  test('the shared list has every extension the app claims to open', () {
    for (final ext in ['.md', '.markdown', '.mmd', '.mdown', '.mdtxt',
        '.mdtext', '.txt']) {
      expect(FileUtils.markdownExtensionsWithDot, contains(ext));
    }
  });

  test('nothing in the program keeps its own copy of that list', () {
    // The window used to; the check is on the source because what matters is
    // that there is one list, not that two lists happen to agree today.
    for (final path in [
      'lib/ui/screens/home_screen.dart',
      'lib/ui/widgets/side_bar.dart',
      'lib/main.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source.contains("{'.md', '.markdown'"), isFalse,
          reason: '$path 里又出现了一份私有的扩展名清单');
    }
  });

  test('a dropped file is judged by that list', () {
    expect(FileUtils.isMarkdownFile('/notes/a.mmd'), isTrue);
    expect(FileUtils.isMarkdownFile('/notes/a.mdown'), isTrue);
    expect(FileUtils.isMarkdownFile('/notes/a.pdf'), isFalse);
    expect(FileUtils.isMarkdownFile('/notes/a.png'), isFalse);
  });
}
