import 'package:flutter_test/flutter_test.dart';
import 'package:marktext_plus/services/export_service.dart';
import 'package:marktext_plus/services/html_to_markdown.dart';
import 'package:marktext_plus/services/markdown_parser.dart';

/// What the editor writes as HTML, it has to be able to read back.
///
/// The two directions are separate tables of tags, and nothing joined them.
/// The export learned `<mark>`, `<u>`, `<sup>` and `<sub>` and the paste path
/// knew none of them, so the editor's own HTML — never mind a web page — came
/// back with the marking gone and only the words left.
void main() {
  String roundTrip(String markdown) {
    final node = MarkdownParser().parse('$markdown\n').single;
    return HtmlToMarkdown.convert(ExportService.nodeToHtml(node)) ?? '';
  }

  void survives(String name, String markdown) {
    test(name, () => expect(roundTrip(markdown), markdown));
  }

  survives('plain words', 'Just a sentence.');
  survives('bold', 'a **bold** word');
  survives('italic', 'a *soft* word');
  survives('struck out', 'a ~~gone~~ word');
  survives('inline code', 'call `doThing()` now');
  survives('a link', 'read [the manual](https://example.com) first');
  survives('marked', 'see ==the point== here');
  survives('underlined', 'see ++the line++ here');
  survives('raised', 'area 5cm^2^ total');
  survives('lowered', 'water H~2~O only');
}
