import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// A backslash inside a code span is a backslash.
///
/// The parser hides every `\x` behind a sentinel before the inline pattern
/// runs — that is what stops `\*literal\*` reading as emphasis — and puts the
/// character back afterwards without its backslash. Inside a code span that is
/// wrong: the content is literal, so the backslash is part of it.
///
/// The readers of this editor write regular expressions and Windows paths, and
/// both are usually written in code. `` `\.` `` came out as `.` and
/// `` `C:\temp\*.md` `` lost a separator — quietly, in the preview, in the
/// exported HTML and in the Word document alike.
///
/// The rule already existed for entities: `_finishSpan` returns a code span
/// without decoding them, citing CommonMark. Escapes are the other half of
/// that same sentence and were missed — the sibling nobody looked at.
void main() {
  String html(String source) =>
      MarkdownParser().parse(source).map(ExportService.nodeToHtml).join();

  test('a regular expression keeps its escapes', () {
    expect(html(r'`\.`'), contains(r'<code>\.</code>'));
    expect(html(r'`\*`'), contains(r'<code>\*</code>'));
    expect(html(r'`\_`'), contains(r'<code>\_</code>'));
  });

  test('a Windows path keeps every separator', () {
    // `\t` is not an escapable character, so it survived either way; `\*` is,
    // and it was the one that went.
    expect(html(r'`C:\temp\*.md`'), contains(r'<code>C:\temp\*.md</code>'));
  });

  test('and outside a code span an escape is still an escape', () {
    // The other half. Removing the exception would be a different bug, and
    // this is what says so.
    final out = html(r'\* not emphasis \*');
    expect(out, contains('* not emphasis *'));
    expect(out, isNot(contains('<em>')));
    expect(out, isNot(contains(r'\*')));
  });

  test('a code span inside a link is still literal', () {
    // `_finishSpan` recurses, and each span is restored by its own type. A
    // code span nested in something else has to keep the rule.
    expect(html(r'[see `\.` here](x)'), contains(r'<code>\.</code>'));
  });

  test('a fenced block was never affected', () {
    // Its content never reaches the inline parser. Asserted so that a change
    // to where escapes are handled cannot quietly start affecting it.
    expect(html('```\n\\.\n```'), contains(r'\.'));
  });
}
