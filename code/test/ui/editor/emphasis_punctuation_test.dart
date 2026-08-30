import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';
import 'package:marktext_plus/ui/editor/source_editor.dart';

/// Ctrl+B on a selection that ends in punctuation.
///
/// `**加粗。**后面` is not bold anywhere — not here, not in marked, not on
/// GitHub: the closing run sits between a full stop and a letter, and the
/// format says such a run can neither open nor close. A reader selecting a
/// sentence including its full stop and pressing Ctrl+B was handed markup that
/// renders as its own asterisks. Chinese sentences end in `。` far more often
/// than English ones end in `.` inside the words being marked, so this is a
/// daily occurrence rather than a corner.
void main() {
  bool rendersBold(String source) => MarkdownParser()
      .parse(source)
      .map(ExportService.nodeToHtml)
      .join()
      .contains('<strong>');

  String bolded(String text, int start, int end) =>
      SourceEditor.toggleWrap(text, start, end, '**', '**').text;

  group('what Ctrl+B produces actually renders', () {
    test('a selection ending in a Chinese full stop', () {
      final out = bolded('加粗。后面接中文', 0, 4);
      expect(out, '**加粗。后**面接中文');
      expect(rendersBold(out), isTrue);
    });

    test('a selection wrapped in Chinese brackets', () {
      final out = bolded('前面「加粗」后面', 2, 6);
      expect(out, '前面「**加粗**」后面');
      expect(rendersBold(out), isTrue);
    });

    test('an English sentence ending in a full stop', () {
      final out = bolded('bold. after', 0, 5);
      expect(out, '**bold**. after');
      expect(rendersBold(out), isTrue);
    });

    test('strikethrough too, which GitHub judges the same way', () {
      // `~~文字。~~后面` is not struck through in marked or on GitHub, for the
      // same reason. This parser is more forgiving and stays so — a document
      // should not stop rendering because it was opened here — but what is
      // written from here should mean the same wherever it is read.
      expect(
        SourceEditor.toggleWrap('示例文字。后面', 0, 5, '~~', '~~').text,
        '~~示例文字~~。后面',
      );
    });

    test('a trailing space is left outside', () {
      // True of every marker, not only these: `**text **` closes on a space
      // and is not emphasis in any reader. The space stays in the document —
      // it is moved out of the emphasis, not deleted.
      expect(bolded('文字 ', 0, 3), '**文字** ');
    });
  });

  group('what is left alone', () {
    test('ordinary text', () {
      expect(bolded('普通文字', 0, 4), '**普通文字**');
    });

    test('a selection that is nothing but punctuation', () {
      // Trimming would leave nothing to mark, so it is wrapped as it is.
      expect(bolded('——', 0, 2), '**——**');
    });

    test('highlight and underline keep their punctuation', () {
      // This editor's own markers, with no flanking rule to satisfy: moving
      // the punctuation would change what the reader asked to mark for no
      // gain at all.
      expect(
        SourceEditor.toggleWrap('示例文字。后面', 0, 5, '==', '==').text,
        '==示例文字。==后面',
      );
      expect(
        SourceEditor.toggleWrap('示例文字。后面', 0, 5, '++', '++').text,
        '++示例文字。++后面',
      );
    });

    test('inline code keeps the punctuation it was given', () {
      // The rule is about emphasis. A code span has no flanking rules —
      // `` `代码。` `` is code, punctuation and all.
      expect(
        SourceEditor.toggleWrap('代码。', 0, 3, '`', '`').text,
        '`代码。`',
      );
    });

    test('unwrapping still works after the trim', () {
      // Selecting the words of `**加粗**。` and pressing Ctrl+B again finds
      // the markers just outside the selection and takes them off.
      expect(bolded('**加粗**。', 2, 4), '加粗。');
    });

    test('a link keeps its brackets', () {
      // Trimming a closing parenthesis would leave a link that is no longer
      // a link. Only sentence punctuation is moved.
      expect(
        bolded('见[链接](url)', 0, 10),
        '**见[链接](url)**',
      );
    });

    test('applying italic to bold nests instead of stripping', () {
      // `**bold**` begins and ends with `*`; trimming those would take a
      // layer off rather than adding one.
      expect(
        SourceEditor.toggleWrap('**bold**', 0, 8, '*', '*').text,
        '***bold***',
      );
    });
  });
}
