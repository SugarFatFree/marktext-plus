import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// What the exporter has to escape, and where.
///
/// `_escapeHtml` is correct and two of its five replacements were held by
/// nothing: removing the one for `&` or the one for `"` left every export
/// test passing.
///
/// They fail differently. Without `&`, a document that says `&lt;` in so many
/// words exports as `&lt;` and a browser draws `<` — the reader's text turned
/// into markup. Without `"`, a link title carrying a quotation mark closes
/// the attribute it was written into, and the rest of the title becomes
/// markup of the browser's choosing.
void main() {
  String html(String markdown) =>
      MarkdownParser().parse(markdown).map(ExportService.nodeToHtml).join();

  test('an ampersand the reader typed stays an ampersand', () {
    expect(html('AT&T'), contains('AT&amp;T'));
  });

  test('an entity the reader typed keeps its meaning', () {
    // `&lt;` is an entity: it means `<`, and a browser must be shown `&lt;`
    // so it draws one. Written through without the ampersand rule it would
    // still read `&lt;` by luck — this is here for the case below it.
    expect(html('&lt;'), contains('&lt;'));

    // A backslash-escaped ampersand is a separate matter and this exporter
    // gets it wrong: `\&lt;` is four characters the reader can see, and it
    // comes out as `&lt;`, which a browser draws as `<`. That belongs to the
    // "Backslash escapes" group the CommonMark ratchet still fails, not to
    // the escaping rules this file is about. Written down rather than left
    // for someone to find twice.
  });

  test('a quotation mark in a link title stays inside the attribute', () {
    // Single-quoted title, so the double quotes belong to the text.
    final out = html("""[x](/url 'he said "hi"')""");
    expect(out, contains('title="he said &quot;hi&quot;"'),
        reason: '标题里的引号没转义就会把属性提前关掉，'
            '后面的内容变成浏览器自己解释的标记');
    expect(out, isNot(contains('title="he said "')),
        reason: '属性不能在标题中间就闭合');
  });

  test('angle brackets in prose do not become tags', () {
    expect(html('a < b and c > d'), contains('&lt;'));
    expect(html('a < b and c > d'), contains('&gt;'));
  });

  test('a single quote is escaped too', () {
    // Not required in body text, but `_escapeHtml` promises it and attributes
    // written with single quotes elsewhere would need it.
    expect(html("it's here"), contains('&#39;'));
  });
}
