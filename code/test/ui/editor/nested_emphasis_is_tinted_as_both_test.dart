import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/ui/editor/syntax_highlighter.dart';

/// `***bold***` is strong around emphasis, and the preview draws it as both.
///
/// The source pane's bold pattern is `\*\*(.+?)\*\*` with nothing saying the
/// run may not be longer, so on `***bold***` it matched `***bold**` and left the
/// last asterisk in the default colour — the pane saying that marker is not part
/// of the emphasis while the pane beside it read all six.
///
/// This is not a corner: pressing Ctrl+I on bold text is how the shape gets
/// written, so every nested emphasis in the document showed a stray asterisk.
void main() {
  const boldColor = Colors.red;
  const defaultColor = Colors.black;

  List<TextSpan> paint(String source) => MarkdownSyntaxHighlighter.highlight(
        source,
        headingColor: Colors.blue,
        boldColor: boldColor,
        codeColor: Colors.green,
        linkColor: Colors.purple,
        defaultColor: defaultColor,
        quoteColor: Colors.teal,
      ).children!.cast<TextSpan>();

  for (final (source, name) in [('***bold***', 'asterisks'), ('___bold___', 'underscores')]) {
    test('$name: a nested run is one span, tinted as bold and italic', () {
      final spans = paint(source);
      expect(spans.map((span) => span.text).join(), source);
      expect(spans, hasLength(1), reason: 'the run was split: '
          '${spans.map((span) => span.text).toList()}');
      expect(spans.single.style?.color, boldColor);
      expect(spans.single.style?.fontWeight, FontWeight.bold);
      expect(spans.single.style?.fontStyle, FontStyle.italic);
    });
  }

  test('a doubled run is still bold and not italic', () {
    for (final source in ['**bold**', '__bold__']) {
      final spans = paint(source);
      expect(spans, hasLength(1), reason: source);
      expect(spans.single.style?.fontWeight, FontWeight.bold, reason: source);
      expect(spans.single.style?.fontStyle, isNot(FontStyle.italic),
          reason: source);
    }
  });

  test('a single run is still italic and not bold', () {
    for (final source in ['*it*', '_it_']) {
      final spans = paint(source);
      expect(spans, hasLength(1), reason: source);
      expect(spans.single.style?.fontStyle, FontStyle.italic, reason: source);
      expect(spans.single.style?.fontWeight, isNot(FontWeight.bold),
          reason: source);
    }
  });

  /// The flanking rule applies to a run of three the same way it applies to a
  /// run of two: a closing run between a full stop and a letter can neither
  /// close nor open, so the pane must not tint it.
  test('a nested run that is not emphasis where it stands is left alone', () {
    final spans = paint('***加粗。***后面');
    expect(
      spans.every((span) => span.style?.fontStyle != FontStyle.italic),
      isTrue,
      reason: 'tinted as emphasis: '
          '${spans.map((span) => "${span.text}/${span.style?.fontStyle}").toList()}',
    );
  });
}
