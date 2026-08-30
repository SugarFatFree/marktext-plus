import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/screens/home_screen.dart';
import 'package:marktext_plus/utils/file_utils.dart';

/// Which dropped files the window should complain about.
///
/// `desktop_drop` broadcasts every drop to every registered target and lets
/// each decide by its own bounds — there is no hit test that consumes the
/// event. The editor sits inside the window, so a file dropped on the text
/// area reaches both handlers. The editor takes images and writes a link; the
/// window used to count that same file as refused, so a picture appeared in
/// the document and a message appeared beside it saying the file had not been
/// opened.
void main() {
  test('a markdown document is handled', () {
    for (final ext in FileUtils.markdownExtensions) {
      expect(HomeScreen.dropIsUnhandled('/tmp/note.$ext', editorPresent: true), isFalse,
          reason: '.$ext 是本应用支持的扩展名');
    }
  });

  test('an image is handled — by the editor, not by the window', () {
    for (final name in [
      'a.png', 'b.jpg', 'c.jpeg', 'd.gif', 'e.webp', 'f.bmp', 'g.svg',
    ]) {
      expect(HomeScreen.dropIsUnhandled('/tmp/$name', editorPresent: true), isFalse,
          reason: '$name 会被编辑器接手，不该报告为"未打开"');
    }
  });

  test('anything else is worth telling the reader about', () {
    for (final name in ['a.pdf', 'b.docx', 'c.zip', 'd.exe', 'e']) {
      expect(HomeScreen.dropIsUnhandled('/tmp/$name', editorPresent: true), isTrue, reason: name);
    }
  });

  test('the extension is matched whatever its case', () {
    expect(HomeScreen.dropIsUnhandled('/tmp/NOTE.MD', editorPresent: true), isFalse);
    expect(HomeScreen.dropIsUnhandled('/tmp/PICTURE.PNG', editorPresent: true), isFalse);
  });

  test('with no editor on screen an image has nowhere to land, and is '
      'reported', () {
    // No document open means no text area and no drop target on it, so the
    // picture reaches nobody. Passing over it in silence is exactly the
    // failure this whole change is about, just moved somewhere else.
    expect(HomeScreen.dropIsUnhandled('/tmp/a.png', editorPresent: false),
        isTrue);
    // A markdown document still opens without an editor already on screen —
    // opening one is what it does.
    expect(HomeScreen.dropIsUnhandled('/tmp/note.md', editorPresent: false),
        isFalse);
  });
}
